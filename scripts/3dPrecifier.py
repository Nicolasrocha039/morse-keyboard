import sys
import os
import re
import ollama
import pygetwindow as gw
import pyautogui
import json
import time
import subprocess  # <--- Injeção para controle nativo do clipboard

# ==========================================
# CONSTANTES DA INFRAESTRUTURA (Extraídas da UI)
# ==========================================
POTENCIA_W = 115.0            # Consumo real da Ender 3 V3 KE
CUSTO_KWH = 0.82              # Tarifa de energia (R$/kWh)
DESGASTE_POR_HORA = 10.0      # Valor alocado para manutenção/desgaste (R$/h)
MARGEM_LUCRO = 2.0            # Margem de 100% (Custo Base * 2)

def parse_time_to_hours(time_str):
    """Converte strings do fatiador (ex: '3h34m') para horas decimais"""
    horas = 0
    minutos = 0
    
    match_h = re.search(r'(\d+)h', time_str, re.IGNORECASE)
    match_m = re.search(r'(\d+)m', time_str, re.IGNORECASE)
    
    if match_h:
        horas = int(match_h.group(1))
    if match_m:
        minutos = int(match_m.group(1))
        
    return horas + (minutos / 60.0)

def analyze_slicer_window():
    """Varre instâncias, captura tela e usa OpenCV+Tesseract para extrair dados"""
    try:
        slicer_windows = gw.getWindowsWithTitle('CrealityPrint')
    except Exception as e:
        print(f"Erro ao buscar janela: {e}")
        return 0.0, 0.0
        
    if not slicer_windows:
        print("Nenhuma janela do Creality Print encontrada.")
        return 0.0, 0.0

    # Configuração do Tesseract (ajuste o caminho se necessário)
    import pytesseract
    pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
    
    total_weight = 0.0
    total_hours = 0.0
    
    for i, win in enumerate(slicer_windows):
        try:
            if win.isMinimized:
                import win32gui
                # SW_SHOWNOACTIVATE = 4 (Restaura o tamanho/posição mas NÃO rouba o foco)
                win32gui.ShowWindow(win._hWnd, 4)
                time.sleep(0.5)
            # Removemos o win.activate() para manter em segundo plano
        except Exception:
            pass
        
        # ==========================================
        # CAPTURA DA JANELA (BACKGROUND)
        # ==========================================
        try:
            import win32gui
            import win32ui
            import win32con
            import ctypes
            import numpy as np
            import cv2
            
            hwnd = win._hWnd
            left, top, right, bot = win32gui.GetClientRect(hwnd)
            w = right - left
            h = bot - top
            
            hwndDC = win32gui.GetWindowDC(hwnd)
            mfcDC  = win32ui.CreateDCFromHandle(hwndDC)
            saveDC = mfcDC.CreateCompatibleDC()
            
            saveBitMap = win32ui.CreateBitmap()
            saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
            saveDC.SelectObject(saveBitMap)
            
            # PrintWindow flag 3 para janelas modernas
            ctypes.windll.user32.PrintWindow(hwnd, saveDC.GetSafeHdc(), 3)
            
            bmpinfo = saveBitMap.GetInfo()
            bmpstr = saveBitMap.GetBitmapBits(True)
            
            img = np.frombuffer(bmpstr, dtype='uint8')
            img.shape = (bmpinfo['bmHeight'], bmpinfo['bmWidth'], 4)
            
            win32gui.DeleteObject(saveBitMap.GetHandle())
            saveDC.DeleteDC()
            mfcDC.DeleteDC()
            win32gui.ReleaseDC(hwnd, hwndDC)
            
            # Converte BGRA para BGR
            img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
            
        except Exception as e:
            # Fallback para pyautogui se o Windows API falhar
            print(f"Fallback para captura normal: {e}")
            win.activate()
            time.sleep(0.5)
            screenshot = pyautogui.screenshot(region=(win.left, win.top, win.width, win.height))
            import numpy as np
            import cv2
            img = cv2.cvtColor(np.array(screenshot), cv2.COLOR_RGB2BGR)
            
        # ==========================================
        # FASE 2: PROCESSAMENTO OPENCV + OCR
        # ==========================================
        try:
            import pytesseract
            
            # Ampliar imagem (ajuda o OCR com letras pequenas)
            img = cv2.resize(img, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
            
            # Converter para escala de cinza
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # Binarização (Otsu) - Melhor contraste
            _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
            
            # Extrair texto com Tesseract
            # --psm 11: Sparse text. Encontra o máximo de texto possível disperso na tela.
            custom_config = r'--oem 3 --psm 11'
            text = pytesseract.image_to_string(thresh, config=custom_config)
            
            # Buscar Tempo (Ex: 1h 34m ou 1h34m ou 45m)
            # Usamos findall e pegamos o ÚLTIMO item encontrado, pois a tabela exibe os tempos 
            # de cada placa (Plate 1, Plate 2...) e a linha "Total" fica no final.
            matches_time = re.findall(r'(\d+)\s*[hH]\s*(\d+)\s*[mM]', text)
            matches_min_only = re.findall(r'(?<!\d[hH]\s)(\d+)\s*[mM]', text)
            
            tempo_str = ""
            if matches_time:
                last_match = matches_time[-1] # Pegar o último match (linha Total)
                tempo_str = f"{last_match[0]}h{last_match[1]}m"
            elif matches_min_only:
                tempo_str = f"{matches_min_only[-1]}m"
            
            # Buscar Peso (Ex: 120g ou 15.5g ou 15,5g)
            # A tabela de Filamento tem colunas (Model, Support, Flushed, Total)
            # Pegando o ÚLTIMO valor em gramas encontrado no texto, garantimos
            # que é a intersecção da linha "Total" com a coluna "Total".
            matches_weight = re.findall(r'(\d+[.,]\d+|\d+)\s*[gG](?!\w)', text)
            peso_float = 0.0
            
            if matches_weight:
                peso_str = matches_weight[-1].replace(',', '.')
                peso_float = float(peso_str)
                
            horas_float = parse_time_to_hours(tempo_str) if tempo_str else 0.0
            
            if peso_float > 0 or horas_float > 0:
                total_weight += peso_float
                total_hours += horas_float
                
        except ImportError:
             print("ERRO: Bibliotecas cv2 (opencv-python) ou pytesseract não encontradas. Rode: pip install opencv-python pytesseract")
        except pytesseract.TesseractNotFoundError:
             print("ERRO: O executável do Tesseract não foi encontrado. Instale o Tesseract-OCR no Windows e descomente a linha pytesseract.pytesseract.tesseract_cmd no topo da função.")
        except Exception as e:
            print(f"Erro no OpenCV/OCR: {e}")
            

    return total_weight, total_hours

if __name__ == "__main__":
    # 1. Captura o valor do filamento passado pelo AutoHotkey
    try:
        preco_kg_filamento = float(sys.argv[1].replace(',', '.')) 
    except IndexError:
        preco_kg_filamento = 190.00
    except ValueError:
        print("Erro: O valor do filamento passado pelo AHK é inválido.")
        sys.exit(1)

    print("Iniciando extração visual furtiva com Granite-Vision...")
    peso_total, horas_totais = analyze_slicer_window()
    
    if peso_total == 0.0 and horas_totais == 0.0:
        print("Falha na extração. Abortando precificação.")
        sys.exit(1)

    # ==========================================
    # MOTOR MATEMÁTICO
    # ==========================================
    custo_material = (peso_total / 1000.0) * preco_kg_filamento
    consumo_kw = POTENCIA_W / 1000.0
    custo_energia = consumo_kw * horas_totais * CUSTO_KWH
    custo_desgaste = horas_totais * DESGASTE_POR_HORA
    
    custo_base = custo_material + custo_energia + custo_desgaste
    preco_venda = custo_base * MARGEM_LUCRO
    
    preco_formatado = f"{preco_venda:.2f}".replace('.', ',')
    
    margem_str = str(MARGEM_LUCRO).replace('.', ',')
    relatorio = f"""=========================================
      RELATÓRIO DE PRECIFICAÇÃO 3D
=========================================
[Parâmetros Base]
- Preço do Filamento: R$ {preco_kg_filamento:.2f}/kg
- Tarifa de Energia: R$ {CUSTO_KWH:.2f}/kWh
- Desgaste/Manutenção: R$ {DESGASTE_POR_HORA:.2f}/h
- Margem de Lucro: {(MARGEM_LUCRO - 1) * 100:.0f}% (x{margem_str})

[Dados da Impressão]
- Peso Estimado: {peso_total:.2f} g
- Tempo Estimado: {horas_totais:.2f} h

[Custos Detalhados]
- Custo de Material: R$ {custo_material:.2f}
- Custo de Energia: R$ {custo_energia:.2f}
- Custo de Desgaste: R$ {custo_desgaste:.2f}
-----------------------------------------
- Custo Base (Total): R$ {custo_base:.2f}

>>> PREÇO SUGERIDO DE VENDA: R$ {preco_formatado} <<<
========================================="""
    
    # Substituir os pontos por vírgulas em todos os números flutuantes formatados com .2f
    import re
    relatorio_br = re.sub(r'(\d+)\.(\d{2})', r'\1,\2', relatorio)
    
    # No console do Windows pode haver problema de codificação ao printar acentos.
    try:
        print(relatorio_br)
    except UnicodeEncodeError:
        print(relatorio_br.encode('ascii', 'ignore').decode('ascii'))
    
    # ==========================================
    # DEPLOY NA ÁREA DE TRANSFERÊNCIA (Clipboard)
    # ==========================================
    try:
        import win32clipboard
        import win32con
        
        # Envia o relatório completo direto pro buffer do Windows em formato UNICODE
        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardData(win32con.CF_UNICODETEXT, relatorio_br)
        win32clipboard.CloseClipboard()
        
        print("[STATUS] Relatório copiado para a área de transferência com sucesso!")
    except ImportError:
        # Fallback caso win32clipboard não consiga ser importado (improvável pois o win32gui funcionou antes)
        try:
            import subprocess
            CREATE_NO_WINDOW = 0x08000000
            subprocess.run(['clip'], input=relatorio_br.encode('mbcs'), check=True, creationflags=CREATE_NO_WINDOW)
            print("[STATUS] Relatório copiado para a área de transferência com sucesso! (Fallback)")
        except Exception as e:
            print(f"[ERRO] Falha no clipboard fallback: {e}")
    except Exception as e:
        print(f"[ERRO] Falha ao injetar valor no clipboard nativo: {e}")
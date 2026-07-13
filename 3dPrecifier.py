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
    """Varre instâncias, captura tela furtivamente e usa OCR (Granite) para extrair dados"""
    try:
        slicer_windows = gw.getWindowsWithTitle('CrealityPrint')
    except Exception as e:
        print(f"Erro ao buscar janela: {e}")
        return 0.0, 0.0
        
    if not slicer_windows:
        print("Nenhuma janela do Creality Print encontrada.")
        return 0.0, 0.0

    imagens_capturadas = []
    
    # ==========================================
    # FASE 1: CAPTURA FÍSICA (Latência Mínima)
    # ==========================================
    for i, win in enumerate(slicer_windows):
        try:
            if win.isMinimized:
                win.restore()
            win.activate()
            time.sleep(0.5) 
        except Exception:
            pass
        
        # ==========================================
        # MACRO-ZONE CROP (Terço Esquerdo da Janela)
        # ==========================================
        # Captura toda a altura, mas apenas os primeiros 35% da largura da janela
        crop_x = win.left
        crop_y = win.top
        crop_width = int(win.width * 0.5) 
        crop_height = win.height
        
        nome_arquivo = f'slicer_temp_{i}.png'
        screenshot = pyautogui.screenshot(region=(crop_x, crop_y, crop_width, crop_height))
        screenshot.save(nome_arquivo)
        imagens_capturadas.append(nome_arquivo)
            
    # ==========================================
    # FASE 2: PROCESSAMENTO OCR EM BACKGROUND
    # ==========================================
    total_weight = 0.0
    total_hours = 0.0
    
    for img in imagens_capturadas:
        try:
            client = ollama.Client(host='http://127.0.0.1:11434')
            response = client.chat(
                model='granite3.2-vision:2b',
                messages=[{
                    'role': 'user',
                    'content': 'Extract the estimated printing time and filament weight from this 3D slicer screenshot. Return the exact values you see.',
                    'images': [img]
                }],
                format={
                    "type": "object",
                    "properties": {
                        "time": {
                            "type": "string",
                            "description": "Estimated printing time (e.g., '1h 30m' or '45m')"
                        },
                        "weight": {
                            "type": "string",
                            "description": "Filament weight in grams (e.g., '120g' or '15.5g')"
                        }
                    },
                    "required": ["time", "weight"]
                },
                options={
                    'temperature': 0.0,
                    'seed': 42
                }
            )
            
            raw_output = response['message']['content']
            match = re.search(r'\{.*?\}', raw_output, re.DOTALL)
            
            if match:
                clean_json = match.group(0)
                try:
                    data = json.loads(clean_json)
                    
                    tempo_str = data.get('time', '0h0m')
                    peso_str = str(data.get('weight', '0')).replace(',', '.')
                    peso_clean = re.sub(r'[^\d.]', '', peso_str)
                    
                    if not peso_clean or peso_clean == '.':
                        peso_float = 0.0
                    else:
                        peso_float = float(peso_clean)
                        
                    horas_float = parse_time_to_hours(tempo_str)
                    
                    total_weight += peso_float
                    total_hours += horas_float
                    
                except json.JSONDecodeError:
                    pass
        except Exception as e:
            print(f"Erro no Ollama: {e}")
            
    for img in imagens_capturadas:
        try:
            os.remove(img)
        except:
            pass

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
    
    print(f"\n[DADOS] Peso: {peso_total}g | Tempo: {horas_totais:.2f}h")
    print(f"\n>>> PREÇO FINAL CALCULADO: R$ {preco_formatado} <<<")
    
    # ==========================================
    # DEPLOY NA ÁREA DE TRANSFERÊNCIA (Clipboard)
    # ==========================================
    try:
        # Envia a string formatada direto pro buffer do Windows
        subprocess.run(['clip'], input=preco_formatado, text=True, check=True)
        print("[STATUS] Valor copiado para a área de transferência com sucesso!")
    except Exception as e:
        print(f"[ERRO] Falha ao injetar valor no clipboard: {e}")
    
import os
import sys
import time
import pyautogui
from PIL import ImageGrab
import pygetwindow as gw

def click_buttons_from_folder(folder_path, region=None, target_image=None, click_last=False):
    if not os.path.exists(folder_path):
        print(f"A pasta '{folder_path}' não foi encontrada.")
        return

    # Salva a posição original do mouse e a janela atual focada
    original_mouse_pos = pyautogui.position()
    active_win = gw.getActiveWindow()
    
    try:
        haystack_image = None
        if region:
            x, y, w, h = region
            try:
                bbox = (x, y, x + w, y + h)
                haystack_image = ImageGrab.grab(bbox=bbox, all_screens=True)
                print(f"Capturando região da janela: {bbox}")
            except Exception as e:
                print(f"Erro ao capturar segunda tela com region. Erro: {e}")
                try:
                    haystack_image = ImageGrab.grab(all_screens=True)
                    region = None 
                except:
                    pass
        
        if not haystack_image:
            try:
                haystack_image = ImageGrab.grab(all_screens=True)
                print("Capturando todas as telas inteiras...")
            except:
                print("Fallback para tela principal")
                haystack_image = ImageGrab.grab()

        found = False
        
        # Se uma imagem específica foi fornecida, procuramos apenas ela.
        # Caso contrário, procuramos todas as imagens da pasta.
        files_to_search = [target_image] if target_image else os.listdir(folder_path)

        for filename in files_to_search:
            if not filename:
                continue
                
            # Se for passado um nome sem extensão ou quisermos garantir que é imagem
            if not filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
                # Assume que é PNG se não tiver extensão
                filename += '.png'
                
            image_path = os.path.join(folder_path, filename)
            if not os.path.exists(image_path):
                print(f"Imagem '{filename}' não encontrada na pasta.")
                continue
                
            print(f"Procurando {filename}...")
            
            for conf in [0.9, 0.8, 0.7]:
                try:
                    if click_last:
                        locations = list(pyautogui.locateAll(image_path, haystack_image, confidence=conf))
                        location = locations[-1] if locations else None
                    else:
                        location = pyautogui.locate(image_path, haystack_image, confidence=conf)
                    
                    if location:
                        center_x, center_y = pyautogui.center(location)
                        
                        if region:
                            abs_x = region[0] + int(center_x)
                            abs_y = region[1] + int(center_y)
                        else:
                            abs_x = int(center_x)
                            abs_y = int(center_y)
                            
                        print(f"  -> ENCONTRADO! Posição: ({abs_x}, {abs_y}) - Confiança: {int(conf*100)}%")
                        
                        pyautogui.moveTo(abs_x, abs_y, duration=0.2)
                        time.sleep(0.1)
                        pyautogui.click()
                        time.sleep(0.1)
                        found = True
                        break
                        
                except pyautogui.ImageNotFoundException:
                    pass
                except Exception as e:
                    if "confidence" in str(e).lower():
                        print("AVISO: Falta instalar o opencv-python para buscas com confiança.")
                        try:
                            if click_last:
                                locations = list(pyautogui.locateAll(image_path, haystack_image))
                                location = locations[-1] if locations else None
                            else:
                                location = pyautogui.locate(image_path, haystack_image)
                            if location:
                                center_x, center_y = pyautogui.center(location)
                                if region:
                                    abs_x = region[0] + int(center_x)
                                    abs_y = region[1] + int(center_y)
                                else:
                                    abs_x = int(center_x)
                                    abs_y = int(center_y)
                                pyautogui.moveTo(abs_x, abs_y, duration=0.2)
                                time.sleep(0.1)
                                pyautogui.click()
                                found = True
                                break
                        except:
                            pass
                        return

            if found:
                break
                
    finally:
        # Garante que o mouse volta para a posição original
        pyautogui.moveTo(original_mouse_pos)
        
        # Garante que o foco volta para a janela que você estava usando
        if active_win:
            try:
                active_win.activate()
            except:
                pass
            
if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    buttons_folder = os.path.join(current_dir, "..", "Buttons")
    
    # Parâmetros esperados:
    # python click_buttons.py [--last] [nome_da_imagem] [X] [Y] [W] [H]
    
    target_image = None
    search_region = None
    click_last = False
    
    args = sys.argv[1:]
    if "--last" in args:
        click_last = True
        args.remove("--last")
        
    if len(args) >= 1:
        target_image = args[0]
        
    if len(args) == 5:
        try:
            search_region = (int(args[1]), int(args[2]), int(args[3]), int(args[4]))
        except ValueError:
            pass
            
    if not search_region:
        print("Aguardando 3 segundos...")
        time.sleep(3)
        
    click_buttons_from_folder(buttons_folder, region=search_region, target_image=target_image, click_last=click_last)


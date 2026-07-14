import sys
import pygetwindow as gw
import pyautogui
import time

def main():
    if len(sys.argv) < 2:
        return
        
    cmd = sys.argv[1]
    
    # Mapping:
    # 1=Shuffle(^s), 2=Repeat(^r), 3=Like(!+b)
    # 4=SeekBack(+{Left}), 5=SeekForward(+{Right}), 6=Search(^l)
    keys = []
    if cmd == "1":
        keys = ['ctrl', 's']
    elif cmd == "2":
        keys = ['ctrl', 'r']
    elif cmd == "3":
        keys = ['alt', 'shift', 'b']
    elif cmd == "4":
        keys = ['shift', 'left']
    elif cmd == "5":
        keys = ['shift', 'right']
    elif cmd == "6":
        keys = ['ctrl', 'l']
    else:
        return

    # Procura janelas que contenham 'Spotify' ou 'spotify' no título
    spotify_windows = [w for w in gw.getAllWindows() if 'spotify' in w.title.lower()]
    
    if not spotify_windows:
        return
        
    # Pega a janela principal (filtrando processos em background por tamanho)
    spotify_win = None
    for w in spotify_windows:
        if w.width > 200 and w.height > 200:
            spotify_win = w
            break
            
    if not spotify_win:
        spotify_win = spotify_windows[0]

    active_win = gw.getActiveWindow()
    
    try:
        # Traz o Spotify para frente rapidamente
        was_minimized = spotify_win.isMinimized
        if was_minimized:
            spotify_win.restore()
            
        spotify_win.activate()
        time.sleep(0.05) 
        
        pyautogui.hotkey(*keys)
        time.sleep(0.05)
        
        if was_minimized:
            spotify_win.minimize()
            
    except Exception as e:
        print(f"Erro: {e}")
        
    finally:
        # Devolve o foco para a janela anterior
        if active_win and active_win._hWnd != spotify_win._hWnd:
            try:
                active_win.activate()
            except:
                pass

if __name__ == "__main__":
    main()

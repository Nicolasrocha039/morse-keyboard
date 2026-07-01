import sys
import os

# Removido hack de AppData: Agora usando dependências locais do Python embutido.

# Evitar travamento do pythonw.exe por conta de sys.stdout/stderr nulos
try:
    if sys.stdout is None:
        sys.stdout = open(os.devnull, 'w', encoding='utf-8')
except AttributeError:
    pass

try:
    if sys.stderr is None:
        sys.stderr = open(os.devnull, 'w', encoding='utf-8')
except AttributeError:
    pass

import asyncio
import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import win32gui
import win32process
import win32api
import ctypes
from ctypes import wintypes
import websockets

# Estruturas do Windows para Caret
class RECT(ctypes.Structure):
    _fields_ = [("left", ctypes.c_long),
                ("top", ctypes.c_long),
                ("right", ctypes.c_long),
                ("bottom", ctypes.c_long)]

class GUITHREADINFO(ctypes.Structure):
    _fields_ = [("cbSize", wintypes.DWORD),
                ("flags", wintypes.DWORD),
                ("hwndActive", wintypes.HWND),
                ("hwndFocus", wintypes.HWND),
                ("hwndCapture", wintypes.HWND),
                ("hwndMenuOwner", wintypes.HWND),
                ("hwndMoveSize", wintypes.HWND),
                ("hwndCaret", wintypes.HWND),
                ("rcCaret", RECT)]

def get_caret_pos():
    hwnd_active = win32gui.GetForegroundWindow()
    if not hwnd_active:
        return None
    thread_id, _ = win32process.GetWindowThreadProcessId(hwnd_active)
    gui_info = GUITHREADINFO()
    gui_info.cbSize = ctypes.sizeof(GUITHREADINFO)
    if ctypes.windll.user32.GetGUIThreadInfo(thread_id, ctypes.byref(gui_info)):
        if gui_info.hwndCaret:
            point = wintypes.POINT()
            point.x = gui_info.rcCaret.left
            point.y = gui_info.rcCaret.bottom
            ctypes.windll.user32.ClientToScreen(gui_info.hwndFocus, ctypes.byref(point))
            return point.x, point.y
    return None

def simulate_key(key):
    VK_CODES = {
        'Q': 0x51,
        'A': 0x41,
        'RIGHT': 0x27,
        'SPACE': 0x20,
        'ENTER': 0x0D,
        'BACKSPACE': 0x08,
        'CAPSLOCK': 0x14
    }
    vk = VK_CODES.get(key.upper())
    if vk:
        # 0 = key down, 2 = key up (KEYEVENTF_KEYUP)
        ctypes.windll.user32.keybd_event(vk, 0, 0, 0)
        ctypes.windll.user32.keybd_event(vk, 0, 2, 0)

# Estado global compartilhado
state = {
    "word": "",
    "visual": "",
    "seq": "",
    "active": False
}
clients = set()
loop = None

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

unigram_dict = []
bigram_dict = {}

def load_dictionaries():
    global unigram_dict, bigram_dict
    dict_path = os.path.join(SCRIPT_DIR, "dict.ini")
    if os.path.isfile(dict_path):
        with open(dict_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("["):
                    parts = line.split("=")
                    if len(parts) >= 2 and parts[1]:
                        unigram_dict.append(parts[1])
                    elif len(parts) >= 1 and parts[0]:
                        unigram_dict.append(parts[0])
                        
    bigrams_path = os.path.join(SCRIPT_DIR, "bigrams.json")
    if os.path.isfile(bigrams_path):
        try:
            with open(bigrams_path, "r", encoding="utf-8") as f:
                bigram_dict = json.load(f)
        except Exception:
            bigram_dict = {}

def save_bigrams():
    bigrams_path = os.path.join(SCRIPT_DIR, "bigrams.json")
    try:
        with open(bigrams_path, "w", encoding="utf-8") as f:
            json.dump(bigram_dict, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print("Error saving bigrams:", e)

MIME_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".js":   "application/javascript; charset=utf-8",
    ".css":  "text/css; charset=utf-8",
    ".json": "application/json",
    ".png":  "image/png",
    ".svg":  "image/svg+xml",
    ".ico":  "image/x-icon",
}

class StateHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?")[0]  # remover query strings
        if path == "/" or path == "":
            path = "/osd.html"
        
        file_path = os.path.join(SCRIPT_DIR, path.lstrip("/").replace("/", os.sep))
        
        if os.path.isfile(file_path):
            ext = os.path.splitext(file_path)[1].lower()
            content_type = MIME_TYPES.get(ext, "application/octet-stream")
            with open(file_path, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found")

    def do_POST(self):
        global state
        if self.path == "/state":
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                state.update(data)
                # Notificar clientes websocket
                if loop:
                    asyncio.run_coroutine_threadsafe(broadcast_state(), loop)
            except Exception as e:
                print("Error parsing state:", e)
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')

        elif self.path == "/input":
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                try:
                    data = json.loads(post_data.decode('utf-8'))
                    key = data.get("key")
                    if key:
                        simulate_key(key)
                except Exception as e:
                    print("Error simulating key:", e)
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')

        elif self.path == "/suggest":
            content_length = int(self.headers.get('Content-Length', 0))
            suggestion = ""
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                try:
                    data = json.loads(post_data.decode('utf-8'))
                    word_buffer = data.get("wordBuffer", "").strip()
                    visual_buffer = data.get("visualBuffer", "").lower()
                    
                    words = word_buffer.split()
                    prev_word = words[-1].lower() if words else ""
                    
                    if prev_word in bigram_dict:
                        next_words = bigram_dict[prev_word]
                        sorted_next = sorted(next_words.items(), key=lambda item: item[1], reverse=True)
                        for n_word, freq in sorted_next:
                            if n_word.startswith(visual_buffer):
                                suggestion = n_word
                                break
                    
                    if not suggestion and visual_buffer:
                        for u_word in unigram_dict:
                            if u_word.lower().startswith(visual_buffer):
                                suggestion = u_word
                                break
                except Exception as e:
                    print("Error predicting suggestion:", e)
            
            resp = json.dumps({"suggestion": suggestion})
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(resp.encode('utf-8'))

        elif self.path == "/learn":
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                try:
                    data = json.loads(post_data.decode('utf-8'))
                    word_buffer = data.get("wordBuffer", "").strip()
                    
                    words = word_buffer.split()
                    if len(words) >= 2:
                        w1 = words[-2].lower()
                        w2 = words[-1].lower()
                        
                        if w1 not in bigram_dict:
                            bigram_dict[w1] = {}
                        if w2 not in bigram_dict[w1]:
                            bigram_dict[w1][w2] = 0
                        bigram_dict[w1][w2] += 1
                        
                        save_bigrams()
                except Exception as e:
                    print("Error learning bigram:", e)
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
            
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, format, *args):
        pass  # Silenciar logs do HTTP server no console

def run_http_server():
    import socket
    server = HTTPServer(('0.0.0.0', 8766), StateHandler)
    try:
        local_ip = socket.gethostbyname(socket.gethostname())
    except Exception:
        local_ip = 'SEU-IP'
    print(f"Servidor HTTP rodando em:")
    print(f"  http://localhost:8766  (este PC)")
    print(f"  http://{local_ip}:8766  (rede local)")
    print(f"\n==============================================")
    print(f"📱 CONTROLE REMOTO PELO CELULAR:")
    print(f"  Abra no seu celular: http://{local_ip}:8766/remote.html")
    print(f"==============================================\n")
    server.serve_forever()

async def ws_handler(websocket):
    clients.add(websocket)
    # Envia o estado inicial
    await websocket.send(json.dumps({"type": "state", "data": state}))
    try:
        async for message in websocket:
            pass
    finally:
        clients.remove(websocket)

async def broadcast_state():
    if clients:
        message = json.dumps({"type": "state", "data": state})
        dead = set()
        for client in list(clients):
            try:
                await client.send(message)
            except Exception:
                dead.add(client)
        clients.difference_update(dead)

async def heartbeat_loop():
    """Transmite o estado atual a todos os clientes a cada 1 segundo.
    Garante que a página OSD saiba que está conectada mesmo quando Morse está inativo."""
    while True:
        await asyncio.sleep(1)
        if clients:
            await broadcast_state()

async def track_caret_loop():
    hwnd_osd = None
    while True:
        try:
            if state.get("active", False):
                if not hwnd_osd or not win32gui.IsWindow(hwnd_osd):
                    hwnd_osd = win32gui.FindWindow(None, "MorseWordOSD")
                
                if hwnd_osd:
                    pos = get_caret_pos()
                    if pos:
                        target_x, target_y = pos[0], pos[1] + 20
                    else:
                        x, y = win32gui.GetCursorPos()
                        target_x, target_y = x, y + 20
                    
                    # Limitar coordenadas à resolução da tela principal
                    screen_w = win32api.GetSystemMetrics(0)
                    screen_h = win32api.GetSystemMetrics(1)
                    
                    # Estimar tamanho do OSD de palavra (300px larg, 40px alt)
                    w, h = 300, 40
                    if target_x + w > screen_w:
                        target_x = screen_w - w
                    if target_x < 0:
                        target_x = 0
                    if target_y + h > screen_h:
                        target_y = screen_h - h
                    if target_y < 0:
                        target_y = 0
                    
                    # Reposicionar a janela AHK sem focar ou alterar a ordem Z
                    win32gui.SetWindowPos(hwnd_osd, 0, target_x, target_y, 0, 0, 21) # SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE
        except Exception as e:
            pass
        await asyncio.sleep(0.02) # Checar a cada 20ms

async def main():
    global loop
    loop = asyncio.get_running_loop()
    
    load_dictionaries()
    
    # Iniciar servidor HTTP em thread separada
    http_thread = threading.Thread(target=run_http_server, daemon=True)
    http_thread.start()
    
    # Iniciar loop de rastreamento do cursor
    asyncio.create_task(track_caret_loop())
    
    # Iniciar heartbeat (envia estado a cada 1s para manter clientes atualizados)
    asyncio.create_task(heartbeat_loop())
    
    # Iniciar servidor WebSocket acessível na rede local
    async with websockets.serve(ws_handler, "0.0.0.0", 8765):
        print("Servidor WebSocket rodando em ws://0.0.0.0:8765...")
        await asyncio.Future()  # Rodar indefinidamente

if __name__ == "__main__":
    import traceback
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        # Gravar erro com caminho absoluto para garantir gravação
        script_dir = os.path.dirname(os.path.abspath(__file__))
        log_path = os.path.join(script_dir, "python_error.log")
        with open(log_path, "w", encoding="utf-8") as f:
            traceback.print_exc(file=f)

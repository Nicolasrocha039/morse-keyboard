import os

filepath = r'c:\Users\Nicolas\.gemini\antigravity-ide\scratch\morse_keyboard\morse_osd.ahk'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

header = '''global osdPosX := IniRead(A_ScriptDir . "\osd_pos.ini", "Position", "X", 10)
global osdPosY := IniRead(A_ScriptDir . "\osd_pos.ini", "Position", "Y", 10)

OnMessage(0x0201, WM_LBUTTONDOWN)
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global osd, osdMini, osdPosX, osdPosY
    if (hwnd == osd.Hwnd || hwnd == osdMini.Hwnd) {
        ; SendMessage blocks until dragging is finished
        SendMessage(0xA1, 2, 0, 0, "ahk_id " hwnd)
        
        ; Save the new position
        WinGetPos(&X, &Y, , , "ahk_id " hwnd)
        IniWrite(X, A_ScriptDir . "\osd_pos.ini", "Position", "X")
        IniWrite(Y, A_ScriptDir . "\osd_pos.ini", "Position", "Y")
        
        ; Keep them synced
        osdPosX := X
        osdPosY := Y
        
        ; Move the other GUI to match
        if (hwnd == osd.Hwnd) {
            try osdMini.Move(X, Y)
        } else {
            try osd.Move(X, Y)
        }
    }
}

'''

# We inject this right before '; ── GUI pequena (OFF) ──'
target_gui = '; ── GUI pequena (OFF) ──'
if target_gui in text:
    text = text.replace(target_gui, header + target_gui)

text = text.replace('osdMini.Show("Hide x10 y10")', 'osdMini.Show("Hide x" . osdPosX . " y" . osdPosY)')
text = text.replace('osd.Show("Hide x10 y10")', 'osd.Show("Hide x" . osdPosX . " y" . osdPosY)')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

print('Success')

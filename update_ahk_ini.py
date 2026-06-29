import re

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix UI corrupted texts
text = text.replace('digita\ufffdo', 'digitação')
text = text.replace('RQQQ:\ufffd | RAQQ:\ufffd', 'RQQQ:à | RAQQ:ç')
text = text.replace('Modo Morse Keyboard \ufffd Projetado', 'Modo Morse Keyboard - Projetado')
text = text.replace('Navega\ufffdo de abas', 'Navegação de abas')

ini_logic = """
; Carregar dicionário a partir do arquivo INI
global morseMap := Map()
try {
    iniPath := A_ScriptDir . "\\morse_map.ini"
    mapStr := IniRead(iniPath, "MorseMap")
    Loop Parse, mapStr, "`n", "`r"
    {
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length == 2) {
            morseMap[parts[1]] := parts[2]
        }
    }
} catch as err {
    MsgBox("Erro ao carregar morse_map.ini: " . err.Message)
}
"""

match = re.search(r'; \-\-\- INICIO DO MAPEAMENTO AUTOMATICO \-\-\-.*?; \-\-\- FIM DO MAPEAMENTO AUTOMATICO \-\-\-', text, flags=re.DOTALL)
if match:
    text = text.replace(match.group(0), ini_logic)

# Remove any lingering morseMap assignments (like the manual ones at the top)
text = re.sub(r'morseMap\["[QAR]+"\]\s*:=\s*"[^"]*"\n?', '', text)

with open('morse_keyboard.ahk', 'w', encoding='utf-8-sig') as f:
    f.write(text)

print("Updated morse_keyboard.ahk to use INI file.")

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

import re
matches = re.findall(r'morseMap\["[A-Z]+"\] := "\ufffd"', text)
for m in matches:
    print(m)

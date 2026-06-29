import os

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open(r'c:\Users\Nicolas\.gemini\antigravity-ide\brain\cc0c5820-c5d2-4677-8261-42853592c286\scratch\inv_syllables.txt', 'r', encoding='utf-8') as f:
    inv_content = f.read()

insert_idx = -1
for i, line in enumerate(lines):
    if line.strip() == 'morseMap["RRAAAQR"] := "Ur"':
        insert_idx = i + 1
        break

if insert_idx != -1:
    lines.insert(insert_idx, '\n' + inv_content + '\n')
    with open('morse_keyboard.ahk', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("Injected successfully!")
else:
    print("Target line not found.")

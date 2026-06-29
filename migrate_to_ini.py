import re

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix corrupted strings in the text globally before extraction
text = text.replace('\ufffd', '') # Just to be safe, but wait, some are valid characters mapped to \ufffd!
# Actually, let's fix known ones:
text = text.replace('morseMap["RRRAQQ"] := "\ufffd"', 'morseMap["RRRAQQ"] := "Ç"')
text = text.replace('morseMap["RAQQ"] := "\ufffd"', 'morseMap["RAQQ"] := "ç"')
text = text.replace('morseMap["RRAQQQ"] := "\ufffd"', 'morseMap["RRAQQQ"] := "ã"')
text = text.replace('morseMap["RRAQQA"] := "\ufffd"', 'morseMap["RRAQQA"] := "õ"')
text = text.replace('morseMap["RRAQQR"] := "\ufffd"', 'morseMap["RRAQQR"] := "â"')

matches = re.findall(r'morseMap\["([QAR]+)"\]\s*:=\s*"([^"]+)"', text)

ini_content = "[MorseMap]\n"
for seq, val in matches:
    ini_content += f"{seq}={val}\n"

with open('morse_map.ini', 'w', encoding='utf-8-sig') as f:
    f.write(ini_content)

print(f"Extracted {len(matches)} mappings into morse_map.ini")

import re

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    lines = f.readlines()

map_keys = {}
duplicates = []
for i, line in enumerate(lines):
    match = re.search(r'morseMap\["([QAR]+)"\]\s*:=\s*"([^"]+)"', line)
    if match:
        key = match.group(1)
        val = match.group(2)
        if key in map_keys:
            duplicates.append((key, val, i+1, map_keys[key]))
        else:
            map_keys[key] = (val, i+1)

if duplicates:
    for d in duplicates:
        print(f'Duplicate: {d[0]} -> {d[1]} (line {d[2]}), previously {d[3][0]} (line {d[3][1]})')
else:
    print('No duplicates found!')

import re

# Arbitrary syllables to remove
old_syls = [
    'ch', 'lh', 'nh',
    'qu', 'que', 'qui',
    'as', 'es', 'is', 'os', 'us',
    'an', 'en', 'in', 'on', 'un',
    'am', 'em', 'im', 'om', 'um',
    'al', 'el', 'il', 'ol', 'ul'
]
old_syls_upper = [s.capitalize() for s in old_syls]
to_remove = set(old_syls + old_syls_upper)

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open('triples.txt', 'r', encoding='utf-8') as f:
    triples_content = f.read()

new_lines = []
skip = False
for line in lines:
    # Check if this line is an assignment to an old syllable
    match = re.search(r'morseMap\["[QAR]+"\]\s*:=\s*"([^"]+)"', line)
    if match:
        val = match.group(1)
        if val in to_remove:
            continue
    
    # Check if it's the section header for old syllables to remove the comments
    if "SÍLABAS E DÍGRAFOS COMUNS" in line:
        # We will inject the triples here!
        new_lines.append(triples_content + '\n')
        skip = True
        continue
    
    if skip:
        # We skip until we hit the next major section
        if "SÍLABAS UNIVERSAIS (Consoante + Vogal + R)" in line:
            skip = False
            # Append the previous comment line (the separator)
            new_lines.append('; ═══════════════════════════════════════════════════════════════════════════════\n')
            new_lines.append(line)
        continue
    
    new_lines.append(line)

with open('morse_keyboard.ahk', 'w', encoding='utf-8-sig') as f:
    f.writelines(new_lines)

print("Updated morse_keyboard.ahk")

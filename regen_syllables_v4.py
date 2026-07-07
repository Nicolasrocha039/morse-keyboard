import codecs

letters = {
    'a': 'QQ', 'b': 'QA', 'c': 'QR', 'd': 'QQQ', 'e': 'QQA', 'f': 'QQR', 'g': 'QAQ',
    'h': 'QAA', 'i': 'QAR', 'j': 'QRQ', 'k': 'QRA', 'l': 'QRR', 'm': 'AQ', 'n': 'AA',
    'o': 'AR', 'p': 'AQQ', 'q': 'AQA', 'r': 'AQR', 's': 'AAQ', 't': 'AAA', 'u': 'AAR',
    'v': 'ARQ', 'w': 'ARA', 'x': 'ARR', 'y': 'RQ', 'z': 'RRA' # Note: Using RRA for z to avoid Ctrl (RA) collision if any, though RA was original
}
# Wait, user's morse_map.ini uses RA for Ctrl. Let's make sure 'z' doesn't collide with Ctrl.
# Actually, the user doesn't have 'z' as a single letter mapped right now, but for suffix 'z' we can use RRA or RA.
# I'll use RRA for z just in case.

vowels = ['a', 'e', 'i', 'o', 'u']
consonants = [c for c in letters.keys() if c not in vowels]

valid_triples = {
    'r': ['b', 'c', 'd', 'f', 'g', 'p', 't', 'v'],
    'l': ['b', 'c', 'f', 'g', 'p', 't'],
    'h': ['c', 'l', 'n'],
    'u': ['q', 'g']
}

# Now suffixes are exactly the letters!
suffixes_cons = {
    'm': letters['m'],
    'n': letters['n'],
    'r': letters['r'],
    's': letters['s'],
    'z': letters['z'],
    'l': letters['l']
}

suffixes_vowels = {
    'i': letters['i'],
    'u': letters['u'],
    'a': letters['a'],
    'o': letters['o'],
    'e': letters['e']
}

generated = {}
collisions = []

def add_seq(seq, val):
    if seq in generated:
        collisions.append(f"Internal Collision: {seq} -> {generated[seq]} and {val}")
    generated[seq] = val
    seq_up = "RR" + seq
    if seq_up in generated:
         collisions.append(f"Internal Collision: {seq_up} -> {generated[seq_up]} and {val.capitalize()}")
    generated[seq_up] = val.capitalize()

# 1. Universais (C + R + V)
for c in consonants:
    for v in vowels:
        add_seq(letters[c] + 'R' + letters[v], c + v)

# 2. Invertidas (V + R + C)
for v in vowels:
    for c in consonants:
        add_seq(letters[v] + 'R' + letters[c], v + c)

# 3. Triplas (C1 + R + C2 + R + V)
for mod, cons_list in valid_triples.items():
    for c in cons_list:
        for v in vowels:
            if mod == 'u' and v == 'u': continue
            add_seq(letters[c] + 'R' + letters[mod] + 'R' + letters[v], c + mod + v)

# 4. Encontros Vocálicos Independentes (V + R + V)
for v1 in vowels:
    for v2 in vowels:
        if v1 == v2: continue
        add_seq(letters[v1] + 'R' + letters[v2], v1 + v2)

# 5. C + R + V + R + Suffix_Consonant
for c in consonants:
    for v in vowels:
        for term, suf in suffixes_cons.items():
            add_seq(letters[c] + 'R' + letters[v] + 'R' + suf, c + v + term)

# 6. C + R + V + R + Suffix_Vowel
for c in consonants:
    for v in vowels:
        for v2, suf in suffixes_vowels.items():
            if v == v2: continue
            add_seq(letters[c] + 'R' + letters[v] + 'R' + suf, c + v + v2)

# 7. Triplas + R + Suffix_Consonant
for mod, cons_list in valid_triples.items():
    for c in cons_list:
        for v in vowels:
            if mod == 'u' and v == 'u': continue
            for term, suf in suffixes_cons.items():
                add_seq(letters[c] + 'R' + letters[mod] + 'R' + letters[v] + 'R' + suf, c + mod + v + term)

print(f"Generated {len(generated)} syllables.")
if collisions:
    for c in collisions[:20]:
        print(c)
else:
    print("No internal collisions!")

used = set()
used_map = {}
with open('c:/Users/Nicolas/.gemini/antigravity-ide/scratch/morse_keyboard/morse_map.ini', 'r', encoding='utf-16') as f:
    for line in f:
        line = line.strip()
        if '=' in line and not line.startswith('['):
            parts = line.split('=', 1)
            val = parts[1]
            if len(val) == 1 or val.startswith('{') or val.startswith('^') or val.startswith('~') or val.startswith('´') or val.startswith('`'):
                used.add(parts[0])
                used_map[parts[0]] = val

ext = []
for s in list(generated.keys()):
    if s in used:
        ext.append(f"{s} -> {generated[s]} collides with {used_map[s]}")
        val = generated[s]
        del generated[s]
        add_seq(s + 'Q', val)

if ext:
    print(f"External collisions resolved: {len(ext)}")
else:
    print("No external collisions.")

# Save to morse_map.ini replacing old syllables
with open('c:/Users/Nicolas/.gemini/antigravity-ide/scratch/morse_keyboard/morse_map.ini', 'r', encoding='utf-16') as f:
    lines = f.readlines()

filtered = []
for line in lines:
    stripped = line.strip()
    if '=' in stripped and not stripped.startswith('['):
        k, v = stripped.split('=', 1)
        if len(v) > 1 and not v.startswith('{') and not v.startswith('^') and not v.startswith('~') and not v.startswith('´') and not v.startswith('`'):
            if v.isalpha() and len(v) >= 2:
                continue # Skip old syllables
    filtered.append(line)

clean_lines = []
for i, line in enumerate(filtered):
    if line.strip() == "" and (i == 0 or filtered[i-1].strip() == ""):
        continue
    clean_lines.append(line)

out_ini = "".join(clean_lines)
out_ini += "\n; ====================================================================================================\n"
out_ini += "; NOVA LÓGICA DE SÍLABAS UNIFICADA (Lógica Pura: L + R + L + R + L...)\n"
out_ini += "; ====================================================================================================\n"
for seq, val in generated.items():
    if not seq.startswith('RR'):
        out_ini += f"{seq}={val}\n"
        
out_ini += "\n; --- MAIÚSCULAS ---\n"
for seq, val in generated.items():
    if seq.startswith('RR'):
        out_ini += f"{seq}={val}\n"

with open('c:/Users/Nicolas/.gemini/antigravity-ide/scratch/morse_keyboard/morse_map.ini', 'w', encoding='utf-16') as f:
    f.write(out_ini)
print("Updated morse_map.ini successfully!")

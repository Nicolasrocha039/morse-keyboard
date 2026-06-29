import os

consonants = {
    'b': 'QA', 'c': 'QR', 'd': 'QQQ', 'f': 'QQR', 'g': 'QAQ', 
    'h': 'QAA', 'j': 'QRQ', 'k': 'QRA', 'l': 'QRR', 'm': 'AQ', 
    'n': 'AA', 'p': 'AQQ', 'q': 'AQA', 'r': 'AQR', 's': 'AAQ', 
    't': 'AAA', 'v': 'ARQ', 'w': 'ARA', 'x': 'ARR', 'y': 'RQ', 'z': 'RA'
}
vowels = {'a': 'QQ', 'e': 'QA', 'i': 'QR', 'o': 'AQ', 'u': 'AA'}

# R-modifier (Consonant + r + Vowel) -> Suffix: A
r_cons = ['b', 'c', 'd', 'f', 'g', 'p', 't', 'v']

# L-modifier (Consonant + l + Vowel) -> Suffix: AQ
l_cons = ['b', 'c', 'f', 'g', 'p', 't']

# H-modifier (Consonant + h + Vowel) -> Suffix: AR
h_cons = ['c', 'l', 'n']

# U-modifier (q/g + u + Vowel) -> Suffix: AA
u_cons = ['q', 'g']

output = "; ═══════════════════════════════════════════════════════════════════════════════\n"
output += "; SÍLABAS TRIPLAS (Cons + r/l/h + Vogal)\n"
output += "; ═══════════════════════════════════════════════════════════════════════════════\n"

def generate_group(cons_list, modifier_letter, suffix, name):
    res = f"; --- {name} --- \n"
    for c in cons_list:
        for v, v_code in vowels.items():
            if name == 'U-modifier (q/g + u + Vogal) [Sufixo: AA]' and v == 'u': continue
            
            syl = c + modifier_letter + v
            code = consonants[c] + v_code + suffix
            res += f'morseMap["{code}"] := "{syl}"\n'
            
            syl_up = syl.capitalize()
            code_up = "RR" + code
            res += f'morseMap["{code_up}"] := "{syl_up}"\n'
        res += "\n"
    return res

output += generate_group(r_cons, 'r', 'A', 'R-modifier (Cons + r + Vogal) [Sufixo: A]')
output += generate_group(l_cons, 'l', 'AQ', 'L-modifier (Cons + l + Vogal) [Sufixo: AQ]')
output += generate_group(h_cons, 'h', 'AR', 'H-modifier (Cons + h + Vogal) [Sufixo: AR]')
output += generate_group(u_cons, 'u', 'AA', 'U-modifier (q/g + u + Vogal) [Sufixo: AA]')

with open('triples.txt', 'w', encoding='utf-8') as f:
    f.write(output)

print("Generated triples.txt")

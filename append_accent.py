import os
with open(r'c:\Users\Nicolas\.gemini\antigravity-ide\scratch\morse_keyboard\morse_core.ahk', 'a', encoding='utf-8') as f:
    f.write('''
CombineAccent(accent, char) {
    if accent = "´" {
        MapA := Map("a", "á", "e", "é", "i", "í", "o", "ó", "u", "ú", "A", "Á", "E", "É", "I", "Í", "O", "Ó", "U", "Ú", "c", "ç", "C", "Ç")
        return MapA.Has(char) ? MapA[char] : char
    }
    if accent = "~" {
        MapT := Map("a", "ã", "o", "õ", "n", "ñ", "A", "Ã", "O", "Õ", "N", "Ñ")
        return MapT.Has(char) ? MapT[char] : char
    }
    if accent = "^" {
        MapC := Map("a", "â", "e", "ê", "i", "î", "o", "ô", "u", "û", "A", "Â", "E", "Ê", "I", "Î", "O", "Ô", "U", "Û")
        return MapC.Has(char) ? MapC[char] : char
    }
    if accent = "``" {
        MapG := Map("a", "à", "e", "è", "i", "ì", "o", "ò", "u", "ù", "A", "À", "E", "È", "I", "Ì", "O", "Ò", "U", "Ù")
        return MapG.Has(char) ? MapG[char] : char
    }
    return char
}
''')
print('Done')

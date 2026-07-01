with open('morse_core.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''RemoveAccents(str) {
    str := StrReplace(str, "á", "a")
    str := StrReplace(str, "à", "a")
    str := StrReplace(str, "ã", "a")
    str := StrReplace(str, "â", "a")
    str := StrReplace(str, "é", "e")
    str := StrReplace(str, "ê", "e")
    str := StrReplace(str, "í", "i")
    str := StrReplace(str, "ó", "o")
    str := StrReplace(str, "õ", "o")
    str := StrReplace(str, "ô", "o")
    str := StrReplace(str, "ú", "u")
    str := StrReplace(str, "ç", "c")
    return str
}'''

import re
text = re.sub(r'RemoveAccents\(str\) \{.*?return str\n\}', replacement, text, flags=re.DOTALL)

with open('morse_core.ahk', 'w', encoding='utf-8-sig') as f:
    f.write(text)

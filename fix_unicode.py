with open('morse_core.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''RemoveAccents(str) {
    str := StrReplace(str, "\u00e1", "a")
    str := StrReplace(str, "\u00e0", "a")
    str := StrReplace(str, "\u00e3", "a")
    str := StrReplace(str, "\u00e2", "a")
    str := StrReplace(str, "\u00e9", "e")
    str := StrReplace(str, "\u00ea", "e")
    str := StrReplace(str, "\u00ed", "i")
    str := StrReplace(str, "\u00f3", "o")
    str := StrReplace(str, "\u00f5", "o")
    str := StrReplace(str, "\u00f4", "o")
    str := StrReplace(str, "\u00fa", "u")
    str := StrReplace(str, "\u00e7", "c")
    return str
}'''

import re
text = re.sub(r'RemoveAccents\(str\) \{.*?return str\n\}', replacement, text, flags=re.DOTALL)

with open('morse_core.ahk', 'w', encoding='utf-8-sig') as f:
    f.write(text)

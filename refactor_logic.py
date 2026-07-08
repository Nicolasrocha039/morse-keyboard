import sys
import os

filepath = r'c:\Users\Nicolas\.gemini\antigravity-ide\scratch\morse_keyboard\morse_core.ahk'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

target1 = '''        ; === DEAD KEYS: Modificadores e Acentos acumulam no pendingPrefix ===
        global pendingPrefix
        if !IsSet(pendingPrefix)
            pendingPrefix := ""'''

replacement1 = '''        ; === DEAD KEYS: Modificadores e Acentos acumulam separadamente ===
        global pendingModifiers, pendingAccent, pendingSpecial
        if !IsSet(pendingModifiers)
            pendingModifiers := ""
        if !IsSet(pendingAccent)
            pendingAccent := ""
        if !IsSet(pendingSpecial)
            pendingSpecial := ""'''

text = text.replace(target1, replacement1)

# Replace all occurrences of pendingPrefix in Modifier, Accent, FKey, MKey, MacroKey
text = text.replace('pendingPrefix .= "^"', 'pendingModifiers .= "^"')
text = text.replace('pendingPrefix := StrReplace(pendingPrefix, "^", "")', 'pendingModifiers := StrReplace(pendingModifiers, "^", "")')
text = text.replace('InStr(pendingPrefix, "^")', 'InStr(pendingModifiers, "^")')
text = text.replace('pendingPrefix .= "+"', 'pendingModifiers .= "+"')
text = text.replace('pendingPrefix := StrReplace(pendingPrefix, "+", "")', 'pendingModifiers := StrReplace(pendingModifiers, "+", "")')
text = text.replace('InStr(pendingPrefix, "+")', 'InStr(pendingModifiers, "+")')
text = text.replace('pendingPrefix .= "!"', 'pendingModifiers .= "!"')
text = text.replace('pendingPrefix := StrReplace(pendingPrefix, "!", "")', 'pendingModifiers := StrReplace(pendingModifiers, "!", "")')
text = text.replace('InStr(pendingPrefix, "!")', 'InStr(pendingModifiers, "!")')
text = text.replace('pendingPrefix .= "#"', 'pendingModifiers .= "#"')
text = text.replace('pendingPrefix := StrReplace(pendingPrefix, "#", "")', 'pendingModifiers := StrReplace(pendingModifiers, "#", "")')
text = text.replace('InStr(pendingPrefix, "#")', 'InStr(pendingModifiers, "#")')

text = text.replace('ToolTip("Prefixo: " . (pendingPrefix != "" ? pendingPrefix : "(nenhum)"),', 'ToolTip("Modificadores: " . (pendingModifiers != "" ? pendingModifiers : "(nenhum)"),')
text = text.replace('LogBuffers("Modifier Prefix Toggle Ctrl → pendingPrefix: " . pendingPrefix)', 'LogBuffers("Modifier Toggle Ctrl → pendingModifiers: " . pendingModifiers)')
text = text.replace('LogBuffers("Modifier Prefix Toggle Shift → pendingPrefix: " . pendingPrefix)', 'LogBuffers("Modifier Toggle Shift → pendingModifiers: " . pendingModifiers)')
text = text.replace('LogBuffers("Modifier Prefix Toggle Alt → pendingPrefix: " . pendingPrefix)', 'LogBuffers("Modifier Toggle Alt → pendingModifiers: " . pendingModifiers)')
text = text.replace('LogBuffers("Modifier Prefix Toggle Win → pendingPrefix: " . pendingPrefix)', 'LogBuffers("Modifier Toggle Win → pendingModifiers: " . pendingModifiers)')

text = text.replace('pendingPrefix .= output', 'pendingAccent := output')
text = text.replace('ToolTip("Acento pendente: " . pendingPrefix,', 'ToolTip("Acento pendente: " . pendingAccent,')
text = text.replace('LogBuffers("Accent Prefix: " . pendingPrefix)', 'LogBuffers("Accent: " . pendingAccent)')

text = text.replace('pendingPrefix .= "F:"', 'pendingSpecial := "F:"')
text = text.replace('LogBuffers("FKey Prefix: " . pendingPrefix)', 'LogBuffers("FKey Prefix: " . pendingSpecial)')
text = text.replace('pendingPrefix .= "M:"', 'pendingSpecial := "M:"')
text = text.replace('LogBuffers("MKey Prefix: " . pendingPrefix)', 'LogBuffers("MKey Prefix: " . pendingSpecial)')
text = text.replace('pendingPrefix .= "X:"', 'pendingSpecial := "X:"')
text = text.replace('LogBuffers("MacroKey Prefix: " . pendingPrefix)', 'LogBuffers("MacroKey Prefix: " . pendingSpecial)')

text = text.replace('if InStr(pendingPrefix, "F:") {', 'if pendingSpecial == "F:" {')
text = text.replace('modOnly := StrReplace(pendingPrefix, "F:", "")', 'modOnly := pendingModifiers')
text = text.replace('if InStr(pendingPrefix, "M:") {', 'if pendingSpecial == "M:" {')
text = text.replace('modOnly := StrReplace(pendingPrefix, "M:", "")', 'modOnly := pendingModifiers')
text = text.replace('if InStr(pendingPrefix, "X:") {', 'if pendingSpecial == "X:" {')

# The separation logic target
target2 = '''        ; Separar acentos e modificadores do pendingPrefix
        accentChars := ""
        modifierChars := ""
        if pendingPrefix != "" {
            Loop Parse, pendingPrefix {
                ch := A_LoopField
                if ch = "^" || ch = "!" || ch = "+" || ch = "#"
                    modifierChars .= ch
                else
                    accentChars .= ch ; ´, ~, `, ^(acento)
            }
        }'''

replacement2 = '''        accentChars := pendingAccent
        modifierChars := pendingModifiers'''

text = text.replace(target2, replacement2)

# Fix remaining pendingPrefix resets in final part
text = text.replace('pendingPrefix := ""', 'pendingModifiers := ""\n            pendingAccent := ""')

text = text.replace('pendingSpecial := ""\n            UpdateOSD()\n            return\n        }\n\n        if pendingSpecial == "M:"', 'pendingSpecial := ""\n            pendingModifiers := ""\n            UpdateOSD()\n            return\n        }\n\n        if pendingSpecial == "M:"')

text = text.replace('pendingSpecial := ""\n            UpdateOSD()\n            return\n        }\n\n        if pendingSpecial == "X:"', 'pendingSpecial := ""\n            pendingModifiers := ""\n            UpdateOSD()\n            return\n        }\n\n        if pendingSpecial == "X:"')

text = text.replace('pendingSpecial := ""\n            UpdateOSD()\n            return\n        }\n\n        ; Verificar se é um comando', 'pendingSpecial := ""\n            pendingModifiers := ""\n            UpdateOSD()\n            return\n        }\n\n        ; Verificar se é um comando')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

print('Done')

import sys
import re

with open('morse_core.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

target1 = """        } else {
            ; Usando o ADBKeyBoard para suportar acentos e caracteres especiais nativamente
            escapedOutput := StrReplace(output, "'", "'\\''")
            
            ; Envia os caracteres usando o Intent de broadcast do ADBKeyBoard
            adbCmd := adbPath . ' shell am broadcast -a ADB_INPUT_TEXT --es msg ' . "'" . escapedOutput . "'"
            RunWait(adbCmd, , "Hide")
        }"""

replacement1 = """        } else if RegExMatch(output, "i)^\^([a-z])$", &match) {
            ; Atalhos de texto: Ctrl+C, Ctrl+X, Ctrl+V, Ctrl+Z, Ctrl+A
            char := StrLower(match[1])
            if char == "c"
                RunWait(adbPath . " shell input keyevent 278", , "Hide") ; COPY
            else if char == "x"
                RunWait(adbPath . " shell input keyevent 277", , "Hide") ; CUT
            else if char == "v"
                RunWait(adbPath . " shell input keyevent 279", , "Hide") ; PASTE
            else if char == "z"
                RunWait(adbPath . " shell input keyevent 281", , "Hide") ; UNDO
            else if char == "a"
                RunWait(adbPath . " shell input keyevent 286", , "Hide") ; SELECT ALL
            else {
                escapedOutput := StrReplace(output, "'", "'\\''")
                adbCmd := adbPath . ' shell am broadcast -a ADB_INPUT_TEXT --es msg ' . "'" . escapedOutput . "'"
                RunWait(adbCmd, , "Hide")
            }
        } else {
            ; Usando o ADBKeyBoard para suportar acentos e caracteres especiais nativamente
            escapedOutput := StrReplace(output, "'", "'\\''")
            
            ; Envia os caracteres usando o Intent de broadcast do ADBKeyBoard
            adbCmd := adbPath . ' shell am broadcast -a ADB_INPUT_TEXT --es msg ' . "'" . escapedOutput . "'"
            RunWait(adbCmd, , "Hide")
        }"""

target2 = """            } else {
                ; Caractere normal — montar envio com acentos e modificadores
                if accentChars != "" {
                    ; Enviar cada acento como dead key seguido da letra
                    ; Ex: ´ + a → á (o Windows combina automaticamente)
                    Loop Parse, accentChars {
                        Send("{Blind}{" . A_LoopField . "}")
                    }
                }
                if modifierChars != "" {
                    ; Atalho com modificador: ^c, !{F4}, etc.
                    SendToSystem(modifierChars . output)
                } else {
                    ; Letra normal (possivelmente precedida de acento dead key)
                    wordBuffer .= output
                    visualBuffer .= output
                    SendToSystem(output)
                }
                pendingPrefix := ""
            }"""

replacement2 = """            } else {
                ; Caractere normal — montar envio com acentos e modificadores
                finalChar := output
                if accentChars != "" {
                    finalChar := CombineAccent(SubStr(accentChars, -1), output)
                    
                    if !adbMode {
                        ; No Windows, enviamos os acentos separados como dead keys para o SO processar (ex: ´ + a)
                        Loop Parse, accentChars {
                            Send("{Blind}{" . A_LoopField . "}")
                        }
                    }
                }

                if modifierChars != "" {
                    if adbMode && accentChars != "" {
                        SendToSystem(modifierChars . finalChar)
                    } else {
                        SendToSystem(modifierChars . output)
                    }
                } else {
                    if adbMode && accentChars != "" {
                        SendToSystem(finalChar)
                    } else {
                        SendToSystem(output)
                    }
                    if modifierChars == "" {
                        wordBuffer .= finalChar
                        visualBuffer .= finalChar
                    }
                }
                pendingPrefix := ""
            }"""

replacement3 = """}

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
"""

if target1 not in text:
    print("target1 not found!")
else:
    text = text.replace(target1, replacement1)

if target2 not in text:
    print("target2 not found!")
else:
    text = text.replace(target2, replacement2)

if "CombineAccent(" not in text:
    # replace the last closing brace with the replacement3
    idx = text.rfind("}")
    if idx != -1:
        text = text[:idx] + replacement3 + text[idx+1:]
    else:
        print("Could not find the end of the file!")

with open('morse_core.ahk', 'w', encoding='utf-8') as f:
    f.write(text)

print("Patch complete.")

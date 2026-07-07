import os

with open('morse_core.ahk', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """          if output == "{MacroKey}" {
              Run('"' . A_ScriptDir . '\python\python.exe" "' . A_ScriptDir . '\3dPrecifier.py"', A_ScriptDir, "Hide")
              LogBuffers("Executed Macro: 3dPrecifier")
          } else if isCommand {"""

content = content.replace('          if isCommand {', replacement)

with open('morse_core.ahk', 'w', encoding='utf-8-sig') as f:
    f.write(content)

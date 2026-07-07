import os

for f in ['morse_keyboard.ahk', 'morse_core.ahk', 'morse_config.ahk']:
    with open(f, 'r', encoding='utf-8', errors='ignore') as file:
        content = file.read()
    
    idx = content.find('#Requires AutoHotkey v2.0')
    if idx != -1:
        content = content[idx:]
    else:
        # For morse_core.ahk which doesn't have #Requires
        idx = content.find('SendStateToPython() {')
        if idx != -1:
            content = content[idx:]
    
    with open(f, 'w', encoding='utf-8-sig') as file:
        file.write(content)

with open('morse_core.ahk', 'r', encoding='utf-8-sig') as f:
    content = f.read()

replacement = """          if output == "{MacroKey}" {
              Run('"' . A_ScriptDir . '\python\python.exe" "' . A_ScriptDir . '\3dPrecifier.py"', A_ScriptDir, "Hide")
              LogBuffers("Executed Macro: 3dPrecifier")
          } else if isCommand {"""

content = content.replace('          if isCommand {', replacement)
# Inject 127.0.0.1 fix since I checked out HEAD~1
content = content.replace('localhost:8765', '127.0.0.1:8765')
content = content.replace('localhost:8766', '127.0.0.1:8766')

with open('morse_core.ahk', 'w', encoding='utf-8-sig') as f:
    f.write(content)

print("Fixed!")

import re

out = '#Requires AutoHotkey v2.0\n\nglobal MONO_FONT := "Consolas"\n\n'

with open('recovered.txt', 'r', encoding='utf-8') as f:
    r1 = f.read()
# Strip line numbers like '443: '
r1 = re.sub(r'^\s*\d+:\s?', '', r1, flags=re.MULTILINE)
# Extract FormatForCard to end
idx = r1.find('FormatForCard(val) {')
if idx != -1:
    out += r1[idx:] + '\n\n'

with open('recovered_gui.txt', 'r', encoding='utf-8') as f:
    r2 = f.read()
r2 = re.sub(r'^\s*\d+:\s?', '', r2, flags=re.MULTILINE)
idx_gui = r2.find('; ── GUI pequena (OFF) ──')
end_gui = r2.find('TabGoRight() {')
if idx_gui != -1 and end_gui != -1:
    # Need to remove the literal strings BuildLetrasText() etc, because we removed those and use FileRead!
    # In morse_osd.ahk, the mapTab setup:
    gui_block = r2[idx_gui:end_gui]
    gui_block = gui_block.replace('BuildLetrasText()', 'osdGeral1')
    gui_block = gui_block.replace('BuildNumSimboloText()', 'osdGeral2')
    gui_block = gui_block.replace('BuildEspeciaisText()', 'osdSyllables')
    gui_block = gui_block.replace('BuildFKeysText()', 'osdTriples')
    # Actually wait! The tabs were Letras, Numeros, Atalhos, Especiais, Sylabas in v11.
    # In my current version, I extracted osd_geral_col1, osd_geral_col2, osd_syllables, osd_triples!
    # Let me just grab the GUI block from the FIRST extraction attempt which was correct!

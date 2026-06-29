import re

ahk = open('morse_keyboard.ahk', encoding='utf-8').read()
matches = re.findall(r'morseMap\[\"(.*?)\"\]\s*:=\s*\"(.*?)\"', ahk)

seqs = []
for seq, out in matches:
    out_escaped = out.replace('\"', '\\\"').replace('\\', '\\\\')
    seqs.append(f'{{s:\"{seq}\",o:\"{out_escaped}\"}}')

js_array = 'const SEQ = [\n  ' + ',\n  '.join(seqs) + '\n];'

osd_html = open('osd.html', encoding='utf-8').read()
start_marker = 'const SEQ = ['
end_marker = '];'
start_idx = osd_html.find(start_marker)
end_idx = osd_html.find(end_marker, start_idx) + len(end_marker)

new_osd = osd_html[:start_idx] + js_array + osd_html[end_idx:]
open('osd.html', 'w', encoding='utf-8').write(new_osd)
print(f'Extraidas {len(matches)} sequencias para osd.html.')

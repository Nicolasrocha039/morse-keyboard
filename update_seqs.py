import re

# Read sequences from INI
seqs = []
with open('morse_map.ini', 'r', encoding='utf-16') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('[') or '=' not in line:
            continue
        parts = line.split('=', 1)
        if len(parts) == 2:
            seq, out = parts
            out_escaped = out.replace('\"', '\\\"').replace('\\', '\\\\')
            seqs.append(f'{{s:\"{seq}\",o:\"{out_escaped}\"}}')

js_array = 'const SEQ = [\n  ' + ',\n  '.join(seqs) + '\n];'

# Update osd.html
with open('osd.html', 'r', encoding='utf-8') as f:
    osd_html = f.read()

start_marker = 'const SEQ = ['
end_marker = '];'
start_idx = osd_html.find(start_marker)
end_idx = osd_html.find(end_marker, start_idx) + len(end_marker)

new_osd = osd_html[:start_idx] + js_array + osd_html[end_idx:]

with open('osd.html', 'w', encoding='utf-8') as f:
    f.write(new_osd)

print(f'Extraidas {len(seqs)} sequencias para osd.html.')

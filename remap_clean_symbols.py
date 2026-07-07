import codecs

# First remove all RARR mappings we added
content = codecs.open('morse_map.ini', 'r', 'utf-16le').read()
lines = content.split('\r\n')
new_lines = [l for l in lines if not l.startswith('RARR')]
codecs.open('morse_map.ini', 'w', 'utf-16le').write('\r\n'.join(new_lines))

# Now add the 8 clean symbols
symbols = [
    ('RARRQ', '/'),
    ('RARRA', ';'),
    ('RARRR', '-'),
    ('RARRQQ', '='),
    ('RARRQA', '['),
    ('RARRQR', ']'),
    ('RARRAQ', "'"),
    ('RARRAA', '\\\\')
]
content = codecs.open('morse_map.ini', 'r', 'utf-16le').read()
for seq, sym in symbols:
    content += f'{seq}={sym}\r\n'

# Oh wait, we shouldn't remove ALL RARR, because RARRRQ=´ and RARRQAQ=` are accents!
# Let me fix that:
new_lines = [l for l in lines if not (l.startswith('RARR') and 'RARRRQ' not in l and 'RARRQAQ' not in l)]
codecs.open('morse_map.ini', 'w', 'utf-16le').write('\r\n'.join(new_lines))
content = codecs.open('morse_map.ini', 'r', 'utf-16le').read()
for seq, sym in symbols:
    content += f'{seq}={sym}\r\n'
codecs.open('morse_map.ini', 'w', 'utf-16le').write(content)
print('Done remapping clean symbols')

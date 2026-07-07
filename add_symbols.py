import codecs
symbols = [
    ('RARRQ', '?'), ('RARRA', '/'), ('RARRR', ';'),
    ('RARRQQ', ':'), ('RARRQA', '-'), ('RARRQR', '_'),
    ('RARRAQ', '='), ('RARRAA', '+'), ('RARRAR', '['),
    ('RARRQQQ', '{'), ('RARRQQA', ']'), ('RARRQQR', '}'),
    ('RARRRQQ', "'"), ('RARRRQA', '\"'), ('RARRRQR', '<'),
    ('RARRAQQ', '>'), ('RARRAQA', '\\\\')
]
content = codecs.open('morse_map.ini', 'r', 'utf-16le').read()
for seq, sym in symbols:
    content += f'{seq}={sym}\r\n'
codecs.open('morse_map.ini', 'w', 'utf-16le').write(content)
print('Done mapping symbols')

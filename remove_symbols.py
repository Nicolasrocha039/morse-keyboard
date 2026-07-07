import codecs
content = codecs.open('morse_map.ini', 'r', 'utf-16le').read()
lines = content.split('\r\n')
to_remove = ['RARRQ=?', 'RARRQQ=:', 'RARRQR=_', 'RARRAA=+', 'RARRQQQ={', 'RARRQQR=}', 'RARRRQA=\"', 'RARRRQR=<', 'RARRAQQ=>']
new_lines = [l for l in lines if l not in to_remove]
codecs.open('morse_map.ini', 'w', 'utf-16le').write('\r\n'.join(new_lines))
print('Removed redundant symbols')

import urllib.request
from bs4 import BeautifulSoup
import re

url = 'https://support.microsoft.com/pt-br/windows/atalhos-do-teclado-no-windows-dcc61a57-8ff0-cffe-9796-cb9706c75eec'
html = urllib.request.urlopen(url).read().decode('utf-8')
soup = BeautifulSoup(html, 'html.parser')

tables = soup.find_all('table')
config = '[Shortcuts]\n'
keys_seen = set()
count = 0

for table in tables:
    for row in table.find_all('tr')[1:]:
        cols = row.find_all(['td', 'th'])
        if len(cols) >= 2:
            key = cols[0].get_text(separator=' ', strip=True).replace('\n', ' ')
            desc = cols[1].get_text(separator=' ', strip=True).replace('\n', ' ')
            if key and desc and key not in keys_seen:
                keys_seen.add(key)
                config += f'{key}={desc}\n'
                count += 1

out_path = r'c:\Users\Nicolas\.gemini\antigravity-ide\scratch\morse_keyboard\config\windows_shortcuts.ini'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(config)

print(f'Saved {count} shortcuts to {out_path}')

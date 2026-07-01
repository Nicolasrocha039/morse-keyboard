import nltk
import ssl
import collections

# Fix SSL context for downloading
try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    pass
else:
    ssl._create_default_https_context = _create_unverified_https_context

print("Baixando corpus do NLTK...")
nltk.download('floresta', quiet=True)
nltk.download('mac_morpho', quiet=True)

from nltk.corpus import floresta, mac_morpho

print("Processando palavras...")
words = []
try:
    words.extend(floresta.words())
except Exception as e:
    print("Aviso: floresta falhou", e)

try:
    words.extend(mac_morpho.words())
except Exception as e:
    print("Aviso: mac_morpho falhou", e)

# Filter words (alpha only, lowercase)
valid_words = [w.lower() for w in words if w.isalpha() and len(w) > 1]

print("Contando frequências...")
counter = collections.Counter(valid_words)

# Sort by frequency (most common first)
sorted_words = [word for word, count in counter.most_common()]

print(f"Total de palavras únicas: {len(sorted_words)}")

import unicodedata

def strip_accents(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')

# Write to dict.ini
print("Escrevendo dict.ini...")
with open("dict.ini", "w", encoding="utf-8-sig") as f:
    f.write("[Palavras]\n")
    for w in sorted_words:
        unaccented = strip_accents(w)
        f.write(f"{unaccented}={w}\n")

print("dict.ini gerado com sucesso!")

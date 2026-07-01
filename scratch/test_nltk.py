import nltk
import ssl
import sys

try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    pass
else:
    ssl._create_default_https_context = _create_unverified_https_context

try:
    nltk.download('floresta')
    from nltk.corpus import floresta
    words = floresta.words()
    # just print unique word count
    unique_words = set(w.lower() for w in words if w.isalpha())
    print("Floresta unique words:", len(unique_words))
    
    nltk.download('mac_morpho')
    from nltk.corpus import mac_morpho
    words2 = mac_morpho.words()
    unique_words2 = set(w.lower() for w in words2 if w.isalpha())
    print("Mac_morpho unique words:", len(unique_words2))
except Exception as e:
    print("Error:", e)
    sys.exit(1)

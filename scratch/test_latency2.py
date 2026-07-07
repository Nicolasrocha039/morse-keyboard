import time
import urllib.request
import json

data = json.dumps({"wordBuffer": "", "visualBuffer": "ab"}).encode('utf-8')
t0 = time.time()
try:
    resp = urllib.request.urlopen('http://127.0.0.1:8766/suggest', data=data).read()
    print("Latency 127.0.0.1:", time.time() - t0)
    
    t1 = time.time()
    resp2 = urllib.request.urlopen('http://localhost:8766/suggest', data=data).read()
    print("Latency localhost:", time.time() - t1)
except Exception as e:
    print("Error:", e)

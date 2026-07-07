import time
import urllib.request
import json

data = json.dumps({"wordBuffer": "", "visualBuffer": "ab"}).encode('utf-8')
t0 = time.time()
try:
    resp = urllib.request.urlopen('http://localhost:8766/suggest', data=data).read()
    print("Latency:", time.time() - t0)
    print("Response:", resp)
except Exception as e:
    print("Error:", e)

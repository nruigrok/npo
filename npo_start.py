

import re
import requests

BASE_URL = 'https://www.npostart.nl/media/series/{POW}/fragments?tileMapping=normal'
HEADER = {'X-Requested-With': 'XMLHttpRequest'}

pow = "KN_1699061"


url = BASE_URL.format(POW=pow)
r = requests.get(url, headers = HEADER)
r.raise_for_status()
data = r.json()['tiles']
print((data))
for d in data:
    print((d))
    #nextlink = r.json()['nextlink']

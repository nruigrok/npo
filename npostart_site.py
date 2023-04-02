import argparse
import csv
import json
import re
import sys
from pathlib import Path
from typing import Iterable
import cssselect
from lxml import html, etree
from amcatclient import AmcatAPI
import requests
from itertools import count
from datetime import datetime
import cssselect
import lxml
import logging

from requests import HTTPError

#OP1_URL = "https://www.npostart.nl/op1/POW_04596562"
OP1_URL = "https://www.npostart.nl/{pow}"

def get_content(pow: str) -> str:
    url = OP1_URL.format(pow=pow)
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    text = tree.xpath("//meta[@name='description']")
    text2 = text[0].get("content")
    return text2


def get_pows(fn: Path):
    d = json.load(fn.open())
    for tile in d['tiles']:
        m = re.search('<a href="https://www.npostart.nl/.*?/(\d+-\d+-\d+)/(\w+_\d+)', tile)
        if not m:
            print(repr(tile))
            raise Exception()
        date, pow = m.groups()
        yield date, pow



#print(get_gasten("POW_04917677"))
if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse", type=Path)
    args = parser.parse_args()

    w = csv.writer(sys.stdout)
    w.writerow(["date", "pow", "content"])
    for file in args.files:
        logging.info(file)
        for date, pow in get_pows(file):
            content = get_content(pow)
            w.writerow([date, pow, content])

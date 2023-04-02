import argparse
import json
import re
from pathlib import Path
from typing import Tuple, Iterable

from amcatclient.amcatclient import get_chunks
from lxml import html
from amcatclient import AmcatAPI
import requests
from datetime import datetime
import logging

import requests

BASE_URL = "https://www.npostart.nl/media/series/{POW}/fragments?tileMapping=normal&tileType=asset&pageType=franchise"
BASE_URL_NEXT = "https://www.npostart.nl{nextlink}&tileMapping=normal&tileType=asset&pageType=franchise"
HEADER = {'X-Requested-With': 'XMLHttpRequest'}
BASE_URL_ITEM = "https://www.npostart.nl/{pow}"


def api_calls(pow: str) -> Iterable[dict]:
    url = BASE_URL.format(POW=pow)
    data, nl = api_call(url)
    while nl != "":
        url = BASE_URL_NEXT.format(nextlink=nl)
        data, nl = api_call(url)
        yield data


def api_call(url):
    r = requests.get(url, headers=HEADER)
    r.raise_for_status()
    data = r.json()['tiles']
    nextlink = r.json()['nextLink']
    return data, nextlink


def get_content(url: str) ->  str:
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    text = tree.xpath("//meta[@name='description']")
    text2 = text[0].get("content")
    return text2


def get_pows(tile):
    m = re.search('<a href="https://www.npostart.nl/.*?/(\d+-\d+-\d+)/(\w+_\d+)', tile)
    if not m:
        raise Exception()
    date, pow = m.groups()
    return date, pow


def scrape_tiles(tiles, publisher, seen_urls):
    for tile in tiles:
        date, pow = get_pows(tile)
        url = BASE_URL_ITEM.format(pow=pow)
        print(url)
        if url in seen_urls:
            continue
        article = {}
        content = get_content(url)
        article['date'] = datetime.strptime(date, "%d-%m-%Y")
        article['title'] = pow
        article['text'] = content
        article['url'] = url
        article['publisher'] = publisher
        yield article


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("pow", nargs="+", help="files to parse", type=Path)
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument("publisher", help="Publisher",)
    parser.add_argument("--batchsize", help="Batch size for uploading to AmCAT", type=int, default=10)
    args = parser.parse_args()

    logging.info(f"Scraping into AmCAT {args.articleset}")
    conn = AmcatAPI(args.server)
    publisher = args.publisher

    urls = {a['url'] for a in conn.get_articles(args.project, args.articleset, columns=["url"], publisher=publisher)}

    logging.info(f"Already {len(urls)} in AmCAT {args.project}:{args.articleset}")
    pow = args.pow[0]

    for data in api_calls(pow):
        articles = list(scrape_tiles(data, publisher, urls))
        conn.create_articles(args.project, args.articleset, articles)
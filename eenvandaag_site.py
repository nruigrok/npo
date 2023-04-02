import argparse
import csv
import json
import re
import sys
from pathlib import Path
from typing import Iterable

from amcatclient.amcatclient import get_chunks
from lxml import html, etree
from amcatclient import AmcatAPI
import requests
from itertools import count
from datetime import datetime
import cssselect
import lxml
import logging
import locale
import sys
from requests import HTTPError
import elasticsearch


from elasticsearch import Elasticsearch
from elasticsearch.helpers import scan

es = Elasticsearch("https://search-api.avrotros.nl/v5/eenvandaag")
r = es.search(size=0, from_=0)
n = r['hits']['total']

def get_articles(batch_size,from_):
    query = {"sort": [{"datetime": {"order": "desc"}}]}
    r = es.search(body=query, size=batch_size, from_=from_)
    with open('data.json', 'w') as outfile:
        json.dump(r, outfile)
    for art in r['hits']['hits']:
        article = {}
        src = art['_source']
        article['url'] = src['url']
        print(article['url'])
        if "/contact/" in article['url']:
            logging.warning(f"Skipping article {article['url']}: contact")
            continue
        if "eenvandaag.avrotros.nl/tag/" in article['url']:
            logging.warning(f"Skipping article {article['url']}: contact")
            continue
        date = src['datetime']
        dt = datetime.fromtimestamp(date)
        article['date'] = dt.strftime("%Y-%m-%d")
       # if not "2021" in article['date']:
        #    continue
        article['title'] = src['title']
        topics = src['topics']
        article['topics'] = (", ".join(topics))
        tags = src['tags']
        article['tags'] = (", ".join(tags))
        authors = src['members']
        article['author'] = (", ".join(authors))
        teaser = src['teaser']
        body = src['bodytext']
        if teaser:
            article['text'] = teaser + body
        else:
            article['text'] = body
        if article['text'] is None:
            logging.warning(f"Skipping article {article['url']}: no text")
            continue
        if article['text'] == "":
            logging.warning(f"Skipping article {article['url']}: no text")
            continue
        yield article


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument("--batchsize", help="Batch size for uploading to AmCAT", type=int, default=10)
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    logging.info(f"Scraping into AmCAT {args.articleset}")
    conn = AmcatAPI(args.server)
    print(f"{n} in total")
    batch_size = 100
    urls = {a['url'] for a in conn.get_articles(args.project, args.articleset, columns=["url"])}
    logging.info(f"Already {len(urls)} in AmCAT {args.project}:{args.articleset}")

    for from_ in range(0, n, batch_size):
        batch = list(get_articles(batch_size,from_))
        conn.create_articles(args.project, args.articleset, batch)


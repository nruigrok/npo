import sys
from datetime import datetime
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv

from amcatclient import AmcatAPI
from amcatclient.amcatclient import get_chunks



def scrape_files(files, publisher):
    for file in files:
        meta = {}
        with open(str(file)) as data_file:
            data = json.load(data_file)
            id = data['info']['id']
            meta['publisher'] = publisher
            meta['npo_id'] = id
            meta['omroep'] = data['info']['licensor']
            try:
                meta['description'] = data['info']['description']
            except KeyError:
                meta['description'] = data['info']['fullTitle']
            meta['url'] = f"https://zoeken.beeldengeluid.nl/program/{id}"
            date = data['info']['broadcastDate']
            meta['date'] = datetime.strptime(date, '%d-%m-%Y').isoformat()
            print(meta)
            if 'assets' not in data:
                continue
            for asset in data['assets']:
                for segment in asset['segments']:
                    article = meta.copy()
                    article['title'] = segment['title']
                    try:
                        article['text'] = segment['description']
                    except KeyError:
                        article['text'] = segment['title']
                    try:
                        article['displayOffset'] = segment['displayOffset']
                    except KeyError:
                        article['displayOffset'] = 0
                    article['startAt'] = segment['startAt']
                    article['duration'] = segment['duration']
                    if article['date'] >="2022-01-01":
                        print(article)
                        yield article
                    else:
                        continue


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument("publisher", help="Program name", )
    parser.add_argument("files", nargs="+", help="files to parse")
    parser.add_argument("--batchsize", help="Batch size for uploading to AmCAT", type=int, default=10)
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    logging.info(f"Scraping into AmCAT {args.articleset}")
    conn = AmcatAPI(args.server)
    chunks = get_chunks(scrape_files(args.files, args.publisher), batch_size=args.batchsize)
    for batch in chunks:
        print(f"!!! Uploading {len(batch)} articles")
        conn.create_articles(args.project, args.articleset, batch)


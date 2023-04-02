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



def get_meta(data, publisher):
    meta={}
    id = data['info']['id']
    meta['publisher'] = publisher
    meta['npo_id'] = id
    meta['omroep'] = data['info']['licensor']
    date = data['info']['broadcastDate']  
    meta['url'] = f"https://zoeken.beeldengeluid.nl/program/{id}"
    meta['date'] = datetime.strptime(date, '%d-%m-%Y').isoformat()
    return meta

def scrape_files(files, publisher):
    for file in files:
        with open(str(file)) as data_file:
            data = json.load(data_file)
            s = data['assets'][0]['segments']
            print(f"type is {type(s)} and s is {s}")
            for segment in data['assets'][0]['segments']:
                meta =get_meta(data, publisher)
                meta['title'] = (segment['title'])
                meta['text']=(segment['description'])               
                yield meta


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
    print(conn)

    chunks = get_chunks(scrape_files(args.files, args.publisher), batch_size=args.batchsize)
    for batch in chunks:
        print(f"!!! Uploading {len(batch)} articles")
        conn.create_articles(args.project, args.articleset, batch)


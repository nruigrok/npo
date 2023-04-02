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


def extract_subtitles(data, start, finish, type='subtitle', lag=1000) -> Iterable[str]:
    for x in data['subtitles']:
        xstart = x['startAt'] - lag
        xfinish = xstart + x['duration']
        if x['type'] == type and xstart >= start and xfinish < finish:
            yield x['title']


def extract_segments(data: dict) -> Iterable[dict]:
    for x in data['assets'][0]['segments']:
        start = x['startAt']
        duration = x['duration']
        finish = start + duration
        segment = dict(
            segment_id=x['id'],
            title=x['title'],
            start=start,
            duration=duration,
        )
        subtitles = extract_subtitles(data, start, finish)
        segment['text'] = "\n\n".join(subtitles)
        segment['speakers_tag'] = list(set(extract_subtitles(data, start, finish, type="speaker-label")))
        yield segment

def scrape_files(files):
    for file in files:
        article = {}
        with open(str(file)) as data_file:
            data = json.load(data_file)
            id = data['info']['id']
            article['npo_id'] = id
            article['publisher'] = data['info']['licensor']
            article['url'] = f"https://zoeken.beeldengeluid.nl/program/{id}"
            date = data['info']['broadcastDate']
            article['date'] = datetime.strptime(date, '%d-%m-%Y').isoformat()
            for segment in extract_segments(data):
                segment.update(article)
                print(json.dumps(segment, indent=2))
                yield segment


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument("files", nargs="+", help="files to parse")
    parser.add_argument("--batchsize", help="Batch size for uploading to AmCAT", type=int, default=10)
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    logging.info(f"Scraping into AmCAT {args.articleset}")
    conn = AmcatAPI(args.server)


    for art in scrape_files(args.files):
        if art['text']=="":
            continue
        for batch in get_chunks(art, batch_size=args.batchsize):
            print(f"!!! Uploading {len(batch)} articles")
            conn.create_articles(args.project, args.articleset, [art])

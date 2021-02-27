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


def extract_subtitles(data):
    id = data['info']['id']
    speakers = []
    subtitles = []
    for x in data['subtitles']:
        if x['type'] == 'speaker-label':
            speakers.append(x)
        if x['type'] == 'subtitle':
            subtitles.append(x)
    speakers = sorted(speakers, key=lambda x: x['startAt'])
    subtitles = sorted(subtitles, key=lambda x: x['startAt'])
    (print(f"!!!!{speakers}"))
    if speakers:
        current_speaker = speakers.pop(0)
    else:
        current_speaker = None
    for sub in subtitles:
        while (current_speaker is not None) and (sub['startAt'] >= current_speaker['startAt'] + current_speaker['duration']):
            if speakers:
                current_speaker = speakers.pop(0)
            else:
                current_speaker = None
        if (current_speaker is None) or (sub['startAt'] < current_speaker['startAt']):
            speaker = None
        else:
            speaker = current_speaker
        yield sub, speaker



def scrape_files(files):
    for file in files:
        article = {}
        with open(str(file)) as data_file:
            data = json.load(data_file)
            id = data['info']['id']
            article['npo_id'] = id
            article['publisher'] = data['info']['licensor']
            article['url'] = f"https://zoeken.beeldengeluid.nl/program/{id}"
            if 'fullTitle' in data['info']:
                article['title'] = data['info']['fullTitle']
            else:
                article['title'] = data['info']['title']
            date = data['info']['broadcastDate']
            article['date'] = datetime.strptime(date, '%d-%m-%Y').isoformat()
            subtitles = [x['title'] for x in data['subtitles'] if x['type'] == 'subtitle']
            article['text'] = "\n\n".join(subtitles)
            yield article

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
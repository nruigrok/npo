import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv

def scrape(data):
    id = data['info']['id']
    if 'fullTitle' in data['info']:
        title = data['info']['fullTitle']
    else:
        title = data['info']['title']
    date = data['info']['broadcastDate']
    nsub = len([x for x in data['subtitles'] if x['type'] == 'subtitle'])
    nface = len([x for x in data['subtitles'] if x['type'] == 'face-label'])
    nspeech = len([x for x in data['subtitles'] if x['type'] == 'speaker-label'])
    other = {x['type'] for x in data['subtitles']} - {"subtitle", "face-label", "speaker-label"}
    speakers = []
    subtitles = []
    for x in data['subtitles']:
        if x['type'] == 'speaker-label':
            speakers.append(x)
        if x['type'] == 'subtitle':
            subtitles.append(x)
    speakers = sorted(speakers,key=lambda x: x['startAt'])
    subtitles = sorted(subtitles, key=lambda x: x['startAt'])
    if other:
        logging.warning(f"Unknown sub types: {other}")


    #print(title, id, date)
    return [id, title, date, nsub, nface, nspeech]




def scrape_files(files, name):
    out = csv.writer(sys.stdout)
    out.writerow(["programid", "name", "date", "#subtitles"])

    for file in files:
        #logging.info(file)
        with open(str(file)) as data_file:
            data = json.load(data_file)
            row = scrape(data)
            out.writerow(row)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="name of program to parse")
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()

    scrape_files(args.files, args.name)

import re
import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv

def extract_segments(data):
    id = data['info']['id']
    for x in data['assets'][0]['segments']:
        yield x

def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["id", "omroep","title", "date", "item_start", "item_duration","topic","text", "covid"])
    for file in files:
        logging.info(file)
        with open(str(file)) as data_file:
            data = json.load(data_file)
            id = data['info']['id']
            if 'fullTitle' in data['info']:
                title = data['info']['fullTitle']
            else:
                title = data['info']['title']
            date = data['info']['broadcastDate']
            omroep = data['info']['licensor']
            try:
                description = data['info']['description']
            except KeyError:
                description = data['info']['fullTitle']
            covid = int(bool(re.search("covid|corona|vaccin|avondklok|lockdown|mondkapje|quarantaine|anderhalvemetersamenleving", description.lower())))
            subject = None
            sstart = None
            duration = None
            out.writerow([id, omroep, title, date, sstart, duration, subject, description, covid])


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()
    scrape_files(args.files)

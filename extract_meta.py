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
    description = data['info']['description']
    series = data['info']['series']['title']
    omroep = data['info']['licensor']

    date = data['info']['broadcastDate']
    nsub = len([x for x in data['subtitles'] if x['type'] == 'subtitle'])
    nface = len([x for x in data['subtitles'] if x['type'] == 'face-label'])
    nspeech = len([x for x in data['subtitles'] if x['type'] == 'speaker-label'])
    return [id, series, omroep, title, date, nsub, nface, nspeech, description]




def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["programid", "name", "omroep", "titel","date","nsubtitles","nfaces","nspeakerlabels","description"])

    for file in files:
        #logging.info(file)
        with open(str(file)) as data_file:
            data = json.load(data_file)
            row = scrape(data)
            out.writerow(row)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()

    scrape_files(args.files)

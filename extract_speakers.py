import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv

def extract_speakers(data):
    speakers =[]
    for x in data['subtitles']:
        if x['type'] == 'speaker-label':
            speakers.append(x)
    return speakers


def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["series", "date", "speaker", "total duration (s)", "text"])
    for file in files:
        #logging.info(file)
        with open(str(file)) as data_file:
            data = json.load(data_file)
            title = data['info']['series']['title']
            date = data['info']['broadcastDate']
           # text = data['subtitles'][title]
            speakers = {}
            for speaker in extract_speakers(data):
                s = speaker['title']
                d = speaker['duration']
                out.writerow([title, date, s, d/1000])



if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()

    scrape_files(args.files)

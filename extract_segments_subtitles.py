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



def get_segment(data):
   if 'assets' not in data:
       segments = data['info']['description']
       segments = segments.split('*')
       length = 60/len(segments)
       for text in segments:
           yield text, length
   else:
        for asset in data['assets']:
                for segment in asset['segments']:
                    if 'description' not in segment:
                        text = segment['fullTitle']
                        length = segment['duration']
                        yield text, length
                    else:
                    #            print(json.dumps(segment, indent=2))
                        text = segment['description']
                        length = segment['duration']
                        yield text, length


def scrape(data):
    id = data['info']['id']
    if 'fullTitle' in data['info']:
        title = data['info']['fullTitle']
    else:
        title = data['info']['title']
    series = data['info']['series']['title']
    omroep = data['info']['licensor']
    date = data['info']['broadcastDate']
    for segment, length in get_segment(data):
        yield [id, series, omroep, title, date, segment, length]


def scrape_files(files):
    print(files)
    out = csv.writer(sys.stdout)
    out.writerow(["programid", "show", "omroep", "titel","date", "segment","length"])
    for file in files:
        with open(str(file)) as data_file:
            data = json.load(data_file)
            for row in scrape(data):
                out.writerow(row)



if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()
    scrape_files(args.files)


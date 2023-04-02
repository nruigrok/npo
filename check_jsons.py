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
    if 'description' not in data['info']:
        return
    else:
        if "Talkshow om en om gepresenteerd door Khalid Kasem en Sophie Hilbrand" in data['info']['description']:
            series = data['info']['series']['title']
            omroep = data['info']['licensor']
            date = data['info']['broadcastDate']
            yield [id, series, omroep, date]



def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["programid", "name", "omroep", "titel"])
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

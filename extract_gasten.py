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

def get_gasten(meta):
    try:
        guests = meta['nisv.guest']
        for gast in guests['value']:
            name = gast[0]['value']
            yield name
    except KeyError:
        name = "-"
    else:
        return


    

def scrape(data):
    id = data['info']['id']
    if 'fullTitle' in data['info']:
        title = data['info']['fullTitle']
    else:
        title = data['info']['title']
    meta = {item['name']: item for item in data['details']['metadata']}
    series = data['info']['series']['title']
    omroep = data['info']['licensor']
    date = data['info']['broadcastDate']
    for gast in get_gasten(meta):
        yield [id, series, omroep, title, date, gast]




def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["programid", "name", "omroep", "titel","date","gast"])
    for file in files:
        print(file)
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

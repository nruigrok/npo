import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv

from lxml.doctestcompare import strip


def extract_segments(data):
    id = data['info']['id']
    for x in data['assets'][0]['segments']:
        yield x

def get_gasten(meta):
    for item in meta:
        if item['type'] == 'speaker-label':
            speaker = item['title']
            speaker = speaker.split(',')
            name = " ".join(reversed(speaker))
            name = strip(name)
            duration = item['duration']/1000
            rol = "tafelgast"
            yield name, rol, duration

def get_crew(crew):
    crews = crew['nisv.crew']
    if 'value' not in crews:
        return
    for crew in crews['value']:
        name = crew[0]['value']
        name = name.split(',')
        name = " ".join(reversed(name))
        name = strip(name)
        rol = "presentator"
        duration = 0
        yield name, rol, duration



def get_person(person):
    persons = person['nisv.person']
    if 'value' not in persons:
        return
    for person in persons['value']:
        name = person[0]['value']
        name = name.split(',')
        name = " ".join(reversed(name))
        name = strip(name)
        rol = "gespreksonderwerp"
        duration = 0
        yield name, rol, duration



def scrape(data):
    id = data['info']['id']
    if 'fullTitle' in data['info']:
        title = data['info']['fullTitle']
    else:
        title = data['info']['title']
    meta = data['timecodedMetadata']
    shownames = {item['name']: item for item in data['details']['metadata']}
    series = data['info']['series']['title']
    omroep = data['info']['licensor']
    date = data['info']['broadcastDate']
    for name, rol, duration in get_crew(shownames):
        yield [id, series, omroep, title, date, name, rol, duration]
    for name, rol, duration in get_gasten(meta):
        yield [id, series, omroep, title, date, name, rol, duration]
    for name, rol, duration in get_person(shownames):
        yield [id, series, omroep, title, date, name, rol, duration]




def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["programid", "show", "omroep", "titel","date", "name","rol","duration"])
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

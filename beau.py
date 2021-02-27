import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv
import locale

from datetime import datetime as dt, timedelta as td


def get_date(i):
    start = '2020-11-09'
    sd = dt.strptime(start, '%Y-%m-%d')
    w = (i -1)//5
    d = (i-1) + (2 * w)
    date = sd + td(days=d)
    date = dt.strftime(date, '%Y-%m-%d')
    return(date)


def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["id", "date", "description", "duration"])
    for file in files:
        #logging.info(file)
        with open(str(file)) as data_file:
            data = json.load(data_file)
            for x in data['details']:
                if "S" in x:
                    continue
                id = data['details'][x]['id']
                locale.setlocale(locale.LC_ALL, 'nl_NL.UTF-8')
                try:
                    date = data['details'][x]['title']
                    date = dt.strptime(date, '%a %d-%m-%Y')
                except ValueError:
                    position = data['details'][x]['position']
                    date = get_date(position)
                description = data['details'][x]['description']
                duration = data['details'][x]['runtime']
                out.writerow([id, date, description, duration/60])



if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()

    scrape_files(args.files)

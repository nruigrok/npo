import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv
import re
import locale

import datetime



def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["id", "date", "description", "duration"])
    for file in files:
        with open(str(file)) as data_file:
            data = json.load(data_file)
            for x in data:
                id = x['id']
                description = x['description']
                locale.setlocale(locale.LC_ALL, 'nl_NL.UTF-8')
                position = x['formattedDate']
                if 'Gisteren' in position:
                    datum = datetime.datetime.today()
                    date2 = datum - datetime.timedelta(days=1)
                elif 'Vandaag' in position:
                    datum = datetime.datetime.today()
                    date2 = datum - datetime.timedelta(days=0)
                elif 'Eergisteren' in position:
                    datum = datetime.datetime.today()
                    date2 = datum - datetime.timedelta(days=2)
                elif '2022' in position:
                    position = re.sub('[!@#$.]', '', position)
                    date2 = datetime.datetime.strptime(position, "%a %d %b %Y")
                else:
                    position = re.sub('[!@#$.]', '', position)
                    date2 = datetime.datetime.strptime(position, "%a %d %b").replace(year=2022)
                duration = x['formattedDuration']
                hm = re.findall(r'\d+', duration)
                if len(hm)==1:
                    duration2=int(hm[0])
                else:
                    hour=int(hm[0])*60
                    minutes=int(hm[1])
                    duration2=hour+minutes
                out.writerow([id, date2, description, duration2])



if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()

    scrape_files(args.files)

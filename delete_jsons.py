import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import os







def scrape_files(files):
    for file in files:
        with open(str(file)) as data_file:
            data = json.load(data_file)
            if "Live talkshow uit Amsterdam" in data['info']['description']:
                print(file)
                file_path = file
                os.remove(file_path)

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()
    scrape_files(args.files)

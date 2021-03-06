import sys
from pathlib import Path
import json
import logging
from typing import Iterable
import logging
import argparse
import csv

def extract_subtitles(data):
    id = data['info']['id']
    speakers = []
    subtitles = []
    for x in data['subtitles']:
        if x['type'] == 'speaker-label':
            speakers.append(x)
        if x['type'] == 'subtitle':
            subtitles.append(x)
    speakers = sorted(speakers, key=lambda x: x['startAt'])
    subtitles = sorted(subtitles, key=lambda x: x['startAt'])
    if speakers:
        current_speaker = speakers.pop(0)
    else:
        current_speaker = None
    for sub in subtitles:
        while (current_speaker is not None) and (sub['startAt'] >= current_speaker['startAt'] + current_speaker['duration']):
            if speakers:
                current_speaker = speakers.pop(0)
            else:
                current_speaker = None
        if (current_speaker is None) or (sub['startAt'] < current_speaker['startAt']):
            speaker = None
        else:
            speaker = current_speaker
        yield sub, speaker



def scrape_files(files):
    out = csv.writer(sys.stdout)
    out.writerow(["id", "title", "date", "speaker_start", "tot","speaker","sub_start","text"])

    for file in files:
        #logging.info(file)
        with open(str(file)) as data_file:
            data = json.load(data_file)
            id = data['info']['id']
            if 'fullTitle' in data['info']:
                title = data['info']['fullTitle']
            else:
                title = data['info']['title']
            date = data['info']['broadcastDate']
            for sub, speaker in extract_subtitles(data):
                if speaker:
                    s = speaker['title']
                    sstart = speaker['startAt']
                    stot= speaker['startAt'] + speaker['duration']
                else:
                    sstart, stot, s = None, None, None
                out.writerow([id, title, date, sstart, stot, s, sub['startAt'], repr(sub['title'])])


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="files to parse")
    args = parser.parse_args()

    scrape_files(args.files)

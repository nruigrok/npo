import csv
import logging


def scrape_segment(out, program_id, segment_id):
    data = api_call(f"/model/segments/{segment_id}/metadata")
    metadata = {x["name"]: x.get("value") for x in data["metadata"]}
    #if len(data["metadata"]) != len(metadata):
     #   raise Exception("Something went wrong, keys not unique?")
    if 'nisv.guest' in metadata:
        if metadata['nisv.guest']:
            for (guest, role) in metadata['nisv.guest']:
                if "value" in guest:
                    out.writerow([program_id, segment_id, "guest", guest["value"]])
    if 'nisv.person' in metadata:
        if metadata['nisv.person']:
            for (person, ) in metadata['nisv.person']:
                if 'value' not in person:
                    logging.warning(f"no person found in {program_id}, {segment_id}")
                    continue
                else:
                    out.writerow([program_id, segment_id, "person", person["value"]])
    if 'nisv.crew' in metadata:
        if metadata['nisv.crew']:
            for (crew, role, annotation) in metadata['nisv.crew']:
                if 'value' not in crew:
                    logging.warning(f"no crew found in {program_id}, {segment_id}")
                else:
                    out.writerow([program_id, segment_id, "crew", crew["value"]])
    if 'nisv.subjectterm' in metadata:
        if metadata['nisv.subjectterm']:
            for (subject, ) in metadata['nisv.subjectterm']:
                if 'value' not in subject:
                    logging.warning(f"no subject found in {program_id}, {segment_id}")
                else:
                    out.writerow([program_id, segment_id, "subjectterm", subject["value"]])
    length = metadata['nisv.strlength']
    out.writerow([program_id, segment_id, "length", length])
    summary = metadata['nisv.summary']
    out.writerow([program_id, segment_id, "summary", summary])

import sys

import argparse
parser = argparse.ArgumentParser()

parser.add_argument("segments", nargs="*", help="Specify segments to scrape instead of reading from input")
args = parser.parse_args()

logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

out = csv.writer(sys.stdout)
out.writerow(["programid", "segmentid", "key", "value"])

if args.segments:
    for segment_id in args.segments:
        scrape_segment(out, "?", "urn:vme:default:logtrackitem:2101702270676347824")
else:
    ids = list(csv.DictReader(open("data/segments.csv")))
    for i, program in enumerate(ids):
        program_id = program["programid"]
        segment_id = program["segmentid"]
        logging.info(f"[{i}/{len(ids)}] Scraping {program_id} segment {segment_id}")
        scrape_segment(out, program_id, segment_id)


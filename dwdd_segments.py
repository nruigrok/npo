import csv
import requests
import logging

from requests import HTTPError
from dwdd_api import api_call

DWDD = "urn:vme:default:series:2101608030021689431"
API = "https://zoeken-api.beeldengeluid.nl/gp/api/v1"

def get_segments(program_id):
    # 1 - find asset id for segments
    assets = api_call(f"/model/programs/{program_id}/mediaNEW")["assets"]
    for asset in assets:
        # 2 - get segments based on asset id
        for segment in api_call(f"/model/programs/{program_id}/mediaNEW/{asset['id']}/segments")["segments"]:
            yield asset, segment


logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
out_segments = csv.writer(open("data/segments.csv", "w"))
out_segments.writerow(["programid",
                       "assetid", "assetOffset", "assetStart", "assetDuration", "carrierType", "materialType", "carrier",
                       "segmentid", "offset", "start", "duration", "tag", "title", "description"])
program_ids = [program["id"] for program in csv.DictReader(open("data/meta.csv"))]
print(program_ids)
for i, program_id in enumerate(program_ids):
    logging.info(f"{i}/{len(program_ids)}: {program_id}")
    segments = list(get_segments(program_id))
    logging.info(f"... {len(segments)} segments for {program_id}")
    for asset, segment in segments:
        out_segments.writerow([program_id,
                               asset["id"],
                               asset.get("displayOffset"),
                               asset.get("startAt"),
                               asset.get("duration"),
                               asset.get("carrierType"),
                               asset.get("materialType"),
                               asset.get("carrier"),
                               segment["id"],
                               segment.get("displayOffset"),
                               segment.get("startAt"),
                               segment.get("duration"),
                               segment.get("tag"),
                               segment.get("fullTitle"),
                               segment.get("description")])


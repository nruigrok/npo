import csv
import requests
import logging

from requests import HTTPError
from dwdd_api import api_call

#OP1 = "urn:vme:default:series:2101608030021756931"
#OP1="urn:vme:default:series:2101608030027682731"
OP1 = "urn:vme:default:series:210160803002506553"
API = "https://zoeken-api.beeldengeluid.nl/gp/api/v1"

def get_segments(program_id):
    # 1 - find asset id for segments
    assets = api_call(f"/model/programs/{program_id}/mediaNEW")["assets"]
    for asset in assets:
        # 2 - get segments based on asset id
        for segment in api_call(f"/model/programs/{program_id}/mediaNEW/{asset['id']}/segments")["segments"]:
            yield asset, segment


logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
out_segments = csv.writer(open("data/segments_op1.csv", "w"))
out_segments.writerow(["programid", "date",
                       "assetid", "assetOffset", "assetStart", "assetDuration", "carrierType", "materialType", "carrier",
                       "segmentid", "offset", "start", "duration", "tag", "title", "description"])


for program in csv.DictReader(open("data/meta_goedemorgen.csv")):
    if program['date'] > "2021-01-01":
        segments = list(get_segments(program["id"]))
        logging.info(f"... {len(segments)} segments for {program['id']}")
        for asset, segment in segments:
            out_segments.writerow([program['id'],
                                   program['date'],
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


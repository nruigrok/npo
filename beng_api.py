import re
import sys
from pathlib import Path
from typing import Iterable
import re
import requests
import logging
import argparse
import os
import json
from amcatclient import AmcatAPI
from amcatclient.amcatclient import get_chunks, serialize

API = "https://zoeken-api.beeldengeluid.nl/gp/api/v1"


def api_call(request):
    url = f"{API}{request}"
    r = requests.get(url)
    r.raise_for_status()
    data = r.json()["payload"]
    return data


def get_season_title(urn):
    data = api_call(f"/model/seasons/{urn}")
    return data['title']


def get_items(model, id, item, offset=0, limit=10):
    data = api_call(f"/model/{model}/{id}/{item}?offset={offset}&limit={limit}")
    # what are the members called?
    keys = set(x.replace("Pagination", "") for x in data.keys()) - {"id", "type"}
    if len(keys) != 1:
        raise Exception(f"Cannot find members name from {data.keys}: {keys}")
    key = list(keys)[0]
    return data[key], data[f"{key}Pagination"]


def get_all_items(model, id, item, offset=0, limit=10):
    while True:
        members, pagination = get_items(model, id, item, offset, limit)
        yield from members
        offset += limit
        if offset >= pagination['total']:
            break


def get_timecoded_metadata(urn: str) -> Iterable[dict]:
    return get_all_items("programs", urn, "timecodedMetadata")


def get_subtitles(urn: str) -> Iterable[dict]:
    return get_all_items("programs", urn, "subtitles")


def get_assets(urn: str) -> Iterable[dict]:
    d = api_call(f"/model/programs/{urn}/mediaNEW")
    return d['assets']


def get_segments(program_urn: str, asset_urn: str) -> Iterable[dict]:
    d = api_call(f"/model/programs/{program_urn}/mediaNEW/{asset_urn}/segments")
    return d['segments']


def get_metadata(urn: str) -> dict:
    return api_call(f"/model/programs/{urn}/metadata")


def parse_urn(urn: str) -> int:
    m = re.match(r"urn:vme:default:\w+:(\d+)", urn)
    if not m:
        raise ValueError(f"Cannot parse urn {urn}")
    return int(m.group(1))


def scrape_season(season: str, out_folder: Path):
    season_id = parse_urn(season)
    season_title = get_season_title(season)
    season_title= re.sub(r"\W", "", season_title)
    season_complete = str(season_id)+str(season_title)
    folder = out_folder / season_complete
    logging.info(f"Scraping season {season} to {folder}")
    if not folder.exists():
        logging.info(f"Creating output folder {folder}")
        folder.mkdir(parents=True)
    for program in get_all_items("seasons", season, "members"):
        urn = program['id']
        program_id = parse_urn(urn)
        out_file = folder / f"{program_id}.json"
        if out_file.exists():
            logging.info(f"{out_file} exists, skipping")
            continue
        data = dict(info=program)
        data.update(scrape_program(urn))
        data = json.dumps(data, indent=2)
        logging.info(f"Writing program info to {out_file}")
        with out_file.open("w") as f:
            f.write(data)

def scrape_program(urn: str) -> dict:
    data = {}
    data["details"] = get_metadata(urn)
    logging.info("... Retrieving segments")
    data['assets'] = []
    for asset in get_assets(urn):
        segments = list(get_segments(urn, asset['id']))
        asset['segments'] = segments
        data['assets'].append(asset)
    logging.info("... Retrieving subtitles")
    data["subtitles"] = list(get_subtitles(urn))
    logging.info("... Retrieving timecoded metadata")
    data["timecodedMetadata"] = list(get_subtitles(urn))
    return data

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("urn", help="Season or program Id to scrape")
    args = parser.parse_args()
    urn = args.urn
    if not urn.startswith("urn:"):
        raise Exception(f"Invalid urn: {urn}")
    if urn.startswith("urn:vme:default:season:"):
        out_folder = Path.cwd() / "data" / "op1"
        scrape_season(urn, out_folder)
    elif urn.startswith("urn:vme:default:program:"):
        d = scrape_program(urn)
        print(json.dumps(d, indent=2))



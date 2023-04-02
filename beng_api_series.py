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

class ItemNotFound(Exception):
    pass


def api_call(request):
    url = f"{API}{request}"
    print(f"API CALL {url}")
    r = requests.get(url)
    r.raise_for_status()
    data = r.json()["payload"]
    return data


def get_series_title(urn):
    data = api_call(f"/model/series/{urn}")
    return data['title']


def get_items(model, id, item, offset=0, limit=10):
    data = api_call(f"/model/{model}/{id}/{item}?offset={offset}&limit={limit}")
    # what are the members called?
    program_ids=[]
    print(data)
    for ids in data['programs']:
        id = ids['id']
        program_ids.append(id)
    print(f"programids is {program_ids}")
    return(program_ids)


def get_all_items(model, id, item, offset=2600, limit=100):
    while True:
        members = get_items(model, id, item, offset, limit)
        yield from members


def get_items2(model, id, item, offset=0, limit=10):
    data = api_call(f"/model/{model}/{id}/{item}?offset={offset}&limit={limit}")

    # what are the members called?
    keys = set(x.replace("Pagination", "") for x in data.keys()) - {"id", "type"}
    if len(keys) != 1:
        raise Exception(f"Cannot find members name from {data.keys}: {keys}")
    key = list(keys)[0]
    paginationkey = f"{key}Pagination"
    if paginationkey not in data:
        raise ItemNotFound(paginationkey)
    return data[key], data[paginationkey]



def get_all_items2(model, id, item, offset=0, limit=10):
    while True:
        members, pagination = get_items2(model, id, item, offset, limit)
        yield from members
        offset += limit
        if offset >= pagination['total']:
            break


def get_timecoded_metadata(urn: str) -> Iterable[dict]:
    return get_all_items2("programs", urn, "timecodedMetadata")


def get_subtitles(urn: str) -> Iterable[dict]:
    return get_all_items2("programs", urn, "subtitles")


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


def scrape_series(series: str, out_folder: Path):
    series_id = parse_urn(series)
    series_title = get_series_title(series)
    series_title= re.sub(r"\W", "", series_title)
    series_complete = str(series_id)+str(series_title)
    folder = out_folder / series_complete
    logging.info(f"Scraping season {series} to {folder}")
    if not folder.exists():
        logging.info(f"Creating output folder {folder}")
        folder.mkdir(parents=True)
    for program in get_all_items("series", series, "members"):
        print(f"program is {program}")
        urn = program
        program_id = parse_urn(urn)
        out_file = folder / f"{program_id}.json"
        if out_file.exists():
            logging.info(f"{out_file} exists, skipping")
            continue
        data = dict(info=program)
        try:
            data.update(scrape_program(urn))
        except ItemNotFound:
            logging.exception(f"Item not found, skipping {urn}")
            continue
        data = json.dumps(data, indent=2)
        logging.info(f"Writing program info to {out_file}")
        with out_file.open("w") as f:
            f.write(data)

def scrape_program(urn: str) -> dict:
    print(f"URN is {urn}")
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
    o = Path.cwd() / "data"
    files = [f.name for f in o.glob('**/*.json')]
    if not urn.startswith("urn:"):
        raise Exception(f"Invalid urn: {urn}")
    if urn.startswith("urn:vme:default:series:"):
        out_folder = Path.cwd() / "data" / "Nieusuur2018"
        scrape_series(urn, out_folder)
    elif urn.startswith("urn:vme:default:program:"):
        d = scrape_program(urn)
        print(json.dumps(d, indent=2))


#2019
#Nieuwsuur urn:vme:default:season:2101901020252722831
#NOS 20h urn:vme:default:season:2101901010252703931
#NOS zaterdag 20h urn:vme:default:season:2101901050252763931
#NOS zondag 20h urn:vme:default:season:2101901060252779931
#goedemorgen urn:vme:default:season:2101901070252785431
#goedemorgen urn:vme:default:season:2101901070252786231
#goedemorgen urn:vme:default:program:2101901070252787031
#goedemrogen urn:vme:default:season:2101901070252788331
#goedemorgen urn:vme:default:program:2101909020260841531
#goedemorgen urn:vme:default:season:2101909020260842331
#goedemorgen urn:vme:default:season:2101909020260843331
#goedemorgen urn:vme:default:season:2101909020260844031
#eenvandaag urn:vme:default:season:2101901020252719531
#jinek urn:vme:default:season:2101805160244432531

#2018
#EenVandaag urn:vme:default:series:2101608030021756931
#Nieuwsuur urn:vme:default:season:2101806250247979031
#NOS Zondag urn:vme:default:season:2101806260248022331
#NOS zaterdag urn:vme:default:season:2101807210248395731
#NOS 18h urn:vme:default:season:2101806260247992731
#goedemorgen urn:vme:default:season:2101712100234281931
#goedemorgen blok 1 urn:vme:default:season:2101809030248997531
#goedemorgen urn:vme:default:season:2101809030248998231
#goedemorgen urn:vme:default:season:2101809030248998631
#goedemorgen urn:vme:default:season:2101809030248999531




#Buitenhof: urn:vme:default:season:2102101100292259331
#Nieuwsuur: urn:vme:default:season:2102101020291520731
#EenVandaag: urn:vme:default:season:2102101020291505931
#NOSJournaal20h: urn:vme:default:season:2102101010291423031
#NOSJournaal20h: urn:vme:default:season:2102001010264092231
#NOSJournaal20h zaterdag: urn:vme:default:season:2102101020291511831
#NOSJournaal20h zondag: urn:vme:default:season:2102101030291603631
#M: urn:vme:default:season:2102101040291705731
#M najaar 2021 urn:vme:default:season:2102111080322151531
#Mzomer2018 urn:vme:default:series:2101806190247164631
#M2019 urn:vme:default:season:2101904010254236631
#M2020: urn:vme:default:season:2102003300266197231
#vooravond : urn:vme:default:season:2102102150295888931
#op1: urn:vme:default:season:2102101040291723131
#goedemorgen blok 1: urn:vme:default:season:2102109060315796931
#goedemorgen blok 2: urn:vme:default:season:2102109060315798831
#goedemorgen blok 3: urn:vme:default:season:2102109060315801231
#goedemorgen blok 4: urn:vme:default:season:2102109060315803231
#goedemorgen blok 5: urn:vme:default:season:2102109060315811831
#goedemorgen blok 6: urn:vme:default:season:2102109060315817931
#K&S: urn:vme:default:season:2102108300315185431
#Jeugd urn:vme:default:season:2102101010291419231

# PenW 2012 2101608040028828331
#najaar 2012 2101608040028872931
#voorjaar 2013 2101608040028891831
#najaar 2013 2101608040028924831
#beste 2101608040028971431
#voorjaar 2014 2101608040028957931

#PAUW 2014 urn:vme:default:season:2101608040028997831
#najaar2015 urn:vme:default:season:2101608040029055531
#voorjaar 2015 urn:vme:default:season:2101608040029026431
#voorjaar 2016 urn:vme:default:season:2101608040029083831
#najaar 2016 urn:vme:default:season:2101712150234469331
#voorjaar 2017 urn:vme:default:season:2101712100234328231

#najaar 2017 urn:vme:default:season:2101712150234470931
#voorjaar 2018 urn:vme:default:season:2101805160244417831
#najaar 2018 urn:vme:default:season:2101809040249014231
#voorjaar 2019 urn:vme:default:season:2101904160254472131
#najaar 2019 urn:vme:default:season:2101910010261586231



#Nieuwsuur: urn:vme:default:season:2102101020291520731
#EenVandaag: urn:vme:default:season:2102101020291505931
#NOSJournaal20h: urn:vme:default:season:2102101010291423031
#NOSJournaal20h zaterdag: urn:vme:default:season:2102101020291511831
#NOSJournaal20h zondag: urn:vme:default:season:2102101030291603631
#M: urn:vme:default:season:2102101040291705731
#Mzomer2018 urn:vme:default:series:2101806190247164631
#M2019 urn:vme:default:season:2101904010254236631
#M2020: urn:vme:default:season:2102003300266197231
#vooravond : urn:vme:default:season:2102102150295888931
#op1: urn:vme:default:season:2102101040291723131
#goedemorgen blok 1: urn:vme:default:season:2102101040291646431
#goedemorgen blok 2: urn:vme:default:season:2102101040291649031
#goedemorgen blok 3: urn:vme:default:season:2102101040291651531
#goedemorgen blok 4: urn:vme:default:season:2102101040291654231
#goedemorgen blok 5: urn:vme:default:season:2102101040291657931
#goedemorgen blok 6: urn:vme:default:season:2102101040291660531

#DWDD:urn:vme:default:season:2102001060264233831
#dwdd20212 urn:vme:default:season:2101608040028827731
#dwdd2012 verkiezingen urn:vme:default:program:2101608140119437031
#dwdd2012-2013 urn:vme:default:season:2101608040028870231
#dwdd2013-2014 urn:vme:default:season:2101608040028925731
#dwdd 2014-2015 urn:vme:default:season:2101608040028996631
#dwdd2015-2016 urn:vme:default:season:2101608040029053431
#dwdd2016-2017 urn:vme:default:season:2101712150234462031
#dwdd2017-2018 urn:vme:default:season:2101712100234262031
#dwdd 2018 najaar urn:vme:default:season:2101809240249336431
#dwdd najaar 2019 urn:vme:default:season:2101909020260858231
#dwdd voorjaar 2019 urn:vme:default:season:2101901070252799431

#JINEK 2013-2014 urn:vme:default:season:2101608040028932431?q=jinek
#14-15 urn:vme:default:season:2101608040029006231
#zomer 15 urn:vme:default:season:2101608040029033431
#voorjaar 16 urn:vme:default:season:2101608040029075331
#17 urn:vme:default:season:2101712150234470531
#18 urn:vme:default:season:2101805160244432531
#zomer18 urn:vme:default:season:2101806250247979531
#19 urn:vme:default:season:2101901020252706731

#eenvandaag 2020 urn:vme:default:season:2102001020264109131
#Nieuwsuur: urn:vme:default:season:2102001020264112631
#EenVandaag: urn:vme:default:season:2102001020264109131
#NOSJournaal20h: urn:vme:default:season:2102001010264092231
#NOSJournaal20h zaterdag: urn:vme:default:season:2102001040264142431
#NOSJournaal20h zondag: urn:vme:default:season:2102001050264160431
#goedemorgen blok 1: urn:vme:default:season:2102009070279035031
#goedemorgen blok 2: urn:vme:default:season:2102009070279037731
#goedemorgen blok 3: urn:vme:default:season:2102009070279040431
#goedemorgen blok 4: urn:vme:default:season:2102009070279043331
#goedemorgen blok 5: urn:vme:default:season:2102009070279061031
#goedemorgen blok 6: urn:vme:default:season:2102009070279065831

#nog verder
#goedemorgen blok 1: urn:vme:default:season:2102001060264167031
#goedemorgen blok 2: urn:vme:default:season:2102001060264167831
#goedemorgen blok 3: urn:vme:default:season:2102001060264168331
#goedemorgen blok 4: urn:vme:default:season:2102001060264169531

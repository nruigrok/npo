import csv
from nieuwsuur_api import *

out_meta = csv.writer(open("data/meta_nos.csv", "w"))
out_meta.writerow(["id", "date",  "season", "season_id", "episode", "description"])



for season in get_all_members("series", NIEUWSUUR):
    print(season["id"], season["title"])
    for program in get_all_members("seasons", season["id"]):
        print("...", program["id"], program["broadcastDate"])
        if not program.get('broadcastDate'):
            continue
        if program.get("title") == "Compilatie":
            print("SKIP compilatie")
            continue

        out_meta.writerow([program["id"], program["broadcastDate"], season["title"], season["id"], program.get("episodeNumber"), program.get("description")])


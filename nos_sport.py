import requests, csv, datetime, sys, json, argparse, os, re
from lxml import html
import logging

logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

s = requests.Session()
headers = {'User-agent': 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36'}
w = csv.writer(sys.stdout)
w.writerow(['url','date'])

date=datetime.datetime(2020,1,1)
while date<datetime.datetime(2021,6,1):
    logging.info(f"busy with {date}")
    URL = "https://nos.nl/nieuws/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
    page = s.get(URL, headers=headers)
    page = html.fromstring(page.content)
    links = page.findall('.//ul[@class="list-time"]/li//a')
    for link in links:
        url = 'https://nos.nl' + link.get("href")
        w.writerow([url,date.isoformat()])
    date= date + datetime.timedelta(days=1)


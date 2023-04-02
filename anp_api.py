from amcatclient.amcatclient import get_chunks
from requests.auth import HTTPBasicAuth
import requests
import logging
import argparse
from amcatclient import AmcatAPI
from datetime import datetime
import time
import re


BASE_URL = "https://newsapi.anp.nl/services/sources/{source}/items/"
BASE_URL_NEXT = "https://newsapi.anp.nl/services/sources/{source}/items?fromItem={id}"
BASE_URL_ITEM = "https://newsapi.anp.nl/services/sources/{source}/items/{id}"
API = "https://newsapi.anp.nl/services/login"
#sources = ["b5611621-338b-4929-afc7-e294a2952336", "0a3dda3b-4cb6-4b6f-92dd-6288fe100db1",
 #          "5d4f697b-6f97-4baf-ba52-e5d5a57ea6fa", "393e6095-47fd-476c-a079-110226bf9dab"]
sources = ["0a3dda3b-4cb6-4b6f-92dd-6288fe100db1",
           "5d4f697b-6f97-4baf-ba52-e5d5a57ea6fa", "393e6095-47fd-476c-a079-110226bf9dab"]


def api_calls(s, source: str, anp_ids):
    url = BASE_URL.format(source=source)
    hasmore = True
    while hasmore:
        logging.info(f"getting ids from {url}")
        hasmore, ids, last_id = api_call(s, url)
        for id in ids:
            if id in anp_ids:
                continue
            article = get_article(s, source, id)
            if article is None:
                continue
            yield article
            if article['date'] <= datetime(2020,5,31):
                return
        url = BASE_URL_NEXT.format(source=source, id=last_id)


def api_call(s, url):
    data = do_call_retry(s, url)
    ids =[]
    hasmore = data['data']['hasMore']
    for i in data['data']['items']:
        id = i['id']
        ids.append(id)
    last_id = ids[-1]
    return hasmore, ids, last_id


def do_call(session, url):
    r1 = session.get(url)
    r1.raise_for_status()
    return r1.json()


def do_call_retry(session, url):
    for retry in range(10):
        try:
            return do_call(session, url)
        except Exception:
            logging.exception(f"{retry} error retrieving url {url}")
            if retry > 5:
                time.sleep(1)
    return do_call(session, url)


def get_article(s, source, id):
    url = BASE_URL_ITEM.format(source=source, id=id)
    print(url)
    data3 = do_call_retry(s, url)
    art = data3['data']
    article = {}
    article['anp_id'] = id
    article['section'] = art['sourceTitle']
    article['publisher'] = "ANP"
    authors = art['authors']
    article['author'] = (", ".join(authors))
    article['title'] = art['title']
    date = art['pubDate']
    article['date'] = datetime.strptime(date, "%Y-%m-%dT%H:%M:%SZ")
    body = art['bodyText']
    article['text'] = re.sub('<[^<]+?>', '', body)
    if not article['text']:
        return
    article['words'] = art['wordCount']
    return article


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument("--batchsize", help="Batch size for uploading to AmCAT", type=int, default=100)
    args = parser.parse_args()

    logging.info("Logging on to ANP")
    s = requests.Session()
    r = s.get(API, auth=('nelruigrok@nieuwsmonitor.org', 'S1nterklaas'))
    print(f"INLOG GELUKT {r}")
    r.raise_for_status()

    logging.info(f"Scraping into AmCAT {args.articleset}")
    conn = AmcatAPI(args.server)
    anp_ids = {a['anp_id'] for a in conn.get_articles(args.project, args.articleset, columns=["anp_id"])}
    logging.info(f"Already {len(anp_ids)} in AmCAT {args.project}:{args.articleset}")

    for source in sources:
        chunks = get_chunks(api_calls(s, source, anp_ids), batch_size=args.batchsize)
        for batch in chunks:
            print(f"!!! Uploading {len(batch)} articles")
            conn.create_articles(args.project, args.articleset, batch)


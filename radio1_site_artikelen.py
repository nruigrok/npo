import argparse
from amcatclient.amcatclient import get_chunks

from lxml import html, etree
from amcatclient import AmcatAPI
import requests
import datetime
import re
import logging
import locale
import urllib3

from requests import HTTPError

BASE_URL = "https://www.nporadio1.nl"
def join_ps(ps):
    content = "\n\n".join(p.text_content() for p in ps)
    return re.sub("\n\n\s*", "\n\n", content).strip()

def get_article(art):
    url = f"{BASE_URL}{art}"
    article = {}
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    article['url'] = url
   # article['date'] = art['date']
    article['publisher'] = "Radio1"
    section = tree.cssselect('.sc-1eneipn-0.fQMbCi.hum7p-1.cSEETJ')
    if section:
        article['section'] = section[0].text_content()
    omroep = tree.cssselect("div.sc-13a6rnp-18.fCQVGB + span")
    if omroep:
        article['omroep'] = omroep[0].text_content()
    author = tree.cssselect("span.thema__content__header__author")
    if author:
        article['author'] = author[0].text_content()
    title = tree.cssselect("h1.hum7p-4.fcNcdv")
    article['title'] = title[0].text_content()
    lead_ps = tree.cssselect('div.sc-2ydgnd-0.eHmkHC')
    body_ps = tree.cssselect('div.wmjr9k-0.cXMGDn > p,h2')
    article['text'] = join_ps(lead_ps + body_ps)
    locale.setlocale(locale.LC_ALL, 'nl_NL.UTF-8')
    date = tree.cssselect("div.sc-13a6rnp-11.cgaxzi")
    if not date:
        date = tree.cssselect("div.sc-13a6rnp-12.dMCLsx")
        if not date:
            date = tree.cssselect("span.dkx024-5.iCQAuS")
    date2 = date[0].text_content().strip()
    if 'Vandaag' in date2:
        date2 = datetime.datetime.today()
    elif 'Gisteren' in date2:
        datum = datetime.datetime.today()
        date2 = datum - datetime.timedelta(days=1)
    else:
        try:
            date2 = datetime.datetime.strptime(date2, "%d %B %Y %H:%M")
        except ValueError:
            try:
                date2 = datetime.datetime.strptime(date2, "%d %b %Y - %H:%M uur")
            except ValueError:
                date2 = datetime.datetime.strptime(date2, "%d %B %Y - %H:%M uur")
    article['date'] = date2
    return article

def get_page(pag):
    while True:
        try:
            url = f"https://www.nporadio1.nl/nieuws?page={pag}"
            req = urllib3.Request(url)
            response = urllib3.urlopen(req)
            htmlSource = response.read()
            if response.getcode() == 200:
                break
        except Exception as inst:
            print(inst)
        tree = html.fromstring(req.text)
        return tree

def get_links(tree):
    articles = tree.cssselect("div.dec0op-0.kBNrGI a")
    for a in articles:
        article = {}
        art = a.cssselect(".ustjrh-5.eHbDAs")
        article = art[0].get("href")
        yield article

def get_url(link):
    url = f"{BASE_URL}{link}"
    r = requests.get(url)
    r2 = (r.url)
    return r2

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument("--batchsize", help="Batch size for uploading to AmCAT", type=int, default=10)
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

    logging.info(f"Scraping into AmCAT {args.articleset}")
    conn = AmcatAPI(args.server)
    urls = {a['url'] for a in conn.get_articles(args.project, args.articleset, columns=["url"])}
    for u in urls:
        re.sub("https:www/nporadio1.nl","", u)
    logging.info(f"Already {len(urls)} in AmCAT {args.project}:{args.articleset}")

    page = range(0,4000,1)
    for p in page:
        articles=[]
        page = get_page(p)
        for l in get_links(page):
            if l not in urls:
                link = get_url(l)
                if 'fragmenten' in link:
                    continue
                try:
                    article = get_article(l)
                except HTTPError as err:
                    if err.response.status_code == 500:
                        print("Internal server error 500")
                        continue
                    else:
                        print("Some other error. Error code: ", err.code)
                articles.append(article)
            conn.create_articles(args.project, args.articleset, articles)



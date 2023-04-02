from typing import Sequence

import requests, csv, datetime, sys, json, argparse, os, re
from lxml import html
from dateutil.parser import parse
from amcatclient import AmcatAPI
import logging

def get_meta_dict(page):
    meta = {}
    for m in page.findall('head/meta'):
        m = m.attrib
        key = 'name' if 'name' in m else 'property'
        if key not in m: continue
        if key == 'viewport': continue
        meta[m[key]] = m['content']
    return meta



class nosScraper():
    def __init__(self):
        self.s = requests.Session()
        self.headers = {'User-agent': 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36'}

    def get_archive_urls(self, date, from_date):
        while date >= from_date:
            yield "https://nos.nl/sport/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
            yield "https://nos.nl/nieuwsuur/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
            yield "https://nos.nl/nieuws/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
            date -= datetime.timedelta(1)

    def get_article_urls(self, archive_url: str) -> dict:
        page = self.s.get(archive_url, headers=self.headers)
        page = html.fromstring(page.content)
        links = page.findall('.//ul[@class="list-time"]/li')
        for l in links:
            if 'Voor de gekozen dag zijn geen artikelen gevonden' in l.text_content(): continue
            date = parse(l.find('.//time').attrib['datetime'])
            headline = l.xpath('.//div[contains(@class, "list-time__title")]')[0].text_content()
            url = 'https://nos.nl' + l.find('a').attrib['href']
            archive_url = archive_url
            yield dict(date=date, title=headline, url=url, archive_url=archive_url)

    def p_text(self,p):
        for br in p:
            br.tail = "\n" + br.tail if br.tail else "\n"       
        return p.text_content()
  
  
    def parse_item(self, page, article: dict) -> dict:
        body = ''
        par = page.xpath('.//p[contains(@class, "blKpuK")]')
        for p in par:
            txt = p.text_content()
            body += txt + '\n\n'
        article['text'] = body
        article['publisher']="nos.nl"
        return article

    def parse_article(self, article: dict) -> Sequence[dict]:
        page = self.s.get(article['url'], headers=self.headers)
        page = html.fromstring(page.content)
        is_liveblog = 'liveblog' in article['url']
        if is_liveblog:
            return
        else:
            yield self.parse_item(page, article)


    def scrape(self, from_date, to_date, done_urls):
        for archive_url in self.get_archive_urls(date = to_date, from_date = from_date):
            print(archive_url)
            logging.info(f"Archive URL: {archive_url}")
            for article in self.get_article_urls(archive_url):
                if article['url'] in done_urls:
                    continue
                logging.info(f'... {article["url"]}')
                #article['url']="https://nos.nl/artikel/2410197-ook-in-alta-badia-nog-geen-olympisch-ticket-voor-skier-meiners"
                for a in self.parse_article(article):
                    if a['url'] in done_urls:
                        continue
                    yield a
                    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    parser.add_argument('fromdate', help='Start date, in format yyyy-mm-dd')
    parser.add_argument('todate', help='End date, in format yyyy-mm-dd')
    parser.add_argument('--check_liveblogs', help="If true, check liveblog updates", default=False, action="store_true")
    args = parser.parse_args()
    fromdate = datetime.datetime.fromisoformat(args.fromdate)
    todate = datetime.datetime.fromisoformat(args.todate)

    conn = AmcatAPI(args.server)

    logging.info(f"Scraping into AmCAT {args.project}:{args.articleset}")

    done_urls = [a['url'] for a in conn.get_articles(args.project, args.articleset, columns=["url"])]

    logging.info(f"Already {len(done_urls)} in AmCAT {args.project}:{args.articleset}")

    broken_links = ['https://nos.nl/artikel/479389-liveblog-laatste-dag-benedictus.html',
                    'https://nos.nl/nieuwsuur/artikel/2079854-xx.html',
                    'https://nos.nl/nieuwsuur/artikel/2370218-de-uitzending-van-25-februari.html',
                    'https://nos.nl/artikel/325429-2011-doorbraak-van-het-liveblog.html']
    done_urls = done_urls + broken_links
    
    s = nosScraper()   
    for a in s.scrape(fromdate, todate, done_urls):
        a['date'] = a['date'].isoformat()
        if a['text'] == "":
            continue
        import json
        conn.create_articles(args.project, args.articleset, a)

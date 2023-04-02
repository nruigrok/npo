import requests, csv, datetime, sys, json, argparse, os, re, time
from lxml import html
from dateutil.parser import parse
from amcatclient import AmcatAPI
import logging



def p_text(p):
    for br in p.findall('.//br'):
        br.tail = "\n" + br.tail if br.tail else "\n"
    return p.text_content()

def get_body(elem):
    body = ''
    urls = []
    for par in elem.xpath('.//p|.//h1|.//h2|.//h3|.//h4|.//h5|.//li'):
        for a in par.findall('.//a'):
            if 'href' in a.attrib:
                urls.append(a.attrib['href'])
        txt = p_text(par)
        if 'Deze browser wordt niet ondersteund voor het spelen van video' in txt: continue
        txt = re.sub('\n\n+', '\n\n' , txt.replace('\t', '')).strip()
        if txt == '': continue
        if par.tag == 'p': 
            body += txt + '\n\n'
        else:
            body += txt + '\n'
    return body


class nuScraper():
    def __init__(self):
        self.s = requests.Session()
        self.headers = {'User-agent': 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36'}

    def get_index(self):
        index_page = self.s.get('https://www.nu.nl/sitemap_index.xml')
        index_urls = ['https://www.nu.nl/sitemap_news.xml']
        for loc in str(index_page.content).split('<loc>')[3:]:
            index_urls.append(loc.split('<')[0])
        return index_urls

    def get_text(self, url):
        page = self.s.get(url)
        if page.status_code == 404: return None
        e = html.fromstring(page.content)
        body = ''
        if '/video/' in url or '/video-' in url:
            bodyelem = e.find('.//div[@data-type = "videoautoplay"]')
        else:
            bodyelem = e.xpath('.//div[contains(@class,"textblock paragraph")]')
        for p in bodyelem:
            txt = p.text_content()
            body += txt + '\n\n'
        return body

    def get_article(self, page, done_urls):
        articles_page = self.s.get(page)
        for url in str(articles_page.content).split('<url>'):
            if '<loc>' not in url: continue
            article_url = url.split('<loc>')[1].split('<')[0]
            if article_url in done_urls:
                continue
            if "/audio/" in article_url:
                continue
            if "/video/" in article_url:
                continue
            if article_url == 'https://www.nu.nlNone':
                continue
            date = parse(url.split('<news:publication_date>')[1].split('<')[0])
            title = url.split('<news:title>')[1].split('<')[0]
            keywords = url.split('<news:keywords>')[1].split('<')[0] if '<news:keywords>' in url else ''
            publisher = url.split('<news:name>')[1].split('<')[0]
            text = self.get_text(article_url)
            if not text:
                continue
            article_dict = {'url': article_url,
                            'publisher': publisher,
                            'title':title,
                            'date':date,
                            'keywords':keywords,
                            'text':text,
                        }
            yield(article_dict)



if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("server", help="AmCAT host name", )
    parser.add_argument("project", help="AmCAT project", )
    parser.add_argument("articleset", help="AmCAT Articleset ID", type=int)
    args = parser.parse_args()
    conn = AmcatAPI(args.server)

    logging.info(f"Scraping into AmCAT {args.project}:{args.articleset}")
    done_urls = [a['url'] for a in conn.get_articles(args.project, args.articleset, columns=["url"])]
    logging.info(f"Already {len(done_urls)} in AmCAT {args.project}:{args.articleset}")

    s = nuScraper()

    lijst = ["https://www.nu.nl/sitemap_2022_W47.xml","https://www.nu.nl/sitemap_2022_W46.xml","https://www.nu.nl/sitemap_2022_W45.xml",
             "https://www.nu.nl/sitemap_2022_W44.xml", "https://www.nu.nl/sitemap_2022_W43.xml","https://www.nu.nl/sitemap_2022_W42.xml",
             "https://www.nu.nl/sitemap_2022_W41.xml","https://www.nu.nl/sitemap_2022_W40.xml","https://www.nu.nl/sitemap_2022_W39.xml",
             "https://www.nu.nl/sitemap_2022_W38.xml","https://www.nu.nl/sitemap_2022_W37.xml","https://www.nu.nl/sitemap_2022_W36.xml", 
             "https://www.nu.nl/sitemap_2022_W35.xml","https://www.nu.nl/sitemap_2022_W34.xml", "https://www.nu.nl/sitemap_2022_W33.xml",
             "https://www.nu.nl/sitemap_2022_W32.xml","https://www.nu.nl/sitemap_2022_W31.xml","https://www.nu.nl/sitemap_2022_W30.xml",
             "https://www.nu.nl/sitemap_2022_W29.xml","https://www.nu.nl/sitemap_2022_W28.xml","https://www.nu.nl/sitemap_2022_W27.xml"]
    
    for a in s.get_index():
        print(a)
        if a in lijst:
            continue
        else:
            for art in s.get_article(a, done_urls):
                conn.create_articles(args.project, args.articleset, art)

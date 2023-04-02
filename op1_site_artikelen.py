import argparse
from amcatclient.amcatclient import get_chunks

from lxml import html, etree
from amcatclient import AmcatAPI
import requests
from datetime import datetime
import re
import logging
import locale

def join_ps(ps):
    content = "\n\n".join(p.text_content() for p in ps)
    return re.sub("\n\n\s*", "\n\n", content).strip()

def get_article(url):
    print(url)
    article = {}
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    article['url'] = url
    article['publisher'] = "Op1"
    date = tree.cssselect("div.m-container time")
    locale.setlocale(locale.LC_ALL, 'nl_NL.UTF-8')
    date = date[0].text_content()
    article['date'] = datetime.strptime(date, "%d %B %Y")
    title = tree.cssselect("h1.m-single-article__title")
    article['title'] = title[0].text_content()
    body_ps = tree.cssselect('div.m-single-article__content > p')
    if not body_ps:
        body_ps = tree.cssselect("div.read-more-modal > p")
        if not body_ps:
            body_ps = tree.cssselect("div.m-container p")
    article['text'] = join_ps(body_ps)
    return article

def get_page(pag):
    url = f"https://op1npo.nl/artikelen/page/{pag}/"
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    return tree

def get_links(tree):
    articles = tree.cssselect("article.m-article-excerpt a")
    links = []
    for a in articles:
        link = a.get("href")
        links.append(link)
    return links



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
    logging.info(f"Already {len(urls)} in AmCAT {args.project}:{args.articleset}")

    page = range(0, 67, 1)
    for p in page:
        articles=[]
        page = get_page(p)
        for l in get_links(page):
            if l not in urls:
                article = get_article(l)
                articles.append(article)
        conn.create_articles(args.project, args.articleset, articles)



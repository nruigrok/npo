import json
import sys

from lxml import html, etree
from amcatclient import AmcatAPI
import requests
from itertools import count
from datetime import datetime
import cssselect
import lxml
import logging

from requests import HTTPError

DWDD_URL = "https://www.bnnvara.nl/dewerelddraaitdoor/artikelen"


def get_first():
    url = DWDD_URL
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    next, = tree.cssselect("#__NEXT_DATA__")
    data = json.loads(next.text_content())

    state = data['props']['pageProps']['apolloState']
    for art_key in state.keys():
        if art_key.startswith("Article:"):
            yield state[art_key]


def get_articles(end_cursor):
    payload = [{"operationName": "FetchArticlesAndPages",
                "variables": {"brandSlug": "dewerelddraaitdoor",
                              "type": "article",
                              "paginator": {"cursor": end_cursor, "limit": 8}},
                "query": "query FetchArticlesAndPages($brandSlug: ID!, $paginator: PaginatorInput!, $type: PageTypeEnum) {\n  brand(slug: $brandSlug) {\n    id\n    pages(paginator: $paginator, type: $type) {\n      edges {\n        ... on Article {\n          id\n          type\n          title\n          slug\n          publishDate\n          tags {\n            id\n            name\n            slug\n            __typename\n          }\n          thumbnail {\n            id\n            url\n            __typename\n          }\n          __typename\n        }\n        ... on ContentPage {\n          id\n          type\n          title\n          slug\n          publishDate\n          tags {\n            id\n            name\n            slug\n            __typename\n          }\n          thumbnail {\n            id\n            url\n            __typename\n          }\n          __typename\n        }\n        __typename\n      }\n      pageInfo {\n        endCursor\n        hasNextPage\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n"}]
    r = requests.post("https://api.bnnvara.nl/bff/graphql", json=payload)
    r.raise_for_status()
    data = r.json()
    return data[0]['data']['brand']['pages']['edges']


def parse_articles(articles):
    for art in articles:
        try:
            yield parse_article(art)
        except HTTPError:
            logging.exception(f"Cannot parse article {art['id']}:{art['slug']}")
            continue


def parse_article(art):
    title = art['title']
    id = art['id']
    url = f'https://www.bnnvara.nl/dewerelddraaitdoor/artikelen/{art["slug"]}'
    date = art['publishDate']
    text = get_article_text(url)
    return dict(title=title, dwdd_id=id, url=url, date=date, text=text, publisher="DWDD")


def get_article_text(url):
    page = requests.get(url)
    page.raise_for_status()
    tree = html.fromstring(page.text)
    text = "\n\n".join(t.text_content()  for t in tree.cssselect(".sc-1fnykkm-0.gxieGH,h1.di2x5p-0"))
    return text

conn = AmcatAPI("http://localhost:8000")

if len(sys.argv) > 1:
    end_cursor = sys.argv[1]
else:
    articles = get_first()
    amcat_articles = list(parse_articles(articles))
    conn.create_articles(1, 101, amcat_articles)
    end_cursor = amcat_articles[-1]['dwdd_id']

for i in count():
    print(f"{i}: {end_cursor}")
    articles = get_articles(end_cursor)
    amcat_articles = list(parse_articles(articles))
    conn.create_articles(1, 101, amcat_articles)
    end_cursor = amcat_articles[-1]['dwdd_id']

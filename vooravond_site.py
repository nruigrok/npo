from amcatclient import AmcatAPI
from amcatclient.amcatclient import get_chunks
from lxml import html
import json
import requests
import re
import logging
import argparse


QUERY = """query FetchArticlesAndPages($brandSlug: ID!, $paginator: PaginatorInput!, $type: PageTypeEnum) {
brand(slug: $brandSlug) {
    id
    pages(paginator: $paginator, type: $type) {
      edges {
        ... on Article {
          id
          type
          title
          slug
          publishDate
          likes
          commentCount
        }
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}"""


def query_payload(brandslug, cursor):
    return {
        "operationName": "FetchArticlesAndPages",
        "query": QUERY,
        "variables": {
            "brandSlug": brandslug,
            "paginator": {
                "cursor": cursor,
                "limit": 8
            },
            "type": "article"
        }
    }


def get_articles(url):
    r = requests.get(url)
    r.raise_for_status()
    tree = html.fromstring(r.text)
    script, = tree.cssselect("script#__NEXT_DATA__")
    data = json.loads(script.text_content())

    brandslug = data['query']['brandSlug']
    for name, data in data['props']['pageProps']['apolloState'].items():
        if name.startswith("Article"):
            yield data
        if name.endswith(".pageInfo") and "endCursor" in data:
            cursor = data['endCursor']

    while True:
        r = requests.post("https://api.bnnvara.nl/bff/graphql", json=query_payload(brandslug, cursor))
        r.raise_for_status()
        data = r.json()
        pages = data['data']['brand']['pages']
        for edge in pages['edges']:
            yield edge

        cursor = pages['pageInfo']['endCursor']
        hasnext = pages['pageInfo']['hasNextPage']
        if not hasnext:
            break


def join_ps(ps):
    content = "\n\n".join(p.text_content() for p in ps)
    return re.sub("\n\n\s*", "\n\n", content).strip()

def get_text(url):
    r = requests.get(url)
    r.raise_for_status()
    tree = html.fromstring(r.text)
    text = tree.cssselect("div.beRzEK, h3.beRzEK")
    text = join_ps(text)
    return text

def scrape_files(base_url, publisher):
    for article in get_articles(base_url):
        art = {}
        slug = article['slug']
        art['title'] = article['title']
        art['date'] = article['publishDate']
        art['url'] = f"{base_url}/{slug}"
        art['text'] = get_text(art['url'])
        yield art

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
    base_url = "https://www.bnnvara.nl/devooravond/artikelen"
    publisher = "De Vooravond"

    chunks = get_chunks(scrape_files(base_url, publisher), batch_size=args.batchsize)
    for batch in chunks:
        print(f"!!! Uploading {len(batch)} articles")
        conn.create_articles(args.project, args.articleset, batch)

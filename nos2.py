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
    return body, json.dumps(urls)


class nosScraper():
    def __init__(self):
        self.s = requests.Session()
        self.headers = {'User-agent': 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36'}

    def get_archive_urls(self, date, from_date):
        while date >= from_date:
          #  yield "https://nos.nl/sport/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
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
            yield dict(date=date, title=headline, url=url)

    def parse_liveblog(self, page, article: dict) -> Sequence[dict]:
        for update in page.xpath('.//li[contains(@id, "UPDATE-container")]'):
            entry = article.copy()
            id = update.attrib['id']
            entry['url'] = article['url'] + '#' + id
            entry['title'] = update.find('h2').text_content()
            entry['text'], entry['links_json'] = get_body(update.find('.//div[@class = "liveblog__elements"]'))
            datestring = update.find('.//time').attrib['datetime']
            if datestring[0:4] != '0000':
                entry['date'] = parse(datestring)
            entry['images_json'] = self.get_image(update)
            entry['tweets_json'] = self.get_tweets(update)
            yield entry

    def parse_item(self, page, article: dict) -> dict:
        art = page.find('.//article')
      #  lc = art.xpath('.//div[contains(@class, "linkContainer_")]')
       # if len(lc) > 0: 
        #    read_more = []
         #   for l in lc:   ## sometimes there are 'bekijk ook' links in the middle as well
          #      l.getparent().remove(l)
           #     read_more += self.get_readmore_links(l)
           # article['readmore_json'] = json.dumps(read_more)

        article['text'], article['links_json'] = get_body(art.xpath('.//div[contains(@class, "contentBody")]')[0])
        #article['images_json'] = self.get_image(art)
        #article['tweets_json'] = self.get_tweets(art)
        return article

    def get_page(self, url: str) -> html.HtmlElement:
        page = self.s.get(url, headers=self.headers)
        page.raise_for_status()
        return html.fromstring(page.content)

    def parse_article(self, article: dict) -> Sequence[dict]:
        page = self.get_page(article['url'])
        print(type(page))
        article['meta_json'] = json.dumps(get_meta_dict(page))
        is_liveblog = 'liveblog' in article['url']
      #  article['source'], article['section'] = self.parse_header(page, is_liveblog)
        if is_liveblog:
            yield from self.parse_liveblog(page, article)
        else:
            yield self.parse_item(page, article)

    def get_image(self, elem):
        images = []

        for img_cont in elem.findall('.//figure'):
            img_dict = {'type': 'figure', 'image_url': img_cont.find('.//img').attrib['src'], 'caption': '', 'copyright': ''}
            for span in img_cont.findall('.//figcaption/span'):
                if 'description' in span.attrib['class']: img_dict['caption'] = span.text_content()
                if 'copyright' in span.attrib['class']: img_dict['copyright'] = span.text_content()
            images.append(img_dict)

        for img_cont in elem.findall('.//div[@class = "block_video "]'):
            img_dict = {'type': 'video', 'image_url': img_cont.find('.//img').attrib['src'], 
                                         'video_url': 'https://nos.nl' + img_cont.find('.//a').attrib['href'], 
                                         'caption': ''}
            caption_content = img_cont.find('.//div[@class = "caption_content"]')
            if caption_content is not None: img_dict['caption'] = caption_content.text_content()            
            images.append(img_dict)
        
        for img_cont in elem.xpath('.//a[contains(@class, "externalContent")]'):
            img_dict = {'type': 'link', 'url': img_cont.attrib['href'], 'image_url': '', 'title': ''}
            image = img_cont.xpath('.//div[contains(@class, "image_")]')
            if len(image) > 0: 
                if 'style' in image[0].attrib:
                    img_dict['image_url'] = image[0].attrib['style'].split('url(')[1].split(')')[0].strip('"')
            title = img_cont.xpath('.//div[contains(@class, "title_")]')
            if len(title) > 0: img_dict['title'] = title[0].text_content()
            images.append(img_dict)

        for img_cont in elem.xpath('.//div[contains(@class, "player_")]'):
            img_dict = {'type': 'player', 'image_url': '', 'caption': ''}
            img_str = img_cont.xpath('.//div[contains(@class, "playerOuter_")]')[0].attrib['style']
            img_dict['image_url'] = img_str.split('url(')[1].split(')')[0].strip('"')
            caption_content = img_cont.xpath('.//div[contains(@class, "caption_")]')
            if len(caption_content) > 0: img_dict['caption'] = caption_content[0].text_content()            
            images.append(img_dict)

        return json.dumps(images)

    def get_tweets(self, elem):
        tweets = []
        for tweet in elem.findall('.//a[@class = "ext-twitter"]'):
            tweet_dict = {'url': tweet.attrib['href']}      
            tweet_dict['avatar'] = tweet.find('.//div[@class="ext-twitter-header__avatar"]/img').attrib['src']
            author = tweet.findall('.//div[@class="ext-twitter-header-author"]/div')
            tweet_dict['decorate_name'] = author[0].text_content()
            tweet_dict['user_name'] = author[1].text_content()
            img = tweet.find('.//div[@class = "ext-twitter-content"]/img')
            if img is not None: tweet_dict['image_url'] = img.attrib['src']
            capt = tweet.find('.//div[@class = "ext-twitter-caption"]')
            if capt is not None: tweet_dict['caption'] = capt.text_content()
            tweets.append(tweet_dict)

        for tweet in elem.xpath('.//a[contains(@class, "twitter_")]'):
            tweet_dict = {'url': tweet.attrib['href']}      
            tweet_dict['avatar'] = tweet.xpath('.//div[contains(@class, "avatarImage")]')[0].attrib['src']
            author = tweet.xpath('.//div[contains(@class, "headerContent_")]/span')
            tweet_dict['decorate_name'] = author[0].text_content()
            tweet_dict['user_name'] = author[1].text_content()
            img = tweet.xpath('.//div[contains(@class, "imageWrapper_")]/img')
            if len(image) > 0: tweet_dict['image_url'] = img[0].attrib['src']
            capt = tweet.xpath('.//div[contains(@class, "text_")]')
            if len(capt) > 0: tweet_dict['caption'] = capt[0].text_content()
            tweets.append(tweet_dict)
        
        return json.dumps(tweets)

    def get_readmore_links(self, elem):
        links = []
        for link in elem.xpath('.//li[contains(@class, "listItem_")]'):
            link_dict = {'url': 'https://nos.nl' + link.find('.//a').attrib['href'],
                         'image_url': ''}
            image = link.find('.//img')
            if image is not None: link_dict['image_url'] = image.attrib['src']
            links.append(link_dict)
        return links

    def parse_header(self, elem: html.HtmlElement, liveblog=False):
        if liveblog:
            source = elem.find('.//span[@class = "liveblog-header__meta-supplychannel"]').text_content()
            links = elem.find('.//div[@class = "liveblog-header__meta"]')
        else:
            source = elem.xpath('.//span[contains(@class, "supplyChannelName")]')[0].text_content()
            links = elem.xpath('.//div[contains(@class, "headerMetaData")]')[0]
        section = ''
        for l in links.findall('.//a'):
            if len(section) > 0: section += ' | ' 
            section += l.text_content()       
        return source, section

    def scrape(self, from_date, to_date, done_urls):
        for archive_url in self.get_archive_urls(date = to_date, from_date = from_date):
            print(archive_url)
            logging.info(f"Archive URL: {archive_url}")
            for article in self.get_article_urls(archive_url):
                if article['url'] in done_urls:
                    continue
                print(article['url'])
                logging.info(f'... {article["url"]}')
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
    print(len(done_urls))

    logging.info(f"Already {len(done_urls)} in AmCAT {args.project}:{args.articleset}")

    broken_links = ['https://nos.nl/artikel/479389-liveblog-laatste-dag-benedictus.html',
                    'https://nos.nl/nieuwsuur/artikel/2079854-xx.html',
                    'https://nos.nl/nieuwsuur/artikel/2370218-de-uitzending-van-25-februari.html',
                    'https://nos.nl/artikel/325429-2011-doorbraak-van-het-liveblog.html']
    done_urls = done_urls + broken_links
    
    s = nosScraper()   
    for a in s.scrape(fromdate, todate, done_urls):
        print(a['url'])
        a['date'] = a['date'].isoformat()
        a['publisher']= "NOS"
        if a['url'] == "https://nos.nl/nieuwsuur/artikel/2424163-duizenden-cosmeticaproducten-bevatten-microplastics":
            continue
        if a['url']=="https://nos.nl/artikel/2420616-quincy-promes-verdacht-van-betrokkenheid-bij-drugshandel":
            continue
        if a['text'] == "":
            continue
        conn.create_articles(args.project, args.articleset, a)

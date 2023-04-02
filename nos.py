import requests, csv, datetime, sys, json, argparse, os, re
from lxml import html
from dateutil.parser import parse


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
          #  yield "https://nos.nl/nieuws/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
           # yield "https://nos.nl/nieuwsuur/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
            yield "https://nos.nl/sport/archief/" + datetime.datetime.strftime(date, '%Y-%m-%d')
            date -= datetime.timedelta(1)

    def get_article_urls(self, archive_url):
        page = self.s.get(archive_url, headers=self.headers)
        page = html.fromstring(page.content)

        links = page.findall('.//ul[@class="list-time"]/li')
    
        for l in links:
            if 'Voor de gekozen dag zijn geen artikelen gevonden' in l.text_content(): continue
            date = parse(l.find('.//time').attrib['datetime'])
            headline = l.xpath('.//div[contains(@class, "list-time__title")]')[0].text_content()
            url = 'https://nos.nl' + l.find('a').attrib['href']
            yield date, headline, url

    def parse_liveblog(self, page, article_url, art_date):
        for update in page.xpath('.//li[contains(@id, "UPDATE-container")]'):
            id = update.attrib['id']
            url = article_url + '#' + id
            headline = update.find('h2').text_content()
            body, links = get_body(update.find('.//div[@class = "liveblog__elements"]'))
            datestring = update.find('.//time').attrib['datetime']
            if datestring[0:4] == '0000':
                date = art_date
            else:
                date = parse(datestring)
            images = self.get_image(update)
            tweets = self.get_tweets(update)
            yield url, headline, body, links, date, images, tweets

    def parse_item(self, page):
        article = page.find('.//article')
        lc = article.xpath('.//div[contains(@class, "linkContainer_")]')
        if len(lc) > 0: 
            read_more = []
            for l in lc:   ## sometimes there are 'bekijk ook' links in the middle as well
                l.getparent().remove(l)
                read_more += self.get_readmore_links(l)
            read_more = json.dumps(read_more)
        else:
            read_more = ''
        
        body, links = get_body(article.xpath('.//div[contains(@class, "contentBody")]')[0])
        images = self.get_image(article)
        tweets = self.get_tweets(article)
        return body, links, images, tweets, read_more

    def parse_article(self, article_url, headline, date):
        page = self.s.get(article_url, headers=self.headers)
        page = html.fromstring(page.content)

        meta = get_meta_dict(page)
        
        is_liveblog = 'liveblog' in article_url
        source, section = self.parse_header(page, is_liveblog)

        articles = []
        if is_liveblog: 
            liveblog_headline = headline
            for url, headline, body, links, date, images, tweets in self.parse_liveblog(page, article_url, date):
                articles.append([url, "liveblog", liveblog_headline, source, section, headline, body, links, date, images, tweets, '', json.dumps(meta)])
        else:
            body, links, images, tweets, read_more = self.parse_item(page)
            articles.append([article_url, "article", "", source, section, headline, body, links, date, images, tweets, read_more, json.dumps(meta)])
        return articles

            
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


    def parse_header(self, elem, liveblog=False):
        if liveblog:
            source = elem.find('.//span[@class = "liveblog-header__meta-supplychannel"]').text_content()
            links = elem.find('.//div[@class = "liveblog-header__meta"]')
        else:
            source = elem.xpath('.//span[contains(@class, "supplyChannel")]')[0].text_content()
            links = elem.xpath('.//div[contains(@class, "headerMetaData")]')[0]
        section = ''
        for l in links.findall('.//a'):
            if len(section) > 0: section += ' | ' 
            section += l.text_content()       
        return source, section

            
    def scrape(self, from_date, to_date, done_urls):
        for archive_url in self.get_archive_urls(date = to_date, from_date = from_date):
            print(archive_url)
            for date, headline, article_url in self.get_article_urls(archive_url):
                if article_url in done_urls: continue
                print('\t' + article_url)
                for a in self.parse_article(article_url, headline, date):
                    if a[0] in done_urls: continue
                    yield a
                    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('fromdate', help='Start date, in format yyyy-mm-dd')
    parser.add_argument('todate', help='End date, in format yyyy-mm-dd')
    parser.add_argument('--file', help='Name of output file', default='nos.csv')
    parser.add_argument('--check_liveblogs', help="If true, check liveblog updates", default=False, action="store_true")
    args = parser.parse_args()

    fromdate = parse(args.fromdate)
    todate = parse(args.todate)

    filepath = args.file
    if os.path.isfile(filepath):
        r = csv.DictReader(open(filepath, 'r'))
        if args.check_liveblogs:
            done_urls = [l['url'] for l in r]
        else:
            done_urls = [l['url'].split('#')[0] for l in r]
        f = open(filepath, 'a')
        w = csv.writer(f)    
    else:    
        done_urls = []
        f = open(filepath, 'w')
        w = csv.writer(f)
        w.writerow(['url','type', 'liveblog_headline', 'source', 'section', 'headline', 'body', 'links', 'date', 'images','tweets', 'read_more', 'meta'])
    
    broken_links = ['https://nos.nl/artikel/479389-liveblog-laatste-dag-benedictus.html',
                    'https://nos.nl/nieuwsuur/artikel/2079854-xx.html',
                    'https://nos.nl/nieuwsuur/artikel/2370218-de-uitzending-van-25-februari.html',
                    'https://nos.nl/artikel/325429-2011-doorbraak-van-het-liveblog.html']
    done_urls = done_urls + broken_links
    
    s = nosScraper()   
    for a in s.scrape(fromdate, todate, done_urls):
        w.writerow(a)

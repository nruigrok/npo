import requests, csv, datetime, sys, json, argparse, os, re, time
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
    return body, urls


class nuScraper():
    def __init__(self):
        self.s = requests.Session()
        self.headers = {'User-agent': 'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36'}

    def update_index(self, filepath):
        done_index = set()
        done_article = set()
            
        if os.path.isfile(filepath):
            r = csv.DictReader(open(filepath, 'r'))
            for l in r:
                done_index.add(l['index_url'])
                done_article.add(l['article_url'])
            f = open(filepath, 'a')
            w = csv.writer(f)    
        else:    
            f = open(filepath, 'w')
            w = csv.writer(f)
            w.writerow(['index_url','article_url','publication','language','date','title','keywords','genres','image_url'])
    

        index_page = self.s.get('https://www.nu.nl/sitemap_index.xml')
        completed_article_reached = False

        index_urls = ['https://www.nu.nl/sitemap_news.xml']
        for loc in str(index_page.content).split('<loc>')[3:]:   
            index_urls.append(loc.split('<')[0])

        for i, index_url in enumerate(index_urls):
            articles_page = self.s.get(index_url)
            if completed_article_reached and index_url in done_index and i > 1: continue
            print(index_url)
            batches = []    ## use batch, because we need to be sure that alle articles from an index page are used. 
            for url in str(articles_page.content).split('<url>'):
                if '<loc>' not in url: continue
                article_url = url.split('<loc>')[1].split('<')[0]
                if article_url == 'https://www.nu.nlNone': continue
                if article_url in done_article:
                    completed_article_reached = True 
                    continue
                publication = url.split('<news:name>')[1].split('<')[0]
                language = url.split('<news:language>')[1].split('<')[0]
                date = parse(url.split('<news:publication_date>')[1].split('<')[0])
                title = url.split('<news:title>')[1].split('<')[0]
                keywords = url.split('<news:keywords>')[1].split('<')[0] if '<news:keywords>' in url else ''
                genres = url.split('<news:genres>')[1].split('<')[0]
                image_url = url.split('<image:loc>')[1].split('<')[0] if '<image:loc>' in url else ''
                batches.append([index_url, article_url, publication, language, date, title, keywords, genres, image_url])
            
            for batch in batches:
                w.writerow(batch)
   
    def get_index(self, from_date, to_date):
        index_file = 'nu_index.csv'
        self.update_index(index_file)
        for l in csv.DictReader(open(index_file, 'r')):
            date = parse(l['date']).date()
            if date < from_date: continue
            if date > to_date: continue
            yield l

    def parse_article(self, index_dict,):    

        ## making sure the current format of the url is used 
        head = self.s.head(index_dict['article_url'])
        if head.status_code == 302:
            index_dict['article_url'] = head.headers['location']

        if not 'www.nu.nl' in index_dict['article_url']:
            index_dict['article_url'] = 'https://www.nu.nl' + index_dict['article_url']

        bodyelem = None
        i = 0
        while bodyelem is None:    ## page sometimes doesn't read right, and some articles are missing. This tries several times before giving up
            if i == 2: break
            if i > 0:
                print('\ntrying again in 10')
                time.sleep(10)
            try:
               page = self.s.get(index_dict['article_url'])
               if page.status_code == 404: return None
            except:
                return None
            e = html.fromstring(page.content)
            if '/video/' in index_dict['article_url'] or '/video-' in index_dict['article_url']:
                bodyelem = e.find('.//div[@data-type = "videoautoplay"]')
            else:
                bodyelem = e.find('.//div[@data-type="article.body"]')
            i += 1

        if bodyelem is not None:
            body, links = get_body(bodyelem) 
        else:
            body, links = '', ''
        article_dict = {'meta': json.dumps(get_meta_dict(e)), 
                        'body': body, 
                        'links': links, 
                        'tweets': self.get_tweets(e)}

        article_dict.update(index_dict)
        return article_dict

    def get_tweets(self, elem):
        tweets = []
        for tweet in elem.findall('.//div[@class = "block twitter"]'):
            tweet_dict = {'url': tweet.attrib['data-href']}      
            tweet_dict['avatar'] = tweet.find('.//dd[@class="avatar"]/img').attrib['src']
            tweet_dict['decorate_name'] = tweet.find('.//dd[@class="username"]').text_content()
            tweet_dict['user_name'] = tweet.find('.//dd[@class="avatar"]/img').attrib['alt']

            body, links = get_body(tweet.find('.//div[@class = "tweet-content"]'))
            tweet_dict['body'] = body
            tweet_dict['links'] = links

            tweets.append(tweet_dict)

        return json.dumps(tweets)
            
    def scrape(self, from_date, to_date, done_urls):
        for index_dict in self.get_index(from_date, to_date):
            if index_dict['article_url'] in done_urls: continue
            if index_dict['article_url'] == 'https://www.nu.nlNone': continue
            print(index_dict['article_url'])
            a = self.parse_article(index_dict)
            if a is not None:
                yield a

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('fromdate', help='Start date, in format yyyy-mm-dd')
    parser.add_argument('todate', help='End date, in format yyyy-mm-dd')
    parser.add_argument('--file', help='Name of output file', default='nu.csv')
    args = parser.parse_args()

    fromdate = parse(args.fromdate).date()
    todate = parse(args.todate).date()

    filepath = args.file
    if os.path.isfile(filepath):
        r = csv.DictReader(open(filepath, 'r'))
        done_urls = [l['url'] for l in r]
        f = open(filepath, 'a')
        w = csv.writer(f)    
    else:    
        done_urls = []
        f = open(filepath, 'w')
        w = csv.writer(f)
        w.writerow(['index_url','url', 'publication','date','title','body','links','keywords','genres','image_url','tweets','meta'])
    

    s = nuScraper()   
    for a in s.scrape(fromdate, todate, done_urls):    
        w.writerow([a['index_url'], a['article_url'], a['publication'], a['date'],a['title'], a['body'], a['links'], a['keywords'], a['genres'],a['image_url'],a['tweets'],a['meta']])

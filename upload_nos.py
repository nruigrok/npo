import csv, argparse, datetime
from dateutil.parser import parse
from amcatclient.amcatclient import AmcatAPI

                                          
def saveArticles(conn, project, articleset, articles):
    batch = []
    for a in articles:
        batch.append(a)
        if len(batch) == 1000:
            conn.create_articles(project=project, articleset=articleset, json_data = batch)
            batch = []
    if len(batch) > 0: 
        conn.create_articles(project=project, articleset=articleset, json_data = batch)
                                

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('csv_file', help='path to handelingen_intro.csv')
    parser.add_argument('host', help='AmCAT host to connect to (http://amcat.vu.nl')
    parser.add_argument('project')
    parser.add_argument('articleset')
    parser.add_argument('--fromdate', help="YYYY-MM_DD")
    parser.add_argument('--todate', help='YYYY-MM-DD')
    args = parser.parse_args()

    conn = AmcatAPI(args.host)

    if args.fromdate is not None:
        urls = {a["url"] for a in conn.get_articles(
            project=args.project,
            articleset=args.articleset,
            start_date=args.fromdate,
            columns=["url"],
            page_size=9999
        )}
    else:
        urls = {a["url"] for a in conn.get_articles(
            project=args.project,
            articleset=args.articleset,
            columns=["url"],
            page_size=9999
        )}

    fromdate = parse(args.fromdate) if args.fromdate is not None else datetime.datetime.min
    todate = parse(args.todate) if args.todate is not None else datetime.datetime.max
    fromdate = fromdate.date()
    todate = todate.date()

    try: 
        args.articleset = int(args.articleset)
    except:
        aset = conn.create_set(project=args.project, name=args.articleset, provenance='Scraped from NOS.nl')
        args.articleset = aset['id']
     
    with open(args.csv_file, 'r') as f:
        batch = []
        i = 1
        for d in csv.DictReader(f):            
            a = dict()
            a['url'] = d['url']
            if a['url'] in urls:
                print('neee')
                continue
            
            urls.add(a['url'])

            a['date'] = parse(d['date'])
            if a['date'].date() < fromdate: continue
            if a['date'].date() > todate: continue

            a['text'] = d['body']
            a['title'] = d['headline']
            a['byline'] = ''
            a['publisher'] = 'NOS nieuws' if 'NOS' in d['source'] else d['source']

            if d['type'] == 'liveblog':
                a['byline'] = 'LIVEBLOG: ' + d['liveblog_headline']
                a['publisher'] = 'NOS liveblog'                
            
            if a['text'] == '' or a['title'] == '': continue
            
            a['section'] = d['section']

            a['images_json'] = d['images']
            a['tweets_json'] = d['tweets']
            a['readmore_json'] = d['read_more']
            a['links_json'] = d['links']
            a['meta_json'] = d['meta']

            batch.append(a)
            if len(batch) == 100:
                print(i * 100)
                if (i * 100) > 0: conn.create_articles(project=args.project, articleset=args.articleset, json_data=batch)
                batch = []
                i += 1
        if len(batch) > 0:
            conn.create_articles(project=args.project, articleset=args.articleset, json_data=batch)

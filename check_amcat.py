from amcatclient import AmcatAPI

conn = AmcatAPI("https://vu.amcat.nl")

done_urls = [a['url'] for a in conn.get_articles(2, 5431, columns=["url"])]

for sx in conn.get_articles(2, 5431, columns=["url"]):
    print(sx)

print(len(done_urls))

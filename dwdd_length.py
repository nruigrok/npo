import csv
from dwdd_api import *

out = csv.writer(open("data/length.csv", "w"))
out.writerow(["programid", "key", "value"])

program_ids = [program["id"] for program in csv.DictReader(open("data/meta.csv"))]
for id in program_ids:
    print(id)
    import sys; sys.exit()

#program_ids = ["urn:vme:default:program:2101608120101556931", "urn:vme:default:program:2101608120102681231"]
#i = program_ids.index("urn:vme:default:program:2101810220249767731")
#program_ids = program_ids[i:]

URL_TEMPLATE = "https://zoeken.beeldengeluid.nl/program/{page}"
URL_ROOT = "https://www.rijksoverheid.nl"


def scrape_pb(url):
    url = URL_ROOT + url
    page = requests.get(url)
    tree = html.fromstring(page.text)
    headline = get_css(tree, "h1.news")
    headline = headline.text_content()
    lead = get_css(tree, "div.intro")
    lead = lead.text_content()
    date = get_css(tree, "p.article-meta")
    date = date.text_content()
    m = re.search((r'\d{2}-\d{2}-\d{4}'),(date))
    if m:
        date2 = datetime.datetime.strptime(m.group(), '%d-%m-%Y').date()
    content = tree.cssselect("div > div.contentBox")
    content += tree.cssselect("div.intro ~ p")
    body2=[]
    body2.append(lead)
    for cont in content:
        text = cont.text_content()
        body2.append(text)
    body2 = "\n\n".join(body2)
    date3 =date2
    return {"title": headline,
            "text": body2,
            "date": date3,
            "medium": "Persberichten",
            "url": url}

for i, program_id in enumerate(program_ids):
    print(f"{i}/{len(program_ids)}: {program_id}")
    metadata = get_metadata("programs", program_id)
    if 'nisv.guest' in metadata:
        if metadata['nisv.guest']:
            for (guest, role) in metadata['nisv.guest']:
                if "value" in guest:
                    out.writerow([program_id, "guest", guest["value"]])
    if 'nisv.subjectterm' in metadata:
        if metadata['nisv.subjectterm']:
            for subject in metadata['nisv.subjectterm']:
                out.writerow([program_id, "subjectterm", subject[0]["value"]])
    if 'nisv.classification' in metadata:
        if metadata['nisv.classification']:
            for (subject, age) in metadata['nisv.classification']:
                out.writerow([program_id, "classification", subject["value"]])

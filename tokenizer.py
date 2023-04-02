import stanza
import csv
import sys
import logging
import argparse

from amcatclient import AmcatAPI
import e2edutch.stanza

conn = AmcatAPI("https://vu.amcat.nl", user = "nel")
#conn = AmcatAPI("http://localhost:8000", user = "nel")
nlp = stanza.Pipeline('nl', processors='tokenize,lemma,pos,depparse,ner,coref', use_gpu=True, pos_batch_size=3000) # Build the pipeline, specify part-of-speech processor's batch size

logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

w = csv.writer(sys.stdout)
w.writerow(["doc_id", "sentence_id", "token_id", "token", "lemma", "upos", "parent", "relation", "loc"])
#fn = '/tmp/nieuws_ondert.csv'

articles = conn.get_articles(2, 5877, columns=["title", "text"], page_size=100)
#articles = conn.get_articles(1, 320, columns=["title", "text"])
#articles = [dict(id=1, title="", text="""
##""")]
for i, article in enumerate(articles):
    if not i%100:
        logging.info(f"{i} articles parsed...")
    doc_id = article['id']
    text = f"{article['title']}\n\n{article['text']}"
    doc = nlp(text)

    for c in doc.clusters:
        print([x.id for x in c])

    for sent_id, sent in enumerate(doc.sentences):
        for token in sent.tokens:
            for word in token.words:
                w.writerow([doc_id, sent_id, word.id, word.text, word.lemma, word.upos, word.head, word.deprel, token.ner])
    sys.exit()

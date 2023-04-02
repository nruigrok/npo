import stanza
import csv
import sys
import logging

nlp = stanza.Pipeline('nl', processors='tokenize,lemma,pos,depparse,ner', use_gpu=True, pos_batch_size=3000) # Build the pipeline, specify part-of-speech processor's batch size

logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')

w = csv.writer(sys.stdout)
w.writerow(["doc_id", "sentence_id", "token_id", "token", "lemma", "upos", "parent", "relation", "loc"])

logging.info(f"Reading from standard input".format(**locals()))
articles = csv.reader(sys.stdin, delimiter=',')
for i, article in enumerate(articles):
    if not i%100:
        logging.info(f"{i} articles parsed...")
    doc_id = article[0]
    text = f"{article[1]}"
    doc = nlp(text)

    for sent_id, sent in enumerate(doc.sentences):
        for token in sent.tokens:
            for word in token.words:
                w.writerow([doc_id, sent_id, word.id, word.text, word.lemma, word.upos, word.head, word.deprel, token.ner])

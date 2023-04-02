library(tidyverse)
library(amcatr)
library(quanteda)
library(corpustools)
library(tokenbrowser)

conn = amcat.connect('https://vu.amcat.nl')
pers = amcat.getarticlemeta(conn, project=78, articleset = 3311, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
nieuws = amcat.getarticlemeta(conn, project=78, articleset = 3312, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
sport = amcat.getarticlemeta(conn, project=78, articleset = 3320)
nieuws = nieuws%>%mutate(publisher=ifelse(id %in% sport$id, "NOS Sport", publisher),
                         publisher=ifelse(is.na(publisher),"EenVandaag", publisher),
                         date=case_when(publisher == "M" ~ date + lubridate::dhours(19),
                                       publisher == "Op1" ~ date + lubridate::dhours(22),
                                       T ~ date))

subt = amcat.getarticlemeta(conn, project=78, articleset = 3517, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))%>%
  mutate(publisher = paste0(publisher,"_sub"))%>%mutate(date=case_when(publisher == "M_sub" ~ date + lubridate::dhours(19),
                                                                       publisher == "De Vooravond_sub" ~ date + lubridate::dhours(19),
                                                                       publisher == "Op1_sub" ~ date + lubridate::dhours(22),
                                                                       T ~ date))


seg = amcat.getarticlemeta(conn, project=78, articleset = 3419, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))%>%
  mutate(publisher = paste0(publisher,"_seg"))%>%mutate(date=case_when(publisher == "M_seg" ~ date + lubridate::dhours(19),
                                                                       publisher == "Op1_seg" ~ date + lubridate::dhours(22),
                                                                       T ~ date))


radio = amcat.getarticlemeta(conn, project=78, articleset = 3519, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))

teletekst = amcat.getarticlemeta(conn, project=78, articleset = 3522, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))

total=nieuws%>%bind_rows(subt,seg,radio,teletekst)
saveRDS(total,"data/npo.rds")
saveRDS(pers,"data/anp.rds")


#ophalen tokens gemaakt via pythonscript tokenizer.py
pb_tokens = read_csv("data/tokens_stanza_persb.csv")%>%as_tibble()
npo_tokens1 = read_csv("data/tokens_stanza_nieuws.csv")%>%as_tibble()
npo_tokens2 = read_csv("data/tokens_stanza_nieuws_segments.csv")%>%as_tibble()
npo_tokens3 = read_csv("data/tokens_stanza_nieuws_ondert.csv")%>%as_tibble()
npo_tokens4 = read_csv("data/tokens_stanza_nieuws_radio.csv")%>%as_tibble()
npo_tokens5 = read_csv("data/tokens_stanza_nieuws_teletekst.csv")%>%as_tibble()


npo_tokens = npo_tokens1%>%bind_rows(npo_tokens2,npo_tokens3, npo_tokens4, npo_tokens5)



#maken DTM's
pb_dfm = pb_tokens %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta=tibble(id=quanteda::docid(pb_dfm))%>%mutate(id=as.numeric(as.character(id)))
pb_meta = pb_meta%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm)=pb_meta


npo_dfm = npo_tokens %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta=tibble(id=quanteda::docid(npo_dfm))%>%mutate(id=as.numeric(as.character(id)))
npo_meta = npo_meta%>%left_join(total)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(npo_dfm)=npo_meta

#Vergelijking via Newsflow
g_pb = RNewsflow::newsflow_compare(pb_dfm, npo_dfm, date='date', 
                                 min_similarity = 0.1,       ## similarity threshold
                                 hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                 measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                 tf_idf=T)                   ## weeg woorden die minder vaak voorkomen zwaarder mee

g_npo = RNewsflow::newsflow_compare(npo_dfm, pb_dfm, date='date', 
                                 min_similarity = 0.1,       ## similarity threshold
                                 hour_window = c(-1*24, 0),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                 measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                 tf_idf=T) 

#Dataframes
e_pb = igraph::as_data_frame(g_pb)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)
e_npo = igraph::as_data_frame(g_npo)%>%rename(id=from, from=to, weight2=weight)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)
e = e_pb%>%left_join(e_npo)

#join aan totaal
total2=total%>%left_join(e)%>%mutate(publisher=ifelse(is.na(publisher),"EenVandaag", publisher))


######################ALLEEN PROPER NAMES #####################

pb_tokens_pn = pb_tokens%>%filter(upos=="PROPN")%>%as_tibble()
npo_tokens_pn = npo_tokens%>%filter(upos=="PROPN")%>%as_tibble()

pb_dfm_pn = pb_tokens_pn %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_pn=tibble(id=quanteda::docid(pb_dfm_pn))%>%mutate(id=as.numeric(as.character(id)))
pb_meta_pn = pb_meta_pn%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_pn)=pb_meta_pn

npo_dfm_pn = npo_tokens_pn %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_pn=tibble(id=quanteda::docid(npo_dfm_pn))%>%mutate(id=as.numeric(as.character(id)))
npo_meta_pn = npo_meta_pn%>%left_join(total)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(npo_dfm_pn)=npo_meta_pn


g_pb_pn = RNewsflow::newsflow_compare(pb_dfm_pn, npo_dfm_pn, date='date', 
                                   min_similarity = 0.1,       ## similarity threshold
                                   hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                   measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                   tf_idf=T)                   ## weeg woorden die minder vaak voorkomen zwaarder mee

g_npo_pn = RNewsflow::newsflow_compare(npo_dfm_pn, pb_dfm_pn, date='date', 
                                    min_similarity = 0.1,       ## similarity threshold
                                    hour_window = c(-1*24, 0),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                    measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                    tf_idf=T) 

e_pb_pn = igraph::as_data_frame(g_pb_pn)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)
e_npo_pn = igraph::as_data_frame(g_npo_pn)%>%rename(id=from, from=to, weight2=weight)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)
e_pn = e_pb_pn%>%left_join(e_npo_pn)%>%rename(weight_pn=weight,weight2_pn=weight2)

total_pn=total%>%left_join(e_pn)%>%mutate(publisher=ifelse(is.na(publisher),"EenVandaag", publisher))

tot3=total2%>%left_join(total_pn)


#################### ZINNEN OVERLAP ###############

#' Compute ngrams, padding with NAs at start
ngram = function(token, n=3) {
  ngrams = token
  for (i in 2:n) {
    token = lag(token)
    ngrams=paste(token, ngrams)
  }
  c(rep(NA, n-1), ngrams[n:length(ngrams)])
}

sum_value = function(value, n=3) {
  value[is.na(value)] = 0
  result = value
  for (i in 2:n) {
    value = lead(value)
    result = pmax(result, value)
  }
  result
}


#' Create dtm from 3-grams
npo_tokens_3 = npo_tokens%>%filter(upos !="PUNCT") %>% group_by(doc_id) %>% filter(n() >= 3) %>% mutate(ngram=ngram(tolower(token), n=3))%>%filter(! is.na(ngram))
pb_tokens_3 = pb_tokens%>%filter(upos !="PUNCT") %>%  group_by(doc_id) %>% filter(n() >= 3) %>% mutate(ngram=ngram(tolower(token), n=3))%>%filter(! is.na(ngram))
pb_dfm_3 = pb_tokens_3 %>% with(split(ngram, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_3=tibble(id=quanteda::docid(pb_dfm_3)) %>% mutate(id=as.numeric(as.character(id)))
pb_meta_3 = pb_meta_3%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_3)=pb_meta_3

npo_dfm_3 = npo_tokens_3 %>% with(split(ngram, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_3 = tibble(id=quanteda::docid(npo_dfm_3)) %>% mutate(id=as.numeric(as.character(id)))
npo_meta_3 = npo_meta_3%>%left_join(total) %>% select(-text)
docvars(npo_dfm_3)=npo_meta_3

#comparison
g_pb_3 = RNewsflow::newsflow_compare(pb_dfm_3, npo_dfm_3, date='date', 
                                      min_similarity = 0.0,       ## similarity threshold
                                      hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                      measure = 'overlap',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                      tf_idf=F)                   ## weeg woorden die minder vaak voorkomen zwaarder mee


e_pb_3 = igraph::as_data_frame(g_pb_3)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)%>%rename(n_ngram3=weight)
tot4a = tot3%>%left_join(e_pb_3)%>%rename(pb_id=from)


#' Create dtm from 10-grams
npo_tokens_10 = npo_tokens%>%filter(upos !="PUNCT") %>% group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))%>%filter(! is.na(ngram))
pb_tokens_10 = pb_tokens%>%filter(upos !="PUNCT") %>%  group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))%>%filter(! is.na(ngram))
pb_dfm_10 = pb_tokens_10 %>% with(split(ngram, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_10=tibble(id=quanteda::docid(pb_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
pb_meta_10 = pb_meta_10%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_10)=pb_meta_10

npo_dfm_10 = npo_tokens_10 %>% with(split(ngram, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_10 = tibble(id=quanteda::docid(npo_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
npo_meta_10 = npo_meta_10%>%left_join(total) %>% select(-text)
docvars(npo_dfm_10)=npo_meta_10

#comparison
g_pb_10 = RNewsflow::newsflow_compare(pb_dfm_10, npo_dfm_10, date='date', 
                                      min_similarity = 0.0,       ## similarity threshold
                                      hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                      measure = 'overlap',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                      tf_idf=F)                   ## weeg woorden die minder vaak voorkomen zwaarder mee


e_pb_10 = igraph::as_data_frame(g_pb_10)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)%>%rename(n_ngram=weight, pb_id=from)
tot4 = tot4a%>%left_join(e_pb_10)
overlap = tot4%>%filter(! is.na(n_ngram))

######Berekening van het aantal zinnen dat de ngrams uiteindelijk overlappen

#tokens_npo= npo_tokens%>%filter(doc_id %in% overlap$id)%>%filter(upos!="PUNCT") %>% 
 # group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))

tokens_npo = npo_tokens %>% inner_join(overlap %>% rename(doc_id=id))%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id, pb_id) %>% mutate(ngram=str_c(pb_id, ": ", ngram(tolower(token), n=10))) %>% arrange(doc_id, pb_id, sentence_id, token_id)

tokens_pb=pb_tokens%>%filter(doc_id %in% overlap$pb_id)%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id) %>% mutate(ngram=str_c(doc_id, ": ", ngram(tolower(token), n=10)))

tokens_npo = tokens_npo %>% mutate(value = as.numeric(!is.na(ngram) & ngram %in% tokens_pb$ngram))
tokens_npo = tokens_npo %>% mutate(value2 = sum_value(value, n=10))%>%mutate(value2=ifelse(is.na(value2),0,value2)) 

weight_zin=tokens_npo%>%group_by(doc_id, pb_id)%>%summarize(n_woorden=sum(value), n_zinnen=sum(value2))%>%rename(id=doc_id)

tot5 = tot4%>%left_join(weight_zin)
table(tot5$publisher)
saveRDS(tot5,"stanza_model_totaal.rds")

tot5=readRDS("stanza_model_totaal.rds")

table(tot5$publisher)
vooravond=tot5%>%filter(publisher=="Vooravond_sub")
View(vooravond)

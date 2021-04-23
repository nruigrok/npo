library(tidyverse)
#library("spacyr")
library(amcatr)
library(quanteda)
library(corpustools)
#spacy_initialize(model = "nl_core_news_sm")
#spacy_download_langmodel("nl")


conn = amcat.connect('https://vu.amcat.nl')
pers = amcat.getarticlemeta(conn, project=78, articleset = 3311, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
pers$medium = 'Persberichten'


nieuws = amcat.getarticlemeta(conn, project=78, articleset = 3312, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
sport = amcat.getarticlemeta(conn, project=78, articleset = 3320)

nieuws = nieuws%>%mutate(medium=ifelse(id %in% sport$id, "NOS Sport", publisher),
                         publisher=ifelse(is.na(publisher),"EenVandaag", publisher),
                         date=case_when(publisher == "EenVandaag" ~ date + lubridate::dhours(18),
                                       publisher == "M" ~ date + lubridate::dhours(19),
                                       publisher == "Op1" ~ date + lubridate::dhours(22),
                                       T ~ date))
table(nieuws$medium)
total=nieuws

######DIT IS EENMALIG OM TOKENS TE MAKEN
nieuws2 = nieuws %>% mutate(text = str_c(title, text, sep="\n\n")) %>% select(doc_id=id, text=text)
nieuws2 %>% write_csv("/tmp/nieuws2b.csv")
Sys.time()
parsedtxt <- spacy_parse(nieuws2)
Sys.time()
write_rds(parsedtxt,"data/tokens_spacy_nieuws.rds")
########

pb_tokens = read_csv("data/tokens_stanza_persb.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_stanza_nieuws.csv")%>%as_tibble()

pb_dfm = pb_tokens %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta=tibble(id=quanteda::docid(pb_dfm))%>%mutate(id=as.numeric(as.character(id)))
pb_meta = pb_meta%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm)=pb_meta


npo_dfm = npo_tokens %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta=tibble(id=quanteda::docid(npo_dfm))%>%mutate(id=as.numeric(as.character(id)))
npo_meta = npo_meta%>%left_join(nieuws)%>%select(-text, -medium)%>%mutate(date=as.POSIXct(date))
docvars(npo_dfm)=npo_meta


g_pb = RNewsflow::newsflow_compare(pb_dfm, npo_dfm, date='date', 
                                 min_similarity = 0.2,       ## similarity threshold
                                 hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                 measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                 tf_idf=T)                   ## weeg woorden die minder vaak voorkomen zwaarder mee

g_npo = RNewsflow::newsflow_compare(npo_dfm, pb_dfm, date='date', 
                                 min_similarity = 0.2,       ## similarity threshold
                                 hour_window = c(-1*24, 0),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                 measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                 tf_idf=T) 

e_pb = igraph::as_data_frame(g_pb)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)

e_npo = igraph::as_data_frame(g_npo)%>%rename(id=from, from=to, weight2=weight)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)



e = e_pb%>%left_join(e_npo)


total2=total%>%left_join(e)%>%mutate(medium=ifelse(is.na(medium),"EenVandaag", medium), publisher=ifelse(is.na(publisher),"EenVandaag", publisher))



######################ALLEEN PROPER NAMES #####################

pb_tokens_pn = read_csv("data/tokens_stanza_persb.csv")%>%filter(upos=="PROPN")%>%as_tibble()
npo_tokens_pn = read_csv("data/tokens_stanza_nieuws.csv")%>%filter(upos=="PROPN")%>%as_tibble()

pb_dfm_pn = pb_tokens_pn %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_pn=tibble(id=quanteda::docid(pb_dfm_pn))%>%mutate(id=as.numeric(as.character(id)))
pb_meta_pn = pb_meta_pn%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_pn)=pb_meta_pn


npo_dfm_pn = npo_tokens_pn %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_pn=tibble(id=quanteda::docid(npo_dfm_pn))%>%mutate(id=as.numeric(as.character(id)))
npo_meta_pn = npo_meta_pn%>%left_join(nieuws)%>%select(-text, -medium)%>%mutate(date=as.POSIXct(date))
docvars(npo_dfm_pn)=npo_meta_pn


g_pb_pn = RNewsflow::newsflow_compare(pb_dfm_pn, npo_dfm_pn, date='date', 
                                   min_similarity = 0.2,       ## similarity threshold
                                   hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                   measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                   tf_idf=T)                   ## weeg woorden die minder vaak voorkomen zwaarder mee

g_npo_pn = RNewsflow::newsflow_compare(npo_dfm_pn, pb_dfm_pn, date='date', 
                                    min_similarity = 0.2,       ## similarity threshold
                                    hour_window = c(-1*24, 0),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                    measure = 'overlap_pct',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                    tf_idf=T) 

e_pb_pn = igraph::as_data_frame(g_pb_pn)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)
head(e_pb_pn)
e_npo_pn = igraph::as_data_frame(g_npo_pn)%>%rename(id=from, from=to, weight2=weight)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)
head(e_npo_pn)
e_pn = e_pb_pn%>%left_join(e_npo_pn)%>%rename(weight_pn=weight,weight2_pn=weight2)
e_pn

total_pn=total%>%left_join(e_pn)%>%mutate(medium=ifelse(is.na(medium),"EenVandaag", medium), publisher=ifelse(is.na(publisher),"EenVandaag", publisher))
head(total_pn)

tot3=total2%>%left_join(total_pn)
tot3



#################### ZINNEN OVERLAP


pb_tokens = readRDS("data/tokens_spacy_persb.rds")%>%as_tibble()
npo_tokens = readRDS("data/tokens_spacy_nieuws.rds")%>%as_tibble()


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

#' Create dtm from 10-grams

npo_tokens_10 = npo_tokens%>%filter(pos !="PUNCT") %>% group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))
pb_tokens_10 = pb_tokens%>%filter(pos !="PUNCT") %>%  group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))

pb_dfm_10 = pb_tokens_10 %>% with(split(ngram, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_10=tibble(id=quanteda::docid(pb_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
pb_meta_10 = pb_meta_10%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_10)=pb_meta_10


npo_dfm_10 = npo_tokens_10 %>% with(split(ngram, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_10 = tibble(id=quanteda::docid(npo_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
npo_meta_10 = npo_meta_10%>%left_join(nieuws) %>% select(-text, -medium)
docvars(npo_dfm_10)=npo_meta_10
#%>% 
#  mutate(h=lubridate::hour(date)) %>% group_by(h, publisher) %>% summarize(n=n()) %>% pivot_wider(values_from=n, names_from=h)


g_pb_10 = RNewsflow::newsflow_compare(pb_dfm_10, npo_dfm_10, date='date', 
                                      min_similarity = 0.0,       ## similarity threshold
                                      hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                      measure = 'overlap',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                      tf_idf=F)                   ## weeg woorden die minder vaak voorkomen zwaarder mee


e_pb_10 = igraph::as_data_frame(g_pb_10)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)%>%rename(n_ngram=weight)
head(e_pb_10)

tot4 = tot3%>%left_join(e_pb_10)
head(tot4)

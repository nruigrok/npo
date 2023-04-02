library(tidyverse)
#library("spacyr")
library(amcatr)
library(quanteda)
library(corpustools)
#spacy_initialize(model = "nl_core_news_sm")
#spacy_download_langmodel("nl")


conn = amcat.connect('https://vu.amcat.nl')
pers = amcat.getarticlemeta(conn, project=78, articleset = 3689, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
pers$medium = 'Persberichten'

nieuws = amcat.getarticlemeta(conn, project=78, articleset = 3695, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))%>%
  mutate(publisher = ifelse(is.na(publisher),"EenVandaag", publisher))


nieuws = nieuws%>%mutate(date=case_when(publisher == "EenVandaag" ~ date + lubridate::dhours(18),
                                       publisher == "M" ~ date + lubridate::dhours(19),
                                       publisher == "Op1" ~ date + lubridate::dhours(22),
                                       T ~ date))%>%
  mutate(medium=publisher)
table(nieuws$medium)
total=nieuws

######DIT IS EENMALIG OM TOKENS TE MAKEN
nieuws2 = nieuws %>% mutate(text = str_c(title, text, sep="\n\n")) %>% select(doc_id=id, text=text)
nieuws2 %>% write_csv("/tmp/nieuws_teletekst.csv")
Sys.time()
parsedtxt <- spacy_parse(nieuws2)
Sys.time()
write_rds(parsedtxt,"data/tokens_spacy_nieuws.rds")
########

pb_tokens = readRDS("data/tokens_spacy_persb.rds")%>%filter(pos != "SPACE")%>%as_tibble()
npo_tokens = readRDS("data/tokens_spacy_nieuws.rds")%>%filter(pos != "SPACE")%>%as_tibble()

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

total2%>%select(-year,-month,-week,-publisher)%>%View()

######################ALLEEN PROPER NAMES #####################

pb_tokens_pn = readRDS("data/tokens_spacy_persb.rds")%>%filter(pos=="PROPN")%>%as_tibble()
npo_tokens_pn = readRDS("data/tokens_spacy_nieuws.rds")%>%filter(pos=="PROPN")%>%as_tibble()

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


pb_tokens = readRDS("data/tokens_spacy_persb.rds")%>%filter(pos != "SPACE")%>%as_tibble()
npo_tokens = readRDS("data/tokens_spacy_nieuws.rds")%>%filter(pos != "SPACE")%>%as_tibble()


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

npo_tokens_10 = npo_tokens%>%filter(! pos %in% c("PUNCT","SPACE")) %>% group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))%>%filter(! is.na(ngram))
pb_tokens_10 = pb_tokens%>%filter(! pos %in% c("PUNCT","SPACE")) %>%  group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))%>%filter(! is.na(ngram))

pb_dfm_10 = pb_tokens_10 %>% with(split(ngram, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_10=tibble(id=quanteda::docid(pb_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
pb_meta_10 = pb_meta_10%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_10)=pb_meta_10


npo_dfm_10 = npo_tokens_10 %>% with(split(ngram, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_10 = tibble(id=quanteda::docid(npo_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
npo_meta_10 = npo_meta_10%>%left_join(nieuws) %>% select(-text, -medium)
docvars(npo_dfm_10)=npo_meta_10
 
#  mutate(h=lubridate::hour(date)) %>% group_by(h, publisher) %>% summarize(n=n()) %>% pivot_wider(values_from=n, names_from=h)


g_pb_10 = RNewsflow::newsflow_compare(pb_dfm_10, npo_dfm_10, date='date', 
                                      min_similarity = 0.0,       ## similarity threshold
                                      hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                      measure = 'overlap',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                      tf_idf=F)                   ## weeg woorden die minder vaak voorkomen zwaarder mee


e_pb_10 = igraph::as_data_frame(g_pb_10)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)%>%rename(n_ngram=weight)
head(e_pb_10)

tot4 = tot3%>%left_join(e_pb_10)%>%rename(pb_id=from)
tot4%>%select(-text,-year,-month,-week,-medium)%>%view()
table(tot4$n_ngram)


saveRDS(tot4,"data/npo_spacy.rds")
overlap = tot4%>%filter(! is.na(n_ngram))



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
    value = lead(value, default=0)
    result = pmax(result, value)
  }
  result
}



######Berekening van het aantal zinnen dat de ngrams uiteindelijk overlappen

pb_tokens = readRDS("data/tokens_spacy_persb.rds")%>%filter(pos != "SPACE")%>%as_tibble()%>%mutate(doc_id=as.numeric(doc_id))
npo_tokens = readRDS("data/tokens_spacy_nieuws.rds")%>%filter(pos != "SPACE")%>%as_tibble()%>%mutate(doc_id=as.numeric(doc_id))

tokens_npo= npo_tokens%>%filter(doc_id %in% overlap$id)%>%filter(pos!="PUNCT") %>% 
  group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))

tokens_npo = npo_tokens %>% inner_join(overlap %>% rename(doc_id=id))%>%filter(pos!="PUNCT") %>% 
  group_by(doc_id, pb_id) %>% mutate(ngram=str_c(pb_id, ": ", ngram(tolower(token), n=10))) %>% arrange(doc_id, pb_id, sentence_id, token_id)

tokens_pb=pb_tokens%>%filter(doc_id %in% overlap$pb_id)%>%filter(pos!="PUNCT") %>% 
  group_by(doc_id) %>% mutate(ngram=str_c(doc_id, ": ", ngram(tolower(token), n=10)))

tokens_npo = tokens_npo %>% mutate(value = as.numeric(!is.na(ngram) & ngram %in% tokens_pb$ngram))
tokens_npo = tokens_npo %>% mutate(value2 = sum_value(value, n=10)) 


table(tokens_npo$value)
sum(tot4$n_ngram, na.rm=T)


weight_zin = tokens_npo%>%group_by(doc_id, pb_id)%>%summarise(n_woorden=sum(value2))%>%mutate(n_zinnen = n_woorden/10)%>%rename(id=doc_id)
weight_zin


tot5 = tot4%>%left_join(weight_zin)
tot5%>%select(-text,-year,-month,-week,-medium,-date)%>%view()
saveRDS(tot5,"spacy_model.rds")

#####selectie om hightlight te kunnen zien


tokens_npo=tokens_npo%>%mutate(pb_id=as.numeric(pb_id))

persb_id = "23676363"
meta = bind_rows(
  tot5 %>% filter(pb_id == persb_id) %>% mutate(doc_id = paste("artikel", id)) %>% select(doc_id, publisher, date, title, weight, weight2, weight_pn,weight2_pn, n_ngram,n_zinnen ),
  pb_meta %>% filter(id == persb_id) %>% mutate(doc_id=paste("persbericht", id)) %>% select(doc_id, publisher, date, title)
)

table(tokens_npo$pb_id)
pb = tokens_npo%>%filter(pb_id==persb_id)%>%mutate(doc_id=paste("artikel", doc_id))
tokens_persb = tokens_pb%>%filter(doc_id==persb_id)%>%mutate(doc_id=paste("persbericht", doc_id),value=as.numeric(! is.na(ngram) & ngram %in% pb$ngram), value2=sum_value(value,n=10))
br=bind_rows(tokens_persb,pb)

highlighted_browser(br, value=br$value2 > 0, meta=meta) %>% view_browser()
view(br)
view(tot5)



pbid = 23700784
artid = 23853126

pblemma = pb_tokens %>% filter(doc_id == pbid, pos == "PROPN") %>% pull(lemma)
artlemma = npo_tokens %>% filter(doc_id == artid, pos == "PROPN") %>% pull(lemma)

intersect(artlemma, pblemma) 
sum(pblemma %in% artlemma) / length(pblemma)
sum(artlemma %in% pblemma) / length(artlemma)
length(intersect(artlemma, pblemma)) / length(artlemma)

tokens_pb2 = pb_tokens%>%filter(doc_id=="23696918")
tokens_npo2 = npo_tokens%>%filter(doc_id %in%  ("23852089"))
view(tokens_npo2)
view(tokens_pb2)





####CODE VOOR RIJEN


for (i in 1:nrow(overlap)) {
  id = overlap$id[i]
  from=overlap$from[i]
  message(id, " : ", from)
  if (i>10) break
}
######

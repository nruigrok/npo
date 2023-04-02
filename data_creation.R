library(tidyverse)
library(amcatr)
library(quanteda)
library(corpustools)
library(tokenbrowser)
library(lubridate)



conn = amcat.connect('https://vu.amcat.nl')



nieuws = amcat.getarticlemeta(conn, project=78, articleset = 3703, dateparts=T,time=T, columns = c("publisher", "date","title", "section", "author", "source", "tags","topics"))
sport = amcat.getarticlemeta(conn, project=78, articleset = 3702, dateparts=T,time=T, columns = c("source"))
eenv = amcat.getarticlemeta(conn, project=78, articleset = 3695, dateparts=T,time=T, columns = c("publisher", "date","title", "section", "author", "source", "tags","topics"))%>%
  filter(is.na(publisher))%>%mutate(publisher="EenVandaag")



nieuws = nieuws%>%bind_rows(eenv)

nieuws = nieuws%>%mutate(publisher=ifelse(id %in% sport$id, "NOS Sport", publisher))%>%
  mutate(date=case_when(publisher == "EenVandaag" ~ date + lubridate::dhours(18),
                         publisher == "Op1" ~ date + lubridate::dhours(22),
                         T ~ date), publisher = ifelse(publisher=="teletekst","Teletekst",publisher))

ondert = amcat.getarticlemeta(conn, project=78, articleset = 3692, dateparts=T,time=T, columns = c("publisher", "date","title", "text","omroep"))%>%
  mutate(publisher = case_when(publisher == "EenVandaag" ~ paste0(publisher,"_sub"),
                               publisher == "Op1" ~ paste0(publisher,"_sub"),
                               T ~ publisher))

nieuws = nieuws%>%bind_rows(ondert)

pers = amcat.getarticlemeta(conn, project=78, articleset = 3689, dateparts=T,time=T, columns = c("publisher", "date","title",  "section", "author"))



#ophalen tokens gemaakt via pythonscript tokenizer.py

pb_tokens = read_csv("data/tokens_pers_stanza2.csv")%>%as_tibble()

npo_tokens = read_csv("data/tokens_nieuws_stanza2.csv")%>%as_tibble()
npo_sport = read_csv("data/tokens_stanza_nieuws_sport.csv")%>%as_tibble()
teletekst = read_csv("data/tokens_teletekst.csv")%>%as_tibble()

npo_tokens = npo_tokens %>% bind_rows(npo_sport,teletekst)
npo_tokens = npo_tokens %>% select(doc_id:upos)
saveRDS(npo_tokens, "data/npo_tokens_20210702.rds")

#maken DTM's
pb_dfm = pb_tokens %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta=tibble(id=quanteda::docid(pb_dfm))%>%mutate(id=as.numeric(as.character(id)))
pb_meta = pb_meta%>%left_join(pers)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm)=pb_meta


npo_dfm = npo_tokens %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta=tibble(id=quanteda::docid(npo_dfm))%>%mutate(id=as.numeric(as.character(id)))
npo_meta = npo_meta%>%left_join(nieuws)%>%select(-text)%>%mutate(date=as.POSIXct(date))
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


#' Create dtm from 10-grams
npo_tokens_10 = npo_tokens%>%filter(upos !="PUNCT") %>% group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))%>%filter(! is.na(ngram))
pb_tokens_10 = pb_tokens%>%filter(upos !="PUNCT") %>%  group_by(doc_id) %>% filter(n() >= 10) %>% mutate(ngram=ngram(tolower(token), n=10))%>%filter(! is.na(ngram))
pb_dfm_10 = pb_tokens_10 %>% with(split(ngram, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta_10=tibble(id=quanteda::docid(pb_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
pb_meta_10 = pb_meta_10%>%left_join(pers)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_10)=pb_meta_10

npo_dfm_10 = npo_tokens_10 %>% with(split(ngram, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_10 = tibble(id=quanteda::docid(npo_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
npo_meta_10 = npo_meta_10%>%left_join(nieuws) %>% select(-text)
docvars(npo_dfm_10)=npo_meta_10

#comparison
g_pb_10 = RNewsflow::newsflow_compare(pb_dfm_10, npo_dfm_10, date='date', 
                                      min_similarity = 0.0,       ## similarity threshold
                                      hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                      measure = 'overlap',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                      tf_idf=F)                   ## weeg woorden die minder vaak voorkomen zwaarder mee


e_pb_10 = igraph::as_data_frame(g_pb_10)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)%>%rename(n_ngram=weight)

e_tot = e%>%full_join(e_pb_10)
head(e_tot)

tot4=nieuws%>%left_join(e_tot)
table(is.na(tot4$id))
tot4%>%select(from,id)%>%unique()%>%nrow()

saveRDS(tot4, "data/npo_juli2021.rds")

tot4 = readRDS( "data/npo_juli2021.rds")


overlap = tot4%>%filter(! is.na(n_ngram))

saveRDS(overlap, "data/overlap_anp_npo_totaal.rds")

overlap = readRDS("data/overlap_anp_npo_totaal.rds")


head(pb_tokens)
head(npo_tokens)
head(overlap)
library(openssl)


######Berekening van het aantal zinnen dat de ngrams uiteindelijk overlappen


#pbid = 37200557
#artid = 34925701
#overlap= overlap%>%filter(id==artid, from==pbid)


tokens_npo = npo_tokens %>% inner_join(overlap %>% rename(doc_id=id, pb_id=from))%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id, pb_id) %>% mutate(ngram=str_c(pb_id, ": ", ngram(tolower(token), n=10))) %>% arrange(doc_id, pb_id, sentence_id, token_id)

tokens_pb=pb_tokens%>%filter(doc_id %in% overlap$from)%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id) %>% mutate(ngram=str_c(doc_id, ": ", ngram(tolower(token), n=10)))

tokens_npo = tokens_npo %>% mutate(value = as.numeric(!is.na(ngram) & ngram %in% tokens_pb$ngram))
tokens_npo = tokens_npo %>% mutate(value2 = sum_value(value, n=10)) 


weight_zin = tokens_npo%>%mutate(value2=ifelse(is.na(value2),0,value2))%>%group_by(doc_id, pb_id)%>%dplyr::summarise(n_woorden=sum(value2))%>%mutate(n_zinnen = n_woorden/10)%>%rename(id=doc_id)


tot5 = tot4%>%rename(pb_id=from)%>%left_join(weight_zin)

saveRDS(tot5,"data/model_npo2021.rds")
table(tot5$n_zinnen)

table(tot5$publisher)
nieuwsuur = ondert%>%filter(publisher=="Nieuwsuur")
tot5=tot5%>%mutate(publisher= ifelse(id %in% nieuwsuur$id, "Nieuwsuur_sub", publisher))

######OVER TIJD

tijden = tot5%>%mutate(hours=format(as.POSIXct(strptime(date,"%Y-%m-%d %H:%M:%S",tz="")) ,format = "%H:%M:%S"),
                       day=format(as.POSIXct(strptime(date,"%Y-%m-%d %H:%M:%S",tz="")),format = "%Y-%m-%d"))%>%
  mutate(tijd = case_when(hours>="00:00:00" & hours<"06:00:00" ~ "Nacht",
                          hours>="06:00:00" & hours<"12:00:00" ~ "Ochtend",
                          hours>="12:00:00" & hours<"18:00:00" ~ "Middag",
                          hours>="18:00:00" & hours<="00:00:00" ~ "Avond",
                          T ~ "Avond"),
         dag = weekdays(as.Date(date)))%>%dplyr::mutate(dag=tools::toTitleCase(dag))

tijden = tijden%>%mutate(pb_hours=format(as.POSIXct(strptime(pb_date,"%Y-%m-%d %H:%M:%S",tz="")) ,format = "%H:%M:%S"),
                         pb_day=format(as.POSIXct(strptime(pb_date,"%Y-%m-%d %H:%M:%S",tz="")),format = "%Y-%m-%d"))%>%
  mutate(pb_tijd = case_when(pb_hours>="00:00:00" & pb_hours<"06:00:00" ~ "Nacht",
                             pb_hours>="06:00:00" & pb_hours<"12:00:00" ~ "Ochtend",
                             pb_hours>="12:00:00" & pb_hours<"18:00:00" ~ "Middag",
                             pb_hours>="18:00:00" & pb_hours<="00:00:00" ~ "Avond",
                             T ~ "Avond"),
         pb_dag = weekdays(as.Date(pb_date)))%>%dplyr::mutate(pb_dag=tools::toTitleCase(pb_dag))

invloed = tijden%>%dplyr::mutate(across(weight:n_zinnen, ~ifelse(is.na(.), 0, .)),
                                 invloed=case_when(weight2 >= 0.7 ~ 3,
                                                   weight2< .7 & n_zinnen>=1 ~ 2,
                                                   (weight2>.3 | weight>.3) & weight2< .7 & n_zinnen<1 ~ 1,
                                                   T ~ 0))%>%
  mutate(pb_id=as.numeric(pb_id))

data = invloed%>%group_by(id)%>%arrange(-invloed, -weight2, -n_zinnen) %>% mutate(n_pb=n()) %>% slice_head(n=1)

saveRDS(data, "data/anp_data_juli2021.rds")

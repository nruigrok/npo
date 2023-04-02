library(tidyverse)
library(amcatr)
library(quanteda)
library(corpustools)
library(tokenbrowser)

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
total=nieuws

#ophalen tokens gemaakt via pythonscript tokenizer.py

pb_tokens = read_csv("data/tokens_stanza_persb.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_stanza_nieuws.csv")%>%as_tibble()


#maken DTM's
pb_dfm = pb_tokens %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta=tibble(id=quanteda::docid(pb_dfm))%>%mutate(id=as.numeric(as.character(id)))
pb_meta = pb_meta%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm)=pb_meta


npo_dfm = npo_tokens %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta=tibble(id=quanteda::docid(npo_dfm))%>%mutate(id=as.numeric(as.character(id)))
npo_meta = npo_meta%>%left_join(nieuws)%>%select(-text, -medium)%>%mutate(date=as.POSIXct(date))
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

total_pn=total%>%left_join(e_pn)%>%mutate(medium=ifelse(is.na(medium),"EenVandaag", medium), publisher=ifelse(is.na(publisher),"EenVandaag", publisher))

tot3=total2%>%left_join(total_pn)


#################### ZINNEN OVERLAP ###############

pb_tokens = read_csv("data/tokens_stanza_persb.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_stanza_nieuws.csv")%>%as_tibble()


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
npo_meta_3 = npo_meta_3%>%left_join(nieuws) %>% select(-text, -medium)
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
npo_meta_10 = npo_meta_10%>%left_join(nieuws) %>% select(-text, -medium)
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

tokens_npo= npo_tokens%>%filter(doc_id %in% overlap$id)%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))

tokens_npo = npo_tokens %>% inner_join(overlap %>% rename(doc_id=id))%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id, pb_id) %>% mutate(ngram=str_c(pb_id, ": ", ngram(tolower(token), n=10))) %>% arrange(doc_id, pb_id, sentence_id, token_id)

tokens_pb=pb_tokens%>%filter(doc_id %in% overlap$pb_id)%>%filter(upos!="PUNCT") %>% 
  group_by(doc_id) %>% mutate(ngram=str_c(doc_id, ": ", ngram(tolower(token), n=10)))

tokens_npo = tokens_npo %>% mutate(value = as.numeric(!is.na(ngram) & ngram %in% tokens_pb$ngram))
tokens_npo = tokens_npo %>% mutate(value2 = sum_value(value, n=10)) 

weight_zin = tokens_npo%>%group_by(doc_id, pb_id)%>%summarise(n_woorden=sum(value2))%>%mutate(n_zinnen = n_woorden/10)%>%rename(id=doc_id)
weight_zin


tot5 = tot4%>%left_join(weight_zin)

saveRDS(tot5,"stanza_model_10.rds")



#####selectie om hightlight te kunnen zien

saveRDS(tokens_npo,"tokens_npo.rds")
saveRDS(tokens_pb,"tokens_pb.rds")

tokens_npo=tokens_npo%>%mutate(pb_id=as.numeric(pb_id))

persb_id = 23696918
meta = bind_rows(
  tot5 %>% filter(pb_id == persb_id) %>% mutate(doc_id = paste("artikel", id)) %>% select(doc_id, publisher, date, title, weight, weight2, weight_pn,weight2_pn, n_ngram,n_zinnen ),
  pb_meta %>% filter(id == persb_id) %>% mutate(doc_id=paste("persbericht", id)) %>% select(doc_id, publisher, date, title)
)

pb = tokens_npo%>%filter(pb_id==persb_id)%>%mutate(doc_id=paste("artikel", doc_id))
tokens_persb = tokens_pb%>%filter(doc_id==persb_id)%>%mutate(doc_id=paste("persbericht", doc_id),value=as.numeric(! is.na(ngram) & ngram %in% pb$ngram), value2=sum_value(value,n=10))
br=bind_rows(tokens_persb,pb)

highlighted_browser(br, value=br$value2 > 0, meta=meta) %>% view_browser()
view(br)



pbid = 23696918
artid = 23852089

pblemma = pb_tokens %>% filter(doc_id == pbid, upos == "PROPN") %>% pull(lemma)
artlemma = npo_tokens %>% filter(doc_id == artid, upos == "PROPN") %>% pull(lemma)

intersect(artlemma, pblemma) 
sum(pblemma %in% artlemma) / length(pblemma)
sum(artlemma %in% pblemma) / length(artlemma)
length(intersect(artlemma, pblemma)) / length(artlemma)




pb_tokens = read_csv("data/tokens_stanza_persb.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_stanza_nieuws.csv")%>%as_tibble()

pbid = 23683188
artid = 2769871

tokens_pb2 = pb_tokens%>%filter(doc_id==pbid)
tokens_npo2 = npo_tokens%>%filter(doc_id==artid)

meta = bind_rows(
  tot5 %>% filter(pb_id == pbid) %>% mutate(doc_id = paste("artikel", id)) %>% select(doc_id, publisher, date, title, weight, weight2, weight_pn,weight2_pn, n_ngram,n_zinnen ),
  pb_meta %>% filter(id == pbid) %>% mutate(doc_id=paste("persbericht", id)) %>% select(doc_id, publisher, date, title)
)


tokens_combined=bind_rows(tokens_pb2%>% mutate(value=as.numeric(token %in% tokens_npo2$token),
                                               doc_id=paste("persbericht", doc_id)),
                          tokens_npo2%>% mutate(value=as.numeric(token %in% tokens_pb2$token),
                                                doc_id=paste("artikel", doc_id)))


highlighted_browser(tokens_combined, value=tokens_combined$value > 0, meta=meta) %>% view_browser()


tokens_pb2 = pb_tokens%>%filter(doc_id=="23696918")
tokens_npo2 = npo_tokens%>%filter(doc_id %in%  ("23852089"))
view(tokens_npo2)
view(tokens_pb2)


dup = tot5%>%group_by(id)%>%top_n(1, weight)     

filter(weight2<.3, weight<.3)

tot5%>%filter(id %in% dup$id)%>%mutate(kopie=ifelse(weight2>.1 & weight2<.2,1,0))%>%filter(kopie==1)%>%select(id,pb_id)%>%unique()%>%sample_n(20)

tot5%>%filter(id %in% dup$id)%>%mutate(kopie=ifelse((n_ngram3>10 & n_zinnen<1.5 & weight2<.4),1,0))%>%filter(kopie==1)%>%select(id,pb_id)%>%arrange(id)

tot5%>%filter(id %in% dup$id)%>%mutate(kopie=ifelse(n_zinnen>10,1,0))%>%filter(kopie==1)%>%select(id,pb_id)%>%arrange(id)


duplicaten = tot5%>%filter(id %in% dup$id)%>%mutate(kopie=ifelse(weight2 >.7,1,0))%>%
  mutate(kopie = ifelse(is.na(kopie),0,kopie))%>%
  group_by(medium,kopie)%>%summarise(n=n())%>%mutate(perc=n/sum(n)*100)%>%filter(kopie==1)
duplicaten


ggplot(data=duplicaten, aes(x=reorder(medium, -n),y=perc, fill=medium)) +
  geom_bar(stat="identity", position="dodge", show.legend = FALSE)+
  geom_text(aes(label=paste0(n,";",round(perc,1))), vjust=-.1, cex=3)+
  labs(x="Medium", y="Percentage overlap")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size=9),axis.title=element_text(size=10,face="italic"))


invloed = tot5%>%filter(id %in% dup$id)%>%mutate(kopie=ifelse(weight >.4 | weight2>.4,1,0))%>%
  mutate(kopie = ifelse(is.na(kopie),0,kopie))%>%
  group_by(medium,kopie)%>%summarise(n=n())%>%mutate(perc=n/sum(n)*100)
invloed




zinnen= tot5%>%filter(id %in% dup$id)%>%mutate(kopie=ifelse(n_zinnen >=1.5,1,0))%>%
  mutate(kopie = ifelse(is.na(kopie),0,kopie))%>%
  group_by(medium,kopie)%>%summarise(n=n())%>%mutate(perc=n/sum(n)*100)%>%filter(kopie==1)
zinnen

ggplot(data=zinnen, aes(x=reorder(medium, -perc),y=perc, fill=medium)) +
  geom_bar(stat="identity", position="dodge", show.legend = FALSE)+
  geom_text(aes(label=paste0(n,";",round(perc,1))), vjust=-.1, cex=3)+
  labs(x="Medium", y="Percentage overlap")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size=9),axis.title=element_text(size=10,face="italic"))



op1=tot5%>%filter(medium=="Op1")%>%view()
ev=tot5%>%filter(medium=="EenVandaag")%>%view()
nieuwsuur=tot5%>%filter(medium=="Nieuwsuur")%>%view()


####Analyses

#aantal berichten
table(tot5$publisher)
npersb = %>%distinct(pb_id)
nnieuws = tot5%>%distinct(id, .keep_all = T)%>%select(id,publisher,week)


dup = tot5%>%group_by(id)%>%top_n(1, weight)     
dup_pb = tot5%>%group_by(pb_id, medium)%>%top_n(1, weight2)     


invloed = tot5%>%filter(id %in% dup_pb$id)%>%dplyr::mutate(invloed=case_when(weight2 >= 0.7 ~ "kopie",
                                                                   weight2< .7 & n_zinnen>=1 ~ "deels overgenomen",
                                                                   weight2>.3 | weight>.3 & weight2< .7 & n_zinnen<1 ~ "zelfde event"))%>%
  filter(! is.na(invloed))%>%
  group_by(medium,invloed)%>%summarise(n=n())%>%mutate(perc=n/sum(n)*100)

View(invloed)
table(invloed$invloed)
invloed


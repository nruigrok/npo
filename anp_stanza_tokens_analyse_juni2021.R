library(tidyverse)
library(amcatr)
library(quanteda)
library(corpustools)
library(tokenbrowser)



conn = amcat.connect('https://vu.amcat.nl')
pers = amcat.getarticlemeta(conn, project=78, articleset = 3689, dateparts=T,time=T, columns = c("publisher", "date","title", "text", "section", "author"))
pers$medium = 'Persberichten'
pb_date=pers%>%select(id,date)%>%rename(doc_id=id)


nieuws = amcat.getarticlemeta(conn, project=78, articleset = 3695, dateparts=T,time=T, columns = c("publisher", "date","title", "text", "section", "source", "author"))%>%
  mutate(publisher = ifelse(is.na(publisher),"EenVandaag", publisher))


ondert = amcat.getarticlemeta(conn, project=78, articleset = 3692, dateparts=T,time=T, columns = c("publisher", "date","title", "text","omroep"))%>%
  mutate(publisher = case_when(publisher == "EenVandaag" ~ paste0(publisher,"_sub"),
                               publisher == "Op1" ~ paste0(publisher,"_sub"),
                               T ~ publisher))
table(ondert$publisher)
nieuws = nieuws%>%mutate(date=case_when(publisher == "EenVandaag" ~ date + lubridate::dhours(18),
                                        publisher == "Op1" ~ date + lubridate::dhours(22),
                                        T ~ date), publisher = ifelse(publisher=="teletekst","Teletekst",publisher))

nieuwstot=nieuws%>%bind_rows(ondert)%>%mutate(medium=publisher)
table(nieuwstot$medium)
total=nieuwstot%>%filter(date>"2020-01-01")


#ophalen tokens gemaakt via pythonscript tokenizer.py

pb_tokens = read_csv("data/tokens_pers_stanza2.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_nieuws_stanza2.csv")%>%as_tibble()


#maken DTM's
pb_dfm = pb_tokens %>% with(split(lemma, doc_id, date)) %>% as.tokens() %>% dfm()
pb_meta=tibble(id=quanteda::docid(pb_dfm))%>%mutate(id=as.numeric(as.character(id)))
pb_meta = pb_meta%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm)=pb_meta


npo_dfm = npo_tokens %>% with(split(lemma, doc_id)) %>% as.tokens() %>% dfm()
npo_meta=tibble(id=quanteda::docid(npo_dfm))%>%mutate(id=as.numeric(as.character(id)))
npo_meta = npo_meta%>%left_join(nieuwstot)%>%select(-text, -medium)%>%mutate(date=as.POSIXct(date))
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
pb_meta_10 = pb_meta_10%>%left_join(pers)%>%select(-text)%>%mutate(date=as.POSIXct(date))
docvars(pb_dfm_10)=pb_meta_10

npo_dfm_10 = npo_tokens_10 %>% with(split(ngram, doc_id)) %>% as.tokens() %>% dfm()
npo_meta_10 = tibble(id=quanteda::docid(npo_dfm_10)) %>% mutate(id=as.numeric(as.character(id)))
npo_meta_10 = npo_meta_10%>%left_join(nieuwstot) %>% select(-text)
docvars(npo_dfm_10)=npo_meta_10

#comparison
g_pb_10 = RNewsflow::newsflow_compare(pb_dfm_10, npo_dfm_10, date='date', 
                                      min_similarity = 0.0,       ## similarity threshold
                                      hour_window = c(0, 1*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                      measure = 'overlap',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                      tf_idf=F)                   ## weeg woorden die minder vaak voorkomen zwaarder mee


e_pb_10 = igraph::as_data_frame(g_pb_10)%>%rename(id=to)%>%mutate(id=as.numeric(id))%>%select(-hourdiff)%>%rename(n_ngram=weight)

e_tot = e%>%full_join(e_pb_10)


tot4=total%>%left_join(e_tot)%>%mutate(medium=ifelse(is.na(medium),"EenVandaag", medium), publisher=ifelse(is.na(publisher),"EenVandaag", publisher))
table(is.na(tot4$id))
tot4%>%select(from,id)%>%unique()%>%nrow()

saveRDS(tot4, "data/npo_juni2021.rds")

head(tot4)
tot4=readRDS("data/npo_juni2021.rds")

overlap = tot4%>%filter(! is.na(n_ngram))

saveRDS(overlap, "data/overlap_anp_npo.rds")

overlap=readRDS("data/overlap_anp_npo.rds")%>%rename(pb_id=from)%>%mutate(pb_id=as.numeric(pb_id))
pb_tokens = read_csv("data/tokens_pers_stanza2.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_nieuws_stanza2.csv")%>%as_tibble()

head(overlap)
head(pb_tokens)
head(npo_tokens)
library(openssl)


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


######Berekening van het aantal zinnen dat de ngrams uiteindelijk overlappen


npo_ngrams = npo_tokens %>%filter(upos!="PUNCT", doc_id %in% overlap$id)%>%
  group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))

pb_ngrams = pb_tokens %>% filter(upos!="PUNCT", doc_id %in% overlap$pb_id)%>% 
  group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))

npo_ngrams = npo_ngrams %>% mutate(hash=md5(ngram))
pb_ngrams = pb_ngrams %>% mutate(hash=md5(ngram))

overlap_hashes = intersect(npo_ngrams$hash, pb_ngrams$hash)

class(pb_ngrams$hash)

npo_ngrams2 = npo_ngrams %>% filter(!is.na(ngram)) %>% select(doc_id, ngram, hash) %>% filter(hash %in% overlap_hashes)
pb_ngrams2 = pb_ngrams %>% filter(!is.na(ngram)) %>% select(doc_id, ngram, hash) %>% filter(hash %in% overlap_hashes)

overlap2=overlap%>%rename(doc_id=id)%>%select(doc_id, pb_id)
npo_grams3 = npo_ngrams2 %>% inner_join(overlap2) %>% mutate(ngram=str_c(pb_id, ":", ngram))
pb_grams3 = pb_ngrams2 %>% mutate(ngram=str_c(doc_id, ":", ngram))

npo_ngrams4 = npo_grams3 %>% mutate(value = as.numeric(ngram %in% pb_grams3$ngram)) 
npo_ngrams5 = npo_ngrams4 %>% filter(value==1) %>% select(doc_id, pb_id, hash, value)
overlap2
overlap3 = npo_ngrams5 %>% select(doc_id, pb_id) %>% unique()


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


pb_tokens = read_csv("data/tokens_pers_stanza2.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_nieuws_stanza2.csv")%>%as_tibble()

pbid = 41518732
artid = 34926567

tokens_pb2 = pb_tokens%>%filter(doc_id==pbid)
tokens_npo2 = npo_tokens%>%filter(doc_id==artid)

meta = bind_rows(
  tot5 %>% filter(pb_id == pbid) %>% mutate(doc_id = paste("artikel", id)) %>% select(doc_id, publisher, date, title, weight, weight2, n_ngram,n_zinnen ),
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


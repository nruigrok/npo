# remotes::install_github("nruigrok/tokenbrowser", force=T)
library(tokenbrowser)
library(tidyverse)
#library("spacyr")
library(amcatr)
library(corpustools)
#spacy_initialize(model = "nl_core_news_sm")
#spacy_download_langmodel("nl")


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

#' 1 if token occurs in tokens for another group
overlap = function(tokens, groups) {
  values = rep(0, length(tokens))
  for (current in groups) {
    values[!is.na(tokens) & groups == current & tokens %in% tokens[groups != current]] = 1
  }
  values
}



#####selectie om hightlight te kunnen zien
conn = amcat.connect('https://vu.amcat.nl')
pers = amcat.getarticlemeta(conn, project=78, articleset = 3311, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
pers$medium = 'Persberichten'
tot5=readRDS("stanza_model.rds")

pb_tokens = read_csv("data/tokens_stanza_persb.csv")%>%as_tibble()
npo_tokens = read_csv("data/tokens_stanza_nieuws.csv")%>%as_tibble()

persb_id=23691803
art_ids = tot5 %>% filter(pb_id == persb_id) %>% pull(id)

meta = bind_rows(
  pers %>% filter(id == persb_id) %>% mutate(doc_id=paste("persbericht", id)) %>% select(doc_id, publisher, date, title),
  tot5 %>% filter(pb_id == persb_id) %>% mutate(doc_id = paste("artikel", id)) %>% select(doc_id, publisher, date, title, weight, weight2, weight_pn,weight2_pn, n_ngram3,n_zinnen )
)

tokens = bind_rows(
  pb_tokens %>% filter(doc_id == persb_id) %>% mutate(doc_id=paste("persbericht", doc_id), pb=T),
  npo_tokens %>% filter(doc_id %in% art_ids) %>% mutate(doc_id=paste("artikel", doc_id), pb=F)
) %>% filter(upos !="PUNCT") %>% 
  group_by(doc_id) %>% 
  filter(n() >= 10) %>% 
  mutate(ngram3=ngram(tolower(token), n=3),
         ngram10=ngram(tolower(token), n=10)) %>%
  ungroup() %>% 
  mutate(value1=ifelse(tolower(token) %in% stopwords::stopwords('dutch', source = 'stopwords-iso'),0,overlap(tolower(token), pb)),
         value3=overlap(ngram3, pb),
         value10=overlap(ngram10, pb),
         value3b = sum_value(value3, n=3),
         value10b = sum_value(value10, n=10),
         values = case_when(value10b == 1 ~ "ngram10",
                            value3b == 1 ~ "ngram3",
                            value1 == 1  ~ "ngram1"))
categorical_browser(tokens, category = tokens$values, meta=meta, drop.missing.meta=T)%>%view_browser()
create_browser

View(br)
###TOKENS
pbid = 23700296
artid = 3287358

tokens_pb2 = tokens_pb%>%filter(doc_id==pbid)
tokens_npo2 = tokens_npo%>%filter(doc_id==artid)

tokens_combined=bind_rows(tokens_pb2%>% mutate(value=as.numeric(token %in% tokens_npo2$token),
                                               doc_id=paste("persbericht", doc_id)),
                          tokens_npo2%>% mutate(value=as.numeric(token %in% tokens_pb2$token),
                                                doc_id=paste("artikel", doc_id)))

highlighted_browser(tokens_combined, value=tokens_combined$value > 0) %>% view_browser()


pblemma = pb_tokens %>% filter(doc_id == pbid, upos == "PROPN") %>% pull(lemma)
artlemma = npo_tokens %>% filter(doc_id == artid, upos == "PROPN") %>% pull(lemma)

intersect(artlemma, pblemma) 
sum(pblemma %in% artlemma) / length(pblemma)
sum(artlemma %in% pblemma) / length(artlemma)
length(intersect(artlemma, pblemma)) / length(artlemma)




tokens_pb2 = pb_tokens%>%filter(doc_id=="23696918")
tokens_npo2 = npo_tokens%>%filter(doc_id %in%  ("23852089"))
view(tokens_npo2)
view(tokens_pb2)

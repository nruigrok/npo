remotes::install_github("kasperwelbers/tokenbrowser", force=T)
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



create_comparison = function(tokens, meta, pb_id, art_ids, ...) {
  m = meta %>% 
    filter(doc_id %in% c(pb_id, art_ids)) %>% 
    mutate(doc_id=str_c(ifelse(anp, "ANP Bericht ", "NPO Item "), doc_id)) %>%
    select(-anp)
  t = tokens %>% filter(doc_id %in% c(pb_id, art_ids),
                    upos != "PUNCT") %>% 
    group_by(doc_id) %>% 
    filter(n() >= 10) %>% 
    mutate(anp=doc_id %in% pb_id,
           doc_id=str_c(ifelse(anp, "ANP Bericht ", "NPO Item "), doc_id),
           ngram3=ngram(tolower(token), n=3),
           ngram10=ngram(tolower(token), n=10)) %>%
    ungroup() %>% 
    mutate(value1=ifelse(tolower(token) %in% stopwords::stopwords('dutch', source = 'stopwords-iso'),0,overlap(tolower(token), anp)),
           value3=overlap(ngram3, anp),
           value10=overlap(ngram10, anp),
           value3b = sum_value(value3, n=3),
           value10b = sum_value(value10, n=10),
           values = case_when(value10b == 1 ~ "ngram10",
                              value3b == 1 ~ "ngram3",
                              value1 == 1  ~ "ngram1"))
  categorical_browser(t, category = t$values, meta=m, drop_missing_meta=T ,...) 
}

create_multiple_comparisons(tokens, meta, pb_ids, art_ids) {
  if (length(pb_ids) != length(art_ids)) stop("pb_ids and art_ids should be the same length")
  for (i in seq_along(pb_ids)) {
    
  }
  
}


#####selectie om hightlight te kunnen zien
conn = amcat.connect('https://vu.amcat.nl')
pers = amcat.getarticlemeta(conn, project=78, articleset = 3311, dateparts=T,time=T, columns = c("publisher", "date","title", "text"))
pers$medium = 'Persberichten'
tot5=readRDS("stanza_model.rds")

tokens = bind_rows(
  read_csv("data/tokens_stanza_persb.csv"),
  read_csv("data/tokens_stanza_nieuws.csv")
)


meta = bind_rows(
  pers %>% select(doc_id=id, publisher, date, title) %>% add_column(anp=T),
  tot5 %>% select(doc_id=id, publisher, date, title, weight, weight2, weight_pn,weight2_pn, n_ngram3, n_zinnen ) %>% add_column(anp=F)
)

pb_id=23703888
art_id=23854074
create_comparison(tokens, meta, pb_id, art_id) %>% view_browser()

artikelen = read_csv("~/Downloads/ANP criteria - Sheet1.csv")
for(i in seq_along(artikelen$art)) {
  pb_id = artikelen$persb[i]
  art_id = artikelen$art[i]
  fn = glue::glue("/tmp/out/{pb_id}_{art_id}.html")
  message(glue::glue("{i}/{nrow(artikelen)}: {fn}"))
  create_comparison(tokens, meta, pb_id, art_id,filename=fn)
}


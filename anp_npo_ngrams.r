
library(tidyverse)
library(amcatr)
library(corpustools)
library(tokenbrowser)

library(zoo)


tc = readRDS("data/anp_npo_tccorpus.rds")

meta=tc$meta%>%as_tibble()
pb_ids=meta%>%filter(medium=="Persberichten")
npo_ids=meta%>%filter(medium!="Persberichten")

tokens=tc$tokens%>%as_tibble()



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


tokens_pb2 = tokens%>%filter(doc_id=="23700551")
tokens_npo2 = tokens%>%filter(doc_id %in%  ("23853067"))

tokens_combined=bind_rows(tokens_pb2%>% mutate(value=as.numeric(token %in% tokens_npo2$token),
                                               doc_id=paste("persbericht", doc_id)),
                          tokens_npo2%>% mutate(value=as.numeric(token %in% tokens_pb2$token),
                                               doc_id=paste("artikel", doc_id)))
                          
highlighted_browser(tokens_combined, value=tokens_combined$value > 0) %>% view_browser()


tokens_pb = tokens%>%filter(doc_id=="23666073")
tokens_npo = tokens%>%filter(doc_id %in%  ("16824682"))


tokens_npo2= tokens_npo%>%filter(pos!="PUNCT") %>% group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))%>%mutate(doc_id=as.numeric(doc_id))
tokens_pb2= tokens_pb%>%filter(pos!="PUNCT") %>%  group_by(doc_id) %>% mutate(ngram=ngram(tolower(token), n=10))%>%mutate(doc_id=as.numeric(doc_id))

tokens_combined = bind_rows(
  tokens_pb2 %>% mutate(value10=as.numeric(!is.na(ngram) & ngram %in% tokens_npo2$ngram),
                        doc_id=paste("persbericht", doc_id)),
  tokens_npo2 %>% mutate(value10=as.numeric(!is.na(ngram) & ngram %in% tokens_pb2$ngram)))


#mutate(value3a=sum_value(value3,3), value10a=sum_value(value10,10), value10b=rollmax(value10, k=10, na.pad=T, align="left"))

tokens_combined %>% select(doc_id, token, ngram, trigram, value3:value10b) %>% View()

tokens_combined2 = tokens_combined%>%group_by(doc_id,sentence)%>%summarise(mean3=mean(value3),mean10=mean(value10))


view(tokens_combined)
table(tokens_combined2$rol_avg10)

highlighted_browser(tokens_combined, value=tokens_combined$value > 0) %>% view_browser()

highlighted_browser(tokens_combined, value=tokens_combined$value2 > 0) %>% view_browser()
categorical_browser(tokens_combined, category = case_when(tokens_combined$value10==1 ~ "10gram", tokens_combined$value3==1 ~ "trigram", T~NA_character_)) %>% view_browser()
tokenbrowser::colorscaled_browser(tokens_combined, value=scales::rescale(tokens_combined$value2, to = c(-1,1)), col_range=c("white", "yellow")) %>% view_browser()
tokenbrowser::colorscaled_browser(tokens_combined, alpha=scales::rescale(tokens_combined$value2), value=1) %>% view_browser()


table(tokens3$value)


tc$tokens
url = tokenbrowser::categorical_browser(tokens2, category=case_when(tokens2$POS %in% c("NOUN", "PROPN", "ADJ") ~ tokens2$POS))
url = tokenbrowser::highlighted_browser(tokens3, value=tokens3$value=="TRUE")

url = tokenbrowser::colorscaled_browser(tokens2, value=str_length(tokens2$token)/10)
url = tokenbrowser::create_browser(tokens2)
tokenbrowser::view_browser(url)


x = c("Obama","Bush")
add_tag(x,'span')## add attributes with the tag_attr function
add_tag(x,'span',
        tag_attr(class = "president"))## add style attributes with the attr_style function within tag_attr
add_tag(x,'span',
        tag_attr(class = "president",style = attr_style(`background-color`='rgba(255, 255, 0, 1)')))


library(tidyverse)
library(quanteda)

d = read_csv("data/op1_subtitles.csv") %>% 
  mutate(doc_id=seq_along(id),
  date = as.Date(date, format="%d-%m-%Y"),
  month = lubridate::month(date) + 12*(lubridate::year(date) - 2020),
  period = case_when(date<"2020-03-01" ~ "pre corona",
                     date<="2020-07-01" ~ "1e golf",
                     date<"2020-10-01" ~ "zomer",
                     T ~ "2e golf"))
  
segments = read_csv("data/op1_descriptions.csv") %>% 
  mutate(segment_id=seq_along(id), 
         item_tot = item_tot + item_start) %>% 
  filter(!is.na(topic))

# corrigeer voor segmenten die geheel of deels binnen een ander segment vallen (bv %>% filter(id=="urn:vme:default:program:2102003230266010231"))
segments = segments %>% 
  mutate(lag_tot = ifelse(id == lag(id), lag(item_tot), NA)) %>% 
  filter(is.na(lag_tot) | item_tot >= lag_tot) %>%  mutate(item_start = pmax(item_start, lag_tot)) 

subseg = inner_join(d %>% select(id, doc_id, sub_start),
                    segments %>% select(id, segment_id, item_start, item_tot)) %>% 
  filter(sub_start >= item_start, sub_start < item_tot) %>% 
  select(doc_id, segment_id)

d = d %>% left_join(subseg) %>% left_join(segments %>% select(segment_id, covid))
clean <- function(x) {
  x = str_replace_all(x, '\\\\n', ' ') 
  x = str_replace_all(x, '\\s+', ' ')
  x = str_replace_all(x, '[^ \\p{LETTER}\\p{DIGIT},\\.]', ' ')
  x
}

library(udpipe)
d = d %>% mutate(text = clean(text))
tokens = udpipe(d, "dutch", parallel.cores=6)
saveRDS(tokens, "data/tokens.rds")
head(tokens)
clean(d$text[4])
table(tokens$upos)

tokens = readRDS("data/tokens.rds")
tokens = tokens%>%filter(upos %in% c("NOUN","PROPN"))
head(tokens)

dfm = split(tokens$lemma, tokens$doc_id) %>% as.tokens() %>% dfm()
order = match(docid(dfm), d$doc_id)  
docvars(dfm) = d %>% select(-doc_id, -text) %>% mutate(covid=ifelse(is.na(covid),0,covid)) %>% slice(order)
head(docvars(dfm))


dfm=dfm_trim(dfm,docfreq_type = c("prop"),max_docfreq = .4, min_termfreq = 15, min_docfreq = .002)


viros = dfm_subset(dfm, speaker %in% c("Osterhaus, Ab", "Gommers, Diederik", "Kuipers, Ernst"))

viros = dfm_subset(dfm)
key = textstat_keyness(viros, target=docvars(viros)$covid == 1)

key %>% as_tibble()  %>% slice_max(abs(chi2), n=100) %>% mutate(y=runif(100)) %>% 
  ggplot() + ggrepel::geom_text_repel(aes(x=chi2, y=y, label=feature, color=chi2, size=(n_target+n_reference)), segment.color = NA) +
scale_size_continuous(range=c(1, 10)) +  
  theme_minimal() + ylab("")  + 
  guides(size=FALSE, colour=FALSE) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.text.y = element_blank(), panel.grid = element_blank()) 

textplot_keyness(key)
textplot_wordcloud(dtm, max_words=100)

# typical words per period
data = list()
for (month in unique(docvars(dfm)$month)) {
  message(month)
  d = textstat_keyness(dfm, target = docvars(dfm)$month == month) %>% as_tibble() 
  data[[as.character(month)]] = d
}
keys = bind_rows(data, .id="month") %>% mutate(rand=runif(length(month)),
                                               month = as.numeric(month),
                                               n = n_target + n_reference)

keys %>% filter(month == 13) %>% arrange(-chi2)

keys %>% slice_max(chi2, n=200) %>%   
  ggplot() + ggrepel::geom_text_repel(aes(x=month, y=rand, label=feature, color=chi2, size=chi2), segment.color = NA) +
  scale_size_continuous(range=c(1, 10)) +  
  theme_minimal() + ylab("")  + 
  guides(size=FALSE, colour=FALSE) +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.text.y = element_blank(), panel.grid = element_blank()) 


library(stm)
m = stm(documents=dtm, K=20, seed=1, prevalence = ~period )


saveRDS(m, "data/topicmodel_op1.rds")

stm::labelTopics(m)
sageLabels(m)


tpd = m$theta
#colnames(tpd) = paste0("topic_", 1:50)
rownames(tpd) = rownames(dtm)
tpd

library(tidyverse)
tpd2 =tpd %>% as_tibble(rownames = "id") %>% pivot_longer(-id, names_to="topic", values_to="loading")

tpd3=tpd2 %>% group_by(topic)%>%arrange(-loading)%>%filter(topic=="V20")
View(head(tpd3,100))
tail(tpd3,40)


prep <- estimateEffect(1:20 ~ period, stmobj = m, meta = quanteda::docvars(dtm))
summary(prep)

## optionally, compute word assignments and add to tcorpus for visualization



head(m$theta)
x = m$theta
head(x)

rownames(x) = rownames(dtm)
x30=as.data.frame(x)
head(x30)
x30$id = rownames(x30)

x30=x30%>%select(id,  V1: V20)%>%gather(key="topic", value="nfreq", -id)%>%
  mutate(nfreq=ifelse(is.na(nfreq),0,as.numeric(nfreq)))%>%mutate(topic=as.numeric(gsub("V","", topic)))%>%as_tibble()


topics = read_csv("data/topics_dtv.csv")


total=merge(x30,topics)%>%mutate(id=as.numeric(id))%>%as_tibble()
head(total)
table(total$id %in% meta$id)



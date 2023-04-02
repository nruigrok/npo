install.packages("googlesheets4")
library(tidyverse)
library(googlesheets4)
d =read_sheet("https://docs.google.com/spreadsheets/d/19St3NM2B_1FP76B4ItYaTOxs0R5oPF8VjeOCHhk7DeY/edit#gid=0") %>% 
  rename(kopie="(Bijna) \nvolledige kopie", 
         deels="Deels \novergenomen", 
         event="Zelfde event", 
         geen="Weinig/geen\n overlap",
         id=art, 
         pb_id=persb)

d2 = d %>% #select(criterium, art, persb, comments, kopie:geen) %>% 
  pivot_longer(kopie:geen, names_to="category") %>% 
  mutate(category=factor(category, levels=c("kopie", "deels", "event", "geen"))) %>%
  filter(!is.na(value)) %>%
  select(-value)

d2 %>% 
  group_by(criterium, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=criterium, x=category, label=n, fill=p))+ geom_tile() + geom_text()

tot5=readRDS("stanza_model.rds") %>% select(id, pb_id, weight:n_zinnen) %>% mutate(pb_id=as.numeric(pb_id))
tot5=tot5%>%mutate(pb_id=as.numeric(pb_id))
head(tot5)
d3 = left_join(d2, tot5) %>% mutate(across(weight:n_zinnen, ~ifelse(is.na(.), 0, .)))
rounddown = function(x) floor(x*10)/10

d4=d3 %>% filter(n_ngram3>10) %>% with(table(category)) # volledig overgeschreven

d3 %>% filter(weight2>=.7) %>% with(table(category)) # volledig overgeschreven
d3 %>% filter(weight2<.7, n_zinnen>=1) %>% with(table(category)) # deels 
d3 %>% filter(weight2<.7, n_zinnen<1, weight2>=.3 | weight >= .3) %>% with(table(category)) # event
d4 = d3 %>% filter(weight2<.7, n_zinnen<1, weight2<.3, weight<.3)
d4 %>% filter(weight2<=.1) %>% with(table(category)) # event
d4 %>% filter(weight<=.1) %>% with(table(category)) # event
d4 %>% filter(weight_pn>.2) %>% with(table(category)) # event
d4 %>% filter(weight2_pn>.2) %>% with(table(category)) # event

table(d4$category)

d4 %>% mutate(w=rounddown(weight)) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text() + ggtitle("Weight") + 
  scale_y_continuous(n.breaks = 10)

d4 %>% mutate(w=rounddown(weight2)) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text()+ ggtitle("weight2")+ 
  scale_y_continuous(n.breaks = 10)

d4 %>% mutate(w=rounddown(weight_pn)) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text()+ ggtitle("weight_pn")+ 
  scale_y_continuous(n.breaks = 10)

d4 %>% mutate(w=rounddown(weight2_pn)) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text()+ ggtitle("weight2_pn")+ 
  scale_y_continuous(n.breaks = 10)

d4 %>% mutate(w=rounddown(pmin(3, n_zinnen))) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text()+ ggtitle("n_zinnen (3=3+)")+ 
  scale_y_continuous(n.breaks = 10)


d4 %>% mutate(w=n_ngram3) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text()+ ggtitle("n_ngram3 (3=3+)")+ 
  scale_y_continuous(n.breaks = 10)

d3 %>% filter(weight2<.3, weight<.3) %>% arrange(category)%>% mutate(w=rounddown(weight2_pn)) %>% 
  group_by(w, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=w, x=category, label=n, fill=p))+ geom_tile() + geom_text()+ ggtitle("weight_pn")+ 
  scale_y_continuous(n.breaks = 10)

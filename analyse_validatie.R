install.packages("googlesheets4")
library(tidyverse)
library(googlesheets4)
d =read_sheet("https://docs.google.com/spreadsheets/d/19St3NM2B_1FP76B4ItYaTOxs0R5oPF8VjeOCHhk7DeY/edit#gid=0") %>% 
  rename(kopie="(Bijna) \nvolledige kopie", 
         deels="Deels \novergenomen", 
         event="Zelfde event", 
         geen="Weinig/geen\n overlap")

d2 = d %>% #select(criterium, art, persb, comments, kopie:geen) %>% 
  pivot_longer(kopie:geen, names_to="category") %>% 
  mutate(category=factor(category, levels=c("kopie", "deels", "event", "geen"))) %>%
  filter(!is.na(value)) %>%
  select(-value)

d2 %>% 
  group_by(criterium, category) %>% 
  summarize(n=n()) %>% mutate(p=n/sum(n)) %>%
  ggplot(aes(y=criterium, x=category, label=n, fill=p))+ geom_tile() + geom_text()


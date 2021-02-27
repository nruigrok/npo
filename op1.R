library(tidyverse)
library(glue)

###SITE
op1gasten = read_csv('data/op1_sitegasten.csv')
head(op1gasten)
op1g = op1gasten%>%pivot_longer(gast:gast11,names_to="gast", values_to = "naam")%>%filter(! is.na(naam))%>%
  mutate(naam=sub("\\.","", naam))

gastentot=read_csv("data/gasten_op1_categorie.csv")

gasten = op1g %>% left_join(gastentot)%>%mutate(date=as.Date(date, "%d-%m-%Y"))

gasten= gasten %>% mutate(period = case_when(
  date < "2020-03-01" ~ "pre-corona", 
  date < "2020-07-01" ~ "eerste golf",
  date < "2020-10-01" ~ "zomer",
  T ~ "tweede golf"),
  period = fct_reorder(period, date)) 

table(gasten$period)

check5=gasten%>%filter(period=="pre-corona" & categorie=="medisch")
View(check5)

gasten %>% filter(! is.na(categorie)) %>% 
  group_by(period, categorie) %>% summarize(t=n()) %>% mutate(total=sum(t)) %>% 
  slice_max(t, n=5)  %>% mutate(n=row_number()) %>% 
  mutate(perc=round(t/total*100, 1), speaker=glue("{categorie} ({perc}%)")) %>%
  select(period, categorie, n) %>% pivot_wider(names_from=period, values_from=categorie)



gasten %>% filter(! is.na(categorie)) %>% 
  group_by(period, naam) %>% summarize(t=n()) %>% mutate(total=sum(t)) %>% 
  slice_max(t, n=5)  %>% mutate(n=row_number()) %>% 
  mutate(perc=round(t/total*100, 1), speaker=glue("{naam} ({t})")) %>%
  select(period, speaker, n) %>% pivot_wider(names_from=period, values_from=speaker)

ranks = gasten  %>% group_by(naam) %>% summarize(n=n()) %>% arrange(-n) %>% mutate(rank=row_number()) %>% select(-n)

gasten %>% inner_join(ranks, by="naam") %>% mutate(month=lubridate::floor_date(date, "month")) %>% 
  filter(date < "2021-02-01") %>% 
  group_by(naam, month, rank) %>% summarize(n=n()) %>% 
  #group_by(month) %>% mutate(total=sum(duration), perc=duration/total*100) %>% 
  filter(rank <= 5) %>%  
  select(naam, month, n) %>% 
  pivot_wider(names_from=naam, values_from="n", values_fill=0) %>% pivot_longer(-month, names_to="naam", values_to="n") %>% 
  ggplot() + geom_line(aes(x=month, y=n, color=naam, group=naam)) + ggthemes::theme_fivethirtyeight() + theme(legend.title = element_blank())+
  ggtitle("Aantal keer te gast voor top-10 gasten")
x












presentatoren= c("Napel, Carrie ten", "Sijtsma, Welmoed","Groenhuijsen, Charles","Hilbrand, Sophie","Logtenberg, Hugo",
                 "Brink, Tijs van den", "Veenhoven, Willemijn","Pauw, Jeroen","Ostiana, Giovanca","Dijkstra, Erik",
                 "Schimmelpenninck, Sander", "Leeuw, Paul de","Joosten, Astrid", "Kelder, Jort", "Fidan Ekiz")

speakers = read_csv("data/op1_speakers.csv")
speakers
  

d = read_csv("data/op1gasten.csv") %>% 
  mutate(presentator=speaker %in% presentatoren, 
         date = as.Date(date, format="%d-%m-%Y"),
         month= lubridate::floor_date(date, "month")) %>% 
  rename(duration=`total duration (s)`) 


d = d%>%left_join(speakers)

d = d %>% mutate(period = case_when(
  date < "2020-03-01" ~ "pre-corona", 
  date < "2020-07-01" ~ "eerste golf",
  date < "2020-10-01" ~ "zomer",
  T ~ "tweede golf"),
  period = fct_reorder(period, date)) 

##CHECK

table(d$naam %in% op1g$naam)
check = op1g %>% filter(! naam %in% d$naam)
d2 =d %>%group_by(naam)%>%summarize(nsub=n(),duration=sum(duration),aantal=length(unique(date)))

check=full_join(d2,op1g)
write_csv(check,"data/check_gasten.csv")

correctie = read_csv("data/check_gasten.csv")
head(correctie)

head(op1g)
op1g2=op1g%>%left_join(correctie)%>%mutate(naam=ifelse(! is.na(correctie), correctie, naam))%>%
  select(-correctie)%>%replace(is.na(.),0)%>%
  group_by(naam)%>%summarise(n=sum(n),nsub=sum(nsub),duration=sum(duration),aantal=sum(aantal))%>%arrange(-n)

op1g2
###koppeling speakers categorie

speaker_cat = speakers%>%select(naam, categorie)
op1g2=op1g2%>%left_join(speaker_cat)

write_csv(op1g2,"data/gasten_op1_categorie.csv")
gastentot=read_csv("data/gasten_op1_categorie.csv")

head(op1g2)

d %>% filter(categorie != "presentator") %>% 
  group_by(period, categorie) %>% summarize(t=sum(duration)) %>% mutate(total=sum(t)) %>% 
  slice_max(t, n=5)  %>% mutate(n=row_number()) %>% 
  mutate(perc=round(t/total*100, 1), t=round(t/60, 0), speaker=glue("{categorie} ({perc}%)")) %>%
  select(period, categorie, n) %>% pivot_wider(names_from=period, values_from=categorie)


d %>% filter(!presentator) %>% group_by(speaker) %>% summarize(t=sum(duration), n=length(unique(date))) %>% arrange(-t) %>% mutate(rank=row_number())


ranks = d %>% filter(!presentator) %>% group_by(speaker) %>% summarize(t=sum(duration)) %>% arrange(-t) %>% mutate(rank=row_number()) %>% select(-t)
ranks %>% filter(str_detect(speaker, "ommer"))

d %>% inner_join(ranks, by="speaker") %>% filter(rank <= 5) %>% group_by(speaker, month) %>% summarize(duration=sum(duration)) %>% 
  ggplot() + geom_line(aes(x=month, y=duration, color=speaker, group=speaker))


d %>% inner_join(ranks, by="speaker") %>% group_by(speaker, month, rank) %>% summarize(duration=sum(duration)) %>% 
  group_by(month) %>% mutate(total=sum(duration), perc=duration/total*100) %>% 
  filter(rank %in% c(1,2,3,4,8,9, 29)) %>%  
  select(speaker, month, perc) %>% 
  pivot_wider(names_from=speaker, values_from="perc", values_fill=0) %>% pivot_longer(-month, names_to="speaker", values_to="perc") %>% 
  ggplot() + geom_line(aes(x=month, y=perc, color=speaker, group=speaker)) + ggthemes::theme_fivethirtyeight() + theme(legend.title = element_blank())+
  ggtitle("Percentage van totale spreektijd voor geselecteerde gasten")

d %>% inner_join(ranks, by="speaker") %>% group_by(speaker, month, rank) %>% summarize(duration=sum(duration)) %>% 
  group_by(month) %>% mutate(total=sum(duration), perc=duration/total*100) %>% 
  filter(rank <= 10) %>%  
  select(speaker, month, perc) %>% 
  pivot_wider(names_from=speaker, values_from="perc", values_fill=0) %>% pivot_longer(-month, names_to="speaker", values_to="perc") %>% 
  ggplot() + geom_line(aes(x=month, y=perc, color=speaker, group=speaker)) + ggthemes::theme_fivethirtyeight() + theme(legend.title = element_blank())+
  ggtitle("Percentage van totale spreektijd voor top-10 gasten")


d %>% filter(!presentator, date < "2021-01-01") %>% 
  group_by(month, speaker)  %>% summarize(t=sum(duration)) %>%
  mutate(total=sum(t)) %>% slice_max(t, n=5) %>%
  mutate(top=sum(t), perc_top=top/total) %>% 
  ggplot() + geom_line(aes(x=month, y=perc_top)) + ggthemes::theme_fivethirtyeight() + ggtitle("% van spreektijd door top-5 gasten")

d %>% filter(!presentator, date < "2021-01-01") %>% 
  group_by(month, speaker)  %>% summarize(t=sum(duration)) %>% summarize(gini=reldist::gini(t)) %>% 
  ggplot() + geom_line(aes(x=month, y=gini)) +ggthemes::theme_fivethirtyeight() + ggtitle("Gini-coefficient van spreektijd per gast","Hoog=meer ongelijkheid")


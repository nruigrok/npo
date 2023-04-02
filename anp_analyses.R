library(tidyverse)
library(amcatr)
library(ggthemes)

#Meta data
tot5=readRDS("data/model_npo2021.rds")

tot5=tot5%>%select(-pb_id)%>%rename(pb_id=from)
head(tot5)

pers=readRDS("data/persberichten_meta.rds")
table(pers$section)

pers_datum=pers%>%select(pb_id=id,pb_date=date, pb_author=author, pb_section=section)
table(pers_datum$pb_section)

table(tot5$pb_id %in% pers_datum$pb_id)

tot5 = tot5%>%mutate(pb_id=as.numeric(pb_id))%>%left_join(pers_datum)
table(tot5$pb_section)

sporten = c("Atletiek", "Autosport", "sport", "Sport","Baanwielrennen","Basketbal","Beachvolleybal","Gehandicaptensport",
            "Voetbal","Golf","Snowboarden","Hockey","Tennis","Turnen","Wielrennen","Zwemmen","Basketbal", "American football",
            "Kunstschaatsen","Taekwondo","Schaatsen","Judo","Paardensport","Darts","Handboogschieten", "Motorsport","Honkbal",
            "Marathonschaatsen","Waterpolo","Volleybal","Skateboarden","Rugby","Shorttrack", "Boksen","Bridge","IJshockey")

pattern= str_c(sporten, collapse="|")

tot5=tot5%>%mutate(sport = str_detect(section,regex(pattern, ignore_case = T)))

tot5=tot5%>%mutate(sport=ifelse(is.na(sport),0,sport))%>%mutate(publisher=ifelse(sport==1,"NOS sport", publisher))

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


tijden = tijden%>%mutate(periode = case_when(date <"2020-03-16" ~ "1. Pre-corona",
                                             date <"2020-06-16" ~ "2. Eerste Golf",
                                             date <"2020-09-01" ~ "3. Zomer",
                                             date <"2021-01-01" ~ "4. Najaar 2020",
                                             date <"2021-03-18" ~ "5. Verkiezingscampagne",
                                             date <"2021-06-01" ~ "6. Formatie"))%>%
  filter(date<"2021-06-01")

invloed = tijden%>%dplyr::mutate(across(weight:n_zinnen, ~ifelse(is.na(.), 0, .)),
                                 invloed=case_when(weight2 >= 0.7 ~ 3,
                                                   weight2< .7 & n_zinnen>=1 ~ 2,
                                                   (weight2>.3 | weight>.3) & weight2< .7 & n_zinnen<1 ~ 1,
                                                   T ~ 0))%>%
  mutate(pb_id=as.numeric(pb_id))

npo_invloed = invloed%>%group_by(id)%>%arrange(-invloed, -weight2, -n_zinnen) %>% mutate(n_pb=n()) %>% slice_head(n=1)

saveRDS(invloed, "data/anp_data_juni2021.rds")

data=readRDS("data/anp_data_juni2021.rds")


#unieke artikelen met hoogste overlap

data2 = data%>%group_by(id)%>%arrange(-invloed, -weight2, -n_zinnen) %>% mutate(n_pb=n()) %>% slice_head(n=1)
websites=c("Radio1", "Op1", "NOS sport", "NOS nieuws", "NOS liveblog", "Nieuwsuur", "EenVandaag", "Teletekst")
subtitles=c("Op1_sub","NOSJournaal","GoedemorgenNL", "EenVandaag_sub","Nieuwsuur")



########################ANALYSES


#websites
web = data2%>%filter(publisher %in% websites)%>%group_by(publisher,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

ggplot(web,aes(x=publisher, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  coord_flip() +
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            web %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()

#ondertiteling
sub= data2%>%filter(publisher %in% subtitles)%>%group_by(publisher,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(publisher = case_when(publisher=="Op1_sub" ~ "Op1",
                               publisher=="EenVandaag_sub" ~ "EenVandaag",
                               T ~ publisher))%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

ggplot(sub,aes(x=publisher, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  coord_flip() +
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            sub %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()

#section


sect= data2%>%filter(publisher %in% websites)%>%filter(! is.na(pb_section))%>%group_by(pb_section,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))
table(data2$pb_section, useNA = 'always')

ggplot(sect,aes(x=pb_section, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  coord_flip() +
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            sect %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()


#maand

maand= data2%>%filter(publisher %in% websites)%>%group_by(month,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

head(maand)
library(scales)
ggplot(maand,aes(x=month, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            maand %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_x_date(date_breaks = "1 month",labels=date_format("%b-%y"), expand = c(0,0)) + 
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme_economist()+
  theme(axis.text.x=element_text(angle=90,hjust=0.5,vjust=0.5))


#dag vd week vanuit Persbericht


dag1= data2%>%filter(publisher %in% websites)%>%filter(! is.na(pb_section))%>%group_by(pb_dag,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

dagen = c("Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag","Zondag")

ggplot(dag1,aes(x=(fct_reorder(pb_dag, match(pb_dag, dagen))), y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            dag1 %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()


#dag van de week vanuit dagbladen
dag2= data2%>%filter(publisher %in% websites)%>%group_by(dag,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

dagen = c("Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag","Zondag")

ggplot(dag2,aes(x=(fct_reorder(dag, match(dag, dagen))), y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            dag2 %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()




#tijd van de dag vanuit persbericht


tijd1= data2%>%filter(publisher %in% websites)%>%filter(! is.na(pb_tijd))%>%group_by(pb_tijd,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

tijden = c("Nacht","Ochtend","Middag","Avond")

ggplot(tijd1,aes(x=(fct_reorder(pb_tijd, match(pb_tijd, tijden))), y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            tijd1 %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()



#tijd van de dag vanuit nieuws


tijd2= data2%>%filter(publisher %in% websites)%>%filter(! is.na(tijd))%>%group_by(tijd,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

tijden = c("Nacht","Ochtend","Middag","Avond")

ggplot(tijd2,aes(x=(fct_reorder(tijd, match(tijd, tijden))), y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            tijd2 %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()


#per auteur

auteur= data2 %>% filter(publisher %in% websites, !is.na(pb_author)) %>%
  mutate(pb_author=str_remove_all(pb_author,"\\(.*?\\)") %>% str_replace_all("\\s+"," ") %>% trimws()) %>%
  filter(invloed>1) %>% 
  group_by(pb_author) %>% summarize(n=n()) %>% 
  mutate(perc=n/sum(n)*100) %>% arrange(-n,-perc)


text = c("ANP (bvz)")
text %>% str_remove_all("\\(.*?\\)")%>%str_replace_all("\\s+"," ")%>%trimws()
text %>% str_replace("\\(a-z\\)", "")



ggplot(auteur %>% head(10),aes(y=pb_author, x=round(perc,1)))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            auteur %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()


##########ONDERTITELING


#ondertiteling
sub= data2%>%filter(publisher %in% subtitles)%>%group_by(publisher,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(publisher = case_when(publisher=="Op1_sub" ~ "Op1",
                               publisher=="EenVandaag_sub" ~ "EenVandaag",
                               T ~ publisher))%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

ggplot(sub,aes(x=publisher, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  coord_flip() +
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            sub %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme(axis.text.x=element_text(angle=45,hjust=1), axis.title.x = element_blank())+
  theme_economist()


#ondertiteling over tijd

subtijd= data2%>%filter(publisher %in% subtitles)%>%group_by(month,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

library(scales)
ggplot(subtijd,aes(x=month, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            subtijd %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_x_date(date_breaks = "1 month",labels=date_format("%b-%y"), expand = c(0,0)) + 
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme_economist()+
  theme(axis.text.x=element_text(angle=90,hjust=0.5,vjust=0.5))


subgn= data2%>%filter(publisher=="GoedemorgenNL")%>%group_by(month,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

library(scales)
ggplot(subgn,aes(x=month, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            subgn %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_x_date(date_breaks = "1 month",labels=date_format("%b-%y"), expand = c(0,0)) + 
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme_economist()+
  theme(axis.text.x=element_text(angle=90,hjust=0.5,vjust=0.5))


table(data2$publisher, useNA = 'always')
subop1= data2%>%filter(! is.na(omroep), publisher=="Op1_sub")%>%group_by(omroep,invloed)%>%summarize(n=n())%>%mutate(perc=n/sum(n)*100)%>%
  mutate(invloed2=case_when(invloed==0 ~ "0. Geen invloed",
                            invloed==1 ~ "1. Zelfde event",
                            invloed==2 ~ "2. Deels overlap",
                            invloed==3 ~ "3. Kopie"))

library(scales)
ggplot(subop1,aes(x=omroep, y=round(perc,1), group=invloed2, fill=invloed2))+
  geom_bar(stat="identity")+
  ggtitle("Invloed ANP per programma") + 
  geom_text(aes(label=round(perc,1)),#paste0(n,"\n",round(perc,1))),
            subop1 %>% filter(perc>3.5),
            position=position_stack(vjust=.5),  color="black", cex=4)+
  scale_fill_discrete(name="") + xlab("") + ylab("") + 
  theme_economist()+
  theme(axis.text.x=element_text(angle=90,hjust=0.5,vjust=0.5))


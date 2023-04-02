library(tidyverse)

radio= read_csv("data/radio.csv")
radio



d2020=read_csv("data/npo2020_resultaat.csv")%>%
  mutate(year=2020)%>%filter(! parent %in% c("Televisieprogrammas","CommercieleTV"))
d2021=read_csv("data/npo2021_resultaat.csv")%>%mutate(year=2021)%>%
  filter(! parent %in% c("Televisieprogrammas","CommercieleTV"))
dtot=d2020%>%bind_rows(d2021)%>%rename(parent_label=parent)


tot=dtot%>%bind_rows(radio)%>%
  mutate(soort = ifelse(label=="BNR", "Commercieel", "NPO"))%>%
  select(-radio)

tot
library(lubridate)
tot=read_csv("data/tot_radio.csv")%>%
  mutate(jaar=as.Date(as.character(year), "%Y"))%>%
  mutate(year=lubridate::year(jaar))%>%filter(year>="2017-01-01")

tot

pertitel = tot%>%filter(year>2017,medtype=="Dagbladen", label !="BNR")%>%
  group_by(label)%>%summarize(n=sum(n))%>%
  mutate(perc=n/sum(n)*100)%>%arrange(-n)

pertitel
pp = tot%>%group_by(label)%>%summarize(n=sum(n))%>%mutate(perc=n/sum(n)*100)%>%arrange(-n)

pp = tot%>%mutate(soort = ifelse(label=="BNR", "BNR", "NPO"))%>%
  filter(year>2017, medtype=="Kamerstukken")%>%group_by(year,soort)%>%
  summarize(n=sum(n))%>%mutate(perc=n/sum(n)*100)%>%arrange(-n)
pp



write_csv(pertitel,"data/programmas_kamerstukken.csv")

pp2 = tot%>%mutate(soort = ifelse(label=="BNR", "Commercieel", "NPO"))%>%
  filter(year>2008, medtype=="Dagbladen", label %in% pertitel$label, soort=="NPO")%>%group_by(year,label)%>%
  summarize(n=sum(n))%>%mutate(perc=n/sum(n)*100)%>%arrange(-n)%>%top_n(10)


pp = tot%>%mutate(soort = ifelse(label=="BNR", "BNR", "NPO"))%>%
  filter(year>2008, medtype=="Dagbladen", soort=="NPO")%>%group_by(year,label)%>%
  summarize(n=sum(n))%>%mutate(perc=n/sum(n)*100)%>%arrange(-n)%>%top_n(10)

###PER JAAR
library(scales)
library(ggthemes)
ggplot(pp2,aes(x=year, group=reorder(label, -n), fill=label, y=perc))+
  geom_bar(stat = "identity", position="dodge")+
  # scale_x_date(date_breaks = "1 year",labels=date_format("%Y"), expand = c(0,0))+
  #ggtitle("Aantal nieuwsberichten per week") + 
  theme(axis.text.x=element_text(angle=90,hjust=0.5,vjust=0.5))+
  geom_text(aes(label=round(perc)), vjust=1.6, color="black",
            position = position_dodge(0.9), size=2.5)+  
  theme_minimal()+
  xlab("")+
  ylab("")+
  theme(legend.title = element_blank())



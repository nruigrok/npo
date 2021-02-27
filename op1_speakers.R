library(tidyverse)

data=read_csv("data/npo2020.csv")
head(data)
colnames(data)
data=data%>%select(id,Programma,Programma2)
head(data)
data2=data%>%pivot_longer(Programma:Programma2,names_to="program")%>%filter(value !="None")%>%group_by(value)%>%
  summarize(n=n())%>%mutate(perc=round(n/sum(n)*100,1))%>%arrange(-perc)
data2
View(data2)


op1=read_csv('data/op1gasten.csv')
View(op1)
length(unique(op1$date))


op12=op1%>%group_by(speaker)%>%summarize(n=sum(`total duration (s)`))%>%arrange(-n)
write_csv(op12,"data/op1_speakers.csv")
presentatoren= c("Napel, Carrie ten", "Sijtsma, Welmoed","Groenhuijsen, Charles","Hilbrand, Sophie","Logtenberg, Hugo",
                 "Brink, Tijs van den", "Veenhoven, Willemijn","Pauw, Jeroen","Ostiana, Giovanca","Dijkstra, Erik",
                 "Schimmelpenninck, Sander", "Leeuw, Paul de","Joosten, Astrid")

length(unique(op1$date))
op1%>%filter(speaker %in% presentatoren)%>%group_by(speaker)%>%summarize(afleveringen=length(unique(date)))
                                                                               
                                                                               
presentatoren =op1%>%filter(speaker %in% presentatoren)%>%group_by(date, speaker)%>%summarize(afleveringen=length(unique(date)),aantal=length(speaker),sec=sum(`total duration (s)`))%>%
  mutate(gem=sec/aantal)%>%arrange(-aantal)
presentatoren

presentatoren2 =op1%>%filter(speaker %in% presentatoren)%>%group_by(speaker)%>%summarize(aantal=length(speaker),sec=sum(`total duration (s)`))%>%
  mutate(gem=sec/aantal)%>%arrange(-aantal)

table(selectie$sec)

aantalspeakers= op1%>%group_by(date)%>%filter(speaker %in% selectie$speaker)%>%
  summarize(n=length(speaker), sec=sum(`total duration (s)`))
aantalspeakers


op13=op1%>%group_by(speaker)%>%filter(speaker %in% selectie$speaker)%>%summarize(n=sum(`total duration (s)`))%>%arrange(-n)
View(op13)



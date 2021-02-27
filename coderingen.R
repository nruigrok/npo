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


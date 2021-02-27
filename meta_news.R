library(tidyverse)

m1 = read_csv("data/meta_vooravond.csv")%>%mutate(show="vooravond")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m2 = read_csv("data/meta_goedemorgen.csv")%>%mutate(show="goedemorgen")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m3 = read_csv("data/meta_eenvandaag.csv")%>%mutate(show="eenvandaag")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m4 = read_csv("data/meta_nieuwsuur.csv")%>%mutate(show="nieuwsuur")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m5 = read_csv("data/meta_NOS.csv")%>%mutate(show="nosjournaal")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m6 = read_csv("data/meta_M.csv")%>%mutate(show="M")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m7 = read_csv("data/meta_dwdd.csv")%>%mutate(show="dwdd")%>%mutate(date=as.Date(date, "%d-%m-%Y"))
m8 = read_csv("data/meta_op1.csv")%>%mutate(show="op1")%>%mutate(date=as.Date(date, "%d-%m-%Y"))

m = m1%>%bind_rows(m1,m2,m3,m4,m5,m6,m7,m8)%>%filter(date>="2021-01-01")
head(m)
table(m$date,m$show)

table(m4$date)

library(tidyverse)
library(ggmap)
#install.packages("tmapstools")
#install.packages("sf")

inloop=read_csv("inloop.csv")
inloop
install.packages("testthat")
library(devtools)
install_github("mtennekes/tmaptools")
library(tmaptools)


inloop%>%mutate(adres=gsub("<p>","", adres))%>%
  mutate(adres1=str_split_fixed(adres,"<br>",n=Inf))

adres= str_split_fixed(inloop$adres,"<br>",n=Inf) %>% as_tibble() %>%
   mutate(postcode=str_match(V2, "^ (\\d{4} \\w{2})")[,2],
          plaats=str_match(V2, "^ \\d{4} \\w{2} (.*)")[,2],
          straat=trimws(V1)) %>%
   select(straat, postcode, plaats) 
 
head(inloop)
head(adres)
adres = bind_cols(inloop, adres)
head(adres)

View(adres)
locations = adres %>% filter(!is.na(plaats)) %>% pull(plaats) %>% unique %>% geocode_OSM() %>% 
  select(adres2=query, lat, long=lon)

head(locations)

x = full_join(locations, locations, by=character(), suffix=c("_new", ""))
# Use haversine function 
x$dist = 0
for (i in seq_along(x$adres2)) {
  x$dist[i] = pracma::haversine(c(x$lat_new[i], x$long_new[i]), c(x$lat[i], x$long[i]))
}
x = x %>% mutate(dist2=dist^2)

dm = x%>%select(adres2,adres2_new,dist2)%>%pivot_wider(names_from = "adres2_new", values_from="dist2")
dmat = dm %>% select(-adres2) %>% as.matrix()
rownames(dmat) = colnames(dmat)
library(TSP)
tsp = TSP(dmat)
image(tsp)
tour <- solve_TSP(tsp)
tour
steden = labels(tour)
zwolle = match("Zwolle", steden)
tour = c(steden[zwolle:length(steden)], steden[1:zwolle-1])

locations = locations %>% as_tibble() %>% mutate(order=match(adres2, tour)) %>% arrange(order) 
locations
#install.packages("tmap")
library(tmap)
library(sf)
library(rgdal)

NLD = readRDS("~/Downloads/gadm36_NLD_1_sp.rds")

NLD_fixed <- subset(NLD, !NLD$NAME_1  %in% c("Zeeuwse meren", "IJsselmeer"))
NLD_fixed <- fortify(NLD_fixed)

library(Cairo)

CairoPNG(file="data/route.pdf", width=1000, height=500)
CairoPNG(filename="data/route.png", width=1000, height=500)

bind_rows(locations, head(locations,1)) %>% 
ggplot(aes(long, lat))+
  geom_polygon(data = NLD_fixed, 
               aes(x = long, y = lat, group = group), color="white", fill="pink") +
  coord_map() + 
  geom_point(color="red", size = 1.5, show.legend = FALSE) +
  geom_path() + geom_label(aes(label=adres2), size=1.5, alpha=.5) +
  ggtitle("Borsten kwijt, baan kwijt, maar wel een fiets en een missie!")
invisible(dev.off())

etappes = locations %>% mutate(dest=lead(adres2)) %>% inner_join(select(x, adres2, dest=adres2_new, dist))
sum(etappes$dist)
summary(etappes$dist)
hist(etappes$dist)

write_csv(etappes,"etappes.csv")

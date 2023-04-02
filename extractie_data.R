install.packages("RPostgres")
library(DBI)
library(tidyverse)

con <- dbConnect(RPostgres::Postgres(), dbname = 'amcat', 
                 host = 'localhost', # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'
                 port = 5434, # or any other port specified by your DBA
                 user = 'amcat',
                 password = 'eno=hoty')

sort(dbListTables(con))

query = function(sql) {
  res <- dbSendQuery(con, sql)
  d = dbFetch(res)
  dbClearResult(res)
  tibble::as_tibble(d)
}
d = query("SELECT * FROM codingjobs WHERE project_id=320")
d

cjs = unique(d$codingjob_id)


codingjobs=query("SELECT * FROM codingjobs WHERE project_id=320")
head(codingjobs)
id = 12721

codedarticles =query(paste0("SELECT * FROM coded_articles WHERE status_id = 2 AND codingjob_id =", id))
codedarticles

coded_aid=1824360
codings = query(paste0("SELECT * FROM codings"))
codings

coding_id=1268460
codes = query(paste0("SELECT * FROM codes"))
codes

cv=query(paste0("SELECT * FROM codings_values"))
cv

table(codes$coding_id %in% code$code_id)

labels = query("SELECT * FROM codes_labels")
head(labels)
ca =  query("SELECT * FROM coded_articles " )
ca

cc =  query("SELECT * FROM codebooks_codes " )
cc

cr =  query("SELECT * FROM codingrules " )
cr

art =  query("SELECT * FROM articles " )
art

cb =  query("SELECT * FROM codebooks_bases " )
cb
code = query("SELECT * FROM codebooks WHERE codebook_id=907" )
head(code)

cv

sort(dbListTables(con))



jobs = query("SELECT * FROM codingjobs WHERE project_id=320")
cjids = paste(jobs$codingjob_id, collapse=",")
cjids = paste(d$codingjob_id[1], collapse=",")

sql = glue::glue("
SELECT ca.article_id, c.coded_article_id, c.coding_id, a.date, a.medium_id, m.name, 
    cf.label AS field, cf.fieldtype_id AS fieldtype, cl.label AS code, cv.intval, cv.strval 
FROM coded_articles ca 
INNER JOIN articles a ON a.article_id = ca.article_id
INNER JOIN media m ON m.medium_id = a.medium_id
INNER JOIN codings c ON c.coded_article_id=ca.id
INNER JOIN codings_values cv ON cv.coding_id = c.coding_id 
INNER JOIN codingschemas_fields cf ON cf.codingschemafield_id = cv.field_id
LEFT JOIN codes_labels cl ON cf.fieldtype_id=5 AND cl.code_id = cv.intval
WHERE ca.codingjob_id IN ({cjids})
")


d = query(sql) 
# Drop duplicate coding_ids
dupes = d %>% select(coded_article_id, coding_id) %>% 
  unique() %>% 
  group_by(coded_article_id) %>% 
  filter(n()>1) %>% 
  arrange(coded_article_id, desc(coding_id) ) %>% 
  filter(row_number() > 1)

d = d %>% filter(!coding_id %in% dupes$coding_id)
head(d)
saveRDS(d,"~/Dropbox/Nieuwsmonitor/NPO/data.rds")
write_csv(d,"data/datanpo2021.csv")

colnames(d)

d2=d%>%select(article_id, code, field,label..44, parent_id)
d2

sql2 = glue::glue("SELECT articles.article_id, date, articles.medium_id, * FROM articles 
             LEFT JOIN media m ON m.medium_id = articles.medium_id
             LEFT JOIN articlesets_articles aa ON aa.article_id = articles.article_id
             LEFT JOIN coded_articles ca ON ca.article_id = articles.article_id
             WHERE codingjob_id IN ({cjids})
                  ")
arts=query(sql2)             
colnames(arts)
arts2=arts%>%select(article_id, date,name)
head(arts2)

table(d2$article_id %in% arts$article_id)

data = d2%>%left_join(arts2)
data
table(data$name)

head(d)















articles = query("SELECT article_id, date, articles.medium_id FROM articles limit 10")

arti = query("SELECT * FROM coded_articles limit 10")
arti
articles

as = query("SELECT * FROM articlesets_articles limit 10")
as
media=query("SELECT * FROM media")
media

programma = d%>%filter(field=="Programma")
colnames(programma)
table(is.na(programma$parent_id))
table(programma$parent_id, programma$code)

check = programma%>%filter(code_id==parent_id)
check

devtools::install_github('kasperwelbers/shinyBZpers', force=TRUE)

library(shinyBZpers)
library(amcatr)

conn = amcat.connect('https://vu.amcat.nl')
data = create_bz_data(conn, project=78, pers_set=3311, nieuws_set=3312, deduplicate=0.9, pers_medium_col='publisher', pers_headline_col='title', 
                         nieuws_medium_col='publisher', nieuws_headline_col='title')
bz_app(data, port = 6171)
saveRDS(data,"data_anp_npo.rds")



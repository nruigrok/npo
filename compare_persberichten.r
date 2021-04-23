

library(amcatr)
library(corpustools)

#### DATA VOORBEREIDEN
## haal data van amcat. Preprocess met corpustools

conn = amcat.connect('https://vu.amcat.nl')


pers = amcat.getarticlemeta(conn, project=78, articleset = 3311, dateparts=T, columns = c("publisher", "date","title", "text"))
pers$medium = 'Persberichten'

nieuws = amcat.getarticlemeta(conn, project=78, articleset = 3312, dateparts=T, columns = c("publisher", "date","title", "text"))

nieuws$medium=nieuws$publisher
meta=nieuws
## maak 1 dataframe van
d = rbind(pers[,c('id','medium','date','title','text')],
          nieuws[,c('id','medium','date','title','text')])

colnames(pers)
colnames(nieuws)
## maak tcorpus. gebruik udpipe_model om te parsen (als je een taal invult dan krijg je suggesties voor modellen in die taal)
tc = create_tcorpus(d, doc_column = 'id', text_columns = c('title','text'), udpipe_model='dutch-alpino')
tc$tokens


## Voor de plagiaatscan van nieuws is het belangrijk dat je data een datum kolom heeft.
## als je in create_tcorpus een data.frame als input gebruikt, dan worden alle kolommen naast de doc_id en text
## vanzelf meegenomen als metadata.
tc$meta

## Zet date in juiste format 
tc$meta$date = as.POSIXct(tc$meta$date)

## Dedupliceren is vaak een goed plan. Vooral omdat bij online kranten data je vaak ook updates van artikelen hebt, 
## waardoor similarity scores sterk beinvloed worden. Je kunt hier een date en meta kolom opgeven, zodat alleen duplicates
## binnen een gegeven tijdsafstand and binnen hetzelfde medium worden verwijderd.
## met keep = 'first' houden we bij duplicates het eerst gepubliceerde artikel (wat voor invloed een goede keuze is)
#tc$deduplicate('lemma', date_col = 'date', meta_cols = 'medium', similarity=0.9, keep='first')


## maak DTMs voor persberichten en nieuws. Met subset_meta kiezen we de documenten (wel/geen perberichten). met subset_tokens
## nemen we een selectie van POS tags
pers = get_dfm(tc, feature='lemma',  
               subset_meta = medium == 'Persberichten', 
               subset_tokens = POS %in% c('PROPN','NOUN','VERB'))

nieuws = get_dfm(tc, feature='lemma', 
                 subset_meta = medium != 'Persberichten', 
                 subset_tokens = POS %in% c('PROPN','NOUN','VERB'))

## je kunt bij get_dfm ook ngrams = 3 oid gebruiken. Dan worden alle opeenvolgende woorden (na de subset)
## in ngrams samengevoegd. Dat maakt de vergelijking strenger (niet alleen woordfrequentie, maar ook volgorde)

#### ARTIKELEN VERGELIJKEN

## artikelen vergelijken kan ook direct vanuit corpustools, maar rnewsflow heeft handige functies om 
## de resultaten te aggregeren. Ook is daar wat meer documentatie voor:
## https://cran.r-project.org/web/packages/RNewsflow/vignettes/RNewsflow.html

library(RNewsflow)

## Hier geef je 2 dtms. De eerste wordt met de 2e vergelijken
## (je kunt ook 1 dtm geven, zodat alle artikelen met elkaar worden vergeleken)
## speel hier een beetje met de instellingen. Met name de similarity threshold
g = RNewsflow::newsflow_compare(pers, nieuws, date='date', 
                                   min_similarity = 0.3,       ## similarity threshold
                                   hour_window = c(0, 2*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                   measure = 'cosine',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                   tf_idf=T)                   ## weeg woorden die minder vaak voorkomen zwaarder mee

## g is een netwerk van alle artikelen. Je kunt daar een data.frame van maken
## je moet dan alleen wel zelf nog de meta data eraan mergen
e = igraph::as_data_frame(g)
e

e = e%>%rename(id=to)%>%mutate(id=as.numeric(id))
colnames(e)
colnames(meta)
class(e$id)
meta2=meta%>%left_join(e)
head(meta2)
table(meta2$publisher)

library(tidyverse)


anp=meta%>%mutate(overlap=ifelse(is.na(weight),0,1))%>%filter(overlap==1)

write_csv(anp,"data/anp_nos_overlap.csv")
View(anp)
overl=meta2%>%mutate(overlap=ifelse(is.na(weight),0,1))%>%group_by(medium3,overlap)%>%summarize(n=length(id))%>%mutate(perc=round(n/sum(n)*100,1))
overl
overl2=overl%>%filter(overlap==1)
overl2



ggplot(data=overl, aes(x=reorder(medium3, -n), y=n, label=paste0(n))) +
  geom_bar(stat="identity", fill='dark blue')+ theme(axis.title.x = element_blank())+theme(axis.title.y = element_blank())+
  geom_text(position=position_stack(vjust=0.5), color='white')+
  theme(legend.position="none")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ids=overl2$id
amcat.add.articles.to.set(conn, project=2,articles=ids, articleset.name = "artikelen obv persberichten")


overl2=overl%>%filter(overlap==1)
overl2
overl=meta%>%mutate(overlap=ifelse(is.na(weight),0,1))%>%filter(! medtype=="Regionaal")%>%group_by(medium3, overlap)%>%summarize(n=length(id))%>%mutate(perc=round(n/sum(n)*100,1))

ggplot(data=overl2, aes(x=reorder(medium3, -n), y=n, label=paste0(n, "\n" ,round(perc),"%"))) +
  geom_bar(stat="identity", fill='dark blue')+ theme(axis.title.x = element_blank())+theme(axis.title.y = element_blank())+
  geom_text(position=position_stack(vjust=0.5), color='white')+
  theme(legend.position="none")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



  
## een alternatief is de network_aggregate functie van RNewsflow, waarmee je edges uit het netwerk kunt
## aggregeren op basis van meta data. Hier aggregeren we alle edges op medium
g_agg = network_aggregate(g, by='medium')
igraph::as_data_frame(g_agg, 'edges')


## Bij het zoeken naar een threshold, kan het ook goed zijn om te kijken naar matches met artikelen
## die eerder dan het persbericht gepubliceerd zijn (dat zijn dan immers false positives, want ze kunnen niet
## op het persbericht gebaseerd zijn. We kunnen daarvoor een nieuwe vergelijking maken met een date window die ook
## matches voor het persbericht zoekt
g = RNewsflow::newsflow_compare(pers, nieuws, date='date', 
                                min_similarity = 0.2,       ## similarity threshold
                                hour_window = c(-7*24, 7*24),   ## tijd window: tussen 0 en 7 dagen na publicatie persbericht
                                measure = 'cosine',         ## cosine similarity. Je kunt ook overlap_pct gebruiken voor assymetrische vergelijking
                                tf_idf=T)                   ## weeg woorden die minder vaak voorkomen zwaarder mee

## we kunnen dan een histogram maken van alle matches per hourdiff. Als het goed is dan
## zouden we vooral matches moeten vinden met een hourdiff > 0 (na de publicatie van het persbericht)
e = igraph::as_data_frame(g)
hist(e$hourdiff, breaks=20, right=F)

## je ziet dat er een paar matches zijn met hourdiff < 0. Nu zouden we deze sowieso negeren, maar het geeft wel aan
## dat er wat ruis in de meting zit. Ook bij hourdiff > 0 is de kans groot dat er een paar foute matches bijzitten.
## Als je de threshold verhoogt dan zul je minder kans hebben op false positives, en zul je dus zien dat
## de matches met hourdiff < 0 zullen verdwijnen. 
e2 = e[e$weight > 0.4, ]
hist(e2$hourdiff, breaks=20, right=F)

## Het is echter niet verstandig om de threshold zo hoog te maken dat ze allemaal weg zijn. 
## Het kan altijd dat er een nieuwsbericht veel lijkt op een persbericht dat later gepubliceerd is
## bijv omdat het over dezelfde gebeurtenis of persconferentie gaat. Met een te hoge threshold
## zul je ook correcte matches weggooien (false negatives)

## Het is ook slim om artikelen met matches terug te lezen.
## hier vragen we om de teksten te bekijken van het eerste from en to artikelen in e
head(e)
browse_texts(tc, doc_ids = c(e$from[1], e$to[1]))

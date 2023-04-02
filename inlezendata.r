

mydir = "data/codebooks"
myfiles = list.files(path=mydir, pattern="codebook*", full.names=TRUE)


cb=list()
for(id in myfiles) {
  message("Getting codebook ",id)
  cb[id] = read_csv(id)
}

cb1068=read_csv("data/codebooks/codebook_1068.csv")
cb1229=read_csv("data/codebooks/codebook_1229.csv")
cb1233=read_csv("data/codebooks/codebook_1233.csv")
cb1267=read_csv("data/codebooks/codebook_1267.csv")
cb270=read_csv("data/codebooks/codebook_270.csv")
cb271=read_csv("data/codebooks/codebook_271.csv")
cb273=read_csv("data/codebooks/codebook_273.csv")
cb274=read_csv("data/codebooks/codebook_274.csv")
cb907=read_csv("data/codebooks/codebook_907.csv")
cb277=read_csv("data/codebooks/codebook_277.csv")
cb344=read_csv("data/codebooks/codebook_344.csv")

cbtot = cb344%>%bind_rows(cb1068,cb1229,cb1233,cb1267,cb270,cb271,cb273,cb274,cb907,cb277)
library(purrr)
cb = purrr::map_df(myfiles, read_csv)
cb%>%group_by(code_id)%>%summarise(n=n())%>%arrange(-n)
table(data2$intval %in% cv$code_id)
head(cb)
data3=data2%>%left_join(cv)
head(data3)
cb%>%group_by()
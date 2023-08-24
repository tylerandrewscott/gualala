library(indexBuild)
library(httr)
term = '"policy entrepreneur*"'
mailto = 'tascott@ucdavis.edu'
works_base <- 'https://api.openalex.org/works'
url <- parse_url(works_base)
url$query$mailto<-mailto
url$query$cursor<-"*"
#200 is max
url$query$`per-page`<-200
from_date <- '2000'
from_date <- if(nchar(from_date)==4){paste(from_date,'01','01',sep = '-')}
url$query$filter$default.search<-term
url$query$filter$from_publication_date<-from_date
to_date <- '2023'
to_date <- if(nchar(to_date)==4){paste(to_date,'12','31',sep = '-')}
url$query$filter$to_publication_date<-to_date
url$query$filter$is_paratext<-"false"
url$query$filter<-paste(paste0(paste0(names(url$query$filter),':'),url$query$filter),collapse = ',')
qurl <- build_url(url)

library(jsonlite)
res = fromJSON(qurl)
p = 1
temp_js_list <- list()
reduce = F
sleep_time = 0.25
reduce_vars <- c('id','title','doi','host_venue','cited_by_count','is_paratext','open_access','publication_year','authorships','type')

while(p==1|ifelse(!exists('js'),T,!is.null(js$meta$next_cursor))){
  print(paste('querying page',p))
  js <- jsonlite::read_json(qurl)
  if(p==1){
    print(paste0(js$meta$count,' works found'))
  }
    if(reduce){
    js$results <- lapply(js$results,function(x) x[reduce_vars])
  }
  temp_js_list <- append(x = temp_js_list,js$results)
  url$query$cursor<-js$meta$next_cursor
  qurl <- build_url(url)
  p <- p + 1
  Sys.sleep(sleep_time)
}


json_object <- toJSON(temp_js_list)
dest_file <- 'data/query_return.json.gz'
write(json_object, file=gzfile(dest_file))

saveRDS(temp_js_list,'scratch/raw_query_return_list.RDS')


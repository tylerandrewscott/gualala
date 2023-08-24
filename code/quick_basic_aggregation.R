library(data.table)
library(pbapply)
res = readRDS('scratch/title_query_return_list.RDS')
res2 = readRDS('scratch/abstract_query_return_list.RDS')

res = append(res,res2)

#### the works object query returns a complicated json file with nested items
### this finds items that are not nested in the query results and isolates those to make a siomple data.table
simple_names=pblapply(res,function(x) names(x)[sapply(x,class)!='list'],cl = 8)
name_set = Reduce(f = intersect,x = simple_names)
reduced_res <- pblapply(res,function(x) x[name_set],cl = 8)

res_dt <- rbindlist(reduced_res,fill = T,use.names = T)

prim_loc <- lapply(res,'[[','primary_location')
source_loc <- lapply(prim_loc,'[[','source')

null2NA <- function(x){x[sapply(x,is.null)]<-NA;return(unlist(x))}

res_dt$open_access <- null2NA(sapply(prim_loc,'[[','is_oa'))
res_dt$source_type <- null2NA(sapply(source_loc,'[[','type'))
res_dt$source.id <- null2NA(sapply(source_loc,'[[','id'))
res_dt$issn_l <- null2NA(sapply(source_loc,'[[','issn_l'))
res_dt$source_name <- null2NA(sapply(source_loc,'[[','display_name'))
res_dt$source_host_name <- null2NA(sapply(source_loc,'[[','host_organization_name'))

res_dt <- res_dt[!duplicated(res_dt),]


fwrite(res_dt,'data/title_abstract_query_overview.csv')
library(tidyverse)
year_count = res_dt %>% group_by(publication_year,source_type) %>% tally()
ggplot(year_count[!is.na(year_count$source_type),]) + geom_path(aes(x = publication_year,y = n,colour = source_type)) + theme_bw()

res_dt %>% group_by(source_name) %>% tally() %>% arrange(-n) %>% 
  filter(!is.na(source_name)) %>% head(15) %>% knitr::kable()




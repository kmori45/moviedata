
start <- 1992
  library(R.utils)
  library(readr)
  library(tidyverse)
  library(RMySQL)
  
  url <- "https://datasets.imdbws.com/title.ratings.tsv.gz"
  dest <- "data/title.ratings.tsv.gz"
  download.file(url, dest)
  gunzip(dest)
  
  title_rate <- read_delim("data/title.ratings.tsv", 
                             "\t", escape_double = FALSE, 
                             trim_ws = TRUE,
                             locale = locale(encoding = 'UTF-8'))
  
  file.remove("data/title.ratings.tsv")
 
  write.csv(title_rate, "data/title_ratings.csv")
  
  
  


 
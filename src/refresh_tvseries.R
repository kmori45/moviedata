
start <- 1992
  library(R.utils)
  library(readr)
  library(tidyverse)
  library(RMySQL)
  
  url <- "https://datasets.imdbws.com/title.basics.tsv.gz"
  dest <- "data/title.basics.tsv.gz"
  download.file(url, dest)
  gunzip(dest)
  
  title_basics <- read_delim("data/title.basics.tsv", 
                             "\t", escape_double = FALSE, 
                             col_types = cols(isAdult = col_character(),
                                              startYear = col_character()), 
                             trim_ws = TRUE,
                             locale = locale(encoding = 'UTF-8'))
  
  file.remove("data/title.basics.tsv")
 
  title_basics$startYear <- as.numeric(title_basics$startYear)
  title_basics$runtimeMinutes <- as.numeric(title_basics$runtimeMinutes)

  title_database <- title_basics %>%
    filter(startYear >= start & startYear < 2019) %>%
    filter(isAdult == 0 & titleType=="tvSeries") %>%
    select(-endYear, -isAdult, -titleType)
  
  updateTime <- Sys.Date() 
  
  title_database$genres <- type.convert(title_database$genres, na.strings="\\N")

  title_database$lastUpdate <- updateTime
  
  file_name <- paste("data/", "tvSeries","_db.csv", sep="")
  
  write.csv(title_database, file_name)
  rm(title_basics)

 
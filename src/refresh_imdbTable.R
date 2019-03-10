# This function retrieves the core IMDB data and puts it in a server location 
# for future use.  Content can be either "movie" or "tvEpisode".

refresh_imdbTable <- function(content = "movie", start = 2000) {
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
  
  url <- "https://datasets.imdbws.com/title.ratings.tsv.gz"
  dest <- "data/title.ratings.tsv.gz"
  download.file(url, dest)
  gunzip(dest)
  
  title_ratings <- read_delim("data/title.ratings.tsv", 
                              "\t", escape_double = FALSE, trim_ws = TRUE,
                              locale = locale(encoding = 'UTF-8'))
  
  file.remove("data/title.ratings.tsv")
  
  title_basics$startYear <- as.numeric(title_basics$startYear)
  title_basics$runtimeMinutes <- as.numeric(title_basics$runtimeMinutes)
  
  title_database <- title_basics %>%
    filter(startYear >= start & startYear < 2019) %>%
    filter(isAdult == 0 & titleType==content) %>%
    select(-endYear, -isAdult, -titleType)
  
  updateTime <- Sys.Date() 
  
  title_database$genres <- type.convert(title_database$genres, na.strings="\\N")
  
  title_database <- left_join(title_database, title_ratings, by = "tconst")
  title_database$lastUpdate <- updateTime
  
  
  
  file_name <- paste("data/", content,"_db.csv", sep="")


  if(content == "tvEpisode"){
    url <- "https://datasets.imdbws.com/title.episode.tsv.gz"
    dest <- "data/title.episode.tsv.gz"
    download.file(url, dest)
    gunzip(dest)
    title_ep <- read_delim("data/title.episode.tsv", 
                           "\t", escape_double = FALSE, trim_ws = TRUE)
    
    title_db <- left_join(title_database, title_ep, by="tconst")
    file.remove("data/title.episode.tsv")
    title_database <- title_db
    rm(title_db)
  }
  
  write.csv(title_database, file_name)
  rm(title_basics, title_ratings)
  rm(title_database)
  
  
 return(file_name)
  
}

# Use the function to refresh movies and TV
refresh_imdbTable(content="tvEpisode", start = 1988)
refresh_imdbTable(content="movie", start = 1940)
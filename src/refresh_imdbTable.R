# This function retrieves IMDB data and puts it in a server location for future
# use.


refresh_imdbTable <- function() {
library(R.utils)
library(readr)
library(tidyverse)
library(RMySQL)

Encoding(title_database$primaryTitle) <- "UTF-8"

head(title_database$primaryTitle,25)

url <- "https://datasets.imdbws.com/title.basics.tsv.gz"
dest <- "~/Downloads/title.basics.tsv.gz"
download.file(url, dest)
gunzip(dest)

title_basics <- read_delim("~/Downloads/title.basics.tsv", 
                           "\t", escape_double = FALSE, 
                           col_types = cols(isAdult = col_character(),
                                            startYear = col_character()), 
                           trim_ws = TRUE,
                           locale = locale(encoding = 'UTF-8'))

file.remove("~/Downloads/title.basics.tsv")

url <- "https://datasets.imdbws.com/title.ratings.tsv.gz"
dest <- "~/Downloads/title.ratings.tsv.gz"
download.file(url, dest)
gunzip(dest)

title_ratings <- read_delim("~/Downloads/title.ratings.tsv", 
                            "\t", escape_double = FALSE, trim_ws = TRUE,
                            locale = locale(encoding = 'UTF-8'))

file.remove("~/Downloads/title.ratings.tsv")


updateTime <- Sys.time()

title_basics$startYear <- as.numeric(title_basics$startYear)
title_basics$runtimeMinutes <- as.numeric(title_basics$runtimeMinutes)


title_database <- title_basics %>%
  filter(startYear > 1940 & startYear < 2019) %>%
  filter(isAdult == 0 & titleType=="movie") %>%
  select(-endYear, -isAdult, -titleType)

rm(title_basics, title_ratings)

title_database$genres <- type.convert(title_database$genres, na.strings="\\N")

title_database <- left_join(title_database, title_ratings, by = "tconst")
title_database$lastUpdate <- updateTime

rm(title_ratings)


mychannel <- dbConnect(MySQL(), 
                       user="kevdev", 
                       dbname = "univ.db", 
                       password = "kevdev01", 
                       host="192.168.1.110")

table_state <- dbExistsTable(mychannel, "imdbTable")

if(table_state) {
  dbRemoveTable(mychannel, "imdbTable")
}

dbWriteTable(mychannel, "imdbTable", title_database, fileEncoding="UTF-8")
table_state <- dbExistsTable(mychannel, "imdbTable")

dbDisconnectAll()

rm(title_database)
}
# Move this function to calling a db (store in db for the long term, add a function
# to update DB periodically)

gen_moviedb <- function(start_year, end_year, min_votes = 0){
  library(tidyverse)
  library(stringr)
  
  title.basics <- 
    read.delim2("~/Dropbox (CSU Fullerton)/gitproj/moviedata/data/title.basics.tsv",
                stringsAsFactors = FALSE)
  
  title.ratings <- 
    read.delim("~/Dropbox (CSU Fullerton)/gitproj/moviedata/data/title.ratings.tsv",
               stringsAsFactors = FALSE)

  title.basics$startYear <- as.numeric(title.basics$startYear)
  title.basics$runtimeMinutes <- as.numeric(title.basics$runtimeMinutes)
  
  title_database <- title.basics %>%
    filter(startYear > start_year & startYear < end_year) %>%
    filter(isAdult == 0 & titleType=="movie") %>%
    select(-endYear, -isAdult, -titleType)
  
  title_database$genres <- type.convert(title_database$genres, na.strings="\\N")
  
  title_database <- left_join(title_database, title.ratings, by = "tconst")

  if(min_votes>0) {
    title_database <- title_database %>%
      filter(!is.na(numVotes)) %>%
      filter(numVotes > min_votes-1)
  }
  
  return(title_database)

}
  
  
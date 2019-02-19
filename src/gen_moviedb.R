# Move this function to calling a db (store in db for the long term, add a function
# to update DB periodically)

gen_moviedb <- function(start_year, end_year, min_votes = 0){
  library(tidyverse)
  library(stringr)
  library(RMySQL)
  
  mychannel <- dbConnect(MySQL(), 
                         user="kevdev", 
                         dbname = "univ.db", 
                         password = "kevdev01", 
                         host="192.168.1.110")
  
  dbSendQuery(mychannel, "SET NAMES utf8mb4;")
  dbSendQuery(mychannel, "SET CHARACTER SET utf8mb4;")
  dbSendQuery(mychannel, "SET character_set_connection=utf8mb4;")
  
  table_state <- dbExistsTable(mychannel, "imdbTable")
  
  title_database <- dbReadTable(mychannel, "imdbTable", fileEncoding="UTF-8")

    if(min_votes>0) {
    title_database <- title_database %>%
      filter(!is.na(numVotes)) %>%
      filter(numVotes > min_votes-1)
  }
  
  return(title_database)

}
  
  
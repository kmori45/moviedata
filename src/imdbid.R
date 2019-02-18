library(tidyverse)
library(stringr)
library(stringdist)

source('src/get_movie_master.R', echo=FALSE)

movie_database <- get_movie_master()

movie_database$pTitleSimple <- str_to_upper(movie_database$primaryTitle)
movie_database$oTitleSimple <- str_to_upper(movie_database$originalTitle)

movie_database <- movie_database %>%
  filter(numVotes > 0)

movielist <- 
  read.csv("~/Dropbox (CSU Fullerton)/gitproj/data539/output/movielist.csv") %>%
  mutate(Media.Name.Upper = str_to_upper(Media.Name))

movielist_1 <- left_join(movielist, movie_database, by=c("Media.Name"= "primaryTitle"))

movielist_unmatched <- movielist_1 %>%
  filter(is.na(tconst)) %>%
  select(1:7)

full_match <- movielist_1 %>%
  filter(!is.na(tconst)) %>%
  group_by(X)

group_count <- full_match %>%
  summarize(grp_count = n())

dup_match <- left_join(full_match, group_count, by="X") %>%
  filter(grp_count > 1)

full_match <- left_join(full_match, group_count, by="X") %>%
  filter(grp_count == 1)

unique(dup_match$X)

rm(movielist_1)

movielist_2 <- left_join(movielist_unmatched, movie_database, by=c("Media.Name.Upper"= "pTitleSimple"))

movielist_unmatched <- movielist_2 %>%
  filter(is.na(tconst)) %>%
  select(1:7)
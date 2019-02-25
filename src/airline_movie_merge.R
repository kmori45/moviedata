library(readr)
library(tidyverse)

# Load data from media load SQL
media_load_titles <- read_csv("data/media_load_titles.csv")

# Load mid-uniqueID lookup table
mid_uniqueID_lookup <- 
  read.csv("data/mid_uniqueID_lookup.csv")

mid_lookup <- mid_uniqueID_lookup[,c(1,2,3,19)]

# Append UniqueID to media load table
media_load_titles <- left_join(media_load_titles, mid_lookup, by="MID") %>%
  filter(!is.na(uniqueID))

# Generate broad categories of stuff
other_stuff <- c("map", "advert", "promo", "safety", "graphic", "trailer", "dvd")
tv <- c("base_tvepisode","tvseries","tvepisode")
movie <- c("base_movie","movie")

media_load_titles$category[media_load_titles$contenttype %in% other_stuff] <- "Other"
media_load_titles$category[media_load_titles$contenttype %in% tv] <- "Television"  
media_load_titles$category[media_load_titles$contenttype %in% movie] <- "Movie"  

# Load data from airlines usage
Media_usage_raw_ES_data_nov <- read.csv("data/Media_usage_raw_ES_data_nov.csv")

media_airplane_titles <- Media_usage_raw_ES_data_nov %>%
  select(Media.Content.Type.Name, Media.Name, Media.Language.Name, 
         Media.Parent.Name, Usage.Type.Name, Media.Unique.ID) %>%
  unique()

#Note: These are IDs from the airplane data that are not in the media load data
tail_nonmatch <- anti_join(media_airplane_titles, media_load_titles, by=c("Media.Unique.ID"="uniqueID")) %>%
  unique() 

nonmatch_summary <- tail_nonmatch %>%
  group_by(Media.Content.Type.Name) %>%
  summarize(n())

barplot(nonmatch_summary$`n()`,names.arg = nonmatch_summary$Media.Content.Type.Name)
nonmatch_summary

# Add movie non-matches to media load (so we can classify them)
movie_nonmatch <- tail_nonmatch[tail_nonmatch$Media.Content.Type.Name=="Movie",] %>%
  select(Media.Unique.ID, Media.Name) %>%
  mutate(category = "Movie", year=NA, countryOrigin=NA, genre=NA, peopleScore=NA, criticScore = NA) %>%
  rename(uniqueID = Media.Unique.ID, mediaTitle = Media.Name)

movie_load <- media_load_titles %>%
  filter(category == "Movie") %>%
  select(uniqueID, title, category, year, genre, countryOrigin, peopleScore, criticScore) %>%
  rename(mediaTitle = title)

movie_uniqueID <- rbind(movie_nonmatch, movie_load) %>%
  unique() %>%
  filter(uniqueID != "sqm111800179m4")

#Write UniqueID classifiers into a file
write.csv(movie_uniqueID, "output/movie_uniqueID.csv", row.names = FALSE)

# Add TV non-matches to media load (so we can classify them)
tv_nonmatch <- tail_nonmatch[tail_nonmatch$Media.Content.Type.Name=="TV Episode",] %>%
  select(Media.Unique.ID, Media.Name) %>%
  mutate(category = "Television", year=NA, countryOrigin=NA, genre=NA, peopleScore=NA, criticScore = NA) %>%
  rename(uniqueID = Media.Unique.ID, mediaTitle = Media.Name)

tv_load <- media_load_titles %>%
  filter(category == "Television") %>%
  select(uniqueID, title, category, year, genre, countryOrigin, peopleScore, criticScore) %>%
  rename(mediaTitle = title)

tv_uniqueID <- rbind(tv_nonmatch, tv_load) %>%
  unique() %>%
  filter(mediaTitle != "New A380 Suites") %>%
  filter(mediaTitle != "Passenger Health Advisory Taipei")

#Write UniqueID classifiers into a file
write.csv(tv_uniqueID, "output/tv_uniqueID.csv", row.names = FALSE)

#Start uniqueID game category (these won't be classified in anything but "games")
gamelist <- c("Game", "game_android")

game_uniqueID <- 
  tail_nonmatch[tail_nonmatch$Media.Content.Type.Name %in% gamelist,] %>%
  select(Media.Unique.ID, Media.Name) %>%
  mutate(category = "Game") %>%
    rename(uniqueID = Media.Unique.ID, mediaTitle = Media.Name) %>%
  unique()

#Start uniqueID music category (these won't be classified in anything but "music")
music_uniqueID <- 
  tail_nonmatch[tail_nonmatch$Media.Content.Type.Name =="Track",] %>%
  select(Media.Unique.ID, Media.Name) %>%
  mutate(category = "Music") %>%
  rename(uniqueID = Media.Unique.ID, mediaTitle = Media.Name) %>%
  unique()

#Start uniqueID other category (these won't be classified in anything but "other")
otherlist <- c("Advert","Graphic", "promo", "Trailer","UNKNOWN")

other_tail <- 
  tail_nonmatch[tail_nonmatch$Media.Content.Type.Name %in% otherlist,] %>%
  select(Media.Unique.ID, Media.Name) %>%
  mutate(category = "Other") %>%
  rename(uniqueID = Media.Unique.ID, mediaTitle = Media.Name)

other_load <- media_load_titles %>%
  filter(category == "Other") %>%
  select(uniqueID, title, category) %>%
  rename(mediaTitle = title)

other_uniqueID <- rbind(other_tail, other_load, music_uniqueID, game_uniqueID) %>%
  filter(uniqueID != "") %>%
  unique()

#Write UniqueID classifiers into a file
write.csv(other_uniqueID, "output/other_uniqueID.csv", row.names = FALSE)


library(tidyverse)

# Load data from airlines usage
Media_usage_raw_ES_data_nov <- read.csv("data/Media_usage_raw_ES_data_nov.csv")

testfile <- data.frame(Media_usage_raw_ES_data_nov$Media.Unique.ID) 
colnames(testfile) <- "uniqueID"

testfile <- testfile %>%
  filter(uniqueID != "")

movie_uniqueID <- 
  read.csv("output/movie_uniqueID.csv")

tv_uniqueID <- 
  read.csv("output/tv_uniqueID.csv")

other_uniqueID <- 
  read.csv("output/other_uniqueID.csv")

matchfile <- rbind(movie_uniqueID[,1:2], tv_uniqueID[,1:2], other_uniqueID[,1:2])

id_count <- matchfile %>%
  group_by(uniqueID) %>%
  summarize(count = n())

#z should be the same length as testfile
z <- left_join(testfile, matchfile, by="uniqueID")
dim(z)[1] == dim(testfile)[1]

z_miss <- z %>%
  filter(is.na(mediaTitle)) # z_miss should be 0
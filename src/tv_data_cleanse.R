library(readr)
library(tidyverse)

# Get TV Episode database
tvEpisode_db <- read.csv("data/tvEpisode_db.csv", stringsAsFactors=FALSE)

# TV Episode database cleanse
tvEpisode_db$seasonNumber <- as.numeric(tvEpisode_db$seasonNumber)
tvEpisode_db$episodeNumber <- as.numeric(tvEpisode_db$episodeNumber)
tvEpisode_db$matchTitle <- toupper(tvEpisode_db$primaryTitle)

# TV episode match data
tv_uniqueID <- read.csv("output/tv_uniqueID.csv", stringsAsFactors = FALSE)

#Clean critic and people scores (numeric, NA for invalid values)
tv_uniqueID$year <- as.numeric(tv_uniqueID$year)
tv_uniqueID$criticScore <- as.numeric(tv_uniqueID$criticScore)
tv_uniqueID$peopleScore <- as.numeric(tv_uniqueID$peopleScore)

# Clean country of origin data
x1 <- str_replace_all(tv_uniqueID$countryOrigin, "\\)","")
y1 <- unlist(str_split_fixed(x1,"\\(",n=3))
z1 <- matrix(ifelse(str_length(y1)==3,y1,""), ncol = 3, byrow=FALSE)
s1 <- paste(z1[,1],z1[,2],z1[,3],sep="")
tv_uniqueID$countryOrigin <- s1
tv_uniqueID$countryOrigin[tv_uniqueID$countryOrigin==""]<- NA
rm(y1, z1, s1, x1)

tvSeries_db <- read.csv("data/tvSeries_db.csv", stringsAsFactors=FALSE)

#Create headers for TV Shows
tv_headers <- tv_uniqueID %>%
  filter(!str_detect(uniqueID, "m4|w4")) %>%
  select(-uniqueID, -parentTitle, -category) %>%
  unique() %>%
  left_join(tvSeries_db[,c(3,5)],by=c("mediaTitle" = "primaryTitle")) %>%
  mutate(s_year = ifelse(is.na(year), startYear, year)) %>%
  select(-year, -startYear) %>%
  rename(year = s_year) %>%
  unique()


#Memo: This is to prevent duplicate titles.  Normally, this is NOT optimal...
tv_headers$peopleScore[tv_headers$mediaTitle=="Fresh Off the Boat S04"]<- 8.01
tv_headers$peopleScore[tv_headers$mediaTitle=="Bob's Burgers S08"]<- 8.11
tv_headers$year[tv_headers$mediaTitle=="Arrested Development S02"]<- 2004
tv_headers$year[tv_headers$mediaTitle=="How I Met Your Mother S02"]<- 2006

tv_episodes <- tv_uniqueID %>%
  filter(str_detect(uniqueID, "m4|w4")) %>%
  mutate(new_title = NA)

tv_match_final <- tv_episodes %>%
  filter(!is.na(parentTitle)) %>%
  mutate(new_title = parentTitle)

tv_unmatched <- tv_episodes %>%
  filter(is.na(parentTitle)) 

rm(tv_episodes)

tv_ep2 <- left_join(tv_unmatched, tv_headers,
          by = c("year", "countryOrigin", "genre", "peopleScore", "criticScore")) %>%
          mutate(new_title = mediaTitle.y) %>%
          select(-mediaTitle.y)

tv_match2 <- tv_ep2 %>%
  filter(!is.na(new_title)) %>%
  rename(mediaTitle = mediaTitle.x)

tv_match_final <- rbind(tv_match_final, tv_match2)

rm(tv_match2)

tv_unmatched2 <- tv_ep2 %>%
  filter(is.na(new_title))

rm(tv_ep2, tv_unmatched)

t <- str_split(tv_unmatched2$mediaTitle.x, "\\(")
k <- str_extract_all(tv_unmatched2$mediaTitle.x, "(?<=\\().+?(?=\\))")
x <- matrix(rep(NA,length(k)*2), ncol = 2)
title <- rep(NA, length(k))
for(i in 1:length(k)) {
 
  if(!is_empty(k[[i]])){
    x[i,] <- unlist(str_split(k[[i]],","))
    if(str_sub(x[i,1],1,1) == 'S'){
      x[i,1] <- str_sub(x[i,1],2,3)
    } else {
      x[i,1] <- NA 
    }
    
    if(str_sub(trimws(x[i,2]),1,2) == 'Ep'){
      x[i,2] <- str_sub(trimws(x[i,2]),3,4)
    } else {
      x[i,2] <- NA 
    }
  }
  title[i] <- t[[i]][1]
}

tv_unmatched2$season <- as.numeric(x[,1])
tv_unmatched2$episode <- as.numeric(x[,2])
tv_unmatched2$new_title <- toupper(trimws(title))
rm(x,k,t)
rm(i,title)


match_join <- left_join(tv_unmatched2, tvEpisode_db, 
                       by=c("new_title" = "matchTitle",
                            "year" = "startYear",
                            "season" = "seasonNumber",
                           "episode" = "episodeNumber")) %>%
                          filter(!is.na(tconst))

match_join <- match_join[-which(duplicated(match_join$uniqueID)),]

match3 <- left_join(match_join, tvSeries_db, by=c("parentTconst"="tconst")) %>%
  select(uniqueID, mediaTitle.x, parentTitle, category, year, countryOrigin, genre, peopleScore, criticScore, primaryTitle.y) %>%
  rename(mediaTitle = mediaTitle.x, new_title = primaryTitle.y)

tv_match_final <- rbind(tv_match_final, match3)

tv_unmatched3 <- anti_join(tv_unmatched2, tvEpisode_db, 
                        by=c("new_title" = "matchTitle",
                             "year" = "startYear",
                             "season" = "seasonNumber",
                             "episode" = "episodeNumber")) %>%
  mutate(new_title = "Unknown TV Show") %>%
  rename(mediaTitle = mediaTitle.x) %>%
  select(-season, -episode)

tv_match_final <- rbind(tv_match_final, tv_unmatched3)

write.csv(tv_match_final, "data/tv_clean.csv", row.names = FALSE)


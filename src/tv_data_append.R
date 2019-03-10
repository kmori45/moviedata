library(rjson)
library(readr)

#Read in TV Series database
tvSeries_db <- read_csv("data/tvSeries_db.csv") %>%
  mutate(primaryTitle = toupper(primaryTitle))

tvRatings <- read.csv("data/title_ratings.csv", stringsAsFactors = FALSE)[,-1]

# Read in cleaned TV titles
tv_data <- read.csv("data/tv_clean.csv")

# Seperate out Singapore airlines promo videos
promo_titles <- c("The Singapore Airlines Experience","Destination Guides")

singapore_promo <- tv_data %>%
  filter(parentTitle %in% promo_titles) %>%
  mutate(countryOrigin = "SGP", genre = "travel") %>%
  mutate(peopleScore = ifelse(is.na(peopleScore),0,peopleScore)) %>%
  mutate(criticScore = ifelse(is.na(criticScore),0,criticScore)) %>%
  mutate(year = ifelse(is.na(year),2018,year)) %>%
  rename(clusterTitle = new_title) %>%
  unique()

# Append movies #1: Movies without any descriptions
append1 <- tv_data %>%
  filter(is.na(genre) & is.na(countryOrigin)) %>%
  filter(!parentTitle %in% promo_titles) %>%
  mutate(new_title = toupper(new_title))

# Append movies #2: Movies that just need a little bit of imputation
append2 <- tv_data %>%
  filter(!is.na(genre) | !is.na(countryOrigin)) %>%
  filter(!parentTitle %in% promo_titles)


# Working on append 1 (clean special characters):
append1$new_title <- str_replace_all(append1$new_title, "’", "'")
append1$new_title <- str_replace_all(append1$new_title, "&", "AND")
append_temp <- str_split(append1$new_title, "([S])+([0-9])+([0-9])")
append <- rep(NA, length(append_temp))

for(i in 1:length(append_temp)){
  append[i] <- trimws(append_temp[[i]][1])
}

append1$new_title <- append
rm(tv_data, append_temp, append, promo)


# Find a corresponding imdb ID first
t_append <- left_join(append1, tvSeries_db, by=c("new_title" = "primaryTitle"))

match1 <- t_append %>%
  filter(!is.na(originalTitle)) %>%
  left_join(tvRatings, by="tconst")
  
dupID <- as.character(match1$uniqueID[duplicated(match1$uniqueID)])

match_final <- match1 %>%
  filter(!uniqueID %in% dupID)

match_dup <- match1 %>%
  filter(uniqueID %in% dupID) %>%
  group_by(uniqueID) %>%
  arrange(.by_group = TRUE, desc(numVotes)) %>%  
  filter(numVotes == first(numVotes))

match_final <- bind_rows(match_final, match_dup) %>%
  mutate(year = startYear, genre=genres, peopleScore = averageRating) %>%
  rename(clusterTitle = new_title) %>%
  select(1:12) %>%
  select(-X1)

match_url1 <- "https://api.themoviedb.org/3/find/"

match_url2 <- "?api_key=21e37387d991ff52e92a225c5b297b1a&language=en-US&external_source=imdb_id"

match_url <- paste(match_url1, match_final$tconst, match_url2, sep="") %>%
  unique()
origin_store <- rep(NA, length(match_url))

for(i in 1:length(match_url)){

  x <- fromJSON(file=match_url[i])

  if(length(x$tv_results) != 0) {
    if(length(x$tv_results[[1]]$origin_country) != 0) {
    origin_store[i] <- x$tv_results[[1]]$origin_country
  }
}
}

origin_store <- data.frame(cbind(unique(match_final$tconst), origin_store))
iso_country <- read.csv("data/iso_country.csv")

match_final <- left_join(match_final, origin_store, by=c("tconst"="V1")) %>%
  left_join(iso_country[,2:3], by=c("origin_store" = "alpha.2")) %>%
  mutate(countryOrigin = alpha.3) %>%
  select(-origin_store, -alpha.3)

unmatch1 <- t_append %>%
  filter(is.na(originalTitle)) %>%
  select(1:10) %>%
  rename(clusterTitle=new_title) 

append2 <- append2 %>%
  mutate(countryOrigin = ifelse(is.na(countryOrigin), "USA", as.character(countryOrigin))) %>%
  rename(clusterTitle = new_title)


final_append_table <- singapore_promo %>%
  bind_rows(match_final) %>%
  bind_rows(append2) %>%
  bind_rows(unmatch1) %>%
  select(-parentTitle) %>%
  rename(parentTitle = clusterTitle) %>%
  select(1:8,10,9) %>%
  mutate(countryOrigin = ifelse(countryOrigin == "NAM",NA,countryOrigin))


write.csv(final_append_table, "output/appended_tvID.csv", row.names = FALSE)

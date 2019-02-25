library(tidyverse)
library(rjson)
library(stringr)

#Load IMDB movie database
movie_db <- read.csv("data/movie_db.csv")

#Load media titles for evaluation and matching
media_load_final <- read.csv("output/movie_uniqueID.csv")

# Remove years in parenthesis for some titles
media_load_final$title_match <- trimws(sub("\\(.*", "", media_load_final$mediaTitle))

#Clean critic and people scores (numeric, NA for invalid values)
media_load_final$peopleScore <- as.character(media_load_final$peopleScore)
media_load_final$peopleScore <- as.numeric(media_load_final$peopleScore)

media_load_final$criticScore <- as.character(media_load_final$criticScore)
media_load_final$criticScore <- as.numeric(media_load_final$criticScore)

#Begin the process of appending IMDB IDs
movielist_1 <- left_join(media_load_final, movie_db, 
                         by=c("title_match"= "primaryTitle", "year"="startYear") )

movielist_2 <- movielist_1 %>%
  filter(is.na(tconst)) %>%
  select(1:11)

full_match <- movielist_1 %>%
  filter(!is.na(tconst)) %>%
  group_by(uniqueID)

group_count <- full_match %>%
  summarize(grp_count = n())

dup_match <- left_join(full_match, group_count, by="uniqueID") %>%
  filter(grp_count > 1) %>%
  select(-grp_count)

full_match <- left_join(full_match, group_count, by="uniqueID") %>%
  filter(grp_count == 1) %>%
  select(-grp_count, -lastUpdate,-X, -title_match)

# Manage duplicate matches here
dup_append <- dup_match %>%
  filter(numVotes == max(numVotes))

full_match <- rbind(full_match, dup_append)

#filter out arts and music (live performances) that don't have metadata
arts_match <- movielist_2 %>%
  filter(genre == "Arts, Music & Culture")

movielist_2 <- movielist_2 %>%
  filter(genre != "Arts, Music & Culture" | is.na(genre))

# Continue to process unmatches

#Generate API URLs for each unmatched movie
url1 <- paste("https://api.themoviedb.org/3/search/movie?api_key=21e37387d991ff52e92a225c5b297b1a&query=",sep="")
name_list <-unique(trimws(movielist_2$title_match))
name_list <- str_replace_all(name_list, " ", "+")

url_vector <- paste(url1, name_list, sep="")

#Create vectors to store return data
n <- length(url_vector)  
z <- rep(NA, n)
w <- rep(NA, n)

#Call API for each movie, return the TMDB ID and TMDB title
for(i in 1:n) {
  
  x <- fromJSON(file=url_vector[i])
  
  if(as.numeric(x$total_results) > 0) {
    z[i] <- x$results[[1]]$title
    w[i] <- x$results[[1]]$id    

  }
}

name_list <- cbind(name_list, z,w)

match_list <- cbind(movielist_2, name_list)

tmdb_match <- match_list %>%
  filter(!is.na(w))

movielist_3 <- match_list %>%
  filter(is.na(w))





#Match TMDB ID with IMDB ID
url2 <- paste("https://api.themoviedb.org/3/movie/",sep="")
imdb_list <-as.character(tmdb_match$w)
url3 <- paste("?api_key=21e37387d991ff52e92a225c5b297b1a", sep="")

imdb_url <- paste(url2, imdb_list, url3, sep="")

imdb_id <- rep(NA, length(imdb_url))

for(i in 1:length(imdb_url)) {
  b <- fromJSON(file=imdb_url[i])  
    if(!is.null(b[["imdb_id"]])) {
      imdb_id[i] <- b[["imdb_id"]]    
    }
}

tmdb_match$imdb_id <- imdb_id

match_list <- left_join(tmdb_match, movie_db, by=c("imdb_id"="tconst"))

imdb_match <- match_list %>%
  filter(!is.na(imdb_id) & imdb_id != "")

movielist_4 <- match_list %>%
  filter(is.na(imdb_id) | imdb_id=="")

#Merge movielist_3 and movielist_4, consider them unclassifiable.
unamtch_list <- rbind(movielist_3[,1:9], movielist_4[,1:9])
rm(movielist_1,movielist_2,movielist_3,movielist_4,tmdb_match,name_list,
   dup_append, b,x, group_count, dup_match, match_list)

#merge imdb_match and full_match
final_match_1 <- full_match[,1:14] %>%
  select(-originalTitle, -genres) %>%
  rename(imdbID = tconst, imdbRating = averageRating, imdbVotes = numVotes)

#imdb_match$year[is.na(imdb_match$year)] <- as.character(imdb_match$startYear)
imdb_final <- imdb_match
imdb_final$year <- ifelse(is.na(imdb_final$year),imdb_final$startYear,imdb_final$year)

split_test <- str_split(imdb_final$genres,",")

imdb_final$new_genre <- sapply(split_test, "[[", 1)
imdb_final$genre <- ifelse(is.na(imdb_final$genre),imdb_final$new_genre,as.character(imdb_final$genre))

imdb_final <- imdb_final %>%
  select(uniqueID, mediaTitle, category, year, countryOrigin, genre, peopleScore, criticScore,
         imdb_id, runtimeMinutes, averageRating, numVotes) %>%
        rename(imdbID = imdb_id, imdbRating = averageRating, imdbVotes = numVotes)

arts_match <- arts_match %>%
  select(uniqueID, mediaTitle, category, year, countryOrigin, genre, peopleScore, criticScore) %>%
  mutate(imdbID=NA, runtimeMinutes=NA, imdbRating=NA, imdbVotes=NA)

unmatch_list <- unamtch_list %>%
  select(-title_match) %>%
  mutate(imdbID=NA, runtimeMinutes=NA, imdbRating=NA, imdbVotes=NA)

final_match <- bind_rows(final_match_1, imdb_final, arts_match, unmatch_list)

rm(final_match_1, imdb_final,split_test, full_match, imdb_match,
   arts_match, unmatch_list)

write.csv(final_match, "output/matched_movie_uniqueID.csv", row.names = FALSE)


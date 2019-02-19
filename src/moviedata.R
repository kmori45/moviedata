library(rjson)


source('src/gen_moviedb.R')

# Generate movie database from daily imdb datafiles.  This avoids excessive
# calls to the OMDB and TMDB API

movie_ref_db <- gen_moviedb(1990, 2019, min_votes = 10)

#Get list of movies to match up
movielist <- 
  read.csv("~/Dropbox (CSU Fullerton)/gitproj/data539/output/movielist.csv")

# Begin the title match process with perfect matches (1:1)

movielist_1 <- left_join(movielist, movie_ref_db, 
                         by=c("Media.Name"= "primaryTitle"))

movielist_2 <- movielist_1 %>%
  filter(is.na(tconst)) %>%
  select(2:6)

full_match <- movielist_1 %>%
  filter(!is.na(tconst)) %>%
  group_by(X)

group_count <- full_match %>%
  summarize(grp_count = n())

dup_match <- left_join(full_match, group_count, by="X") %>%
  filter(grp_count > 1) %>%
  select(-grp_count)

full_match <- left_join(full_match, group_count, by="X") %>%
  filter(grp_count == 1) %>%
  select(-grp_count)

rm(group_count, movielist_1, movielist)

# Manage duplicate matches here



# Continue to process unmatches

url1 <- paste("https://api.themoviedb.org/3/search/movie?api_key=21e37387d991ff52e92a225c5b297b1a&query=",sep="")
name_list <-unique(trimws(movielist_2$Media.Name))
name_list <- str_replace_all(name_list, " ", "+")

url_vector <- paste(url1, name_list, sep="")

n <- length(url_vector)  
z <- rep(NA, n)
w <- rep(NA, n)

for(i in 1:n) {
  
  x <- fromJSON(file=url_vector[i])
  
  if(as.numeric(x$total_results) > 0) {
    z[i] <- x$results[[1]]$title
    w[i] <- x$results[[1]]$id    
    
  }
  Sys.sleep(0.250)
}

name_list <- cbind(name_list, z,w)





  
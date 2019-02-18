source('src/gen_moviedb.R')

# Generate movie database from daily imdb datafiles.  This avoids excessive
# calls to the OMDB and TMDB API

movie_ref_db <- gen_moviedb(1990, 2019, min_votes = 10)

#Get list of movies to match up
movielist <- 
  read.csv("~/Dropbox (CSU Fullerton)/gitproj/data539/output/movielist.csv")
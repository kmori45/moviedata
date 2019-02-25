library(rjson)
library(tidyverse)

final_match <- read.csv("output/matched_movie_uniqueID.csv", stringsAsFactors = FALSE)

#data cleansing: Add country of origin

omdb_api_intro <- "http://www.omdbapi.com/?i="
omdb_footer <- "&apikey=fa0778c7"

omdb_api_url <- paste(omdb_api_intro,
                      final_match$imdbID,
                      omdb_footer,
                      sep = "")

n <- length(omdb_api_url)

country <- rep(NA, n)
awards <- rep(NA, n)
boxoffice <- rep(NA, n)
rated <- rep(NA, n)
response <- rep(NA, n)
metascore <- rep(NA, n)


for(i in 1:n){

  x <- fromJSON(file=omdb_api_url[i])
  
  country[i] <- ifelse(length(x$Country)==0,NA,x$Country)
    
}

split_test <- str_split(country,",")
new_split <- data.frame(sapply(split_test, "[[", 1))
colnames(new_split) <- "countryName"

country_title <- read.csv("data/cntry.csv",stringsAsFactors = FALSE)

ocountry <- left_join(new_split, country_title, by=c("countryName"="Title"))$ISO
final_match$oCountry <- ocountry
x <- str_replace_all(final_match$countryOrigin, "\\)","")
y <- unlist(str_split_fixed(x,"\\(",n=3))
z <- matrix(ifelse(str_length(y)==3,y,""), ncol = 3, byrow=FALSE)
s <- paste(z[,1],z[,2],z[,3],sep="")
s[s==""] <- NA
final_match$countryOrigin <- s

final_match$countryOrigin <- ifelse(is.na(final_match$countryOrigin),final_match$oCountry,final_match$countryOrigin)

write.csv(final_match, "output/appended_movieID.csv")
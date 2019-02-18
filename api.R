library(rjson)

url <- paste("http://www.omdbapi.com/?i=tt1216496&apikey=fa0778c7", sep = "")

x <- as.data.frame(fromJSON(file=url))



url2 <- paste("https://api.themoviedb.org/3/search/movie?api_key=21e37387d991ff52e92a225c5b297b1a&query=Crayon+Shin-chan",sep="")

z1 <- fromJSON(file=url2)

z1
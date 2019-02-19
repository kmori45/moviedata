library(rjson)

url <- paste("http://www.omdbapi.com/?i=tt1216496&apikey=fa0778c7", sep = "")

x <- as.data.frame(fromJSON(file=url))

url2 <- paste("https://api.themoviedb.org/3/search/movie?api_key=21e37387d991ff52e92a225c5b297b1a&query=A+Beautiful+Moment",sep="")

z <- fromJSON(file=url2)$results[[1]]$title

con <- dbConnect(MySQL(),
                 user="kevdev", password="kevdev01",
                 dbname="univ.db", host="192.168.1.110")

on.exit(dbDisconnect(con))
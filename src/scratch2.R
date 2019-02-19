library(readxl)

movielist <- read.csv("~/Dropbox (CSU Fullerton)/gitproj/data539/output/movielist.csv")


movie_det <- read_excel("data/Video Titles from MySQL DUMP tables.xlsx")

movie_2 <- left_join(movielist, movie_det, by=c("Media.Name"= "title"))

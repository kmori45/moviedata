library(dplyr)
movies <- read.csv("~/Dropbox (CSU Fullerton)/gitproj/moviedata/output/appended_movieID.csv")
episodes <- read.csv("~/Dropbox (CSU Fullerton)/gitproj/moviedata/output/appended_tvID.csv")
other <- read.csv("~/Dropbox (CSU Fullerton)/gitproj/moviedata/output/other_uniqueID.csv")

final_list <- bind_rows(movies, episodes,other)

# Testing Protocol #1: No duplicated lines
dup_lines <- sum(duplicated(final_list$uniqueID))


# Did we get all media on that plane?

Media_usage_raw_ES_data_nov <- read_csv("data/Media_usage_raw_ES_data_nov.csv") %>%
  select(`Media Unique ID`, `Media Name`) %>%
  rename(name = `Media Name`, uniqueID = `Media Unique ID`)

ids <- unique(Media_usage_raw_ES_data_nov)

#The only thing that should be in this file are line items with no uniqueID
test_match <- anti_join(ids, final_list, by="uniqueID")

write.csv(final_list, "output/final_list.csv", row.names = FALSE)
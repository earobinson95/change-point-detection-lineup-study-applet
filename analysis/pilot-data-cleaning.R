library(RSQLite)
library(DBI)
library(tidyverse)
library(lubridate)

# Sent out to GG after Study Start time of 1678393962

# Connect to Database ----------------------------------------------------------
filename <- here::here("pilot_cp_lineup_data.db")
sqlite.driver <- dbDriver("SQLite")
db_con <- dbConnect(sqlite.driver,
                    dbname = filename)

dbListTables(db_con)

# Read in data from Database ---------------------------------------------------

users           <- dbReadTable(db_con,"users")
feedback        <- dbReadTable(db_con,"feedback")
picture_details <- dbReadTable(db_con,"picture_details")

# Disconnect from Database -----------------------------------------------------
dbDisconnect(db_con)

# Join Data Sets -----------------------------------------------------

all_data <- users |> 
  full_join(feedback, 
            by = c("ip_address", "nick_name", "study_start_time")
            ) |> 
  full_join(picture_details,
            by = "lineup_id"
            ) |> 
  mutate(correct = ifelse(obs_plot_location == response_no, 1, 0),
         across(c(version, cpLoc, theta, sigma), as.factor))
  # mutate(study_start_time = as.Date(study_start_time))
  

### Test the idb ---------------------------------------------------------------
# n = 210
# bib_id <- tibble(rep = 1:n,
#                  id = NA)
# 
# for(i in 1:n){
#   participant_bib_set <- sample(1:105, size = 1)
#   participant_version <- sample(c("A", "B"), size = 1)
#   bib_id$id[i] <- paste0(participant_version, participant_bib_set)
#   bib_id$assigned[i] <- 1
# }
# 
# bib_unique <- expand_grid(version = c("A", "B"),
#                           set = 1:105) |>
#   mutate(bib_id = paste0(version,set))
# 
# bib_id |>
#   full_join(bib_unique, by = c("id" = "bib_id")) |>
#   mutate(assigned = ifelse(is.na(assigned), 0, assigned)) |>
#   group_by(version, set) |>
#   summarize(nassigned = sum(assigned)) |>
#   ggplot(aes(x = set, y = nassigned, fill = version)) +
#   geom_bar(stat = "identity",
#            position = "stack")

# b = 105
# t = 36
# k = 12

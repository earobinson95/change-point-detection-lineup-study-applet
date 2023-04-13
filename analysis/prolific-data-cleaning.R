library(RSQLite)
library(DBI)
library(tidyverse)
library(lubridate)
library(digest)

# Sent out to GG after Study Start time of 1678393962

# Connect to Database ----------------------------------------------------------
filename <- here::here("cp_lineup_data.db")
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

# all_data <- users |> 
#   full_join(feedback, 
#             by = c("prolific_id", "nick_name")
#             ) |> 
#   left_join(picture_details,
#             by = "lineup_id"
#             ) |>
#   mutate(participant_id = nick_name) |>
#   filter(recruited != "I am the researcher") |>
#   mutate(correct = ifelse(obs_plot_location == response_no, 1, 0),
#          across(c(version, cpLoc, theta, sigma), as.factor)) |> 
#   filter(!is.na(cpLoc), !is.na(sigma), !is.na(theta))
  # mutate(study_start_time = as.Date(study_start_time))


# Distinct prolific_id
distinct_feedback <- feedback |> 
  distinct(prolific_id, study_start_time)
count(distinct_feedback)

distinct_users <- users |> 
  distinct(prolific_id, study_start_time)
count(distinct_users)

full_join(distinct_feedback, distinct_users) |> 
  count()

# Distinct nick_name
distinct_feedback_nn <- feedback |> 
  distinct(nick_name, study_start_time)
count(distinct_feedback_nn)

distinct_users_nn <- users |> 
  distinct(nick_name, study_start_time)
count(distinct_users_nn)

full_join(distinct_feedback_nn, distinct_users_nn) |> 
  count()

# Arrange
users_arrange <- users |> 
  arrange(nick_name, prolific_id, study_start_time) |>  
  select(nick_name, prolific_id, study_start_time)
users_arrange

users_clean <- users |> 
  mutate(prolific_id = case_when(nick_name == "52e036502e079080223d455d44e6c5a6" & prolific_id == "5" ~ "5a",
                                 nick_name == "c9f049a6251236e2e966ca65a0d57bdd" & prolific_id == "5" ~ "5b",
                                 nick_name == "ef93a9feac03335780e1fe78c8329e6b" & prolific_id == "5" ~ "5c",
                                 TRUE ~ prolific_id
                                 )
         ) |> 
  distinct(prolific_id, study_start_time, age, gender, academic_study, health_related, stem_related, recruited, bib_id)

all_data_orig <- feedback |>
  mutate(prolific_id = case_when(nick_name == "52e036502e079080223d455d44e6c5a6" & prolific_id == "5" ~ "5a",
                                 nick_name == "c9f049a6251236e2e966ca65a0d57bdd" & prolific_id == "5" ~ "5b",
                                 nick_name == "ef93a9feac03335780e1fe78c8329e6b" & prolific_id == "5" ~ "5c",
                                 TRUE ~ prolific_id
                                 )
  ) |> 
  left_join(users_clean, 
            by = c("prolific_id", "study_start_time")
  ) |> 
  left_join(picture_details,
            by = "lineup_id"
  ) |>
  rowwise() |> 
  mutate(participant_id = digest(prolific_id)) 

unique(all_data_orig$prolific_id) |> length()
unique(all_data_orig$participant_id) |> length()
dim(feedback)
dim(all_data_orig)

all_data_clean <- all_data_orig|>
  filter(!prolific_id %in% c("9999", "13emily")) |>
  mutate(correct = ifelse(obs_plot_location == response_no, 1, 0),
         across(c(version, cpLoc, theta, sigma), as.factor)) |> 
  # filter(!is.na(cpLoc), !is.na(sigma), !is.na(theta)) |> 
  group_by(participant_id) |> 
  mutate(nlineups = n()) |> 
  ungroup() |> 
  group_by(participant_id, study_start_time) |> 
  mutate(nlineupstime = n()) |> 
  ungroup() |> 
  filter(nlineups >= 12) |> 
  filter(nlineupstime == 12) |> 
  select(participant_id, nlineups, nlineupstime, study_start_time, age, gender, academic_study, health_related, stem_related,
         recruited, bib_id, lineup_order, lineup_start_time, lineup_end_time, lineup_id,
         dataset_id, param_id, mu, theta, cpLoc, sigma, gam, version, obs_plot_location, response_no, correct,
         Tstat, df, pvalue, conf_level, choice_reason, description)

dim(all_data_clean)
nrow(all_data_clean) / 12
unique(all_data_clean$participant_id) |> length()

  

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

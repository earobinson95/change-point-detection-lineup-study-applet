library(RSQLite)
library(DBI)
library(tidyverse)

# Connect to Database ----------------------------------------------------------
filename <- here::here("cp_lineup_data.db")
sqlite.driver <- dbDriver("SQLite")
db_con <- dbConnect(sqlite.driver,
                dbname = filename)

dbListTables(db_con)

# Experiment Details -----------------------------------------------------------
experiment_details <- dbReadTable(db_con,"experiment_details")

# setup original data
experiment_details <- tibble("experiment" = "cp-lineup",
                             "question"   = "Which plot is the most different?",
                             "reasons"    = "Clustering,Different range,Different shape,Different slope,Outlier(s),Other",
                             "lpp"        = 12,
                             "trials_req" = 0
                             )

# replace in db
dbRemoveTable(db_con, "experiment_details")
dbWriteTable(db_con, "experiment_details", experiment_details)

# double check
experiment_details <- dbReadTable(db_con,"experiment_details")
experiment_details

# Feedback ---------------------------------------------------------------------
feedback <- dbReadTable(db_con,"feedback")

# setup original data
feedback <- tibble("prolific_id"       = NA,
                   "ip_address"        = NA,
                   "nick_name"         = NA,
                   "study_start_time"  = NA,
                   "lineup_order"      = NA,
                   "lineup_start_time" = NA,
                   "lineup_end_time"   = NA,
                   "lineup_id"         = NA,
                   "response_no"       = NA,
                   "conf_level"        = NA,
                   "choice_reason"     = NA,
                   "description"       = NA
)

# clear participant feedback
feedback <- feedback[0,]

# replace in db
dbRemoveTable(db_con, "feedback")
dbWriteTable(db_con, "feedback", feedback)

# double check
feedback <- dbReadTable(db_con,"feedback")
feedback

# Picture Details --------------------------------------------------------------
picture_details <- dbReadTable(db_con,"picture_details")

# read in original data
picture_details <- read.csv(here::here("Time Series Change", "lineup-generation", "plots", "picture_details.csv"))

# replace in db
dbRemoveTable(db_con, "picture_details")
dbWriteTable(db_con, "picture_details", picture_details)

# double check
picture_details <- dbReadTable(db_con,"picture_details")
picture_details

# BIB Design -------------------------------------------------------------------
bib_design <- dbReadTable(db_con, "bib_design")

# read in original data
bib_assignments <- read.csv(here::here("Time Series Change", "lineup-generation", "plots", "bib_assignments.csv"))

# assign each parm_id a trt_num 1:36
picture_details <- dbReadTable(db_con,"picture_details")
trt_parm <- picture_details |> 
  select(param_id) |> 
  filter(!str_detect(param_id, pattern = "_0_")) |> 
  distinct(param_id) |> 
  mutate(trt_num = 1:n())

# create bib_design data set that contains:
# bib_id, version, bib_set, order_num, trt_num, param_id, lineup_id
# we will randomly sample a version (A/B) + a bib_set (1:105)
bib_design <- bib_assignments |> 
  mutate(bib_set = 1:n()) |> 
  pivot_longer(cols = c(x1:x12),
               names_to = "order_num",
               values_to = "trt_num"
               ) |> 
  mutate(order_num = as.numeric(str_remove(order_num, "x"))) |> 
  full_join(trt_parm, by = "trt_num") |> 
  expand_grid(version = c("A", "B")) |> 
  mutate(bib_id = paste0(version, bib_set)) |> 
  left_join(picture_details, by = c("version", "param_id")) |> 
  arrange(version, bib_set, order_num) |> 
  select(bib_id, version, bib_set, order_num, trt_num, param_id, lineup_id)

# replace in db
dbRemoveTable(db_con, "bib_design")
dbWriteTable(db_con, "bib_design", bib_design)

# double check
bib_design <- dbReadTable(db_con,"bib_design")
bib_design

# Users ------------------------------------------------------------------------
users <- dbReadTable(db_con,"users")

# setup original data
users <- tibble("prolific_id"       = NA,
                "ip_address"        = NA,
                "nick_name"         = NA,
                "study_start_time"  = NA,
                "bib_id"            = NA,
                "age"               = NA,
                "gender"            = NA,
                "academic_study"    = NA,
                "health_related"    = NA,
                "stem_related"      = NA,
                "recruited"         = NA
)

# clear participant information
users <- users[0,]

# replace in db
dbRemoveTable(db_con, "users")
dbWriteTable(db_con, "users", users)

# double check
users <- dbReadTable(db_con,"users")
users

# Disconnect from Database -----------------------------------------------------
dbDisconnect(db_con)

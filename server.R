# load packages
library(shiny)
library(shinyjs)
library(tidyverse)
library(lubridate)
library(here)
library(RSQLite)
library(DBI)

# add resource paths so Shiny can see them
addResourcePath("plots", "plots")
# addResourcePath("trials", "trials")
addResourcePath("examples", "examples")

# define folders
plots_folder  <- "plots"  # subfolders for data, pdf, png, svg. picture_details.csv in this folder

window_dim_min <- 600 #c(800, 600) # width, height

db_con <- dbConnect(SQLite(), dbname = "cp_lineup_data.db")
experiment_details <- dbReadTable(db_con,"experiment_details")
dbDisconnect(db_con)

shinyServer(function(input, output, session) {

    # randomization: this needs to be run every connection, not just once.
    db_con <- dbConnect(SQLite(), dbname = "cp_lineup_data.db")

    # previous_participant_bibset <-
    # current_participant_bibset  <-

    participant_bib_set <- sample(1:105, size = 1)
    participant_version <- sample(c("A", "B"), size = 1)
    participant_bib_id <- paste0(participant_version, participant_bib_set)

    pic_ids <- dbReadTable(db_con, "bib_design") |>
      filter(bib_id == participant_bib_id) |>
      mutate(pic_order = sample(1:n())) |> 
      arrange(pic_order) |> 
      select(pic_order, lineup_id)

    dbDisconnect(db_con)

    # reactive values to control the trials
    values <- reactiveValues(
        experiment         = experiment_details$experiment,
        question           = experiment_details$question,
        my_picture_details = NULL,
        submitted          = FALSE,
        choice_reason      = NULL,
        reasons            = strsplit(experiment_details$reasons, ",")[[1]],
        study_start_time   = Sys.time(),
        lineup_start_time  = NULL,
        lineup_end_time    = NULL,
        trials_req         = experiment_details$trials_req,
        trials_left        = experiment_details$trials_req,
        lpp                = experiment_details$lpp,
        lpp_left           = experiment_details$lpp,
        lineup_id             = 0,
        correct            = NULL,
        result             = ""
        )

    # Show other text input box if "other" choice reason is selected
    observe({
        if (length(values$reasons) == 1) {
            updateCheckboxInput(session,
                                "otheronly",
                                value = TRUE
                                )
            updateTextInput(session,
                            "other",
                            label = "Reason"
                            )
        }
    })

    # Provide experiment-appropriate reasoning boxes
    observe({
        updateCheckboxGroupInput(session, "reasoning",
                                 choices = values$reasons,
                                 selected = NA
                                 )
    })

    # Only start experiment when consent is provided
    observeEvent(input$beginexp, {
        if (input$consent) updateCheckboxInput(session, "welcome", value = TRUE)
    })

    # Provide a message if the browser is too small
    observeEvent(input$dimension, {
        if (any(input$dimension < window_dim_min))
            showModal(
                modalDialog(
                    title = "Window Size is too small",
                    sprintf("You must view this experiment in a browser window which is at least %s x %s", window_dim_min, window_dim_min),
                    size = "s",
                    easyClose = T
                )
            )
        else {
            removeModal()
        }
    })

    # Title header
    output$welcome_header <- renderText("Welcome to a Survey on Graphical Inference")

    # ---- Introduction --------------------------------------------------------
    # Welcome text and instructions
    output$welcome_text <- renderUI({
        HTML("This web site is designed to conduct a survey on graphical inference which will help us understand human perception of graphics for use in communicating statistics.
             <br/><br/>
             The following examples illustrate the types of questions you may encounter during this experiment.")
    })

    # ---- Example -------------------------------------------------------------
    output$example1_q <- renderText({
        return(paste0("Example 1: ", values$question))
    })

    output$example1_plot <- renderImage({
        if (is.null(values$experiment)) return(NULL)

        list(src = file.path("examples", "example1.png"),
             contentType = 'image/png',
             style = "max-width:100%; max-height = 100%")
    }, deleteFile = FALSE)

    output$example1_a <- renderUI({
        return(HTML(paste0("
            Your choice: <b>Plot 4</b><br/>
            Reasoning: <b>", values$reasons[1], "</b><br/>
            How certain are you: <b>Very Certain</b><br/>
        ")))
    })

    output$example2_q <- renderText({
        return(paste0("Example 2: ", values$question))
    })

    output$example2_plot <- renderImage({
        if (is.null(values$experiment)) return(NULL)

        list(src = file.path("examples", "example2.png"),
             contentType = 'image/png',
             style = "max-width:100%; max-height = 100%")
    }, deleteFile = FALSE)

    output$example2_a <- renderUI({
        return(HTML(paste0("
                    Your choice: <b>Plot 1</b><br/>
                    Reasoning: <b>", values$reasons[2], "</b><br/>
                    How certain are you: <b>Certain</b><br/>
                    ")))
    })

    # ---- Demographic information ---------------------------------------------
    output$demo_text <- renderText({
        return("Please fill out the demographic information to begin.")
    })

    # add demographic information to the database
    observeEvent(input$submitdemo, {
        if (!is.null(input$nickname) && nchar(input$nickname) > 0 && !any(input$dimension < window_dim_min)) {
            con <- dbConnect(SQLite(), dbname = "cp_lineup_data.db")
            
            prolific_id    <- ifelse(is.null(input$prolific_id), "", input$prolific_id)
            age            <- ifelse(is.null(input$age), "", input$age)
            gender         <- ifelse(is.null(input$gender), "", input$gender)
            academic_study <- ifelse(is.null(input$education), "", input$education)
            recruited      <- ifelse(is.null(input$recruited), "", input$recruited)
            health_related <- ifelse(is.null(input$health_related), "", input$health_related)
            stem_related   <- ifelse(is.null(input$stem_related), "", input$stem_related)

            demoinfo       <- data.frame(prolific_id      = prolific_id,
                                         ip_address       = "",
                                         nick_name        = input$nickname,
                                         study_start_time = values$study_start_time,
                                         bib_id           = participant_bib_id,
                                         age              = age,
                                         gender           = gender,
                                         academic_study   = academic_study,
                                         health_related   = health_related,
                                         stem_related     = stem_related,
                                         recruited        = recruited
                                         )

            dbWriteTable(con, "users", demoinfo, append = TRUE, row.names = FALSE)
            dbDisconnect(con)

            updateCheckboxInput(session, "ready", value = TRUE)
        }
    })



    # ---- Question Flow -------------------------------------------------------
    output$question <- renderText({
        return(values$question)
    })

    # Output info on how many trials/lineups left
    output$status <- renderText({
        paste(
            ifelse(values$trials_left > 0, "Trial", ""),
            "Plot",
            ifelse(values$trials_left > 0,
                   paste(values$trials_req - values$trials_left + 1, "of", values$trials_req),
                   paste(values$lpp - values$lpp_left + 1, "of", values$lpp)))
    })

    # Enable submit button if the experiment progresses to ___ stage
    observe({
        if (is.null(input$response_no) || input$response_no == "") {
            enable("submit")
        }
    })

    observeEvent(input$submit, {

        response <- as.character(input$response_no)


        if (nchar(response) > 0 &&
            all(strsplit(response, ",")[[1]] %in% 1:20) &&
            values$lpp_left > 0 &&
            (length(input$reasoning) > 0 || (nchar(input$other) > 0)) &&
            nchar(input$certain) > 0 &&
            !any(input$dimension < window_dim_min)) {

            # Things to do when responses are all filled in and submitted
            disable("submit")

            reason <- input$reasoning
            if ("Other" %in% reason || input$otheronly) {
                reason <- c(reason, input$other)
            }
            reason <- paste(reason, collapse = ", ")

            values$choice <- response

            if (values$trials_left == 0 && values$lpp_left > 0) {
                # This applies to the lineups, not to the trials
                values$result <- "Submitted!"

                
                prolific_id    <- ifelse(is.null(input$prolific_id), "", input$prolific_id)
                
                test <- data.frame(prolific_id       = prolific_id,
                                   ip_address        = input$ipid,
                                   nick_name         = input$nickname,
                                   study_start_time  = values$study_start_time,
                                   lineup_order      = values$lpp - values$lpp_left + 1,
                                   lineup_start_time = values$lineup_start_time,
                                   lineup_end_time   = now(),
                                   lineup_id         = values$lineup_id,
                                   response_no       = values$choice,
                                   conf_level        = input$certain,
                                   choice_reason     = reason,
                                   description       = values$experiment
                                   )

                # Write results to database
                db_con <- dbConnect(SQLite(), dbname = "cp_lineup_data.db")
                dbWriteTable(db_con, "feedback", test, append = TRUE, row.names = FALSE)
                dbDisconnect(db_con)

                # Update variables for next trial
                values$lpp_left <- values$lpp_left - 1
                values$choice <- ""

                # Generate completion code
                if (values$lpp_left == 0) {
                    # values$question <- "All done! Congratulations!"
                    values$question <- paste("All done! Congratulations! Please copy-paste the following completion code to Prolific: \n \n CKQK346R")
                    updateCheckboxInput(session, "done", value = TRUE)
                }

            } else {
                # This applies to the trials, not the lineups
                if (any(strsplit(values$choice, ",")[[1]] %in% values$correct)) {
                    values$trials_left <- values$trials_left - 1
                    values$result <- "Correct! :)"
                } else {
                    values$result <- "Incorrect :("
                }
            }

            values$submitted <- TRUE
        } else {
            # Don't let them move ahead without doing the trial
            showNotification("Please fill in all of the boxes.")
        }
    })

    # This renders the trial/lineup image
    output$lineup <- renderUI({
        if (values$lpp_left == 0 || !input$ready || any(input$dimension < window_dim_min)) return(NULL)

        withProgress(
            # Message: Loading (trial) plot i of n
            message = paste(values$result, "Loading plot", values$lpp - values$lpp_left + 1, "of", values$lpp),

            expr = {
            values$submitted

            values$lineup_start_time <- now()

            if (is.null(values$my_picture_details)) {

              db_con <- dbConnect(SQLite(), dbname = "cp_lineup_data.db")
              picture_details <- dbReadTable(db_con, "picture_details")
              dbDisconnect(db_con)

              values$my_picture_details <- left_join(pic_ids, picture_details, by = "lineup_id")
              next_plot <- values$my_picture_details[1,]
            }
            else {
              next_plot <- values$my_picture_details[values$lpp - values$lpp_left + 1,]
            }

            # Update reactive values
            values$lineup_id  <- next_plot$lineup_id
            values$correct <- next_plot$obs_plot_location

            # Reset UI selections
            values$submitted <- FALSE

            updateSelectizeInput(session, "certain",
                                 # choices = c("", "Very Uncertain", "Uncertain", "Neutral", "Certain", "Very Certain"),
                                 choices = c("", "Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"),
                                 selected = NULL
                                 )
            updateTextInput(session,
                            "response_no",
                            value = ""
                            )
            updateTextInput(session,
                            "other",
                            value = ""
                            )
            updateCheckboxGroupInput(session,
                                     "reasoning",
                                     selected = NA
                                     )

            if (is.null(next_plot$lineup_id)) return(NULL)

            # Read svg and remove width/height
            tmp <- readLines(file.path(plots_folder, "svg", basename(paste0(next_plot$lineup_id, ".svg"))))
            tmp[2] <- str_replace(tmp[2], "width=.*? height=.*? viewBox", "viewBox")

            # Include the lineup picture
            div(
                class="full-lineup-container",
                HTML(tmp)
            )

            }) # end WithProgress
    }) # end renderUI
}) # End app definition

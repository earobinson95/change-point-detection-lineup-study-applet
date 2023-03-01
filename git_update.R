#!/usr/bin/Rscript
# Sorry this isn't elegant but necessary for the cron tab to work
setwd("~/Projects/Graphics/2023-Changepoint-Miguel-Emily/")

# Set up authentication via ssh
cred <- git2r::cred_ssh_key("~/.ssh/id_rsa.pub", "~/.ssh/id_rsa")
repo <- git2r::repository()
git2r::config(repo = repo, global = F, "Susan-auto", "srvanderplas@gmail.com")

# Log job start
httr::POST("https://hc-ping.com/34f67a90-9ccd-41d8-9ef2-d5daba31fd6e/start")

# Check repo status
status <- git2r::status()

tmp <- status$unstaged
modified <- names(tmp) == "modified"
modified <- unlist(tmp[modified])

# If db has been modified
if ("cp_lineup_data.db" %in% modified) {

  # Add changed db to commit and commit
  git2r::add(repo = '.', "*.db")
  try(git2r::commit("*.db", message = "Update data"))
  # Update
  git2r::pull(repo = repo, credentials = cred)
  git2r::push(getwd(), credentials = cred)

  if (length(git2r::status()$unstaged$conflicted) > 0) {
    # Log merge conflict, signal failure (Susan gets an email)
    httr::POST("https://hc-ping.com/34f67a90-9ccd-41d8-9ef2-d5daba31fd6e/fail", body = "Merge conflict")
  } else {
    # Log success
    httr::POST("https://hc-ping.com/34f67a90-9ccd-41d8-9ef2-d5daba31fd6e", body = "Changes pushed")
  }
} else {
  # Log no changes
  httr::POST("https://hc-ping.com/34f67a90-9ccd-41d8-9ef2-d5daba31fd6e", body = "No changes")
}

git2r::config(repo = repo, global = F, "Susan Vanderplas", "srvanderplas@gmail.com")

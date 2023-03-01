# https://rstudio.github.io/renv/#:~:text=Use%20renv%3A%3Ainit(),into%20a%20lockfile%2C%20called%20renv.

# install.packages("renv")

# initialize a new project-local environment with a private R library
renv::init()

# save the state of the project library to the lockfilealled renv.lock
renv::snapshot()

# revert to the previous state as encoded in the lockfile
renv::restore()

# print a diagnostics report summarizing the state of the project
renv::diagnostics()

renv::isolate()

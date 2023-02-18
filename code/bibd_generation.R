#install.packages(c("daewr","AlgDesign"))
library(daewr)
library(tidyverse)
library(AlgDesign)


BIBsize(36,12) #possible number of blocks

#generating the balanced incomplete block
BIB <- optBlock(~.,
                withinData = factor(1:36),
                blocksizes = rep(12,105))

#BIB$Blocks gives you a list of dataframe for each block
#BIB$rows gives you a vector of all the treatments given for each unit

bind_cols(BIB$Blocks,.name_repair = "unique")  -> design
colnames(design) <- paste("Block",1:105)

design |> write.csv(file="./plots/bib_assignment_R.csv")

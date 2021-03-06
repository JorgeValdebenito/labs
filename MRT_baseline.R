install.packages("data.table")
install.packages('bit64')
install.packages("dplyr")## dplyr provides the join functions
library(data.table)
library(dplyr) 

setwd("G:/MAX-Filer/Collab/Labs-kbuzard-S18/Admin")

#Read the data from database citations
citations<- fread("SAScitations.csv")

#Read the data from database possiblenclass
possiblenclass <- fread("SASpossiblenclass.csv")

citations=as.data.table(citations)

#We transform possiblenclass and citations into a smaller subset, 
#given that the memory requirements are too high
#Creating small data tables

setkey(citations,"nclass")
setkey(possiblenclass, "nclass")

smallcitations<-citations[.(1:30)]
#I'm deleting the variables I'll not going to use, to make the data sets smaller.
smallpossiblenclass<-possiblenclass[.(1:30)]
smallpossiblenclass<-smallpossiblenclass[,c(1:50)]
#smallpossiblenclass[,  c("x_control")  := NULL]

smallcitations=as.data.frame(smallcitations)#To use the same objects as Frank's code. 
smallpossiblenclass=as.data.frame(smallpossiblenclass)

#Delete the NAs created in smallmatching2 and smallpossiblenclass by the particioning of the datasets
smallcitations<-smallcitations[-which(is.na(smallcitations$cited)),]
smallpossiblenclass<-smallpossiblenclass[-which(is.na(smallpossiblenclass$control)),]


# Create matrix of citations in big for use below
big_citations <- as.matrix(smallpossiblenclass[, -c(1:9)])

# Function that returns vector of all rows from big that match 'mypatent,' a list
# with named elements corresponding to small. (I.e. mypatent will be a row from 
# small)
get_matching_rows <- function(mypatent) {
  
  # Vector of row indices for all patents in big that cite mypatent
  citing_rows<- which((big_citations == mypatent$cited) & (big_citations == mypatent$patent) , arr.ind = TRUE)[,1]
  
  # Vector of row indices for big that satisfy:
  # (1) same class as mypatent
  # (2) within one year of mypatent
comparable_rows <- which((smallpossiblenclass$nclass == mypatent$nclass) &
                             (abs(mypatent$sasdate - smallpossiblenclass$c_sasdate) < 183) &
                             (abs(smallpossiblenclass$c_invnum - mypatent$invnum)>0) &
                             ((smallpossiblenclass$c_appyear - mypatent$o_gyear)>=0) &
                             (abs(smallpossiblenclass$c_pdpass - mypatent$o_pdpass)>0) &
                             (abs(smallpossiblenclass$c_pdpass - mypatent$pdpass)>0) &
                             (abs(smallpossiblenclass$c_invnum - mypatent$o_invnum)>0) &
                             (abs(smallpossiblenclass$control - mypatent$patent)>0) &
                             (abs(smallpossiblenclass$control - mypatent$cited)>0))  

  
  # A match is a row index in comparable_rows that does *not* cite mypatent 
  matching_rows <- setdiff(comparable_rows, citing_rows)
  return(matching_rows)
} 

# Example: find rows that match first patent in small
my_matches <- get_matching_rows(smallcitations[1,])
head(smallpossiblenclass[my_matches,])

# Now find the full set of matching indices for every patent in small
system.time(
  list_of_matches <- lapply(1:nrow(smallcitations), 
                            function(row) get_matching_rows(smallcitations[row,])))

# Use the list of matches to generate random matches (note that this is a 
# with replacement matching strategy, since we may re-use the same patent
# in big as a match for different patents in small. I think this is actually
# the right way to do things: it's also much easier to code!)
random_matches <- sapply(list_of_matches, function(x) sample(x, 1))

# Now you can cbind the matches if you like:
merged_patents <- cbind(smallcitations, smallpossiblenclass[random_matches,])


#-------
get_matching_rows <- function(mypatent) {
  
  # Indicator (TRUE/FALSE) for patents from big that cite mypatent 
  #cites_mypatent <- unlist(lapply(big_citations, function(x) mypatent$patent %in% x))
  cites_mypatent <- unlist(lapply(big_citations, function(x) mypatent$patent %in% x))
  
  # Find rows in big matching the following conditions:
  #   (1) same class as mypatent
  #   (2) within one year of mypatent
  #   (3) does not cite mypatent
  out <- which((smallpossiblenclass$nclass == mypatent$nclass)) #&
               #(abs(smallpossiblenclass$control - mypatent$cited)>0)) #&
               #(abs(smallpossiblenclass$c_pdpass - mypatent$o_pdpass)>0) & 
               #(abs(smallpossiblenclass$c_invnum - mypatent$o_invnum)>0) & 
               #(abs(smallpossiblenclass$c_invnum - mypatent$invnum)>0) & 
               #(abs(smallpossiblenclass$c_pdpass - mypatent$pdpass)>0) & 
               #((smallpossiblenclass$c_appyear - mypatent$o_gyear)>=0) &
               #(abs(mypatent$sasdate-smallpossiblenclass$c_sasdate)<=182) &
               #(abs(smallpossiblenclass$control - mypatent$patent)>0))
               #(!cites_mypatent))
  return(out)
}

# Example: find rows that match first patent in small
my_matches <- get_matching_rows(smallmatching2[1,])
#smallpossiblenclass[my_matches,]

# Now find the full set of matching indices for every patent in small
system.time(
list_of_matches <- lapply(1:nrow(smallmatching2), 
                          function(row) get_matching_rows(smallmatching2[row,])))

# Use the list of matches to generate random matches (note that this is a 
# with replacement matching strategy, since we may re-use the same patent
# in big as a match for different patents in small. I think this is actually
# the right way to do things: it's also much easier to code!)
random_matches <- sapply(list_of_matches, function(x) sample(x, 1))

# Now you can cbind the matches if you like:
merged_patents <- cbind(smallmatching2, smallpossiblenclass[random_matches,])
        
merged_patentsfinal<- subset(merged_patents, control != cited & control != patent
                             & c_pdpass != pdpass & c_pdpass !=o_pdpass 
                             & c_appyear!= o_gyear & (c_appyear - o_gyear)>=0
                             & c_invnum != invnum & c_invnum != o_invnum
                             & !is.na(cite1)
                             & cited!=cite1--cite12
)

        
        
      
      
      

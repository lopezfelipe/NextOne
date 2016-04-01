## Load required libraries
#  =======================
library('tm')
library('RWeka')
library('lattice')
library('stringi')
library('stringr')
library('wordcloud')
library('hashFunction')
library('data.table')
library('parallel')
library('shiny')
library('dplyr')

#rm(list=ls()); # Clear environment
#libs <- c('tm', 'RWeka', 'lattice', 'stringi', 'wordcloud', 'hashFunction', 'data.table', 'xtable',
#          'stringr', 'ggplot2', 'parallel', 'dplyr', 'shiny') # Array of required libs
#lapply(libs, suppressPackageStartupMessages(require), character.only = TRUE) # Load
#rm(libs) # Remove array

## Attempt to parallelize code
# ============================
gc(reset=T, verbose = FALSE)
cl <- makeCluster(detectCores()-2)
invisible(clusterEvalQ(cl, library(tm))); invisible(clusterEvalQ(cl, library(RWeka)))
options(mc.cores = 1)


##  Function loadData
# ===================
loadData <- function(updateProgress = NULL){

  ## Load hashes as data tables
  #  ==========================
  unigramDT  <<- readRDS('unigram_hash.rds'); updateProgress()
  bigramDT <<- readRDS('bigram_hash.rds'); updateProgress()
  trigramDT <<- readRDS('trigram_hash.rds'); updateProgress()
  tetragramDT <<- readRDS('tetragram_hash.rds'); updateProgress()
  
}

## Run predictor
#  =============
compileStrings <- function(inputString, options=NULL){
  
  # Read input string
  processedString <-  gsub('[^[:space:][:alnum:]]','',inputString) # Remove bad  punctuation
  processedString <-  gsub('[^[a-z|A-Z|[:space:]]','', processedString) # Remove bad  characters
  processedString <- removeNumbers(processedString) # Ignore numbers
  processedString <- stripWhitespace(processedString) # Remove white spaces
  processedString <- tolower(processedString) # Convert to lower case
  wordArray <- rev(str_match_all(processedString, "\\S+")[[1]]) # Read words in reverse  order
  
  # Convert input n-gram to numeric key with Spooky.32
  tetraInput <- as.numeric(spooky.32(paste(paste(wordArray[3], wordArray[2], wordArray[1]))))
  triInput <- as.numeric(spooky.32(paste(paste(wordArray[2], wordArray[1]))))
  biInput <- as.numeric(spooky.32(paste(paste(wordArray[1]))))
  
  # Read entries where n-gram exists (by numeric key): only 
  tetraSubset <- tetragramDT[ngram_number==tetraInput, .(word_out, ngram_freq)]
  triSubset <- trigramDT[ngram_number==triInput, .(word_out, ngram_freq)]
  biSubset <- bigramDT[ngram_number==biInput, .(word_out, ngram_freq)]
  
  # Order returned rows by frequency
  tetraSubset <- tetraSubset[order(-ngram_freq)]
  triSubset <- triSubset[order(-ngram_freq)]
  biSubset <- biSubset[order(-ngram_freq)]
  unigramDT <- unigramDT[order(-ngram_freq)]
  
  # Number of occurences
  numberTetra <- dim(tetraSubset)[1]
  numberTri  <- dim(triSubset)[1]
  numberBi <-  dim(biSubset)[1]
  
  # Normalize counts to obtain probabilities
  ngramsList <- list('tetraSubset'=tetraSubset, 'triSubset'=triSubset, 'biSubset'=biSubset)
  rm(tetraSubset,triSubset,biSubset) # We can remove  subsets now
  for (e in names(ngramsList)){
    ngramFreqVect <- ngramsList[[e]][,ngram_freq]
    ngramsList[[e]][, paste0('prob_', e ) :=round(ngram_freq/sum(ngramFreqVect),6)] 
    Encoding(ngramsList[[e]]$word_out) <- 'unknown'
  }
  
  # Merge information in a single data table
  unigramsList <- unigramDT[, .(word_out, ngram_freq)]
  freqVect <- unigramsList[,ngram_freq]
  unigramsList[, 'prob_uniSubset':=round(ngram_freq/sum(freqVect),6)]
  mergedTable <- list(ngramsList[['tetraSubset']], ngramsList[['triSubset']], ngramsList[['biSubset']], unigramsList)
  lapply(mergedTable, function(i) setkey(i, 'word_out'))
  
  # Apply "stupid backoff" algorithm
  alpha <- 0.01  # Define alpha for equation (5) from reference
  # Multiply trigrams, bigrams and unigrams by  alpha
  mergedTable[[2]]$prob_triSubset <- alpha*mergedTable[[2]]$prob_triSubset
  mergedTable[[3]]$prob_biSubset <- alpha*alpha*mergedTable[[3]]$prob_biSubset
  mergedTable[[4]]$prob_uniSubset <- alpha*alpha*alpha*mergedTable[[4]]$prob_uniSubset
  allMerged <- Reduce(function(...) merge(..., all = T), mergedTable)
  for (i in seq_along(allMerged)) set(allMerged, i=which(is.na(allMerged[[i]])), j=i, value=0)
  allMerged[, 'weight' := prob_tetraSubset+prob_triSubset+prob_biSubset+prob_uniSubset]
  allMerged <- allMerged[, .(word_out, weight)]
  
  if(is.null(options)){
    # Proposals: Only 100 most likely
    proposedMerged <- allMerged[order(-weight)][1:100]
    proposedMerged[, 'probability':=round(weight/sum(proposedMerged[,weight]),6)]
    proposedMerged <- proposedMerged[, .(word_out, probability)]
  } else {
    # Only look for suggestions
    proposedMerged <- filter(allMerged, word_out %in% options)
  }
  
  return(proposedMerged)
  
}

## Server function
# ================
shinyServer(
  function(input, output, session) {
    
    ## Track progress when reading hashes for uni-, bi-, tri-, and tetra-grams
    # ========================================================================
    # Creating a progress object
    progress <- shiny::Progress$new()
    progress$set(message = "Loading data ...", value = 0)
    on.exit(progress$close())
    
    # Create a callback function to update progress by one fourth every time it is called
    updateProgress <- function(value = NULL) {
      if (is.null(value)) {
        value <- progress$getValue()
        value <- value + progress$getMax() / 4
      }
      progress$set(value = value)
    }
    
    # Load data
    loadData(updateProgress)
    
    # Read string and make prediction
    enteredString <- reactive({ input$inputString })
    predictedWords <- reactive({ compileStrings( enteredString() ) })
    
    # Show table
    #output$table <- renderTable({
    #  xtable(predictedWords()[1:10,])
    #}, include.rownames = FALSE)
    
    # Show barplot
    numWords <- 
    output$barPlot <- renderPlot({
      barplot( predictedWords()[1:10,probability], names.arg = predictedWords()[1:10,word_out], 
               xlab = "word", ylab = "probability", las = 2, col = "steelblue" )
    })
    
    # Show wordcloud
    checkbox <- reactive({ input$cb_wc })
    output$wordcloudplot <- renderPlot({
      if (checkbox() == TRUE){
        wordcloud( predictedWords()$word_out, predictedWords()$probability, scale=c(8,0.5),
                  min.freq = 0.00001, max.words=50,
                  colors=brewer.pal(8, "Dark2"))
      }
    })
    
  })

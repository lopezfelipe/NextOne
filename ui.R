## Load required libraries
#  =======================
rm(list=ls()); # Clear environment
libs <- c('tm', 'RWeka', 'lattice', 'stringi', 'wordcloud', 'hashFunction', 'data.table', 'xtable',
          'stringr', 'ggplot2', 'parallel', 'dplyr', 'shiny') # Array of required libs
lapply(libs, suppressPackageStartupMessages(require), character.only = TRUE) # Load
rm(libs) # Remove array

## Build user interface for application
# =====================================
shinyUI(navbarPage("NextOne: Word Predictor for Easier Texting",
                   
                   # create first tab: Prediction app
                   tabPanel("App",
                            # fluid row for space holders
                            fluidRow(

                            # Absolute panel: Read text
                            absolutePanel(
                              # Position attributes
                              top = 20, left = 0, right =0,
                              fixed = TRUE,
                              # Panel with predefined background
                              wellPanel(
                                fluidRow(
                                  br(),
                                  strong("Enter phrase"),
                                  br(),
                                  textInput(inputId="inputString", label=NULL),
                                  br(),
                                  style = "opacity: 0.92; z-index: 100;"
                                ))
                            ),

                            # Spaceholder
                            column(4, div(style = "height: 100px"))
                            ),
                            
                            # Main panel: Results
                            mainPanel(
                              
                              column(6, 
                              
                                br(),
                                strong("Do you want to continue with ..."),
                                plotOutput("barPlot")
                              ),
                              column(6,
                                plotOutput("wordcloudplot"),
                                checkboxInput("cb_wc", "Uncheck to suppress wordcloud", TRUE)
                              
                              ),
                              br(),
                              p("NextOne, 2016. Developed by Felipe Lopez")
                              
                            )

                            ),
                   
                   # second tab: Algorithm explained
                   tabPanel("Statistical method",
                            # load MathJax library so LaTeX can be used for math equations
                            # paragraph
                            p("This project is an application of natural language processing (an area of computational linguistics), where statistics on
                              common writing practices are used to determine what word is most likely to come next. The specific problem solved by the
                              app is based on N-gram language models. An n-gram is a contiguous sequence of n items for a given sequence of text. For
                              instance, a common two-word sequence, such as 'of course', is a bi-gram."),
                            p("The HC Corpora was used to extract data from news, blogs, and Twitter feeds. The extracted text data
                              was preprocessed and cleaned from profanity before being extracting statistics for n-grams. The study was limited to
                              uni-, bi-, tri-, and tetra-grams. In other words, statistics were extracted for the most common one-, two-, three-, and four
                              word combinations. By doing this, it assumed that the next word depends only on the three words that precede it. The model
                              used in this application is an adaptation of the Stupid backoff method, proposed by Brown et al. (1993)"),
                            h4("Stupid backoff algorithm"),
                            p('The adaptation of the stupid backoff algorithm for this third-order Markovian model has the following steps:'),
                            tags$ol(
                              withMathJax(tags$li("Take the last three words and look for tetra-grams. Then find the relative frequency of each word \\(F1\\).")),
                              withMathJax(tags$li("Take the last two words and look for tri-grams. Then find the relative frequency of each word \\(F2\\).")),
                              withMathJax(tags$li("Take the last word and look for bi-grams. Then find the relative frequency of each word \\(F3\\).")),
                              withMathJax(tags$li("Find the relative frequency of the most common words \\(F4\\).")),
                              withMathJax(tags$li("Define a factor alpha \\( (0 < \\alpha < 1) \\), such that the likelihood of a word is given by \\( F = F1  + \\alpha F2 + \\alpha^2 F3  + \\alpha^3 F4\\).
                                                  The factor alpha ensures that closer attention is paid to higher n-grams.")),
                              tags$li("Then the 100 more likely words (higher \\(F\\)) are selected and the likelihoods are normalized in the form of probability.")
                            ),
                            br(),
                            p(strong("Disclaimer:"), "The software is expressly provided as-is. The author makes no warranty of any kind.")

                            )
                   )
        )
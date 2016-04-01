NextOne: Easier Texting
========================================================
author: Felipe Lopez

Texting should be easier
========================================================

<font size=5.5>

Texting is the most widely-used form of communication in the US. 97% of Americans text at least once a day.

Most texts are written in less than 5 seconds.

Short  times + tiny screens = Typos.

Various apps try to make texting easier by predicting what you meant or what you want to say next: Swiftkey, Swype, Fleksy, etc. With these apps we want to get to know you and the way you text so we can predict what you'll type next and suggest a shortcut!

</font> 

![alt text](texting.jpg)


NextOne: How to use
========================================================

![width](NextOne.png)

What does NextOne do?
========================================================

<font size=5.5>

NextOne is an app developed with shiny, an R library. Its purpose is to show the power of natural language processing for text prediction.

For this example we used English texts ownloaded from the HC Corpora, a collection of text files from many different sources, such as newspapers, magazines, blogs and Twitter updates.

The stupid backoff algorithm based on an n-gram language model is used to predict the most likely word to be entered next based on the three previous ones. The system was modeled as a third-order Markov process because  of simplicity and due to memory limitations and for fast operation.

All text mining an natural language processing was done using R libraries like tm, RWeka, stringi, hashFunction and wordcloud. For more efficient use of the processor, the library parallel was used to parallelize the code.

</font>

NextOne performance
========================================================

<font size=5.5>

The accuracy obtained with this example was between 15-25%, depending on the testing set. The accuracy may seem low but so far it considers only word-to-word relationships without updating when the first letters of the new word have already been entered. Adding such capabilities is expected to improve the accuracy of NextOne.

The alpha version is available at https://lopezfelipe.shinyapps.io/Week04/

The source code can be downloaded from https://github.com/lopezfelipe/NextOne

For comments and suggestions, email felipelopez@utexas.edu


options(rstudio.markdownToHTML = 
          function(inputFile, outputFile) {      
            require(markdown)
            markdownToHTML(inputFile, outputFile, stylesheet=system.file("misc", "docco-template.html", 
                                                                         package = "knitr"))   
          }
)

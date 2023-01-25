#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(shinycssloaders)

# Define UI for data upload app ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Reciprocal Best App"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      helpText("Compute the reciprocal best hits from two sets of protein sequences"),
      helpText("Usage : Browse to select two sets of protein sequences (FASTA format) and wait for rbhXpress to create a downloadable output"),
      
      # Input: Select a file ----
      fileInput("file1", "Choose 1st Fasta File",
                multiple = FALSE,
                accept = c(".fa",
                           ".fasta",
                           ".pep")),
      fileInput("file2", "Choose 2nd Fasta  File",
                multiple = FALSE,
                accept = c(".fa",
                           ".fasta",
                           ".pep")),
      actionButton("do","Compute orthologs")
    ),
    
    # Main panel using verbatimTextOutput and uiOutput chunks
    # That will display only when the orthologs are computed and
    # the data can be downloaded :
    
    mainPanel(
      verbatimTextOutput("rbhXpressLOG"),
      uiOutput("DownloadData")
      
    )
    
  )
)

options(shiny.maxRequestSize=30*1024^2)
# Define server logic to read selected file ----
server <- function(input, output,session) {
  
  # Copy data to the local folder
  observeEvent(input$do, {
    
    # The whole process can be called only if the two fasta files were successfully uploaded :
    req(input$file1)
    req(input$file2)
    random_number_session <- sample(1:5000,1)
    # read 1st fasta and write to the data folder :
    df <- read.csv(input$file1$datapath,
                   header = FALSE,
                   sep = ",") %>% select(V1)
    
    write.table(df,"sessionFolder/file1.fa",col.names = FALSE,row.names = FALSE,sep=",", quote = FALSE)
    
    # read 2nd fasta and write to the data folder :
    df2 <- read.csv(input$file2$datapath,
                   header = FALSE,
                   sep = ",") %>% select(V1)
    
    write.table(df2,"sessionFolder/file2.fa",col.names = FALSE,row.names = FALSE,sep=",", quote = FALSE)
    
    # run rbhXpress :
    rbh_command_line <- "bash scripts/rbhXpress/rbhXpress.sh -a sessionFolder/file1.fa -b sessionFolder/file2.fa -t 1 -o sessionFolder/reciprocal_best_hits.tab"
    orthologs <- read.table(text = system(rbh_command_line,intern = T),header = FALSE, sep = "\t")
    # orthologs <- read.csv("sessionFolder/reciprocal_best_hits.tab",header = FALSE,sep="\t")
    
    # display amount of orthologs found and download button :
    output$rbhXpressLOG <- renderText({paste0("Found ",length(orthologs$V1)," reciprocal best hits !")})
    
    output$DownloadData <- renderUI({if (!is.null(orthologs)) {downloadButton("Downloadrbh","Download") }})
    
    output$Downloadrbh <- downloadHandler(filename = "reciprocal_best_hits.tab",
                                          content = function(file){
                                            write.table(orthologs,file,col.names = FALSE,row.names = FALSE,sep = "\t",quote = FALSE)
                                          })
  })
  session$onSessionEnded(function() { unlink(c("sessionFolder/file1.fa",
                                             "sessionFolder/file2.fa",
                                             "sessionFolder/p1.dmnd",
                                             "sessionFolder/p2.dmnd",
                                             "sessionFolder/p1_p2",
                                             "sessionFolder/p1_p2.s",
                                             "sessionFolder/p2_p1",
                                             "sessionFolder/p2_p1.s") )})
}

# Create Shiny app ----
shinyApp(ui, server)
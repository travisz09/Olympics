### Olympedia Scrape
### Travis Zalesky
### 2/3/2024
### Purpose: To scrape Olympedia.org for data related
###     to USA athletes and medals

#Load Packages
library("RCurl")
library("XML")
library("tidyverse")

#### SETUP ####
# Get list of sub-pages in USA directory (each contains list of Olympic years which the USA has competed in)
## Modify url for alternate nations of interest. See olympedia.org.
USA_directory <- getURL("http://www.olympedia.org/countries/USA") %>%
  htmlParse(asText=TRUE) %>%
  xpathSApply('//td/a', xmlGetAttr, 'href') %>%
  paste('https://www.olympedia.org/', ., sep="")

# Check number of sub-pages 
length(USA_directory) # 689 pages

# Explore directory
head(USA_directory)

USA_directory[8]
USA_directory[10]
USA_directory[112]

xml_seq <- seq(8, 112, 2) #Every other href from 8 - 112 = Results summary data.

#### EVENT DATA ####
df <- data.frame(Year=numeric(),
                 Season=numeric(),
                 Sport=character(), 
                 Event=character(),
                 Athlete=character(),
                 Finish=character(),
                 Medal=character(),
                 Athlete.ID=character(),
                 stringsAsFactors=FALSE) 

sport <- ""

system.time( # Total time, ~8 minutes.
  for (i in xml_seq) { #for every page in xml_seq.
    
    start <- Sys.time() #Optional, page start time.
    
    #Get xml data
    xml <- getURL(USA_directory[i]) %>%
      htmlParse(asText=TRUE)
    
    #Get year from h1
    year <- xml%>%
      xpathSApply('//*//h1', xmlValue) %>%
      parse_number()
    
    #Get season from h1
    header <- xml %>%
      xpathSApply('//*//h1', xmlValue)%>%
      str_split(pattern = " ")
    season <- xmlseason <- header[[1]][6]
    
    #Get data from table
    ##Table is structured in rows of unequal length.
    ##Get table rows (tr).
    xml_table <- xml %>%
      xpathSApply('//*[(@class="table")]//tr', xmlValue)
    ##Get tr attributes
    xml_attrs <- xml %>%
      xpathSApply('//*//tr', xmlAttrs)
    
    #Parse rows, add to df.
    for (y in seq(1, length(xml_table))) { #for every row in table.
      if (is.null(xml_attrs[y][[1]])){ #if tr attributes = NULL, row = sports sub-division
        #Get row data
        parse_row <- xml_table[y]
        #split row on "\n".
        parse_row <- str_split(parse_row, pattern = "\n")[[1]]
        #define sport
        sport <- parse_row[2]
        row <- NULL
      } else { #tr attributes != NULL
        
        #Get row data
        parse_row <- parse_row <- xml_table[y]
        #split row on "\n".
        parse_row <- str_split(parse_row, pattern = "\n")[[1]]
        #length of parse_row should = 5.
        if (length(parse_row) < 5) { 
          # fill in missing table data with "".
          dif <- 5 - length(parse_row)
          row <- c(parse_row, rep("", dif))
        } else {
          row <- parse_row[1:5]
        } #end if/else length parse_row < 5.
        
        #Get Athlete ID(s)
        aID <- xml %>%
          xpathSApply('//*//tr') #list of xml table rows
        
        aID<-aID[y] #get row by index
        
        aID <- aID%>%
          sapply(saveXML) #save xml as text string
        
        aID <- str_extract_all(aID, pattern = '/athletes/\\d+')[[1]]%>%
          parse_number() #get athlete href(s), extract ID(s)
        
        aID <- paste(aID, collapse = ", ") #colapse list to text string
        
      } #end if/else tr attributes = NULL.
      
      if (!is.null(row)) {
        # structure parsed data as df
        df_row <- data.frame(year, season, sport, row[1], row[2], row[3], row[4], aID)
        names(df_row) <- c("Year", "Season", "Sport", "Event", "Athlete", "Finish", "Medal", "Athlete.ID")
        # bind data to df.
        df <- rbind(df, df_row)
      } #else do nothing.
    } #end for row in table.

  stop <- Sys.time() #Optional, page stop time.
  t <- round(stop - start, 1) #Optional, page scrape time.
  print(paste(year, " ", season, ",", " ", t, " ", "seconds.", sep = "")) #track progress
  #Note out start, stop and t for faster run times (lines 140, 197 & 198).
  #Alternate:
  ##print(paste(year, season, sep = " "))
  flush.console() # avoid output buffering

  } #end for pages in xml_seq.
) #end system.time

#Clean up df.
##Sport values only entered on change.
df <- df%>%
  mutate(Event = if_else(Event == "", NA, Event))%>%
  tidyr::fill(Event, .direction = "down")#draw missing "Sport" values down from above.

#Save data.
write.csv(df, file = "Z:/Documents/My Code/Olympics/Data/OlympicsData_Raw.csv",
          row.names = F)

#Clean up
rm(dif, df_row, i, parse_row, row, season, sport, start, 
   stop, t, xml_table, y, year, header, xml_attrs, aID,
   xml, xmlseason)

#### ATHLETE DATA ####
# Initialize vector to store links
individual_links <- c() 

system.time( # ~1.9 minutes
  for (i in seq(8, 112, 2)) {
    
    # parse USA directory sub-page to get all links
    new <- getURL(USA_directory[i]) %>%
      htmlParse(asText=TRUE) %>%
      xpathSApply('//*[(@class="table")]//a', xmlGetAttr, 'href') %>%
      paste('https://www.olympedia.org/', ., sep="")
    
    # update vector of linked pages
    individual_links <- c(individual_links, new) 
    
    # track progress in console
    print(i) 
    flush.console() # avoid output buffering
  }
) 

#Explore links
head(individual_links)

#Subset athlete links
athlete_links <- individual_links%>%
  subset(grepl("athletes", individual_links)==T)
#Remove duplicate links
athlete_links <- unique(unlist(athlete_links, use.names = FALSE))
#Explore athlete links
head(athlete_links)
length(athlete_links)

athlete_df <- data.frame(Name=as.character(),
                         Sex=as.character(),
                         Height=as.numeric(),
                         Weigh=as.numeric(),
                         Born=as.character(),
                         Died=as.character(),
                         Birth.Date=as.character(),
                         Death.Date=as.character(),
                         NOC = as.character(),
                         Athlete.ID = as.character())


system.time({
  start <- Sys.time() #Optional, function start time
  
  #Starting message
  print("Begin data scrape. Please be patient.")
  
for (i in c(1:length(athlete_links))) {
  #Get Athlete ID
  aID <- str_extract(athlete_links[i], "\\d+")
  #Get bio data
  bio <- getURL(athlete_links[i]) %>%
    htmlParse(asText=TRUE) %>%
    xpathSApply('//*[(@class="biodata")]//tr', xmlValue) 
  
  #reset bio variables
  role <- ""
  sex <- ""
  name <- ""
  born <- ""
  dateBorn <- ""
  placeBorn <- ""
  died <- ""
  dateDied <- ""
  placeDied <- ""
  measure <- ""
  height <- ""
  weight <- ""
  noc <- ""
  
  if (!is.null(bio)){ #Checks for broken links and missing data.
    #Bio data follows a variable structure.
    ##Missing data (e.g. Death) results in variable length and index positions of bio data, so data must be selected by keyword.
    for (y in c(1:length(bio))){ #for each row in bio table
      if (grepl("Roles", bio[y])){ #keyword "Roles"
        role <- bio[y]%>%
          str_remove("Roles")
      }
      if (grepl("Sex", bio[y])){ #keyword "Sex"
        sex <- bio[y]%>%
          str_remove("Sex")
      }
      if (grepl("Used name", bio[y])){ #keyword "Used name"
        name <- bio[y]%>%
          str_remove("Used name")%>%
          str_replace("â\u0080¢", " ")
      }
      if (grepl("Born", bio[y])){ #keyword "Bio"
        born <- bio[y]
        dateBorn <- str_split(born, pattern = " in ")[[1]][1]%>%
          str_remove("Born")%>%
          dmy()
        placeBorn <- str_split(born, pattern = " in ")[[1]][2]
      }
      if (grepl("Died", bio[y])){ #keyword "Died"
        died <- bio[y]
        dateDied <- str_split(died, pattern = " in ")[[1]][1]%>%
          str_remove("Died")%>%
          dmy()
        placeDied <- str_split(died, pattern = " in ")[[1]][2]
      }
      if (grepl("Measurements", bio[y])){ #keyword "Measurements"
        measure <- bio[y]
        height <- str_split(measure, pattern = "/")[[1]][1]%>%
          parse_number()
        weight <- str_split(measure, pattern = "/")[[1]][2]%>%
          parse_number()
      }
      if (grepl("NOC", bio[y])){ #Keyword "NOC"
        noc <- bio[y]%>%
          str_remove("NOC")
      }
    } #end bio table keyword search
    
    #Assemble new data
    df_row <- data.frame(name, sex, height, weight, placeBorn,
                         placeDied, dateBorn, dateDied, noc, aID)
    names(df_row) <- c("Name", "Sex", "Height", "Weight", "Born",
                       "Died", "Birth.Date", "Death.Date", "NOC", "Athlete.ID")
    #Bind new data to athlete df
    athlete_df <- rbind(athlete_df, df_row)
  }
  #Track progress
  if (i%%100 == 0) { #print progress every 100 downloads.
    #calculate progress
    prog <- i/length(athlete_links)*100
    #calculate run time
    t <- difftime(Sys.time(), start)
    units <- units(t)
    t <- as.numeric(t)
    #estimate time remaining
    tRemain <- (t/prog)*(100-prog)
    print(paste(round(prog, 2), "% downloaded. ", 
                signif(tRemain, 2), " ", units, " remaining (est).", 
                sep = ""))
    flush.console() # avoid output buffering
  }#end if bio != NULL
  
}# end athlete page search
})# end system.time

write.csv(athlete_df, file = "Z:/Documents/My Code/Olympics/Data/AthleteData_Raw.csv",
          row.names = F)

### Geolocate-API.R
### Travis Zalesky
### 2/8/2024
### Purpose: To geolocate cities for Olympics data.

#### SET UP ####
#Load Packages
library(httr)
library(tidyverse)

url <- "https://geocoding-by-api-ninjas.p.rapidapi.com/v1/geocoding"

#Test case
queryString <- list(
  city = "Almonesson Lake",
  state = "New Jersey",
  country = ""
)

response <- VERB("GET", url, query = queryString, 
                 add_headers('X-RapidAPI-Key' = 'eebc506c98mshc2cae30fc4c5fd1p1d877ajsnc22142de6dd5', 
                             'X-RapidAPI-Host' = 'geocoding-by-api-ninjas.p.rapidapi.com'), 
                 content_type("application/octet-stream"))

content(response, "text")

#Load content
GoldWinners <- read.csv("Z:/Documents/My Code/Olympics/Data/GoldWinners.csv")

Cities <- GoldWinners%>%
  group_by(City, State, Country)%>%
  summarise(Count = n())

Response <- data.frame(City = as.character(),
                       State = as.character(),
                       Country = as.character(),
                       Response = as.character(),
                       lat = as.numeric(),
                       lon = as.numeric(),
                       Note = as.character())

for (i in c(7:nrow(Cities))) {
  city = Cities[i,]$City
  state = Cities[i,]$State
  country = Cities[i,]$Country
  
  queryString <- list(
    city = city, #required
    state = state, #optional
    country = country #optional
  )
  
  response <- VERB("GET", url, query = queryString, 
                   add_headers('X-RapidAPI-Key' = 'eebc506c98mshc2cae30fc4c5fd1p1d877ajsnc22142de6dd5', 
                               'X-RapidAPI-Host' = 'geocoding-by-api-ninjas.p.rapidapi.com'), 
                   content_type("application/octet-stream"))
  
  rText <- content(response, "text")
  rText
  
  if (grepl("error", rText)) { #if response returns error
    note <- "No results"
    row <- data.frame(city, state, country, rText, NA, NA, note)
    names(row) <- names(Response)
  } else {
    #else (no error), if response returns 1 hit
    if (length(str_split(rText, "\\{")[[1]][-1]) == 1) {
      note <- "One result"
      lat <- parse_number(str_split(str_split(rText, "\\{")[[1]][-1][1], pattern = ",")[[1]][2])
      lon <- parse_number(str_split(str_split(rText, "\\{")[[1]][-1][1], pattern = ",")[[1]][3])
      row <- data.frame(city, state, country, rText, lat, lon, note)
      names(row) <- names(Response)
    } else {
      #else (response > 1)
      if (length(str_split(rText, "\\{")[[1]][-1]) > 1) {
        note <- "Multiple results"
        lat <- parse_number(str_split(str_split(rText, "\\{")[[1]][-1][1], pattern = ",")[[1]][2])
        lon <- parse_number(str_split(str_split(rText, "\\{")[[1]][-1][1], pattern = ",")[[1]][3])
        row <- data.frame(city, state, country, rText, lat, lon, note)
        names(row) <- names(Response)
      } else { #else none of these
        note <- "Something went wrong"
        row <- data.frame(city, state, country, rText, NA, NA, note)
        names(row) <- names(Response)
      }# end else, none of these
    }# end else, response > 1
  }# end else, no error
  
  
  Response <- bind_rows(Response, row)
  
}

Good <- Response%>%
  filter(Note == "One result")
Check <- Response%>%
  filter(Note == "Multiple results")
Bad <- Response%>%
  filter(is.na(lat) | is.na(lon))

write.csv(Response, "Z:/Documents/My Code/Olympics/Data/Geo.csv",
          row.names = F)

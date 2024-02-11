### Olympedia Wrangle
### Travis Zalesky
### 2/3/2024
### Purpose: To wrangle and visualize data scraped from
###   Olympedia.org

#### SET UP ####
#Load Packages
library(tidyverse)

#Set WD
wd <- choose.dir()
setwd(wd)

#Read data
olympics_df <- read.csv("Data/OlympicsData_Raw.csv")
athlete_df <- read.csv("Data/AthleteData_Raw.csv")

#Explore data
head(olympics_df)
names(olympics_df)

head(athlete_df)
names(athlete_df)

#### ATHLETE DATA ####
#Check for duplicates
athlete_df%>%group_by(Athlete.ID) %>% 
     filter(n()>1)
### Harry (Jacobs) Kiener is in olympedia twice on different pages.
###  The name, date and place of birth are all the same, the
###  listed events differ and the date of death differs by 1
###  day. I can not explain this discrepancy, but it is almost
###  certainly the same person.

#change athlete_df Name to Athlete for joining later.
athlete_df <- athlete_df%>%
  rename(Athlete = Name)

#Birth and death dates in athlete_df are not standardized.
##Define custom function for parsing ambiguous dates
parseDate <- function(date) {
  #if date is of format m/d/yyyy (or mm/dd/yyyy)
  if (grepl("\\d{1,2}/\\d{1,2}/\\d{4}", date)) {
    date <- mdy(date)
  }  
  
  #if date is of format yyyy-m-d (or yyyy-mm-dd)
  if (grepl("\\d{4}-\\d{1,2}-\\d{1,2}", date)) {
    date <- ymd(date)
  }  else {
    date <- NA
  }
}

##Set up empty dr for date data
date_df <- data.frame(matrix("", nrow = 0, ncol = 3))
names(date_df) <- c("bDate", "dDate", "aID")
date_df[, 1:2] <- sapply(date_df[, 1:2], as.Date)

##Iterate through athlete_df, extract, parse, and save data.
###You could do this faster with dataTable, but I like dplyr for readability.
system.time( # ~1 minute
for (i in c(1:nrow(athlete_df))) {
  bDate <- athlete_df$Birth.Date[i]
  dDate <- athlete_df$Death.Date[i]
  aID <- as.character(athlete_df$Athlete.ID[i])
  
  bDate <- parseDate(bDate)
  dDate <- parseDate(dDate)
  
  row <- data.frame(bDate, dDate, aID)
  
  date_df <- bind_rows(date_df, row)
} #end for rows in athlete_df
) #end system.time()

#Update date_df column names and types for joining
date_df <- date_df%>%
  rename(Athlete.ID = aID)%>%
  mutate(Athlete.ID = as.numeric(Athlete.ID))

#Join new date data to athlete_df
athlete_df <- athlete_df%>%
  left_join(date_df, by = "Athlete.ID")

#Extract additional birthplace location data
athlete_df <- athlete_df%>%
  mutate(City = str_remove_all(str_extract(Born, ".*,"), 
                               pattern = "([:punct:])"),
         State = str_remove_all(str_extract(Born, ", .* "), 
                                pattern = "([:punct:] )"),
         Country = str_remove_all(str_extract(Born, "\\(.{3}\\)"), 
                                  pattern = "([:punct:])"),
         State = str_remove(State, pattern = "\\s$")) #get rid or trailing whitespace in State.

#Get full country names from IOC codes
unique(athlete_df$Country)

#Run "country codes wiki scrape", skip if already run.
source("country codes wiki scrape.R")
iocCodes <- read.csv("Data/IOCCodes.csv")

athlete_df <- athlete_df%>%
  left_join(iocCodes)

#Save
write.csv(athlete_df, file = "Data/AthleteData.csv",
          row.names = F)

#Clean up
rm(aID, bDate, dDate, i, date_df)

#### OLYMPICS DATA ####
#check for bad unicode characters
unique(olympics_df$Year) #good, length 37
unique(olympics_df$Season) #good, length 3
unique(olympics_df$Sport) #good, length 85
unique(olympics_df$Event) #needs fixing, length 729
unique(olympics_df$Athlete) #long, 9211 athletes
unique(olympics_df$Finish) #good, length 936
unique(olympics_df$Medal) #good, length 4

#Fix events
unique(olympics_df$Event)[63]
olympics_df%>%filter(grepl('Ã\u0089pÃ©e', Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('Ã\u0089pÃ©e', "Epee", olympics_df$Event))
unique(olympics_df$Event)[63]

unique(olympics_df$Event)[72]
olympics_df%>%filter(grepl("Â½", Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('Â½', "1/2", olympics_df$Event))
unique(olympics_df$Event)[72]

unique(olympics_df$Event)[116]
olympics_df%>%filter(grepl("Ã\u0097", Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('Ã\u0097', "x", olympics_df$Event))
unique(olympics_df$Event)[116]

unique(olympics_df$Event)[170]
olympics_df%>%filter(grepl("Â¼", Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('Â¼', "1/4", olympics_df$Event))
unique(olympics_df$Event)[170]

unique(olympics_df$Event)[171]
olympics_df%>%filter(grepl("â\u0085\u0093", Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('â\u0085\u0093', "1/3", olympics_df$Event))
unique(olympics_df$Event)[171]

unique(olympics_df$Event)[180]
olympics_df%>%filter(grepl("â\u0085\u0094", Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('â\u0085\u0094', "2/3", olympics_df$Event))
unique(olympics_df$Event)[180]

unique(olympics_df$Event)[668]
olympics_df%>%filter(grepl("â\u0089¤", Event))
olympics_df <- olympics_df%>%
  mutate(Event = gsub('â\u0089¤', "<=", olympics_df$Event))
unique(olympics_df$Event)[668]

unique(olympics_df$Event) #good

write.csv(olympics_df, "Data/OlympicsData.csv",
          row.names = F)

#Fix Athlete data, define teams
## Team sports are formatted weirdly, the team name is listed with the finish 
##    and medal status with the list of team members on the following row.
unique(olympics_df$Athlete)
head(olympics_df%>%filter(grepl("â\u0080¢", Athlete))) #team sports
olympics_df <- olympics_df%>%
  mutate(Team = str_count(Athlete, "â\u0080¢")+1, #count athlete delimiters + 1
         Team.Name = if_else(grepl("â\u0080¢", Athlete), lag(Athlete), NA), #team name = prior athlete if row contains athlete delimiters.
         Medal = if_else(grepl("â\u0080¢", Athlete), lag(Medal), Medal),#if no finish data then medal = prior medal.
         Finish = if_else(Finish == "", lag(Finish), Finish))%>% #if no finish data then finish = prior finish if.  
  filter(!lead(grepl("â\u0080¢", Athlete))) #remove rows with team names to avoid duplicates.

#There is probably a better approach for extracting individuals from teams, but this is what I came up with.
teams <- olympics_df%>%
  filter(Team > 1)

individual <- olympics_df%>%
  filter(Team == 1)

nrow(individual)+nrow(teams) == nrow(olympics_df) #should be TRUE

system.time({ #about 10 seconds
for (i in c(1:nrow(teams))){
  row <- teams[i,] #select row
  year <- as.character(row$Year)
  season <- row$Season
  sport <- row$Sport
  event <- row$Event
  finish <- as.character(row$Finish)
  medal <- row$Medal
  team <- as.character(row$Team)
  teamName <- row$Team.Name
  
  athletes <- str_split(row$Athlete, pattern = " â\u0080¢ ")[[1]]
  aIDs <- str_split(row$Athlete.ID, patter = ", ")[[1]]
  
  df <- data.frame(matrix("", nrow = 0, ncol = 10))
  names(df) <- names(teams)
  
  for (y in c(1:length(athletes))) {
    new_row <- data.frame(year, season, sport, event,
                          athletes[y], finish, medal,
                          aIDs[y], team, teamName)
    names(new_row) <- names(teams)
    
    df <- bind_rows(df, new_row)
  }#end for y in athletes
  
  #change df column types
  df$Year <- as.integer(df$Year)
  df$Team <- as.numeric(df$Team)
  
  individual <- bind_rows(individual, df)
}#end for i in teams
})#end system.time

#Change Athlete ID to numeric
individual$Athlete.ID <- as.numeric(individual$Athlete.ID)

#Remove "Teams"
individual <- individual%>%
  filter(!is.na(Athlete.ID))

#Save data
write.csv(individual, "Data/OlympicsData_splitTeams.csv")

#Clean up
rm(df, new_row, row, aID, aIDs, athletes, event, finish,
   i, medal, season, sport, team, teamName, y, year)

#### SUMMARIES & FILTERS ####
#Filter Gold medal winners
gold <- olympics_df%>%
  filter(Medal == "Gold")

gold_ind <- individual%>%
  ungroup()%>%
  filter(!grepl("(\\(DNS\\))", Athlete), #Starters only. DNS = Did Not Start
         Medal == "Gold")%>%
  mutate(Fract.Gold = 1/Team)%>% #Fract.Gold = fractional gold, could be useful for weighting individual events.
  group_by(Athlete.ID)%>%
  select(-Athlete)%>% #drop athlete name, use athlete names from athlete_df
  summarise(Gold.Years = paste(unique(Year), collapse = ", "),
            Gold.Seasons = paste(unique(Season), collapse = ", "),
            Gold.Sports = paste(unique(Sport), collapse = ", "),
            Gold.Events = paste(unique(Event), collapse = " | "),
            Golds = n(),
            Fract.Gold = sum(Fract.Gold))%>%
  left_join(athlete_df, by = "Athlete.ID")%>%
  ungroup()

#Try to find missing birth location data
missing <- gold_ind%>%
  filter(is.na(Born) | Born == "")#40 missing locations

#Manually searched for missing data
##Import found data
found_data <- read.csv("Data/missing.csv")

#Drop extraneous columns
found_data <- found_data%>%
  select(-Source, -Notes)

#Extract additional birthplace location data
found_data <- found_data%>%
  mutate(City = str_remove_all(str_extract(Born, ".*,"), 
                               pattern = "([:punct:])"),
         State = if_else(grepl("\\,", Born),
                         str_remove_all(str_extract(Born, ", .* "), 
                                pattern = "([:punct:] )"),
                         str_remove_all(str_extract(Born, ".* \\("), 
                                        pattern = "( [:punct:])")),
         Country = str_remove_all(str_extract(Born, "\\(.{3}\\)"), 
                                  pattern = "([:punct:])"))%>%
  mutate(State = str_remove(State, pattern = "\\s$"))%>%#remove trailing whitespace from States
  left_join(iocCodes)
  
aIDs <- list(missing$Athlete.ID)[[1]]

#Update gold_ind df
gold_ind <- gold_ind%>%
  filter(!Athlete.ID %in% aIDs)%>%
  bind_rows(found_data)

gold_ind <- gold_ind%>%
  mutate(Athlete.ID = as.character(Athlete.ID))

check <- gold_ind%>%
  group_by(City, State, Country)%>%
  summarise(Count = n())

write.csv(gold_ind, file = "Data/GoldWinners.csv",
          row.names = F)

gold_country <- gold_ind%>%
  group_by(Country.Long, Country)%>%
  summarise(Athletes = n(),
            Golds = sum(Golds))%>%
  arrange(desc(Golds))%>%
  mutate(Country.Long = if_else(Country.Long == "Dominican Republic",
                               "Dominican Rep.", Country.Long),
         Country.Long = if_else(Country.Long == "Virgin Islands",
                                "Virgin Is.", Country.Long),
         Country.Long = if_else(Country.Long == "Trinidad and Tobago",
                                "Trinidad & Tobago", Country.Long))


#Run "Geolocate-API.R", skip if already run.
source("Geolocate-API.R")
#Read geolocated data
geo <- read.csv("Data/Geo.csv")

#Drop extraneous coluns
geo <- geo%>%
  select(-Response, -Note)

gold_ind_geo <- gold_ind%>%
  left_join(geo, by = join_by(City, State, Country))

#Save
write.csv(gold_ind_geo, file = "Data/GoldWinners_Geolocated.csv",
          row.names = F)

Cities <- gold_ind_geo%>%
  group_by(City, State, Country, lat, lon)%>%
  summarise(Athletes = n(),
            Golds = sum(Golds), 
            Fract.Golds = sum(Fract.Gold))

write.csv(Cities, file = "Data/Cities.csv",
          row.names = F)

#### GRAPHS ####
dir.create(paste(wd, "Graphs", sep ="/"))
source("ggplot theme.R")

plot <- ggplot(subset(gold_country, Country != "USA"),
               aes(reorder(Country.Long, desc(Athletes)), Athletes))+
  geom_col(fill = "#F5DF67")+
  labs(title = "Foreign Born Gold Medalists",
       y = "Gold Medalists",
       x = "Birth Country")+
  scale_y_continuous(breaks = seq(0, 10, by = 2))+
  theme(plot.background = element_rect(fill = 'transparent', color = "transparent"),
        #panel.background = element_rect(fill = "#BEE8FF"),
        panel.grid.major.x = element_blank(),
        panel.border = element_rect(color = "black", linewidth = 1, fill = 'transparent'),
        axis.text.x = element_text(angle = 45, vjust = 1, hjust=1, color = "Black"),
        axis.title.x = element_text(size = 24, vjust = 2),
        axis.text.y = element_text(color = "black"),
        axis.title.y = element_text(size = 24, vjust = 1, hjust = 0.3),
        plot.title = element_text(size = 40))
plot
ggsave(plot, path = "Graphs",
       filename = "OtherCountries.png", scale = 2)

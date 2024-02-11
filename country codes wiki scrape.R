### Wikipedia Scrape
### Travis Zalesky
### 2/3/2024
### Purpose: To scrape IOC country codes from Wikipedia.

#Load Packages
library("RCurl")
library("XML")
library("tidyverse")


link <- "https://en.wikipedia.org/wiki/List_of_IOC_country_codes"


xml <- readLines(link)%>% #XML::getURL returning error: "CertGetCertificateChain trust error CERT_TRUST_IS_NOT_TIME_VALID"
  htmlParse(asText=TRUE)

#Get tables from xml
xml_table <- xml%>%
  xpathSApply('//*//table', xmlValue)

xml_table <- xml_table[1] #only need table 1.

#parse xml_table rows
xml_table <- str_split(xml_table, pattern = "\\[.*\\]")[[1]]

#Set up empty df
df <- data.frame(matrix("", nrow = 0, ncol = 2))

#first row is a little different than subsequent table rows
xml_tableHead <- xml_table[1]

tableHead <- str_split(xml_tableHead, "\n")[[1]][c(1,3)]

names(df) <- tableHead
                       
row <- str_split(xml_tableHead, "\n")[[1]][c(8,9)]
row[1] <- str_remove(row[1], pattern = ".*\\}")
row <- data.frame(row[1], row[2])
names(row) <- tableHead
df <- bind_rows(df, row)

for (i in c(2:length(xml_table))) {
  row <- str_split(xml_table[i], "\n")[[1]]
  row <- row[sapply(row, function(x){str_length(x) > 1})]
  
  if (length(row) > 0) {
    row <- data.frame(row[1], row[2])
    names(row) <- tableHead
    df <- bind_rows(df, row)
  } #else do nothing
  
} #end for i in xml_table

#There are 2 bad rows; 23 and 191
##Additionally, there are white spaces present.
df <- df%>%
  rename(Country = Code,
         Country.Long = `National Olympic Committee`)%>%
  filter(!is.na(Country.Long))%>%
  mutate(Country.Long = str_remove(Country.Long, pattern = "^\\s"))

write.csv(df, file = "Z:/Documents/My Code/Olympics/Data/IOCCodes.csv",
          row.names = F)

#Clean up
rm(df, i, link, row, tableHead, xml, xml_table, xml_tableHead)

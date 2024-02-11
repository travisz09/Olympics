# The Olympic States of America
## Scrape and Analize Olympics Data from [Olympedia.org](https://www.olympedia.org/)
### Original R Code by Travis Zalesky

#### Summary: 
Data was scraped from [Olympedia.org](https://www.olympedia.org/) in R (v4.3.2)[^1] using packages RCurl[^2], XML[^3], and tidyverse[^4], with an emphasis on team USA. Geographic data was geolocated using packages httr[^5] and tidyverse[^4], with geolocation services provided by [API-Ninjas](https://rapidapi.com/apininjas/api/geocoding-by-api-ninjas). Data analysis and vissualization was performed with tidyverse[^4], and other supporting R code. Final figure generation was completed in ArcGIS Pro (v3.2.1)[^6].

#### Objective:
This collection of original R scripts was developed with the intention of generating a geospacial vissualization (i.e. a map) of USA Olympic gold medalist for submission to the [University of Arizona](https://www.arizona.edu/), [Data Vissualization Challenge, 2024](https://data.library.arizona.edu/data-science/data-viz-challenge). All works herin are authored by me (Travis Zalesky) and are being provided to the GitHub community in the interest of transparency and repeatability.

#### Methods:
- ##### olympedia scrape.R
A directory of links related to team USA was downloaded from [olympedia.org/countries/USA](http://www.olympedia.org/countries/USA). A subset of this directory was identified containing internal page links to detailed results for every event in which an American athlete competed, for every Olympics. Xml text was downloaded for each relevant page and the xml was subest to isolate the table of results. Results data was extracted from the xml table and saved as a data frame (df). Additionally, links to each American athlete's bio page were extracted and data was again downloaded as, and extracted from, xml text. A unique athlete ID number was generated for each. Athlete data was saved as a seperate, large, df.

- ##### olympedia wrangle.R
Dates were parsed for both athlete and event data from an ambiguous format using a custom function. Birthplace information for each athlete was extracted and seperated from a text string and saved as an unambiguous City, State, Country format, being careful to remove extranious punctuation and whitespaces. Birth country names were infered from three letter International Olympic Commitie (IOC) country codes (see Supporting Code). 
The events data was searched for bad unicode charachers and were updated as neccessary with simplified text. The events data frame was then lengthened by identifying and extracting individual athletes from team events. The resulting df was then filtered to only include gold medalists and was summarized for each athlete by unique athlete ID. The gold medalists event data was joined to their biographical data by athlete ID. Next, the gold medalists were queried to identify athletes with missing birthplace data. Fourty athletes with incomplete records were identified and additional biographical data was manually searched on the web and obtained from a variety of sources (see file "missing.csv"). Updated biographical data was then appended to the df as needed. Next the unique birthplaces of each athlete were extracted and summarized in a seperate df which was then geolocated (see "Geolocate-API.R"). Finally, data was summarized using a varriety of statistics and vissualizations were generated using ggplot (a part of the tidyverse).

- ##### Geolocate-API.R
Each unique birthplace of all American gold medalists were querired through [API-Ninjas](https://rapidapi.com/apininjas/api/geocoding-by-api-ninjas) free geolocation service (subscription required, terms apply). Geolocation results were returned as a string, from which latitudes and longitudes were extracted. Additional notes were generated and full, detailed results were retained. Locations returning errors (primarily the result of bad unicode characters) were manually querried and appended as neccesary. Geolocation results were then saved and joined to the gold medalist df by City, State, and Country.

- ##### Supporting Code
Additional supporting R code is given in "country codes wiki scrape.R" and "ggplot theme.R". These scripts (1) scrape IOC country codes and their associated countries names from [Wikipedia](https://en.wikipedia.org/wiki/Main_Page), [List of IOC country codes](https://en.wikipedia.org/wiki/List_of_IOC_country_codes), and (2) set my perfered ggplot2 theme for general use data vissualization.

- ##### Final Figure Generation
Finishing and cartogrophy was completed in ArcGIS Pro (v3.2.1)[^6]. 

#### Licencing
Copyright (c) 2024 Travis Zalesky

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




[^1]: R Core Team. (2021). R: A Language and Environment for Statistical Computing. R Foundation for Statistical Computing. https://www.R-project.org/
[^2]: Lang, D. T. (2024). RCurl: General Network (HTTP/FTP/...) Client Interface for R. https://CRAN.R-project.org/package=RCurl
[^3]: Lang, D. T. (2024). XML: Tools for Parsing and Generating XML Within R and S-Plus. https://CRAN.R-project.org/package=XML
[^4]: Wickham, H., Averick, M., Bryan, J., Chang, W., McGowan, L. D., François, R., Grolemund, G., Hayes, A., Henry, L., Hester, J., Kuhn, M., Pedersen, T. L., Miller, E., Bache, S. M., Müller, K., Ooms, J., Robinson, D., Seidel, D. P., Spinu, V., … Yutani, H. (2019). Welcome to the tidyverse. Journal of Open Source Software, 4(43), 1686. https://doi.org/10.21105/joss.01686
[^5]: Wickham, H. (2023). httr: Tools for Working with URLs and HTTP. https://CRAN.R-project.org/package=httr
[^6]: ESRI 2023. ArcGIS Pro: Release 3. Redlands, CA: Environmental Systems Research Institute.

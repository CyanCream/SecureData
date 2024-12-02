library(tidyverse)
library(arrow)
library(dplyr)

pq_path <- paste0(getwd(),"/inst/extdata/starwars.parquet")

my_starwars <- read.csv("C:/Users/yren/Documents/github/SecureData/inst/extdata/starwars.csv")

my_starwars |>
  mutate(record_date =
           as.Date(runif(n(),
                         as.numeric(as.Date('2017/01/01')),
                         as.numeric(as.Date('2023/05/01'))),
                   origin = "1970-01-01"))|>
  dplyr::group_by(record_date,homeworld) |>
  arrow::write_dataset(path = pq_path, format = "parquet")

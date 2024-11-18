library(tidyverse)
library(arrow)
library(dplyr)

pq_path <- paste0(getwd(),"/inst/extdata/starwars.parquet")

my_starwars <- read.csv("C:/Users/yren/Documents/github/SecureData/inst/extdata/starwars.csv")

my_starwars|>
  dplyr::group_by(homeworld) |>
  arrow::write_dataset(path = pq_path, format = "parquet")




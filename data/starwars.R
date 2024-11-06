library(tidyverse)
library(arrow)
library(dplyr)

pq_path <- "data_arrow/starwars"

dplyr::starwars|>
  dplyr::group_by(homeworld) |>
  arrow::write_dataset(path = pq_path, format = "parquet")

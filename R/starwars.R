library(tidyverse)
library(arrow)
library(dplyr)

pq_path <- "data/starwars"

starwars|>
  group_by(homeworld) |>
  write_dataset(path = pq_path, format = "parquet")

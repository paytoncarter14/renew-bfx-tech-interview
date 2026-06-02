#!/usr/bin/env Rscript

library(tidyverse)

args = commandArgs(trailingOnly = TRUE)

expected_reference = args[1]

files = list.files(pattern = "*.flagstat.txt")
results = tibble(
  sample = character(),
  reference = character(),
  state = character(),
  primary_reads = numeric(),
  primary_mapped_reads = numeric(),
  pct_primary_mapped = numeric()
)

for (file in files) {
  name = strsplit(file, '.', fixed = T)[[1]][1]
  split = strsplit(name, '__', fixed = T)[[1]]
  sample = split[[1]]
  state = split[[2]]
  reference = split[[3]]
  tsv = read_tsv(file, col_names = F)
  primary_reads = tsv[[2,1]] |> as.numeric()
  primary_mapped_reads = tsv[[9,1]] |> as.numeric()
  pct_primary_mapped = tsv[[10,1]] |>
    str_sub(end = -2) |>
    as.numeric()
  results = results |> add_row(sample, reference, state, primary_reads, primary_mapped_reads, pct_primary_mapped)
}

results = results |> mutate(state = factor(state, levels = c('before', 'after')))
write_csv(results, 'results.csv')

for (sample in distinct(results, sample)$sample) {

  dropped_results = results |> filter(reference != expected_reference, sample == sample)
  expected = results |> filter(reference == expected_reference, sample == sample)
  expected_before = expected |> filter(state == 'before') |> pull(pct_primary_mapped)
  expected_after = expected |> filter(state == 'after') |> pull(pct_primary_mapped)
  
  caption = paste0(
    "Expected reference: ", expected_reference,
    "\nBefore % primary mapped: ", expected_before,
    "\nAfter % primary mapped: ", expected_after
  )
  p = ggplot(dropped_results, aes(x=state, y=pct_primary_mapped, fill=reference)) +
    geom_bar(stat='identity', position='dodge') +
    ggtitle(sample) +
    labs(caption = caption)
  
  ggsave(paste0(sample, '.png'), height = 4, width = 6, dpi = 300)

}
###############################################################################
# Process Origin–Destination (OD) Census Data for Portugal
# Author: André Brito
# Date: 2025-11-27
# -----------------------------------------------------------------------------
# This script:
# 1. Loads reference municipality/district metadata
# 2. Cleans Origin and Destination codes
# 3. Reconstructs "Origem" values downward where NA is used to indicate grouping
# 4. Joins administrative codes
# 5. Outputs an OD dataset in tidy format
###############################################################################

# ─────────────────────────────────────────────────────────────────────────────
# Libraries
# ─────────────────────────────────────────────────────────────────────────────
library(readxl)
library(dplyr)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
`%!in%` <- function(x, y) !(x %in% y)

# ─────────────────────────────────────────────────────────────────────────────
# User Inputs
# ─────────────────────────────────────────────────────────────────────────────
# Path to district/municipality reference table
ref_path <- "caop.rds"

# Raw Excel OD data (exported from INE)
raw_excel <- "all_data.xlsx"

# Output path
out_path <- "OD_data_Portugal_Census.rds"

# ─────────────────────────────────────────────────────────────────────────────
# Load inputs
# ─────────────────────────────────────────────────────────────────────────────
dist_muni_ref <- readRDS(ref_path)
all_data <- read_excel(raw_excel)

# Sanity check
if (!all(c("Origem", "Destino", "n") %in% names(all_data))) {
  stop("Input file must contain at least: 'Origem', 'Destino', 'n'.")
}

# ─────────────────────────────────────────────────────────────────────────────
# Detect destinations missing from reference table
# ─────────────────────────────────────────────────────────────────────────────
missing_dest <- dist_muni_ref$Name %!in% all_data$Destino
if (any(missing_dest)) {
  warning("Some municipalities in reference table are not present in the data:\n",
          paste(dist_muni_ref$Name[missing_dest], collapse = ", "))
}

# ─────────────────────────────────────────────────────────────────────────────
# Reconstruct "Origem"
# NOTE: INE tables often omit repeated values; the first row gives a parent,
# and below rows inherit that origin until a new one appears.
# ─────────────────────────────────────────────────────────────────────────────
n <- nrow(all_data)
new_origem <- rep(NA_character_, n)

prev <- all_data$Origem[1]
new_origem[1] <- prev

for (i in 2:n) {
  cur <- all_data$Origem[i]
  if (!is.na(cur)) prev <- cur
  new_origem[i] <- prev
}

all_data$new_origem <- new_origem
all_data <- all_data %>% select(-Origem)

# ─────────────────────────────────────────────────────────────────────────────
# Extract codes
# Assuming municipality codes = first 4 characters of municipality name
# ─────────────────────────────────────────────────────────────────────────────
all_data$code_origin      <- substr(all_data$new_origem, 1, 4)

# ─────────────────────────────────────────────────────────────────────────────
# Join metadata
# ─────────────────────────────────────────────────────────────────────────────
ref_clean <- dist_muni_ref %>%
  select(REF, Name) %>%
  distinct()

all_data <- left_join(
  all_data,
  ref_clean %>% rename(code_destination = REF, Destino = Name),
  by = "Destino"
)

all_data <- left_join(
  all_data,
  ref_clean %>% rename(code_origin = REF, Origem_ref = Name),
  by = "code_origin"
)

# ─────────────────────────────────────────────────────────────────────────────
# Final selection
# ─────────────────────────────────────────────────────────────────────────────
OD_data <- all_data %>%
  select(
    code_origin,
    Origem = Origem_ref,
    code_destination,
    Destino,
    n
  )

# ─────────────────────────────────────────────────────────────────────────────
# Export
# ─────────────────────────────────────────────────────────────────────────────
saveRDS(OD_data, out_path)
message("✔ OD data successfully saved: ", out_path)
  


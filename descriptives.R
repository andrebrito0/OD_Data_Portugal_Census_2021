
# ─────────────────────────────────────────────────────────────────────────────
# Libraries
# ─────────────────────────────────────────────────────────────────────────────
library(readxl)
library(dplyr)
library(ggplot2)
library(sf)
library(circlize)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
'%!in%' <- function(x, y) !(x %in% y)

# ─────────────────────────────────────────────────────────────────────────────
# User Inputs
# ─────────────────────────────────────────────────────────────────────────────
# Path to district/municipality reference table
ref_caop <- "caop.rds"

# Raw Excel OD data (exported from INE)
ref_data <- "OD_data_Portugal_Census.rds"

# Output path
out_path <- "OD_data_Portugal_Census.rds"

# ─────────────────────────────────────────────────────────────────────────────
# Load inputs
# ─────────────────────────────────────────────────────────────────────────────
dist_muni_ref <- readRDS(ref_caop)
od_data <- readRDS(ref_data)

dist_od <- od_data %>% 
  mutate(district_origin = substr(code_origin, 1, 2),
         ditritct_destination = substr(code_destination, 1, 2)) %>% 
  select(district_origin, ditritct_destination, n) %>% 
  group_by(district_origin, ditritct_destination) %>% 
  summarise(n = sum(n))

dist_od <- dist_od %>% filter(district_origin != ditritct_destination)
dist_ref <- dist_muni_ref %>% group_by(Code) %>% summarise(District = first(District))

dist_od <- merge(dist_od, dist_ref %>% rename(district_origin = Code, Origin = District))
dist_od <- left_join(dist_od, dist_ref %>% rename(ditritct_destination = Code, Destination = District))


# Ensure districts and counts are properly formatted
od_clean <- dist_od %>%
  group_by(Origin, Destination) %>%
  summarise(count = sum(n), .groups = "drop")

od_sorted <- od_clean %>%
  mutate(
    Origin = factor(Origin, levels = district_order),
    Destination = factor(Destination, levels = district_order)
  )

flow_totals <- od_clean %>%
  mutate(
    outflow = count,
    inflow  = count
  ) %>%
  group_by(Origin) %>% summarise(outflow = sum(outflow)) %>%
  full_join(
    od_clean %>% group_by(Destination) %>% summarise(inflow = sum(count)),
    by = c("Origin" = "Destination")
  ) %>%
  mutate(total_flow = outflow + inflow) %>%
  rename(district = Origin)

district_order <- flow_totals %>%
  arrange(desc(total_flow)) %>%
  pull(district)

pastel_18 <- c(
  "#FBB4AE", "#B3CDE3", "#CCEBC5", "#DECBE4", 
  "#FED9A6", "#FFFFCC", "#E5D8BD", "#FDDAEC", 
  "#F2F2F2", "#F6D8AE", "#D5E8D4", "#E1D5E7",
  "#CCE5FF", "#FFCCCC", "#FFE6CC", "#E6FFCC",
  "#D9CCFF", "#CCF2FF"
)

pastel_pal <- setNames(pastel_18, district_order)

# Set output file and resolution
svg("chord_diagram.svg", width = 8, height = 8)
chordDiagram(
  od_sorted,
  grid.col = pastel_pal,
  annotationTrackHeight = c(0.08, 0.02),   # increase the name track
  link.sort = TRUE
)
dev.off()

library(viridis)

col_pal <- setNames(
  viridis(length(districts), option = "D"),
  districts
)

circos.clear()

chordDiagram(
  od_clean,
  grid.col = col_pal,
  transparency = 0.2,
  directional = 1,         # arrows from origin → destination
  direction.type = c("arrows", "diffHeight"),
  link.arr.type = "big.arrow",
  annotationTrack = "grid",
  preAllocateTracks = 1
)

circos.trackPlotRegion(
  track.index = 1,
  panel.fun = function(x, y) {
    sector.name <- get.cell.meta.data("sector.index")
    circos.text(
      x = get.cell.meta.data("xcenter"),
      y = get.cell.meta.data("ylim")[1] + mm_y(3),
      labels = sector.name,
      facing = "clockwise",
      niceFacing = TRUE,
      adj = c(0, 0.5),
      cex = 0.7
    )
  },
  bg.border = NA
)



# ─────────────────────────────────────────────────────────────────────────────
# Districts 
# ─────────────────────────────────────────────────────────────────────────────

mainland <- st_read("~/PhD/2025/Individual-Based Models/OD Movement Data/maps/mainland_portugal.shp")
st_crs(mainland) <- st_crs(4326)  # Example: WGS84 (EPSG:4326)
distritos <- st_read("~/PhD/2025/Individual-Based Models/OD Movement Data/maps/distritos-shapefile/distritos.shp")
distritos <- st_as_sf(distritos)
distritos %>% filter(TYPE_1 == 'Distrito') -> distritos

# Check which polygons are invalid
invalid_geometries <- distritos[!st_is_valid(distritos), ]
distritos <- st_make_valid(distritos)

centroids <- st_centroid(distritos)

ggplot() +
  geom_sf(data = distritos, fill = "grey95", color = "black") +
  geom_sf(data = centroids, fill = 'indianred1')

make_curve <- function(p1, p2, curve = 0.15) {
  
  # extract coordinates
  c1 <- st_coordinates(p1)
  c2 <- st_coordinates(p2)
  
  # midpoint
  mid <- (c1 + c2) / 2
  
  # vector from p1 → p2
  v <- c2 - c1
  
  # perpendicular vector
  perp <- c(-v[2], v[1])
  perp <- perp / sqrt(sum(perp^2))  # normalize
  
  # shift midpoint for curvature
  mid_shifted <- mid + perp * curve * sqrt(sum(v^2))
  
  # build curved line (3-point linestring)
  st_linestring(rbind(c1, mid_shifted, c2))
}

# Join OD with coordinates
od_sf <- dist_od %>%
  left_join(centroids %>% select(CCA_1, geometry), by = c("district_origin" = "CCA_1")) %>%
  rename(geom_origin = geometry) %>%
  left_join(centroids %>% select(CCA_1, geometry), by = c("ditritct_destination" = "CCA_1")) %>%
  rename(geom_dest = geometry)

od_sf <- dist_od %>%
  left_join(centroids %>% select(CCA_1, geometry), by = c("district_origin" = "CCA_1")) %>%
  rename(geom_o = geometry) %>%
  left_join(centroids %>% select(CCA_1, geometry), by = c("ditritct_destination" = "CCA_1")) %>%
  rename(geom_d = geometry) %>%
  filter(!st_is_empty(geom_o), !st_is_empty(geom_d)) %>%   # removes missing cases
  rowwise() %>%
  mutate(
    geometry = st_sfc(
      st_linestring(
        rbind(
          st_coordinates(geom_o),
          st_coordinates(geom_d)
        )
      ),
      crs = st_crs(centroids)
    )
  ) %>% 
  ungroup() %>% 
  st_as_sf() %>%
  select(district_origin, ditritct_destination, n, geometry) %>% 
  st_set_geometry("geometry")

ggplot() +
  geom_sf(data = distritos, fill = "antiquewhite", color = "black") +
  geom_sf(data = od_sf,
          aes(size = n, color = district_origin),
          alpha = 0.7) +
  geom_sf(data = centroids, fill = "indianred1", shape = 21, color = "black") +
  theme_bw() +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"), panel.border = element_rect(colour = "black", fill=NA, size=1)) +
  scale_size(range = c(0.3, 3)) +
  labs(size = "Flow count")


curved_od <- dist_od %>%
  left_join(centroids %>% select(CCA_1, geometry), by = c("district_origin" = "CCA_1")) %>%
  rename(geom_o = geometry) %>%
  left_join(centroids %>% select(CCA_1, geometry), by = c("ditritct_destination" = "CCA_1")) %>%
  rename(geom_d = geometry) %>%
  rowwise() %>%
  mutate(
    geometry = st_sfc(
      make_curve(geom_o, geom_d, curve = 0.15), 
      crs = st_crs(centroids)
    )
  ) %>%
  ungroup() %>%
  st_as_sf() %>%
  st_set_geometry("geometry")   # important!

ggplot() +
  geom_sf(data = distritos, fill = "antiquewhite", color = "black") +
  geom_sf(data = curved_od,
          aes(size = n, color = district_origin),
          alpha = 0.7) +
  geom_sf(data = centroids, aes(fill = CCA_1), shape = 21, color = "black") +
  theme_bw() +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), 
        panel.background = element_rect(fill = "aliceblue"), 
        panel.border = element_rect(colour = "black", fill=NA, size=1),
        legend.position = 'none') +
  scale_size(range = c(0.3, 3)) +
  labs(size = "Flow count")

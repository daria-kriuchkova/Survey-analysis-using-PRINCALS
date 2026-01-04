# 0: loading the libraries

library(Gifi)
library(dplyr)
library(ggplot2)
library(plotly)
library(readr)

options(repr.plot.width = 10, repr.plot.height = 7)

# 1: formatting

# Likert question names
likert_names <- paste0("q", 1:19)

# Major party colors
major_parties <- c(
  "A"  = "#D00000",
  "F"  = "#E600A8",
  "V"  = "#1041C0",
  "B"  = "#A022B6",
  "C"  = "#7DAE00",
  "Ø" = "#F25700",
  "I"  = "#00A8D9",
  "Å" = "#1DA82D",
  "Q"  = "#21D2B4",
  "ME" = "#EECA3A"
)

all_colors <- c(major_parties, "Other" = "gray70")

assign_party_colors <- function(df) {
  df$party_color_group <- ifelse(
    df$party_code %in% names(major_parties),
    df$party_code,
    "Other"
  )
  df
}

# 2: loading the data

df <- read_csv("survey_raw.csv", show_col_types = FALSE)
df <- as.data.frame(df)

# Keep only complete Likert responses
df <- df[complete.cases(df[, likert_names]), ]

# Preview
dim(df)
head(df[, likert_names])

# 3: loading the questions

questions <- read.csv("questions.csv", stringsAsFactors = FALSE)
head(questions)

# 4: candidates per color group

df <- assign_party_colors(df)
table(df$party_color_group)

# 5: adding my answers

my_answers <- data.frame(
  q1 =  -0.5, q2 = -1, q3 = -0.5, q4 =  0.5, 
  q5 = -1,  q6 =  0.5, q7 =  0.5, q8 =  -0.5, 
  q9 =  1, q10 = -1, q11 = -0.5, q12 = -0.5, 
  q13 = -0.5, q14 = -0.5, q15 =  0.5, q16 = -1, 
  q17 = -0.5, q18 = -0.5, q19 =  0.5
)

# Create a template row matching df
my_row <- df[1, ]
my_row[,] <- NA

# Insert answers
for (q in likert_names) {
  my_row[[q]] <- my_answers[[q]]
}

# Metadata
my_row$party_code  <- "ME"
my_row$party_name  <- "My result"
my_row$cand_number <- 1
my_row$cand_id     <- "ME_1"
my_row$issue_1 <- ""
my_row$issue_2 <- ""
my_row$issue_3 <- ""

# Bind
df_with_me <- rbind(df, my_row)

#tail(df_with_me, 2)

# 6: princals

likert_df <- df_with_me[, likert_names]

fit_princals <- princals(
  likert_df,
  ndim = 3
)

fit_princals

# 7: scree plot

eigenvalues <- fit_princals$evals
var_explained <- eigenvalues / sum(eigenvalues) * 100  # in percent
n_dim <- length(eigenvalues)

# Scree plot 

plot(1:n_dim, var_explained, type = "b", pch = 19, col = "blue",
     xlab = "Principal Component", ylab = "Variance Explained (%)",
     main = "PRINCALS Scree Plot (% Variance Explained)")
abline(h = 5, lty = 2, col = "red")  # optional threshold line (e.g., 5%)

text(1:n_dim, var_explained, labels = round(var_explained, 1), pos = 3, cex = 0.8)

# 8: calculating the scores
selected_pcs <- 1:3
scores <- fit_princals$objectscores[, selected_pcs, drop = FALSE]
head(scores)

# 9: transpolt pc1

options(repr.plot.width = 20, repr.plot.height = 24)
plot(fit_princals,
     plot.type = "transplot",
     var.subset = 1:19,
     lwd = 1)

# Preview the questions
questions

# Convert scores to a data.frame and add row numbers
scores_df <- as.data.frame(scores)
colnames(scores_df) <- paste0("d", 1:ncol(scores))  # d1, d2, d3

# Add a row index to merge
scores_df$row_id <- 1:nrow(scores_df)
df_with_me$row_id <- 1:nrow(df_with_me)

# Merge on row_id
merged_df <- merge(
  df_with_me[, c("row_id", "cand_id", "cand_number", "party_code", "party_name", "issue_1", "issue_2", "issue_3")],
  scores_df,
  by = "row_id"
)

# Optional: remove row_id if not needed
merged_df$row_id <- NULL

#head(merged_df, 2)

plot_princals_loadings <- function(
  fit_princals,
  original_vars,
  dims_2d = c(1, 2),
  control_dims = NULL,
  rotation_deg = 0,
  n_top = 5,
  plot_width = 10,
  plot_height = 10
) {
  # Axis names
  dim_names <- paste0("PC", dims_2d)
  
  # Extract loadings
  coords <- fit_princals$loadings[original_vars, dims_2d, drop = FALSE]
  
  # Regress out control dimensions if requested
  if (!is.null(control_dims)) {
    control_coords <- fit_princals$loadings[original_vars, control_dims, drop = FALSE]
    
    for (i in 1:ncol(coords)) {
      lm_fit <- lm(coords[, i] ~ as.matrix(control_coords))
      coords[, i] <- residuals(lm_fit)
    }
    
    control_names <- paste0("PC", control_dims)
    dim_names <- paste0(
      "Residual ", dim_names,
      " (controlled for ", paste(control_names, collapse = ","), ")"
    )
  }
  
  # Apply rotation (AFTER residualization)
  if (rotation_deg != 0) {
    theta <- rotation_deg * pi / 180
    R <- matrix(
      c(cos(theta), -sin(theta),
        sin(theta),  cos(theta)),
      nrow = 2,
      byrow = TRUE
    )
    
    coords <- as.matrix(coords) %*% t(R)
  }
  
  # Set plot size
  options(repr.plot.width = plot_width, repr.plot.height = plot_height)
  
  # Plot
  par(mar = c(5, 4, 4, 2) + 0.1)
  plot(
    0, 0,
    xlim = range(c(0, coords[, 1])),
    ylim = range(c(0, coords[, 2])),
    xlab = dim_names[1],
    ylab = dim_names[2],
    main = paste(
      "PRINCALS Loadings (",
      dim_names[1], " vs ", dim_names[2],
      if (rotation_deg != 0) paste0(", rotated ", rotation_deg, "°"),
      ")",
      sep = ""
    ),
    type = "n"
  )
  
  arrows(
    0, 0,
    coords[, 1], coords[, 2],
    length = 0.1,
    col = "black"
  )
  
  text(
    coords[, 1], coords[, 2],
    labels = original_vars,
    pos = 3,
    cex = 0.8
  )
  
  # Top contributors
  abs_loadings <- abs(coords)
  
  top_D1 <- sort(abs_loadings[, 1], decreasing = TRUE)[1:n_top]
  top_D2 <- sort(abs_loadings[, 2], decreasing = TRUE)[1:n_top]
  
  cat("Top contributors to", dim_names[1], ":\n")
  for (var in names(top_D1)) {
    cat(var, ":", round(coords[var, 1], 3), "\n")
  }
  
  cat("\nTop contributors to", dim_names[2], ":\n")
  for (var in names(top_D2)) {
    cat(var, ":", round(coords[var, 2], 3), "\n")
  }
}

plot_princals_loadings(fit_princals, likert_names, dims_2d = c(1,2), n_top = 5)

# Define the output file path
output_file <- "pc1_pc2_rot.png"

# Open PNG device
png(filename = output_file, width = 1200, height = 1200, res = 150)

# Call your plotting function
plot_princals_loadings(fit_princals, likert_names, rotation_deg = 190, dims_2d = c(1,2), n_top = 5)

# Close the device to save the file
dev.off()

plot_princals_loadings(fit_princals, likert_names, dims_2d = c(1,3), n_top = 5)

# PC2 vs PC3 after removing PC1 influence
plot_princals_loadings(fit_princals, likert_names, dims_2d = c(2,3), control_dims = 1, n_top = 5)

plot_princals_loadings(fit_princals, likert_names, rotation_deg = 190, dims_2d = c(1,2), n_top = 5)

plot_princals_loadings(fit_princals, likert_names, rotation_deg = 195, dims_2d = c(1,3), n_top = 5)

# Convert scores to a data.frame and add row numbers
scores_df <- as.data.frame(scores)
colnames(scores_df) <- paste0("d", 1:ncol(scores))  # d1, d2, d3

# Add a row index to merge
scores_df$row_id <- 1:nrow(scores_df)
df_with_me$row_id <- 1:nrow(df_with_me)

# Merge on row_id
merged_df <- merge(
  df_with_me[, c("row_id", "cand_id", "cand_number", "party_code", "party_name",
                 "issue_1", "issue_2", "issue_3", likert_names)],
  scores_df,
  by = "row_id"
)

# Optional: remove row_id if not needed
merged_df$row_id <- NULL

#head(merged_df, 2)

# Rotating D1 and D2

theta <- 190 * pi / 180

R <- matrix(
  c(cos(theta), -sin(theta),
    sin(theta),  cos(theta)),
  nrow = 2,
  byrow = TRUE
)

old_scores <- scores[, c(1, 2)]
new_scores <- old_scores %*% t(R)

colnames(new_scores) <- c("d4", "d5")

merged_df$d4 <- new_scores[, 1]
merged_df$d5 <- new_scores[, 2]

tail(merged_df, 2)

# 11: questions input

# Very important questions: exact match
#very_important_questions <- c("q9")  # can be empty: character(0)
very_important_questions <- character(0)

# Important questions: directional agreement
important_questions <- c("q9", "q10")   # can be empty: character(0)
#important_questions <- character(0)

# 12: base calculations for top candidates and parties

# Initialize checks as FALSE by default
merged_df$dir_check <- FALSE
merged_df$vibe_check <- FALSE

# ME_1 row
me_row <- merged_df$cand_id == "ME_1"
my_answers <- merged_df[me_row, likert_names]

# --- Important questions: directional agreement ---
if (length(important_questions) > 0) {
  # Check if each candidate has the same direction as ME_1 on ALL important questions
  dir_agree <- apply(
    merged_df[, important_questions, drop = FALSE],
    1,
    function(x) all(sign(x) == sign(my_answers[, important_questions])))
  
  merged_df$dir_check <- dir_agree
  merged_df$vibe_check <- dir_agree  # For directional questions, vibe_check = same as dir
}

# --- Very important questions: exact match ---
if (length(very_important_questions) > 0) {
  exact_match <- apply(
    merged_df[, very_important_questions, drop = FALSE],
    1,
    function(x) all(x == my_answers[, very_important_questions]))
  
  # Update checks: only candidates passing very important questions remain TRUE
  merged_df$dir_check <- merged_df$dir_check & exact_match
  merged_df$vibe_check <- merged_df$vibe_check & exact_match
}

# Coordinates of ME_1 in rotated space (d3–d5)
coords_me <- as.numeric(merged_df[me_row, c("d3", "d4", "d5")])

# Candidates only
df_candidates <- merged_df

# Update d1 and d2, drop d4 and d5
df_candidates$d1 <- df_candidates$d4
df_candidates$d2 <- df_candidates$d5
df_candidates$d4 <- NULL
df_candidates$d5 <- NULL

# Coordinates of ME_1 in the SAME space (d1, d2, d3)
coords_me <- as.numeric(
  df_candidates[df_candidates$cand_id == "ME_1", c("d1", "d2", "d3")]
)

# Distance to ME_1
df_candidates$distance_to_me <- sqrt(
  rowSums(
    (as.matrix(df_candidates[, c("d1", "d2", "d3")]) -
       matrix(coords_me, nrow = nrow(df_candidates), ncol = 3, byrow = TRUE)
    )^2
  )
)

df_test <- df_candidates[df_candidates$vibe_check, ]
df_test

# 13: Mapping all the candidates

use_vibe_formatting <- FALSE   # set to FALSE to disable vibe-based formatting

# Assign party color group
df_plot <- assign_party_colors(df_candidates)

# Legend grouping
df_plot$party_legend <- ifelse(
  df_plot$party_code %in% names(major_parties),
  df_plot$party_name,
  "Other parties"
)

# Unique major parties in df_plot
major_in_plot <- unique(df_plot$party_code[df_plot$party_code %in% names(major_parties)])

# Map party_name → color
legend_colors <- c(
  setNames(
    major_parties[major_in_plot],
    df_plot$party_name[match(major_in_plot, df_plot$party_code)]
  ),
  "Other parties" = "gray70"
)

# ---- SHAPE LOGIC ----
# If vibe formatting is off, everyone gets the same shape
df_plot$point_shape <- if (use_vibe_formatting) {
  ifelse(df_plot$vibe_check, 16, 4)
} else {
  16
}

# Plot
p <- ggplot(
  df_plot,
  aes(
    x = d1,
    y = d2,
    color = party_legend,
    text = paste(
      "Candidate:", cand_id,
      "<br>Party:", party_name,
      "<br>Distance:", round(distance_to_me, 3),
      "<br>Agrees on important qs:", vibe_check
    )
  )
) +
  geom_point(
    data = df_plot[!duplicated(df_plot$party_code), ],
    size = 2.5,
    shape = df_plot$point_shape[!duplicated(df_plot$party_code)],
    show.legend = FALSE
  ) +
  geom_point(
    data = df_plot[duplicated(df_plot$party_code), ],
    size = 1.5,
    shape = df_plot$point_shape[duplicated(df_plot$party_code)],
    show.legend = FALSE
  ) +
  scale_color_manual(values = legend_colors) +
  theme_minimal() +
  labs(
    x = "PC1: Social → Private",
    y = "PC2: Radical → Mainstream",
    color = "Party"
  )

ggplotly(p, tooltip = "text")

# 14: top candidates passing the vibe check

df_cand <- df_candidates[!me_row, ]

# Filter by vibe_check if any TRUE, otherwise use all candidates
if (any(df_cand$vibe_check)) {
  df_top <- df_cand[df_cand$vibe_check, ]
} else {
  df_top <- df_cand
}

# Order by distance to ME_1
df_top <- df_top[order(df_top$distance_to_me), ]

# Select relevant columns
df_top <- df_top[, c("cand_id", "party_name", "distance_to_me", "issue_1", "issue_2", "issue_3")]
rownames(df_top) <- 1:nrow(df_top)

# Show top candidates

n_cand <- 5
head(df_top, n_cand)

# 15: top parties with average distance

df_spark <- df_cand[, c("party_code", "cand_number", "dir_check", "vibe_check", "distance_to_me")]

# Ensure cand_number is numeric
df_spark$cand_number <- as.numeric(df_spark$cand_number)

# Function to create sparkline string per party
sparkline_agreement <- function(df_party, col_name) {
  if (nrow(df_party) == 0) return("")  # handle empty party
  max_num <- max(df_party$cand_number)
  vec <- rep(0, max_num)
  vec[df_party$cand_number] <- as.numeric(df_party[[col_name]])
  paste(sapply(vec, function(x) if(x==1) "I" else "."), collapse = "")
}

# Compute sparklines, summaries, and average distance per party
party_codes <- unique(df_spark$party_code)
spark_df <- data.frame(
  party_code       = party_codes,
  total_candidates = sapply(party_codes, function(pc) sum(df_spark$party_code == pc)),
  fully_agree      = sapply(party_codes, function(pc) sum(df_spark$vibe_check[df_spark$party_code == pc])),
  dir_agree        = sapply(party_codes, function(pc) sum(df_spark$dir_check[df_spark$party_code == pc])),
  avg_distance     = sapply(party_codes, function(pc) mean(df_spark$distance_to_me[df_spark$party_code == pc])),
  cand_fully_agree = sapply(party_codes, function(pc) sparkline_agreement(df_spark[df_spark$party_code == pc, ], "vibe_check")),
  cand_dir_agree   = sapply(party_codes, function(pc) sparkline_agreement(df_spark[df_spark$party_code == pc, ], "dir_check")),
  stringsAsFactors = FALSE
)

# Only filter out parties with zero directional agreement if any questions are defined
if (length(important_questions) > 0 || length(very_important_questions) > 0) {
  spark_df <- spark_df[spark_df$dir_agree > 0, ]
}

# Order by fully_agree (desc), dir_agree (desc), avg_distance (asc)
spark_df <- spark_df[order(-spark_df$fully_agree, -spark_df$dir_agree, spark_df$avg_distance), ]

spark_df

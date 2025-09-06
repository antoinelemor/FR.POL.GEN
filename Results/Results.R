# ---------------------------------------------------------------------------
# Code pour la création des figures du SIED et CAIED (versions couleur & N&B)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
#### 0. Chargement de l'environnement ####
# ---------------------------------------------------------------------------
rm(list = ls())

# Chemins
import_data_path <- "/Users/antoine/Documents/GitHub/FR.POL.GEN/Database"
export_path      <- "/Users/antoine/Documents/GitHub/FR.POL.GEN/Results/Final_results"

# Librairies nécessaires
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(forcats)
library(RColorBrewer)
library(readxl)
library(tools)
library(stringr)

# ---------------------------------------------------------------------------
#### 1. Charger & préparer les données (identique à l'original) ####
# ---------------------------------------------------------------------------
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))
data$date <- as.Date(data$date)
pm_data <- read_excel(file.path(import_data_path, "PM.xlsx"))
pm_data$date <- as.Date(pm_data$date)
data <- left_join(data, pm_data, by = c("date", "intervenant"))
data$pol <- as.factor(data$pol)

data <- data %>%
  mutate(across(starts_with("detect_") | ends_with(paste0("_", 1:6)), ~ ifelse(. == "oui", 1, 0))) %>%
  group_by(doc_ID, date, intervenant) %>% mutate(total_sentences = n()) %>% ungroup()

# ---------------------------------------------------------------------------
#### 2. Fonctions de calcul (inchangées dans la logique) ####
# ---------------------------------------------------------------------------
calculate_sied_caied <- function(data) {
  data %>%
    pivot_longer(cols = starts_with("detect_"), names_to = "detect_type", values_to = "detect_presence") %>%
    filter(!detect_type %in% c('detect_ecologie','detect_tech','detect_ue','detect_prodem','detect_soc','detect_travail')) %>%
    pivot_longer(cols = ends_with(paste0("_", 1:6)), names_to = "specific_type", values_to = "specific_presence") %>%
    mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
    filter(str_detect(specific_type, detect_type), detect_presence == 1) %>%
    group_by(date, detect_type, intervenant) %>%
    summarise(total_detect = sum(detect_presence), total_specific = sum(specific_presence), .groups = "drop") %>%
    mutate(far_right_score = ifelse(total_detect > 0, (total_specific / total_detect) * 100, NA_real_)) %>%
    ungroup() %>%
    mutate(detect_type_clean = case_when(
      detect_type == "autorite"    ~ "Autoritarisme",
      detect_type == "democratie"  ~ "Anti-démocratie",
      detect_type == "egalite"     ~ "Anti-égalitarisme",
      detect_type == "immigration" ~ "Anti-immigration",
      detect_type == "nation"      ~ "Nationalisme",
      detect_type == "progres"     ~ "Anti-progressisme",
      detect_type == "tradition"   ~ "Traditionalisme",
      TRUE                           ~ detect_type)) %>%
    mutate(detect_type_clean = tools::toTitleCase(gsub("_", " ", detect_type_clean)))
}

calculate_confidence_intervals <- function(data, window_size = 10) {
  data <- data %>% arrange(date) %>% mutate(lower_ci = NA_real_, upper_ci = NA_real_)
  for (i in seq_len(nrow(data))) {
    rng <- max(1, i - window_size %/% 2):min(nrow(data), i + window_size %/% 2)
    win <- data[rng, ]
    if (nrow(win) > 1) {
      se <- sd(win$far_right_score, na.rm = TRUE) / sqrt(nrow(win))
      mult <- qt(0.975, df = nrow(win) - 1)
      data$lower_ci[i] <- data$far_right_score[i] - mult * se
      data$upper_ci[i] <- data$far_right_score[i] + mult * se
    }
  }
  data
}

# ---------------------------------------------------------------------------
#### 3. Fonctions utilitaires de style ####
# ---------------------------------------------------------------------------
make_bw <- function(p) p + scale_colour_grey(start = .2, end = .8) + scale_fill_grey(start = .2, end = .8)

save_dual <- function(plot, name, w, h) {
  ggsave(file.path(export_path, paste0(name, "_col.pdf")), plot, dpi = 300, width = w, height = h, units = "in")
  ggsave(file.path(export_path, paste0(name, "_bw.pdf" )), make_bw(plot), dpi = 300, width = w, height = h, units = "in")
}

# ---------------------------------------------------------------------------
#### 4. Analyse & visualisations ####
# ---------------------------------------------------------------------------
# 4.1 Évolution du SIED par CAIED
far_cai <- calculate_sied_caied(data)
labels_data <- far_cai %>% filter(detect_type_clean == "Traditionalisme") %>% arrange(date) %>% group_by(intervenant) %>% slice(n()) %>% ungroup()

p1 <- ggplot(far_cai, aes(date, far_right_score, colour = detect_type_clean)) +
  geom_line(alpha = .3) + geom_smooth(se = FALSE, method = "loess", span = .7) + geom_point(alpha = .3) +
  geom_text(data = labels_data, aes(label = intervenant), vjust = -7, hjust = .5, colour = "grey", check_overlap = TRUE) +
  theme_minimal() + labs(x = "Date", y = "Prévalence (%)", colour = "CAIED") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_dual(p1, "SIED_CAIED", 10, 8)

# 4.2 SIED par Premier ministre & date
score_pm <- data %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "detect_type", values_to = "detect_presence") %>%
  filter(!detect_type %in% c('detect_ecologie','detect_tech','detect_ue','detect_prodem','detect_soc','detect_travail')) %>%
  pivot_longer(cols = ends_with(paste0("_", 1:6)), names_to = "specific_type", values_to = "specific_presence") %>%
  mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
  filter(str_detect(specific_type, detect_type), detect_presence == 1) %>%
  group_by(date, intervenant, pol) %>% summarise(total_detect = sum(detect_presence), total_specific = sum(specific_presence), .groups = "drop") %>%
  mutate(far_right_score = ifelse(total_detect > 0, 100 * total_specific / total_detect, NA_real_), intervenant_date = paste(intervenant, format(date, "%Y-%m-%d")))

p2 <- ggplot(score_pm, aes(reorder(intervenant_date, far_right_score), far_right_score, fill = pol)) +
  geom_bar(stat = "identity") + scale_fill_manual(values = c(centre = "#e4a54b", gauche = "#d81832", droite = "navy"), labels = c(centre = "Centre", gauche = "Gauche", droite = "Droite")) +
  theme_minimal() + labs(x = "Premier(e) Ministre & Date", y = "SIED (%)", fill = "Orientation") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1), plot.margin = unit(c(2, 2, 4, 2), "cm"))

save_dual(p2, "SIED_PM", 17, 15)

# 4.3 SIED par PM avec IC
data_ci <- calculate_confidence_intervals(score_pm)

p3 <- ggplot(data_ci, aes(date, far_right_score, group = intervenant)) +
  geom_point(alpha = .3) + geom_text(aes(label = intervenant), vjust = -2, size = 3) +
  geom_smooth(method = "loess", se = TRUE, colour = "black", aes(group = 1)) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 350, colour = "grey50") +
  scale_x_date(date_breaks = "10 years", date_labels = "%Y") + theme_minimal() + labs(x = "Date", y = "SIED (%)")

save_dual(p3, "SIED_PM_IC", 12, 10)

# 4.4 SIED moyen par orientation politique
overall <- data_ci %>% group_by(pol) %>% summarise(m = mean(far_right_score, na.rm = TRUE), sd = sd(far_right_score, na.rm = TRUE), n = n()) %>% mutate(se = sd / sqrt(n), lo = m - 1.96 * se, hi = m + 1.96 * se)

p4 <- ggplot(overall, aes(pol, m, fill = pol)) +
  geom_bar(stat = "identity", width = .7) + geom_errorbar(aes(ymin = lo, ymax = hi), width = .2, colour = "grey50") +
  scale_fill_manual(values = c(centre = "#e4a54b", gauche = "#d81832", droite = "navy")) + theme_minimal() +
  labs(x = "Orientation", y = "SIED moyen (%)", fill = "Orientation") + theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_dual(p4, "SIED_moyen", 10, 7)
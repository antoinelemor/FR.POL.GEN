# ---------------------------------------------------------------------------
# Script pour la création de la base de données 
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
#### Chargement de l'environnement ####
# ---------------------------------------------------------------------------

# Effacer l'environnement
rm(list = ls())

# Chemins d'importation et d'exportation
import_data_path <- "/FR.POL.GEN/Database"
export_path <- "/Results/Final_results"

# Chargement des packages nécessaires
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
#### Chargement et préparation des données ####
# ---------------------------------------------------------------------------

# Charger les données annotées
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# S'assurer que la date est au bon format
data$date <- as.Date(data$date)

# Calcul du nombre total de phrases par discours
data_prepared <- data %>%
  group_by(doc_ID, date, intervenant) %>%
  mutate(total_sentences = n()) %>%
  ungroup()

# Calcul de la proportion de chaque thématique par rapport au nombre total de phrases
data_time_series <- data_prepared %>%
  pivot_longer(
    cols = starts_with("detect_"),
    names_to = "variable",
    values_to = "presence"
  ) %>%
  filter(presence == "oui") %>%
  group_by(date, variable, intervenant) %>%
  summarise(
    count = n(),
    total_sentences = first(total_sentences),
    .groups = "drop"
  ) %>%
  mutate(proportion = count / total_sentences) %>%
  ungroup() %>%
  mutate(
    variable_clean = gsub("^detect_", "", variable),
    variable_clean = gsub("_", " ", variable_clean),
    variable_clean = tools::toTitleCase(variable_clean)
  )

# Préparation des étiquettes pour les graphiques (si nécessaire)
labels_data <- data_time_series %>%
  filter(variable_clean == "Progrès") %>%
  arrange(date) %>%
  group_by(intervenant) %>%
  slice(n()) %>%
  ungroup()

# ---------------------------------------------------------------------------
#### Calcul du SIED (Score Idéologique d'Extrême Droite) ####
# ---------------------------------------------------------------------------

# Recharger les données pour une nouvelle manipulation
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# S'assurer que la date est au bon format
data$date <- as.Date(data$date)

# Convertir les valeurs 'oui'/'non' en numériques 1/0
data <- data %>%
  mutate(across(
    starts_with("detect_") | ends_with(paste0("_", 1:6)),
    ~ ifelse(. == "oui", 1, 0)
  ))

# Calcul du SIED
score_data_date <- data %>%
  pivot_longer(
    cols = starts_with("detect_"),
    names_to = "detect_type",
    values_to = "detect_presence"
  ) %>%
  filter(!detect_type %in% c(
    'detect_ecologie', 'detect_tech', 'detect_ue',
    'detect_prodem', 'detect_soc', 'detect_travail'
  )) %>%
  pivot_longer(
    cols = ends_with(paste0("_", 1:6)),
    names_to = "specific_type",
    values_to = "specific_presence"
  ) %>%
  mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
  filter(
    str_detect(specific_type, detect_type),
    detect_presence == 1
  ) %>%
  group_by(date, intervenant) %>%
  summarise(
    total_detect = sum(detect_presence, na.rm = TRUE),
    total_specific = sum(specific_presence, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    far_right_score = ifelse(
      total_detect > 0,
      (total_specific / total_detect) * 100,
      NA_real_
    )
  ) %>%
  arrange(date, intervenant)

# Création d'une colonne combinant intervenant et date (si nécessaire)
score_data_date <- score_data_date %>%
  mutate(intervenant_date = paste(intervenant, format(date, "%Y-%m-%d")))

# ---------------------------------------------------------------------------
#### Calcul de l'indice de négativité du discours ####
# ---------------------------------------------------------------------------

# Recharger les données
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# S'assurer que la date est au bon format
data$date <- as.Date(data$date)

# Calcul de l'indice de négativité
data_negatif <- data %>%
  group_by(doc_ID, intervenant, date) %>%
  summarise(
    total_phrases = n(),
    negatif_count = sum(emotion == "négatif", na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(indice_negatif = (negatif_count / total_phrases) * 100) %>%
  ungroup()

# ---------------------------------------------------------------------------
#### Calcul de l'indice de positivité du discours ####
# ---------------------------------------------------------------------------

# Recharger les données
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# S'assurer que la date est au bon format
data$date <- as.Date(data$date)

# Calcul de l'indice de positivité
data_positif <- data %>%
  group_by(doc_ID, intervenant, date) %>%
  summarise(
    total_phrases = n(),
    positif_count = sum(emotion == "positif", na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(indice_positif = (positif_count / total_phrases) * 100) %>%
  ungroup()

# ---------------------------------------------------------------------------
#### Chargement des données électorales et des informations des PM ####
# ---------------------------------------------------------------------------

# Charger les données électorales (contenant les informations des PM)
excel_data <- read_excel(file.path(import_data_path, "PM.xlsx"))

# S'assurer que la date est au bon format
excel_data$date <- as.Date(excel_data$date)

# ---------------------------------------------------------------------------
#### Création de la base de données finale ####
# ---------------------------------------------------------------------------

# Pivot des données thématiques pour que chaque CAIED soit une colonne
data_themes_pivoted <- data_time_series %>%
  select(date, intervenant, variable_clean, proportion) %>%
  pivot_wider(
    names_from = variable_clean,
    values_from = proportion,
    values_fill = list(proportion = 0)
  )

# Joindre le SIED et les indices de négativité et de positivité
FR_POL_GEN_database <- data_themes_pivoted %>%
  left_join(select(score_data_date, date, intervenant, far_right_score), by = c("date", "intervenant")) %>%
  left_join(select(data_negatif, date, intervenant, indice_negatif), by = c("date", "intervenant")) %>%
  left_join(select(data_positif, date, intervenant, indice_positif), by = c("date", "intervenant"))

# Joindre les données électorales (informations des PM)
FR_POL_GEN_database <- left_join(FR_POL_GEN_database, excel_data, by = c("date", "intervenant"))

# ---------------------------------------------------------------------------
#### Exportation de la base de données finale ####
# ---------------------------------------------------------------------------

# Exporter la base de données finale en CSV
write.csv(
  FR_POL_GEN_database,
  file.path(export_path, "FR.POL.GEN_database.csv"),
  row.names = FALSE
)

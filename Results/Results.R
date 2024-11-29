# ---------------------------------------------------------------------------
# Code pour la création des figures du SIED et CAIED
# ---------------------------------------------------------------------------
  

# ---------------------------------------------------------------------------
#### Chargement de l'environnement ####
# ---------------------------------------------------------------------------

# Effacer l'environnement
rm(list = ls())

# Chemins
import_data_path <- "/Database"
export_path <- "/Final_results"

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
#### Charger et préparer les données ####
# ---------------------------------------------------------------------------

# Charger les données annotées
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurer que la date est au bon format
data$date <- as.Date(data$date)

# Charger les données des Premiers Ministres (incluant 'pol')
pm_data <- read_excel(file.path(import_data_path, "PM.xlsx"))

# Assurer que la date est au bon format
pm_data$date <- as.Date(pm_data$date)

# Fusionner les données pour inclure 'pol'
data <- left_join(data, pm_data, by = c("date", "intervenant"))

# S'assurer que 'pol' est un facteur
data$pol <- as.factor(data$pol)

# Convertir les annotations 'oui'/'non' en valeurs numériques 1/0
data <- data %>%
  mutate(across(
    starts_with("detect_") | ends_with(paste0("_", 1:6)),
    ~ ifelse(. == "oui", 1, 0)
  ))

# Calculer le nombre total de phrases par discours
data <- data %>%
  group_by(doc_ID, date, intervenant) %>%
  mutate(total_sentences = n()) %>%
  ungroup()

# ---------------------------------------------------------------------------
#### Définitions des fonctions ####
# ---------------------------------------------------------------------------

# Fonction pour calculer le SIED par CAIED
calculate_sied_caied <- function(data) {
  data %>%
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
    group_by(date, detect_type, intervenant) %>%
    summarise(
      total_detect = sum(detect_presence, na.rm = TRUE),
      total_specific = sum(specific_presence, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      far_right_score = ifelse(total_detect > 0, 
                               (total_specific / total_detect) * 100, NA_real_)
    ) %>%
    ungroup() %>%
    mutate(
      detect_type_clean = case_when(
        detect_type == "autorite" ~ "Autoritarisme",
        detect_type == "democratie" ~ "Anti-démocratie",
        detect_type == "egalite" ~ "Anti-égalitarisme",
        detect_type == "immigration" ~ "Anti-immigration",
        detect_type == "nation" ~ "Nationalisme",
        detect_type == "progres" ~ "Anti-progressisme",
        detect_type == "tradition" ~ "Traditionalisme",
        TRUE ~ detect_type
      ),
      detect_type_clean = tools::toTitleCase(gsub("_", " ", detect_type_clean))
    )
}

# Fonction pour calculer les intervalles de confiance
calculate_confidence_intervals <- function(data, window_size = 10) {
  data <- data %>%
    arrange(date) %>%
    mutate(lower_ci = NA_real_, upper_ci = NA_real_)
  
  for (i in seq_len(nrow(data))) {
    start <- max(1, i - window_size %/% 2)
    end <- min(nrow(data), i + window_size %/% 2)
    window_data <- data[start:end, ]
    
    if (nrow(window_data) > 1) {
      mean_score <- mean(window_data$far_right_score, na.rm = TRUE)
      sd_score <- sd(window_data$far_right_score, na.rm = TRUE)
      n <- nrow(window_data)
      se_score <- sd_score / sqrt(n)
      ci_multiplier <- qt(0.975, df = n - 1)
      
      data$lower_ci[i] <- data$far_right_score[i] - ci_multiplier * se_score
      data$upper_ci[i] <- data$far_right_score[i] + ci_multiplier * se_score
    }
  }
  data
}

# ---------------------------------------------------------------------------
#### Analyse et Visualisation ####
# ---------------------------------------------------------------------------

# -------------------------------
#### 1. Évolution du SIED par CAIED dans le temps ####
# -------------------------------

# Calculer le SIED par CAIED
far_right_score_time_series <- calculate_sied_caied(data)

# Préparer les étiquettes pour le graphique
labels_data <- far_right_score_time_series %>%
  filter(detect_type_clean == "Traditionalisme") %>%
  arrange(date) %>%
  group_by(intervenant) %>%
  slice(n()) %>%
  ungroup()

# Graphique de l'évolution du SIED par CAIED dans le temps
ggplot(far_right_score_time_series, aes(
  x = date, y = far_right_score, color = detect_type_clean
)) +
  geom_line(alpha = 0.3) +
  geom_smooth(se = FALSE, method = "loess", span = 0.7) +
  geom_point(alpha = 0.3) +
  geom_text(
    data = labels_data,
    aes(label = intervenant),
    vjust = -7, hjust = 0.5,
    color = "grey", check_overlap = TRUE
  ) +
  theme_minimal() +
  labs(
    title = "Évolution des Catégories d'Appartenance Idéologique à l'Extrême Droite (CAIED)",
    x = "Date",
    y = "Prévalence des sous-dimensions d'extrême droite par CAIED",
    color = "CAIED"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Sauvegarder le graphique
ggsave(
  filename = "SIED_par_CAIED.pdf",
  path = export_path,
  width = 10,
  height = 8,
  units = "in"
)

# -------------------------------
#### 2. SIED par Premier Ministre ####
# -------------------------------

# Calcul du SIED par Premier Ministre, Date et Orientation Politique
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
  group_by(date, intervenant, pol) %>%  # Inclure 'pol' ici
  summarise(
    total_detect = sum(detect_presence, na.rm = TRUE),
    total_specific = sum(specific_presence, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    far_right_score = ifelse(total_detect > 0,
                             (total_specific / total_detect) * 100, NA_real_)
  ) %>%
  arrange(date, intervenant) %>%
  mutate(intervenant_date = paste(intervenant, format(date, "%Y-%m-%d")))

# Graphique à barres du SIED par Premier(e) Ministre et Date
ggplot(score_data_date, aes(
  x = reorder(intervenant_date, far_right_score),
  y = far_right_score,
  fill = intervenant
)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = rep("#363636", nrow(score_data_date))) +
  theme_minimal() +
  labs(
    title = "Score Idéologique d'Extrême Droite (SIED) par Premier(e) Ministre et Date",
    x = "Premier(e) Ministre et Date",
    y = "SIED"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

# Sauvegarder le graphique
ggsave(
  filename = "SIED_par_PM.pdf",
  path = export_path,
  width = 14,
  height = 12,
  units = "in"
)

# -------------------------------
#### 3. SIED par Premier ministre avec IC dans le temps ####
# -------------------------------

# Calculer les intervalles de confiance
data_with_ci <- calculate_confidence_intervals(score_data_date, window_size = 10)

# Graphique avec intervalles de confiance et bornes aux extrémités
ggplot(data_with_ci, aes(x = date, y = far_right_score, group = intervenant)) +
  geom_point(alpha = 0.3) +
  geom_text(
    aes(label = intervenant),
    vjust = -2,
    check_overlap = FALSE,
    size = 3
  ) +
  geom_smooth(method = "loess", se = TRUE, color = "black", aes(group = 1)) +
  geom_errorbar(
    aes(ymin = lower_ci, ymax = upper_ci),
    width = 350,  
    color = "#808080"
  ) +
  scale_x_date(date_breaks = "10 years", date_labels = "%Y") +
  theme_minimal() +
  labs(
    title = "Évolution du Score Idéologique d'Extrême Droite (SIED) par Premier(e) Ministre",
    x = "Date",
    y = "SIED"
  )

# Sauvegarder le graphique
ggsave(
  filename = "SIED_avec_IC_par_PM_dans_le_temps.pdf",
  path = export_path,
  width = 12,
  height = 10,
  units = "in"
)

# -------------------------------
#### 4. SIED par Orientation Politique avec IC ####
# -------------------------------

# Calcul des scores moyens du SIED par orientation politique
mean_scores <- data_with_ci %>%
  group_by(pol) %>%
  summarise(
    mean_far_right_score = mean(far_right_score, na.rm = TRUE),
    sd_far_right_score = sd(far_right_score, na.rm = TRUE),
    n = n()
  ) %>%
  mutate(
    se = sd_far_right_score / sqrt(n),
    ci_lower = mean_far_right_score - 1.96 * se,
    ci_upper = mean_far_right_score + 1.96 * se
  )

# Graphique avec intervalles de confiance
ggplot(mean_scores, aes(x = pol, y = mean_far_right_score, fill = pol)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    width = 0.2,
    color = "grey"
  ) +
  labs(
    title = "Comparaison des scores moyens du SIED selon l'orientation politique du/de la premier(e) ministre",
    x = "Orientation Politique",
    y = "SIED Moyen",
    fill = "Orientation Politique"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("centre" = "navy", "gauche" = "pink", "droite" = "red")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Sauvegarder le graphique
ggsave(
  filename = "sied_moyen_par_or_pm.png",
  path = export_path,
  width = 10,
  height = 7,
  units = "in"
)

# -------------------------------
#### 5. SIED par CAIED et orientation politique des PM ####
# -------------------------------

# Calcul du SIED par CAIED et orientation politique
far_right_score_by_intervenant <- data %>%
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
    cols = ends_with(paste0("_", 1:5)),
    names_to = "specific_type",
    values_to = "specific_presence"
  ) %>%
  mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
  filter(str_detect(specific_type, detect_type)) %>%
  group_by(pol, intervenant, detect_type) %>%
  summarise(
    total_detect = sum(detect_presence, na.rm = TRUE),
    total_specific = sum(specific_presence, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    far_right_score = ifelse(total_detect > 0,
                             (total_specific / total_detect) * 100, NA)
  ) %>%
  ungroup() %>%
  mutate(
    detect_type_clean = case_when(
      detect_type == "autorite" ~ "Autoritarisme",
      detect_type == "democratie" ~ "Anti-démocratie",
      detect_type == "egalite" ~ "Anti-égalitarisme",
      detect_type == "immigration" ~ "Anti-immigration",
      detect_type == "nation" ~ "Nationalisme",
      detect_type == "progres" ~ "Anti-progressisme",
      detect_type == "tradition" ~ "Traditionalisme",
      TRUE ~ detect_type
    ),
    detect_type_clean = tools::toTitleCase(gsub("_", " ", detect_type_clean))
  )

# Calcul des scores moyens et des intervalles de confiance
mean_scores_intervenant <- far_right_score_by_intervenant %>%
  group_by(pol, detect_type_clean, intervenant) %>%
  summarise(
    mean_score_intervenant = mean(far_right_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(pol, detect_type_clean) %>%
  summarise(
    mean_score = mean(mean_score_intervenant, na.rm = TRUE),
    sem_score = sd(mean_score_intervenant, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Graphique du SIED par CAIED et orientation politique
ggplot(mean_scores_intervenant, aes(
  x = detect_type_clean,
  y = mean_score,
  fill = pol
)) +
  geom_bar(
    stat = "identity",
    position = position_dodge(width = 0.9),
    width = 0.7
  ) +
  geom_errorbar(
    aes(ymin = mean_score - sem_score, ymax = mean_score + sem_score),
    width = 0.2,
    color = "grey",
    position = position_dodge(0.9)
  ) +
  labs(
    title = "Proportion moyenne de phrases idéologiquement rattachées à l'extrême droite par CAIED",
    x = "CAIED",
    y = "Proportion moyenne de phrases positives (%)",
    fill = "Orientation Politique"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  ) +
  scale_fill_manual(values = c("centre" = "navy", "gauche" = "pink", "droite" = "red"))

# Sauvegarder le graphique
ggsave(
  filename = "proportion_moyenne_SIED_par_CAIED_orientation_pol.pdf",
  path = export_path,
  width = 10,
  height = 7
)

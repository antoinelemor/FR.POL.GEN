# Chemin de la base de données #
import_data_path <- "/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database"
export_path <- "/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Results/Final_results"

# Chargement des données (ajustez le nom du fichier si nécessaire)
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Chargement des packages nécessaires
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyverse)
library(broom)
library(ggplot2)
library(tidyr)
library(dplyr)
library(forcats)
library(RColorBrewer)


#### FIGURE 1 - EVOLUTION DU SIED PAR CAIED DANS LE TEMPS ####
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurer que la date est au bon format
data$date <- as.Date(data$date)

# Préparation des données avec total_sentences conservé par discours
data_prepared <- data %>%
  group_by(doc_ID, date, intervenant) %>%  
  mutate(total_sentences = n()) %>%
  ungroup()

# Calcul de la proportion de chaque thématique par rapport au nombre total de phrases par discours, groupé par date
data_time_series <- data_prepared %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "variable", values_to = "presence") %>%
  filter(presence == "oui") %>%
  group_by(date, variable, intervenant) %>%
  summarise(count = n(), total_sentences = first(total_sentences), .groups = "drop") %>%
  mutate(proportion = count / total_sentences) %>%
  ungroup() %>%
  # Nettoyer les noms des variables pour l'affichage
  mutate(variable_clean = gsub("^detect_", "", variable),
         variable_clean = gsub("_", " ", variable_clean),
         variable_clean = tools::toTitleCase(variable_clean))

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data_prepared <- data_prepared %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Calcul du SIED par CAIED
far_right_score_time_series <- data_prepared %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "detect_type", values_to = "detect_presence") %>%
  filter(!(detect_type %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  pivot_longer(cols = ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
               names_to = "specific_type", values_to = "specific_presence") %>%
  mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
  filter(str_detect(specific_type, detect_type)) %>%
  group_by(date, detect_type, intervenant) %>%
  summarise(total_detect = sum(detect_presence), total_specific = sum(specific_presence), .groups = "drop") %>%
  mutate(far_right_score = ifelse(total_detect > 0, (total_specific / total_detect) * 100, NA)) %>%
  ungroup() %>%
  # Nettoyer les noms des variables pour l'affichage
  mutate(detect_type_clean = case_when(
    detect_type == "autorite" ~ "Autoritarisme",
    detect_type == "democratie" ~ "Anti-démocratie",
    detect_type == "egalite" ~ "Anti-égalitarisme",
    detect_type == "immigration" ~ "Anti-immigration",
    detect_type == "nation" ~ "Nationalisme",
    detect_type == "progres" ~ "Anti-progressisme",
    detect_type == "tradition" ~ "Traditionalisme",
    TRUE ~ detect_type
  )) %>%
  mutate(detect_type_clean = gsub("_", " ", detect_type_clean),
         detect_type_clean = tools::toTitleCase(detect_type_clean))

labels_data <- far_right_score_time_series %>%
  filter(detect_type_clean == "Traditionalisme") %>%
  arrange(date) %>%
  group_by(intervenant) %>%
  slice(n()) %>%
  ungroup()

# Figure

ggplot(far_right_score_time_series, aes(x = date, y = far_right_score, color = detect_type_clean)) +
  geom_line(alpha = 0.3) +  # Lignes originales plus transparentes
  geom_smooth(se = FALSE, method = "loess", span = 0.7) +  # Lissage
  geom_point(alpha = 0.3) +  # Points originaux plus transparents
  geom_text(data = labels_data, aes(label = intervenant), vjust = -7, hjust = 0.5, color = "grey", check_overlap = TRUE) +  # Ajout des étiquettes en noir, plus haut
  theme_minimal() +
  labs(title = "Évolution des Catégories d'Appartenance Idéologique à l'Extrême Droite (CAIED)",
       x = "Date",
       y = "Prévalence des sous-dimensions d'extrême droite par CAIED",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right") +
  guides(color = guide_legend(override.aes = list(alpha = 1)))

ggsave(filename = "SIED_par_CAIED.pdf", path=export_path, width = 10, height = 8, units = "in")






#### FAR RIGHT SCORE PAR PREMIER(E) MINISTRE ####

data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Format date
data$date <- as.Date(data$date)

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Calcul du SIED 
score_data_date <- data %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "detect_type", values_to = "detect_presence") %>%
  filter(!(detect_type %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  pivot_longer(cols = ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
               names_to = "specific_type", values_to = "specific_presence") %>%
  mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
  filter(str_detect(specific_type, detect_type), detect_presence == 1) %>%
  group_by(date, intervenant) %>%
  summarise(total_detect = sum(detect_presence), total_specific = sum(specific_presence), .groups = "drop") %>%
  mutate(far_right_score = ifelse(total_detect > 0, (total_specific / total_detect) * 100, NA_real_)) %>%
  arrange(date, intervenant)


score_data_date <- score_data_date %>%
  mutate(intervenant_date = paste(intervenant, format(date, "%Y-%m-%d")))

# Graphique à barre
ggplot(score_data_date, aes(x = reorder(intervenant_date, far_right_score), y = far_right_score, fill = intervenant)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = rep("#363636", nrow(score_data_date))) +
  theme_minimal() +
  labs(title = "Score Idéologique d'Extrême Droite (SIED) par Premier(e) Ministre et Date",
       x = "Premier(e) Ministre et Date",
       y = "SIED") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave(filename = "SIED_par_PM.pdf", path=export_path, width = 14, height = 12, units = "in")




#### SIED par PM avec smooth et intervalle de confiance ####

# Charger les données
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))
data$date <- as.Date(data$date, "%Y-%m-%d")

# Convertir les valeurs 'oui'/'non' en valeurs numériques et calcul du score
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"),
                ~ ifelse(. == "oui", 1, 0))) %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "detect_type", values_to = "detect_presence") %>%
  filter(!(detect_type %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  pivot_longer(cols = ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"),
               names_to = "specific_type", values_to = "specific_presence") %>%
  mutate(detect_type = str_replace(detect_type, "detect_", "")) %>%
  filter(str_detect(specific_type, detect_type), detect_presence == 1) %>%
  group_by(date, intervenant) %>%
  summarise(total_detect = sum(detect_presence), total_specific = sum(specific_presence), .groups = "drop") %>%
  mutate(far_right_score = ifelse(total_detect > 0, (total_specific / total_detect) * 100, NA_real_)) %>%
  arrange(date, intervenant)

# Calcul des intervalles de confiance avec une fenêtre mobile de 5 points
calculate_rolling_ci <- function(data, window_size = 5) {
  data <- data %>%
    arrange(date) %>%
    mutate(lower_ci = NA_real_,
           upper_ci = NA_real_)
  
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
  
  return(data)
}

# Calcul des intervalles de confiance sur une fenêtre mobile de 5 points
data_with_ci <- calculate_rolling_ci(data, window_size = 10)

# Vérification des valeurs calculées
print(data_with_ci %>% select(date, far_right_score, lower_ci, upper_ci))

# Graphique avec les intervalles de confiance pour chaque point
ggplot(data_with_ci, aes(x = date, y = far_right_score, group = intervenant)) +
  geom_point(alpha = 0.3) +
  geom_text(aes(label = intervenant), vjust = -2, check_overlap = FALSE, size = 3) +
  geom_smooth(method = "loess", se = TRUE, color = "black", aes(group = 1)) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.2, color = "#808080") +
  geom_segment(aes(x = date - 400, xend = date + 400, y = lower_ci, yend = lower_ci), color = "#808080") +  # Borne inférieure
  geom_segment(aes(x = date - 400, xend = date + 400, y = upper_ci, yend = upper_ci), color = "#808080") +  # Borne supérieure
  scale_x_date(date_breaks = "10 years", date_labels = "%Y") +
  theme_minimal() +
  labs(title = "Évolution du Score Idéologique d'Extrême Droite (SIED) par Premier(e) ministre",
       x = "Date",
       y = "SIED")

#Sauvegarde du graphique
ggsave(filename = "SIED_avec_IC_par_PM_dans_le_temps.pdf", path = export_path, width = 12, height = 10, units = "in")

# Base path
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


## DISTRIBUTION DES VARIABLES DANS LE TEMPS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

data <- data %>%
  filter(!(intervenant == "Attal" & date == as.Date("2024-01-31")))

# Transformation des données en format long pour une meilleure visualisation avec ggplot2
data_long <- data %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "variable", values_to = "presence") %>%
  filter(presence == "oui")

ggplot(data_long, aes(x = variable, fill = presence)) +
  geom_bar() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Distribution des détections thématiques", x = "Thématique", y = "Nombre de phrases")



## PROPORTIONS DES THÉMATIQUES ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Préparation des données avec total_sentences conservé
data_prepared <- data %>%
  group_by(doc_ID) %>%
  mutate(total_sentences = n()) %>%
  ungroup()

# Calcul de la proportion de chaque thématique par rapport au nombre total de phrases par discours
data_long <- data_prepared %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "variable", values_to = "presence") %>%
  filter(presence == "oui") %>%
  group_by(doc_ID, variable) %>%
  summarise(count = n(), .groups = "keep") %>%
  ungroup() %>%
  left_join(data_prepared %>% select(doc_ID, total_sentences) %>% distinct(doc_ID, .keep_all = TRUE), by = "doc_ID") %>%
  mutate(proportion = count / total_sentences) %>%
  group_by(variable) %>%
  summarise(mean_proportion = mean(proportion, na.rm = TRUE)) %>%
  arrange(mean_proportion) %>%
  mutate(variable = factor(variable, levels = unique(variable))) %>%
  mutate(variable_clean = gsub("^detect_", "", variable),
         variable_clean = gsub("_", " ", variable_clean),
         variable_clean = tools::toTitleCase(variable_clean))

# Assurer que la commande 'arrange' a bien été appliquée pour ordonner 'mean_proportion'
data_long <- data_long %>%
  arrange(mean_proportion)

# Mise à jour de 'variable_clean' pour être un facteur avec les niveaux dans l'ordre souhaité
data_long$variable_clean <- factor(data_long$variable_clean, levels = unique(data_long$variable_clean))

# Visualiser les proportions moyennes avec une seule couleur grise pour toutes les barres
ggplot(data_long, aes(x = variable_clean, y = mean_proportion)) +
  geom_bar(stat = "identity", fill = "grey") +  # Utilisation d'une couleur grise fixe pour toutes les barres
  theme_minimal() +
  labs(title = "Proportion moyenne de l'ensemble thématiques par discours",
       x = "Thématiques",
       y = "Proportion moyenne") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ggsave(filename = "Thematiques_proportions.pdf", path=export_path, width = 10, height = 8, units = "in")



## THÉMATIQUES DANS LE TEMPS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurer que la date est au bon format
data$date <- as.Date(data$date)

# Préparation des données avec total_sentences conservé par discours
# Cette fois, incluons directement la colonne 'date' dans 'data_prepared'
data_prepared <- data %>%
  group_by(doc_ID, date, intervenant) %>%  # Inclure 'date' dans le group_by
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

labels_data <- data_time_series %>%
  filter(variable_clean == "Progrès") %>%
  arrange(date) %>%
  group_by(intervenant) %>%
  slice(n()) %>%
  ungroup()

# Maintenant que 'date' est correctement incluse depuis le début, nous pouvons continuer sans erreur
# Visualisation de l'évolution des proportions des thématiques dans le temps
ggplot(data_time_series, aes(x = date, y = proportion, color = variable_clean)) +
  geom_line() +
  geom_point() +
  theme_minimal() +
  labs(title = "Évolution de la proportion de chaque thématique dans le temps",
       x = "Date",
       y = "Proportion",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle=45, hjust=1), legend.position = "right")

# Visualisation avec ajustements pour les labels
ggplot(data_time_series, aes(x = date, y = proportion, color = variable_clean)) +
  geom_line(alpha = 0.3) +  # Lignes originales plus transparentes
  geom_smooth(se = FALSE, method = "loess", span = 0.7) +  # Lissage
  geom_point(alpha = 0.3) +  # Points originaux plus transparents
  geom_text(data = labels_data, aes(label = intervenant), vjust = -8, hjust = 0.5, color = "grey", check_overlap = FALSE) +  # Ajout des étiquettes
  theme_minimal() +
  labs(title = "Évolution de la proportion de chaque thématique dans le temps",
       x = "Date",
       y = "Proportion",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right") +
  guides(color = guide_legend(override.aes = list(alpha = 1)))  # Lignes pleines dans la légende

ggsave(filename = "Thematiques_through_time.pdf", path=export_path, width = 10, height = 8, units = "in")

# Calcul de la proportion de chaque thématique par rapport au nombre total de phrases par discours, groupé par date
data_time_series <- data_prepared %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "variable", values_to = "presence") %>%
  filter(presence == "oui") %>%
  # Exclure les variables spécifiques ici
  filter(!(variable %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  group_by(date, variable, intervenant) %>%
  summarise(count = n(), total_sentences = first(total_sentences), .groups = "drop") %>%
  mutate(proportion = count / total_sentences) %>%
  ungroup() %>%
  # Nettoyer les noms des variables pour l'affichage
  mutate(variable_clean = gsub("^detect_", "", variable),
         variable_clean = gsub("_", " ", variable_clean),
         variable_clean = tools::toTitleCase(variable_clean))


labels_data_proportion <- data_time_series %>%
  filter(variable_clean == "Nation") %>%  # Remplacez "Tradition" par la thématique de votre choix
  arrange(date) %>%
  group_by(intervenant) %>%
  slice(n()) %>%
  ungroup()

# Visualisation avec lissage et étiquettes pour une thématique spécifique
ggplot(data_time_series, aes(x = date, y = proportion, color = variable_clean)) +
  geom_line(alpha = 0.3) +  # Rendre les lignes originales plus transparentes
  geom_smooth(se = FALSE, method = "loess") +  # Appliquer le lissage
  geom_point(alpha = 0.3) +  # Points originaux plus transparents
  geom_text(data = labels_data_proportion, aes(label = intervenant), vjust = -2, hjust = 0.5, color = "grey", check_overlap = FALSE) +  # Ajout des étiquettes en noir, plus haut
  theme_minimal() +
  labs(title = "Évolution de la proportion de chaque thématique dans le temps",
       x = "Date",
       y = "Proportion",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right") +
  guides(color = guide_legend(override.aes = list(alpha = 1)))  # Assurer que la légende affiche des lignes pleines

ggsave(filename = "Thematiques_through_time_without_new.pdf", path=export_path, width = 10, height = 8, units = "in")

## FRS PAR THÉMATIQUES ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data_prepared <- data_prepared %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Calculer le score d'extrême droite pour chaque thématique et date
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

ggplot(far_right_score_time_series, aes(x = date, y = far_right_score, color = detect_type_clean)) +
  geom_line(alpha = 0.3) +  # Lignes originales plus transparentes
  geom_smooth(se = FALSE, method = "loess", span = 0.7) +  # Lissage
  geom_point(alpha = 0.3) +  # Points originaux plus transparents
  geom_text(data = labels_data, aes(label = intervenant), vjust = -7, hjust = 0.5, color = "grey", check_overlap = TRUE) +  # Ajout des étiquettes en noir, plus haut
  theme_minimal() +
  labs(title = "Évolution des Catégories d'Appartenance Idéologique à l'Extrême Droite (CAIED)",
       x = "Date",
       y = "Score Idéologique d'Extrême Droite (SIED) par CAIED",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right") +
  guides(color = guide_legend(override.aes = list(alpha = 1)))

ggsave(filename = "Thématiques_with_FRS.pdf", path=export_path, width = 10, height = 8, units = "in")

## FAR RIGHT SCORE PAR PREMIER(E) MINISTRE ##

data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurez-vous que data$date est au bon format
data$date <- as.Date(data$date)

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Simplification du calcul du score d'extrême droite
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

# Créer le graphique à barres avec les scores triés par intervenant et date
ggplot(score_data_date, aes(x = reorder(intervenant_date, far_right_score), y = far_right_score, fill = intervenant)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = rep("#363636", nrow(score_data_date))) +
  theme_minimal() +
  labs(title = "Score Idéologique d'Extrême Droite (SIED) par Premier(e) Ministre et Date",
       x = "Premier(e) Ministre et Date",
       y = "SIED") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave(filename = "FRS_by_PM.pdf", path=export_path, width = 14, height = 12, units = "in")


## HISTOGRAMME FRS PROPORTIONNEL ##

data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurez-vous que data$date est au bon format
data$date <- as.Date(data$date)

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Calculer le score d'extrême droite pour chaque thématique spécifique par discours
score_data_thematique <- data %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "detect_type", values_to = "detect_presence") %>%
  filter(!(detect_type %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  pivot_longer(cols = ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
               names_to = "specific_type", values_to = "specific_presence") %>%
  mutate(detect_type = str_replace(detect_type, "detect_", ""),
         specific_presence = specific_presence * detect_presence) %>%
  group_by(date, intervenant, detect_type) %>%
  summarise(total_specific = sum(specific_presence), .groups = "drop") %>%
  ungroup() %>%
  # Calculer le poids total de chaque thématique par rapport au total des expressions extrémistes
  group_by(date, intervenant) %>%
  mutate(total_extreme = sum(total_specific),
         proportion = total_specific / total_extreme * 100) %>%
  ungroup() %>%
  # Préparer pour le graphique à barres empilées
  select(date, intervenant, detect_type, proportion) %>%
  mutate(intervenant_date = paste(intervenant, format(date, "%Y-%m-%d")),
         detect_type = factor(detect_type, levels = unique(detect_type))) # Assurer l'ordre des thématiques

score_data_thematique <- score_data_thematique %>%
  arrange(date) %>%
  mutate(intervenant_date = factor(intervenant_date, levels = unique(intervenant_date))) # Facteur avec niveau basé sur l'ordre

# Nombre de niveaux distincts dans 'detect_type'
n <- length(unique(score_data_thematique$detect_type))

# Création d'une palette de couleurs rouge
palette_rouge <- colorRampPalette(c("green", "black"))(n)

# Utilisation de scale_fill_manual pour appliquer la palette de couleurs rouge
ggplot(score_data_thematique, aes(x = intervenant_date, y = proportion, fill = detect_type)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = palette_rouge) +
  theme_minimal() +
  labs(title = "Proportion de Thématiques Exprimées de Façon Extrémiste par Discours",
       x = "Intervenant et Date",
       y = "Proportion (%)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave(filename = "FRS_with_proportions_by_PM.pdf", path=export_path, width = 10, height = 8, units = "in")





## FAR RIGHT SCORE DANS LE TEMPS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurez-vous que data$date est au bon format
data$date <- as.Date(data$date)

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Simplification du calcul du score d'extrême droite
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


# Premier Graphique : Évolution du Score d'Extrême Droite par Date et Intervenant
ggplot(score_data_date, aes(x = date, y = far_right_score)) +
  geom_line() + # Utiliser une couleur unique pour toutes les lignes
  geom_point() + # Utiliser une couleur unique pour tous les points
  geom_text(aes(label = intervenant), nudge_y = 1.5, check_overlap = FALSE, size = 3, vjust = 18) + # Ajouter le nom de l'intervenant à côté des points
  scale_x_date(date_breaks = "years", date_labels = "%Y") + # Formater l'axe des x pour montrer les années
  theme_minimal() +
  labs(title = "Évolution du Score de Droite Extrême par Date et Intervenant",
       x = "Date",
       y = "Score de Droite Extrême (Moyenne sur 100)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ggsave(filename = "FRS_through_time_without_smooth.pdf", path=export_path, width = 12, height = 10, units = "in")


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
ggsave(filename = "FRS_through_time_with_confidence_intervals.pdf", path = export_path, width = 12, height = 10, units = "in")



## NÉGATIVITÉ DU DISCOURS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurez-vous que data$date est au bon format
data$date <- as.Date(data$date)

# Calcul de l'indice de négativité
data_negatif <- data %>%
  group_by(doc_ID, intervenant, date) %>%
  summarise(total_phrases = n(),
            negatif_count = sum(emotion == "négatif"),
            .groups = 'drop') %>% # Assurez-vous d'ajouter .groups = 'drop' pour éviter des avertissements.
  mutate(indice_negatif = (negatif_count / total_phrases) * 100) %>%
  ungroup()

# Création du graphique avec des points reliés par des lignes
ggplot(data_negatif, aes(x = as.Date(date), y = indice_negatif)) +
  geom_line() + # Relier les points avec des lignes d'une couleur unique
  geom_point() + # Afficher les points
  geom_text(aes(label = intervenant), nudge_y = 1.5, check_overlap = FALSE, size = 3, vjust = -1) + # Ajouter le nom de l'intervenant à côté des points
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") + # Formater l'axe des x pour afficher les années
  theme_minimal() +
  labs(title = "Indice de négativité dans les discours de politique générale par date et premier(e) ministre",
       x = "Date",
       y = "Indice de négativité (%)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggplot(data_negatif, aes(x = date, y = indice_negatif, group = intervenant)) +
  geom_point(alpha = 0.3) +  # Afficher les points pour chaque score d'intervenant
  geom_text(aes(label = intervenant), vjust = -2, check_overlap = FALSE, size = 3) +  # Étiquettes au-dessus des points sans créer de lignes
  geom_smooth(method = "loess", se = FALSE, color = "black", aes(group = 1)) +  # Lissage global pour toutes les données
  scale_x_date(date_breaks = "10 years", date_labels = "%Y") +  # Ajustement pour espacer les dates
  theme_minimal() +
  labs(title = "Indice de négativité dans les discours de politique générale par date et premier(e) ministre",
       x = "Date",
       y = "Indice de négativité (%)") 
  
ggsave(filename = "NEG_through_time.pdf", path=export_path, width = 10, height = 8, units = "in")


## POSITIVITÉ DU DISCOURS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurez-vous que data$date est au bon format
data$date <- as.Date(data$date)

# Calcul de l'indice de négativité
data_positif <- data %>%
  group_by(doc_ID, intervenant, date) %>%
  summarise(total_phrases = n(),
            positif_count = sum(emotion == "positif"),
            .groups = 'drop') %>% # Assurez-vous d'ajouter .groups = 'drop' pour éviter des avertissements.
  mutate(indice_positif = (positif_count / total_phrases) * 100) %>%
  ungroup()

# Création du graphique avec des points reliés par des lignes
ggplot(data_positif, aes(x = as.Date(date), y = indice_positif)) +
  geom_line() + # Relier les points avec des lignes d'une couleur unique
  geom_point() + # Afficher les points
  geom_text(aes(label = intervenant), nudge_y = 1.5, check_overlap = TRUE, size = 3, vjust = -1) + # Ajouter le nom de l'intervenant à côté des points
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") + # Formater l'axe des x pour afficher les années
  theme_minimal() +
  labs(title = "Indice de positivité dans les discours de politique générale par date et premier(e) ministret",
       x = "Date",
       y = "Indice de positivité (%)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggplot(data_positif, aes(x = date, y = indice_positif, group = intervenant)) +
  geom_point(alpha = 0.3) +  # Afficher les points pour chaque score d'intervenant
  geom_text(aes(label = intervenant), vjust = -2, check_overlap = FALSE, size = 3) +  # Étiquettes au-dessus des points sans créer de lignes
  geom_smooth(method = "loess", se = FALSE, color = "black", aes(group = 1)) +  # Lissage global pour toutes les données
  scale_x_date(date_breaks = "10 years", date_labels = "%Y") +  # Ajustement pour espacer les dates
  theme_minimal() +
  labs(title = "Indice de positivité dans les discours de politique générale par date et premier(e) ministret",
       x = "Date",
       y = "Indice de positivité (%)")  

ggsave(filename = "POS_through_time.pdf", path=export_path, width = 10, height = 8, units = "in")




## NÉGATIVITÉ DES THÉMATIQUES DANS LE TEMPS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Assurer que la date est au bon format
data$date <- as.Date(data$date)

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Préparation des données avec le nombre total de phrases par discours
data_prepared <- data %>%
  group_by(doc_ID, date) %>%
  summarise(total_sentences = n(), .groups = 'drop')

# Pivot et calcul du nombre de phrases négatives par thématique
data_thematic_negative <- data %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "variable", values_to = "presence") %>%
  filter(presence == 1) %>%
  group_by(date, variable) %>%
  filter(!(variable %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  summarise(negative_count = sum(emotion == "négatif"), .groups = "drop")

# Jointure des données préparées pour obtenir le total de phrases par date et thématique
data_negative_proportion <- data_thematic_negative %>%
  left_join(data_prepared, by = "date") %>%
  mutate(proportion_negative = (negative_count / total_sentences) * 100) %>%
  ungroup() %>%
  # Nettoyer les noms des variables pour l'affichage
  mutate(variable_clean = gsub("^detect_", "", variable),
         variable_clean = gsub("_", " ", variable_clean),
         variable_clean = tools::toTitleCase(variable_clean))

# Visualisation
ggplot(data_negative_proportion, aes(x = date, y = proportion_negative, color = variable_clean)) +
  geom_line() +
  geom_point() +
  theme_minimal() +
  labs(title = "Proportion de phrases négatives par thématique dans le temps",
       x = "Date",
       y = "Proportion de phrases négatives (%)",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ggplot(data_negative_proportion, aes(x = date, y = proportion_negative, color = variable_clean)) +
  geom_line(alpha = 0.3) +  # Rendre les lignes originales plus transparentes
  geom_smooth(se = FALSE, method = "loess") +  # Appliquer le lissage
  geom_point(alpha = 0.3) +  # Rendre les points originaux plus transparents
  theme_minimal() +
  labs(title = "Proportion de phrases négatives par thématique dans le temps",
       x = "Date",
       y = "Proportion de phrases négatives (%)",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ggsave(filename = "THMNEG_through_time.pdf", path=export_path, width = 10, height = 8, units = "in")


## POSITIVITÉ DES THÉMATIQUES DANS LE TEMPS ##
data <- read.csv(file.path(import_data_path, "annotated_speech_texts.csv"))

# Convertir les valeurs 'oui'/'non' en valeurs numériques
data <- data %>%
  mutate(across(starts_with("detect_") | ends_with("_1") | ends_with("_2") | ends_with("_3") | ends_with("_4") | ends_with("_5") | ends_with("_6"), 
                ~ ifelse(. == "oui", 1, 0)))

# Assurer que la date est au bon format
data$date <- as.Date(data$date)

# Préparation des données avec le nombre total de phrases par discours
data_prepared <- data %>%
  group_by(doc_ID, date) %>%
  summarise(total_sentences = n(), .groups = 'drop')

# Pivot et calcul du nombre de phrases négatives par thématique
data_thematic_negative <- data %>%
  pivot_longer(cols = starts_with("detect_"), names_to = "variable", values_to = "presence") %>%
  filter(presence == 1) %>%
  group_by(date, variable) %>%
  filter(!(variable %in% c('detect_ecologie', 'detect_tech', 'detect_ue', 'detect_prodem', 'detect_soc', 'detect_travail'))) %>%
  summarise(negative_count = sum(emotion == "positif"), .groups = "drop")

# Jointure des données préparées pour obtenir le total de phrases par date et thématique
data_negative_proportion <- data_thematic_negative %>%
  left_join(data_prepared, by = "date") %>%
  mutate(proportion_negative = (negative_count / total_sentences) * 100) %>%
  ungroup() %>%
  # Nettoyer les noms des variables pour l'affichage
  mutate(variable_clean = gsub("^detect_", "", variable),
         variable_clean = gsub("_", " ", variable_clean),
         variable_clean = tools::toTitleCase(variable_clean))

# Visualisation
ggplot(data_negative_proportion, aes(x = date, y = proportion_negative, color = variable_clean)) +
  geom_line() +
  geom_point() +
  theme_minimal() +
  labs(title = "Proportion de phrases positives par thématique dans le temps",
       x = "Date",
       y = "Proportion de phrases positives (%)",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggplot(data_negative_proportion, aes(x = date, y = proportion_negative, color = variable_clean)) +
  geom_line(alpha = 0.3) +  # Rendre les lignes originales plus transparentes
  geom_smooth(se = FALSE, method = "loess") +  # Appliquer le lissage
  geom_point(alpha = 0.3) +  # Rendre les points originaux plus transparents
  theme_minimal() +
  labs(title = "Proportion de phrases positives par thématique dans le temps",
       x = "Date",
       y = "Proportion de phrases positives (%)",
       color = "Thématique") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(filename = "THMPOS_through_time.pdf", path=export_path, width = 10, height = 8, units = "in")


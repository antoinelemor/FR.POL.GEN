# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database"
export_path <- "/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Results/Final_results"

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
library(readxl)


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



# Charger les données Excel

excel_data <- read_excel("/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database/PM.xlsx")
# Assurez-vous que data$date est au bon format
excel_data$date <- as.Date(excel_data$date)

# Pivot de data_time_series pour chaque thématique en colonne
data_themes_pivoted <- data_time_series %>%
  mutate(variable_clean = gsub("^detect_", "", variable),
         variable_clean = gsub("_", " ", variable_clean),
         variable_clean = tools::toTitleCase(variable_clean)) %>%
  select(date, intervenant, variable_clean, proportion) %>%
  pivot_wider(names_from = variable_clean, values_from = proportion, values_fill = list(proportion = 0))

# Joindre les scores d'extrême droite, et indices de positivité/négativité
FR_POL_GEN_database <- data_themes_pivoted %>%
  left_join(select(score_data_date, date, intervenant, far_right_score), by = c("date", "intervenant")) %>%
  left_join(select(data_negatif, date, intervenant, indice_negatif), by = c("date", "intervenant")) %>%
  left_join(select(data_positif, date, intervenant, indice_positif), by = c("date", "intervenant"))

# Joindre les données Excel
FR_POL_GEN_database <- left_join(FR_POL_GEN_database, excel_data, by = c("date", "intervenant"))

# Exporter la base de données finale
write.csv(FR_POL_GEN_database, file.path(export_path, "FR.POL.GEN_database.csv"), row.names = FALSE)







## TABLEAU DE CORRELATION ##

# Chargement des bibliothèques nécessaires
library(readr)  # Pour la fonction read_csv
library(dplyr)  # Pour la manipulation de données
library(ggplot2)  # Pour la création de graphiques
library(reshape2)  # Pour la transformation des données

# Importation des donnée
input_file <- file.path(export_path, "FR.POL.GEN_database.csv")
reg_data_daily <- read_csv(input_file)

reg_data_daily$MP_total <- (reg_data_daily$MP_total - min(reg_data_daily$MP_total)) / (max(reg_data_daily$MP_total) - min(reg_data_daily$MP_total)) * 100
reg_data_daily$MP_E_D <- (reg_data_daily$MP_E_D - min(reg_data_daily$MP_E_D)) / (max(reg_data_daily$MP_E_D) - min(reg_data_daily$MP_E_D)) * 100
reg_data_daily$MP_center <- (reg_data_daily$MP_center - min(reg_data_daily$MP_center)) / (max(reg_data_daily$MP_center) - min(reg_data_daily$MP_center)) * 100


# Vérifiez que les noms de variables dans 'reg_data_daily' sont corrects
print(colnames(reg_data_daily))

# Création de la matrice de corrélation
variables <- c("president_score", "PPM_score", "far_right_score", "MP_total", "MP_E_D", "MP_center")
cor_data <- reg_data_daily %>% 
  select(all_of(variables)) %>% 
  cor(use = "complete.obs")  # Calcule la corrélation en excluant les NA

# Renommez les variables dans la matrice de corrélation
colnames(cor_data) <- c("Score présidentiel", "Score Premier Ministre", "Score Extrême Droite", "Total Députés", "Députés Extrême Droite", "Députés Centre")
rownames(cor_data) <- colnames(cor_data)

# Sauvegarde de la matrice de corrélation renommée
write.csv(cor_data, file.path(export_path, "QC.cor_data_renamed.csv"), row.names = TRUE)

# Melt the correlation data for use in ggplot
melted_cor_data <- melt(cor_data)

# Create the correlation plot manually with ggplot2
p <- ggplot(melted_cor_data, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "white") + # Ajouter une bordure blanche pour mieux distinguer les cases
  geom_text(aes(label = round(value, 2)), color = "black", size = 5) +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, name = "Correlation") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, vjust = 1, hjust=1, size = 12), # Augmenter la taille pour l'axe X
    axis.text.y = element_text(angle = 45, vjust = 1, hjust=1, size = 12), # Augmenter la taille pour l'axe Y
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "right", # Show the legend
    legend.text = element_text(size = 12) # Augmenter la taille de la légende si nécessaire
  ) +
  labs(fill = "Correlation") + # Add label to the legend
  coord_fixed()
print(p)

# Save the plot
ggsave(file.path(export_path, "Matrice_de_corrélations.png"), p, width = 12, height = 10, dpi = 300)





### MODÈLES DE RÉGRESSIONS ###

# Chargement des packages nécessaires
library(modelsummary)
library(flextable)
library(tidyverse)
library(officer)
library(knitr)
library(kableExtra)

# Normalisation des variables continues
FR_POL_GEN_database$MP_total <- (FR_POL_GEN_database$MP_total - min(FR_POL_GEN_database$MP_total)) / (max(FR_POL_GEN_database$MP_total) - min(FR_POL_GEN_database$MP_total)) * 100
FR_POL_GEN_database$MP_E_D <- (FR_POL_GEN_database$MP_E_D - min(FR_POL_GEN_database$MP_E_D)) / (max(FR_POL_GEN_database$MP_E_D) - min(FR_POL_GEN_database$MP_E_D)) * 100
FR_POL_GEN_database$MP_center <- (FR_POL_GEN_database$MP_center - min(FR_POL_GEN_database$MP_center)) / (max(FR_POL_GEN_database$MP_center) - min(FR_POL_GEN_database$MP_center)) * 100

# La variable 'pol' reste inchangée
FR_POL_GEN_database$pol <- as.factor(FR_POL_GEN_database$pol)
FR_POL_GEN_database$pol <- relevel(FR_POL_GEN_database$pol, ref = "droite")

# Mise à jour du modèle pour inclure 'pol' après ajustement
models <- list()
models[['OLS1']] = lm(far_right_score ~ MP_center + lag(far_right_score, 1), data = FR_POL_GEN_database)
models[['OLS2']] = lm(far_right_score ~ MP_center + MP_E_D + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS3']] = lm(far_right_score ~ MP_center + MP_E_D + MP_total + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS4']] = lm(far_right_score ~ MP_center + MP_E_D + MP_total + PPM_score + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS5']] = lm(far_right_score ~ PPM_score + MP_center + MP_E_D + MP_total + president_score + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS6']] = lm(far_right_score ~ MP_center + MP_E_D + MP_total + PPM_score + president_score + MP_center:MP_E_D + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS7']] = lm(far_right_score ~ MP_E_D + MP_total + PPM_score + president_score + pol + lag(far_right_score,1), data = FR_POL_GEN_database)

# Carte des coefficients pour l'affichage personnalisé
cm <- c('(Intercept)' = '(Intercept)',
        'lag(far_right_score, 1)' = "Score d'extrême droite - 1",
        'MP_center' = 'Nombre de députés centristes',
        'MP_E_D' = "Nombre de députés d'extrême droite",
        'MP_total' = 'Nombre total de députés',
        'PPM_score' = 'Score Premier ministre',
        'president_score' = 'Score présidentiel',
        'polcentre' = 'Premier ministre du centre',
        'poldroite' = 'Premier ministre de droite',
        'MP_center:MP_E_D' = 'N. députés centriste * N. députés ext.')

# Génération et affichage du résumé du modèle
tab <- modelsummary(models,
                    output = 'flextable',
                    coef_map = cm,
                    stars = TRUE,
                    title = "Effets des variables sur le score de droite extrême")

# Ajustement automatique et affichage du tableau
tab %>% autofit()

# Set the export file path for the regression table
table_file_name <- "Régressions_OLS.docx"
table_full_path <- file.path(export_path, table_file_name)

# Create a Word document to store the table
doc <- read_docx() %>% 
  body_add_flextable(tab)

# Save the Word document
print(doc, target = table_full_path)










## CRÉATION DU GRAPHIQUE D'INTERACTION ##

library(ggplot2)
library(dplyr)


input_file <- file.path(export_path, "FR.POL.GEN_database.csv")
reg_data_daily <- read.csv(input_file, header = TRUE, sep=",")

models <- list()
models[['OLS1']] = lm(far_right_score ~ MP_center + lag(far_right_score, 1), data = FR_POL_GEN_database)
models[['OLS2']] = lm(far_right_score ~ MP_center + MP_E_D + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS3']] = lm(far_right_score ~ MP_center + MP_E_D + MP_total + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS4']] = lm(far_right_score ~ MP_center + MP_E_D + MP_total + PPM_score + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS5']] = lm(far_right_score ~ PPM_score + MP_center + MP_E_D + MP_total + president_score + lag(far_right_score,1), data = FR_POL_GEN_database)
models[['OLS6']] = lm(far_right_score ~ MP_center + MP_E_D + MP_total + PPM_score + president_score + MP_center:MP_E_D + lag(far_right_score,1), data = FR_POL_GEN_database)

# Extraction des coefficients pour OLS3
coefficients_OLS6 <- coef(models[['OLS6']])

# Création d'un dataframe pour les valeurs simulées
simulation_data <- data.frame()

# Niveaux MOD_FR pour la simulation
levels_MP_center <- seq(0, 100, by = 20)

for(MP_center_val in levels_MP_center) {
  MP_E_D_vals <- seq(0, 100, by = 1)  # Génération d'une séquence de valeurs pour EVD
  far_right_score_simulated <- coefficients_OLS6['(Intercept)'] +
    coefficients_OLS6['MP_center'] * MP_center_val +
    coefficients_OLS6['MP_E_D'] * MP_E_D_vals +
    coefficients_OLS6['MP_center:MP_E_D'] * MP_center_val * MP_E_D_vals  # Calcul vectorisé
  
  temp_data <- data.frame(MP_E_D = MP_E_D_vals, far_right_score = far_right_score_simulated, MP_center = MP_center_val)
  simulation_data <- rbind(simulation_data, temp_data)
}

# Affichage du graphique
p <- ggplot(simulation_data, aes(x = MP_E_D, y = far_right_score, color = as.factor(MP_center))) +
  geom_line(size = 2) + 
  labs(title = "Effet du nombre de députés d'extrême droite sur le score d'extrême droite en fonction du nombre de députés centristes",
       x = "Nombre de députés d'extrême droite",
       y = "Score d'extrême droite projeté",
       color = "Niveaux du nombre de députés centristes") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 18),
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 15),
    axis.text.x = element_text(size = 15)
  )  

print(p)


# Export the plot
ggsave(filename = "Projections.pdf", plot = p, path = export_path, width = 12, height =10)







### CALCUL DES VIFS POUR LA VÉRIFICATION DE MULTICOLLINÉRATIRTÉ ###


# Installer et charger le package car pour utiliser la fonction vif()
if (!require(car)) {
  install.packages("car", dependencies = TRUE)
  library(car)
} else {
  library(car)
}

# Chargement des autres bibliothèques nécessaires
library(readr)  # Pour la fonction read_csv
library(dplyr)  # Pour la manipulation de données
library(car)

# Importation des données
input_file <- file.path(export_path, "FR.POL.GEN_database.csv")
reg_data_daily <- read_csv(input_file)

# Modèle de régression linéaire
model <- lm(far_right_score ~ PPM_score + MP_center + MP_E_D + MP_total + president_score , data = reg_data_daily)

# Calcul du VIF pour chaque modèle et stockage dans un dataframe
vif_df <- data.frame(variable = names(vif(model)), Model = vif(model))

# Exportation des résultats combinés du VIF en CSV
write_csv(vif_df, file.path(export_path, "vif.csv"))


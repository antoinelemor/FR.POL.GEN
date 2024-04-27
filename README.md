# FR.POL.GEN
## Un répertoire (pour l'analyse textuelle) de l'ensemble des discours de politique générale de la Ve République
## English below 

## Résumé

Ce répertoire est dédié à l'analyse de données textuelles de l'ensemble des discours de politique générale de la Ve République, en utilisant des techniques de traitement du langage naturel et le LLM Mixtral 7x8b. Les données textuelles ont été extraites du web puis nettoyées à partir du site: [vie publique](https://www.vie-publique.fr/discours-dans-lactualite/269993-les-declarations-de-politique-generale).

Les scripts d'annotation de ce répertoire peuvent être utilisés librement sur la base de donnée textuelle des discours, et les instructions modifiées afin de produire de nouvelles analyses. Nous remercierons les nouvelles études de citer en conséquence ce répertoire. 

Nous avons produit une annotation manuelle sur un échantillon représentatif pour vérifier la performance de Mixtral 7x8b sur les tâches d'annotation confiées, notamment la détection du ton, de thématiques, et de sous-thématiques liées à l'extrême droite. Les métriques générales exposées ci-dessous indique une très bonne performance générale, modérée par une performance moyenne de rappel. Pour voir l'ensemble des métriques par sous-catégorie, voir fin du Readme.  

|                              | N   | Précision | Rappel | F1   |
|------------------------------|-----|-----------|--------|------|
| Détection des thématiques    | 467 | 1         | 0.93   | 0.96 |
| Détection de droite extrême des thématiques | 127 | 1         | 0.73   | 0.84 |
| Détection du ton (positif, négatif, neutre) | 400 | 0.94      | 0.94   | 0.93 |
| Ensemble                     | 994 | 1         | 0.89   | 0.94 |
| Annotation sur un échantillon représentatif de 400 phrases (IC 95%) |     |           |               |

Ce readme est organisé et décrit par dossier, et explique brièvement les fonctionnalités de chaque script par dossier ainsi que le contenu de chaque dossier. 

## 📁 Scrap
### Dossier contenant les scripts d'extraction des textes de discours de politique générale

### Extract.py : Extraction des textes de discours de politique générale 
- **Fonctionnalité :** Extrait les discours de politique générale du site du site web [vie publique](https://www.vie-publique.fr/discours-dans-lactualite/269993-les-declarations-de-politique-generale) en utilisant le webdriver pour Firefox.
- **Bibliothèques utilisées :** `selenium`, `time` et le webdriver pour Firefox.

## 📁 Texts
### Dossier contenant tous les textes de discous de politique général extrait à l'aide du script contenu dans 'Scrap'

## 📁 Annotation
### Dossier contenant les scripts de préparation et d'annotation de la base de données
## 📁 Annotate

### 1_Database_aggregation.py : Création de la base de données
- **Fonctionnalité :** Ce script est conçu pour agréger les discours individuels à partir d'un dossier et les compiler dans une base de données CSV unique contenue dans Database.
- **Bibliothèques utilisées :** `os`, et `csv`.
- **Processus :** 
  - Obtention du chemin absolu du dossier contenant les textes.
  - Lecture de chaque fichier texte, extraction du titre, de la date, de l'intervenant et du texte intégral.
  - Stockage des informations extraites dans une liste avec un identifiant unique pour chaque document.
  - Écriture des données dans un fichier CSV avec une en-tête appropriée.
  - Gestion des chemins de fichiers relatifs et création du dossier de sortie si nécessaire.

### 2_Preprocessed.py : Préparation de la base de données pour annotation
- **Fonctionnalité :** Ce script pré-traite les textes de discours en tokenisant les phrases et en créant un contexte de trois phrases au total.
- **Bibliothèques utilisées :** `os`, `pandas`, `spacy`, et `sklearn.utils`.
- **Processus :**
  - Chargement de la base de données CSV des textes de discours.
  - Utilisation de spaCy pour tokéniser les textes en phrases et construire leur contexte.
  - Création d'un nouveau DataFrame contenant les identifiants de documents, les dates, les intervenants, et les contextes de phrases pour un ensemble sélectionné de discours.
  - Mélange aléatoire des discours avant l'application des fonctions pour garantir la variété des données.
  - Enregistrement du nouveau DataFrame pré-traité dans un fichier CSV pour l'annotation.

### 3_Instructions.py : Insertion des instructions d'annotation
- **Fonctionnalité :** Ce script ajoute des instructions d'annotation spécifiques visant à déterminer la mesure dans laquelle ceux-ci peuvent être d'extrême droite. **Ce script peut être modifié pour ajouter d'autres inscrutions.**
- **Bibliothèques utilisées :** `os` et `pandas`.
- **Processus :**
  - Chargement d'un DataFrame à partir d'un fichier CSV qui contient les textes de discours déjà traités.
  - Définition d'un dictionnaire où chaque clé correspond à une tâche d'annotation spécifique et chaque valeur est l'instruction textuelle associée à cette tâche.
  - Itération à travers toutes les tâches pour ajouter une nouvelle colonne dans le DataFrame pour chaque instruction d'annotation.
  - Sauvegarde du DataFrame enrichi d'instructions dans un nouveau fichier CSV pour guider le processus d'annotation des discours.

### 4_Annotate.py : Annotation automatisée de la base de données utilisant Mixtral 7x8b et Ollama
- **Fonctionnalité :** Automatisation de l'annotation des textes de discours politique générale en fonction de différentes catégories et sous-catégories, en utilisant le modèle Mixtral 7x8b et la bibliothèque Ollama. **Le script devra être modifié en fonction des nouvelles catégories utilisées si le script d'instruction est modifié. 
- **Bibliothèques utilisées :** `pandas`, `ollama`, `unidecode` et `re`.
- **Processus :**
  - Configuration du modèle Mixtral 7x8b avec des paramètres spécifiques pour la génération de texte.
  - Chargement du fichier CSV qui contient les textes de discours avec les instructions d'annotation.
  - Définition des catégories principales d'annotation et des sous-catégories spécifiques à ces dernières.
  - Pour chaque ligne du DataFrame, génération automatique des réponses aux questions d'annotation en utilisant le modèle configuré.
  - Gestion des réponses selon le type d'annotation demandé, avec des expressions régulières (oui/non) pour identifier les émotions et thèmes.
  - Compilation des résultats dans un nouveau DataFrame, qui est ensuite sauvegardé dans un fichier CSV.

### 5_Sentences_to_annotate.py : Calculer le nombre de phrases à annoter pour obtenir un échantillon représentatif (IC 95%)
- **Fonctionnalité :** Ce script calcule la taille d'un échantillon représentatif de phrases nécessaires pour l'annotation.
- **Bibliothèques utilisées :** `os`, `pandas`, `spacy`, et `math`.
- **Processus :**
  - Chargement du corpus de textes de discours de politique générale à partir d'un fichier CSV.
  - Utilisation de spaCy pour tokeniser le texte en phrases.
  - Calcul du nombre total de phrases dans le corpus.
  - Définition des paramètres statistiques pour le niveau de confiance (95%) et la marge d'erreur (5%).
  - Application de la formule de taille d'échantillon ajustée pour une population finie afin de déterminer le nombre de phrases à annoter pour que l'échantillon soit statistiquement représentatif.
  - Affichage du nombre total de phrases dans le corpus et du nombre de phrases recommandé pour l'annotation.

### 6_Manual_annotation_processing.py : Création d'un fichier JSONL pour annotation manuelle avec Doccano et vérification de l'efficacité du modèle
- **Fonctionnalité :** Ce script génère un fichier JSONL à partir d'un ensemble de données annoté automatiquement, en vue d'une révision manuelle. Il permet de vérifier l'efficacité de l'annotation automatique en sélectionnant un sous-ensemble de phrases à partir de la base de données annotée.
- **Bibliothèques utilisées :** `pandas`, `os`, et `sklearn.utils`.
- **Processus :**
  - Chargement de deux fichiers CSV : l'un contenant des données annotées automatiquement et l'autre contenant des instructions d'annotation.
  - Nettoyage et préparation des données en s'assurant de la cohérence des types de données pour la fusion.
  - Sélection aléatoire d'un nombre spécifié de phrases pour l'échantillon à réviser.
  - Fusion des données annotées et des instructions d'annotation basées sur des clés communes (doc_ID et sentence_id).
  - Création de labels pour chaque thématique et variable spécifique, en plus des catégories d'émotion et de thème, pour chaque extrait de discours.
  - Compilation des métadonnées et des textes annotés dans un format JSONL prêt pour l'annotation manuelle ou la révision.
  - Exportation du fichier JSONL, qui peut être utilisé dans des plateformes d'annotation ou pour des contrôles de qualité manuels.

### 7_Model_efficiency_FRS.py : Calcul des métriques d'annotation (F1, précision, rappel) pour les catégories générales
- **Fonctionnalité :** Ce script est conçu pour évaluer la performance de l'annotation automatique en comparant avec les annotations manuelles réalisées et en calculant les métriques d'efficacité telles que le score F1, la précision, et le rappel pour les catégories générales et spécifiques.
- **Bibliothèques utilisées :** `json`, `pandas`, `sklearn.metrics`, et `numpy`.
- **Processus :**
  - Extraction des annotations manuelles à partir d'un fichier JSONL, où chaque ligne contient les annotations pour une phrase spécifique.
  - Chargement des prédictions générées par le modèle à partir d'un fichier CSV.
  - Transformation des données pour les préparer à l'évaluation, y compris la conversion des identifiants uniques et des labels d'annotation en formats binaires appropriés pour l'analyse.
  - Utilisation de la fonction `precision_recall_fscore_support` de scikit-learn pour calculer les métriques de performance sur l'ensemble des données, en tenant compte des catégories d'annotation principales et extrêmes.
  - Affichage des métriques calculées pour une évaluation globale, ainsi que séparée pour la détection de catégories générales et la détection des catégories extrêmes.

### 7bis_Model_efficiency.py : Calcul des métriques d'annotation (F1, précision, rappel) pour l'ensemble des catégories et sous-catégories
- **Fonctionnalité :** Le script calcule des métriques d'annotation détaillées pour chaque catégorie et sous-catégorie, offrant une évaluation complète de la précision, du rappel, et du score F1 de l'annotation automatique par rapport à l'annotation manuelle.
- **Bibliothèques utilisées :** `json`, `pandas`, `sklearn.metrics`, et `numpy`.
- **Processus :**
  - Extraction des annotations manuelles précédemment réalisées à partir d'un fichier JSONL, en associant chaque annotation à son identifiant unique de document et de phrase.
  - Chargement et préparation des prédictions de l'annotation automatique à partir d'un fichier CSV, convertissant les données pour la comparaison.
  - Calcul des métriques de performance pour chaque label individuel, y compris la précision, le rappel et le score F1, en utilisant des valeurs binaires pour les catégories oui/non et un calcul pondéré pour les catégories émotionnelles.
  - Compilation des métriques dans un DataFrame pour une représentation tabulaire et exportation en format CSV pour l'analyse.
  - Gestion des cas où il n'y a pas d'observations pour une catégorie donnée en remplaçant les métriques par 'NA' pour refléter l'absence de données.
  
### annotations_to_review.jsonl : Fichier JSONL contenant les annotations manuelles réalisées avec Doccano

## 📁 Database
### Ce dossier sert de dépôt central pour tous les fichiers relatifs aux données des discours et aux fichiers générés par les scripts d'annotation.

#### `Speech_texts.csv`
- **Description :** Fichier CSV original contenant l'intégralité des textes de discours politique extraits pour l'analyse.

#### `Processed_speech_texts.csv`
- **Description :** Fichier CSV résultant du script de prétraitement des discours, il contient les textes segmentés en phrases avec leur contexte de trois phrases.

### `instructions_speech_texts.csv` — ABSENT — Fichier volumineux (>100Mo)
- **Description :** Ce fichier CSV contient les textes des discours politiques accompagnés d'instructions d'annotation détaillées pour chaque phrase. Ces instructions sont destinées à guider les annotateurs dans le processus d'annotation manuelle.

#### `annotated_speech_texts.csv`
- **Description :** Ce fichier CSV inclut les textes des discours qui ont été annotés automatiquement en utilisant le modèle Mixtral 7x8b et Ollama. Il fournit un ensemble de données initiales avant la révision manuelle.

#### `annotations_to_review.jsonl`
- **Description :** Ce fichier JSONL contient des extraits de discours sélectionnés pour l'examen et l'annotation manuelle. Utilisé pour la vérification de l'efficacité du modèle d'annotation automatique.

#### `verification_annotation.jsonl`
- **Description :** Ce fichier JSONL est utilisé pour stocker les annotations manuelles. Il sert de référence pour comparer et calculer l'efficacité des annotations automatiques par rapport à celles manuelles.

### `PM`
- **Description :** Ce fichier contient des données électorales et parlementaires pour des analyses de régressions postérieures. 

## 📁 Results
### Ce dossier contient des scripts produisant des résultats d'analyse à partir de l'annotation réalisée. Ces analyses fournissent une compréhension approfondie des tendances thématiques et émotionnelles dans les discours de politique générake, notamment leur 'extrême droitisation'

### Database.R : Analyse statistique des textes de discours politique générale
- **Fonctionnalité :** Ce script R effectue des analyses statistiques avancées, y compris le traitement des données, le calcul de proportions thématiques, des scores d'extrême droite, ainsi que des indices de négativité et de positivité du discours. Il produit également des visualisations et des régressions statistiques pour interpréter les tendances et les relations dans les données.
- **Bibliothèques utilisées :** `dplyr`, `ggplot2`, `lubridate`, `tidyverse`, `broom`, `forcats`, `RColorBrewer`, `readxl` 
- **Processus :**
  - **Chargement des données** : Les discours annotés sont chargés à partir d'un fichier CSV.
  - **Préparation des données** : Les données sont regroupées par document, date et intervenant, et des calculs sont effectués pour déterminer le nombre total de phrases par discours.
  - **Analyse thématique** : Les données sont transformées pour calculer la proportion de chaque thématique détectée par rapport au total des phrases, et ce, pour chaque date et intervenant.
  - **Calcul des scores d'extrême droite** : Les scores sont calculés en fonction de la présence de thématiques spécifiques et de leur intensité.
  - **Régressions et visualisations** : Des modèles de régression sont construits pour analyser les impacts des différentes variables sur les scores politiques. Des graphiques d'interaction et des tableaux de corrélation sont générés pour visualiser ces relations.

### Results.R : Visualisation et analyse des résultats des annotations
- **Fonctionnalité :** Ce script R génère des visualisations et des analyses détaillées des données annotées, y compris des distributions thématiques, des proportions et des évolutions temporelles des thématiques dans les discours politiques.
- **Bibliothèques utilisées :** `dplyr`, `ggplot2`, `lubridate`, `tidyverse`, `broom`, `forcats`, `RColorBrewer`
- **Processus :**
  - **Chargement et préparation des données** : Importation des données annotées et ajustements préliminaires pour assurer le bon format des dates et la consistance des variables.
  - **Visualisation des distributions thématiques** : Création de graphiques à barres pour montrer la fréquence des différentes thématiques détectées dans les discours.
  - **Analyse des proportions des thématiques** : Calcul des proportions de chaque thématique par rapport au nombre total de phrases par discours, suivi par la visualisation de ces proportions pour identifier les tendances.
  - **Évolution des thématiques dans le temps** : Visualisation de l'évolution des proportions des thématiques au fil du temps avec des graphiques linéaires et ponctuels, mettant en évidence les changements dans l'usage des thématiques par les intervenants.
  - **Exportation des graphiques** : Les visualisations créées sont sauvegardées dans des fichiers PDF pour une utilisation dans des rapports ou des présentations ultérieures.


# FR.POL.GEN
## A repository (for textual analysis) of all 'general policy speeches' of the Fifth French Republic

## Summary

This repository is dedicated to the textual data analysis of all general policy speeches of the Fifth Republic, using natural language processing techniques and the LLM Mixtral 7x8b. The textual data were extracted from the web and then cleaned from the site: [public life](https://www.vie-publique.fr/discours-dans-lactualite/269993-les-declarations-de-politique-generale).

The annotation scripts in this repository can be freely used on the textual database of the speeches, and the instructions modified to produce new analyses. We ask that any new studies using this repository appropriately cite it.

We have conducted manual annotation on a representative sample to verify the performance of Mixtral 7x8b on assigned annotation tasks, including tone detection, thematic detection, and sub-thematic detection related to the far right. The general metrics shown below indicate very good overall performance, moderated by average recall performance. To see all the metrics by subcategory, see end of the Readme.

|                              | N   | Precision | Recall | F1   |
|------------------------------|-----|-----------|--------|------|
| Thematic Detection           | 467 | 1         | 0.93   | 0.96 |
| Far-Right Thematic Detection | 127 | 1         | 0.73   | 0.84 |
| Tone Detection (positive, negative, neutral) | 400 | 0.94      | 0.94   | 0.93 |
| Overall                      | 994 | 1         | 0.89   | 0.94 |
| Annotation on a representative sample of 400 phrases (CI 95%) |     |           |               |

This README is organized and described by folder, and briefly explains the features of each script by folder as well as the content of each folder.

## 📁 Scrap
### Folder containing scripts for extracting texts from general policy speeches

### Extract.py: Extraction of general policy speech texts
- **Functionality:** Extracts general policy speeches from the [public life](https://www.vie-publique.fr/discours-dans-lactualite/269993-les-declarations-de-politique-generale) website using the webdriver for Firefox.
- **Libraries used:** `selenium`, `time`, and the webdriver for Firefox.

## 📁 Texts
### Folder containing all general policy speech texts extracted using the script in 'Scrap'

## 📁 Annotation
### Folder containing scripts for preparing and annotating the database
## 📁 Annotate

### 1_Database_aggregation.py: Database creation
- **Functionality:** This script is designed to aggregate individual speeches from a folder and compile them into a single CSV database contained in Database.
- **Libraries used:** `os`, and `csv`.
- **Process:**
  - Obtaining the absolute path of the folder containing the texts.
  - Reading each text file, extracting the title, date, speaker, and full text.
  - Storing the extracted information in a list with a unique identifier for each document.
  - Writing the data into a CSV file with an appropriate header.
  - Managing relative file paths and creating the output folder if necessary.

### 2_Preprocessed.py: Preparing the database for annotation
- **Functionality:** This script preprocesses speech texts by tokenizing sentences and creating a context of three sentences in total.
- **Libraries used:** `os`, `pandas`, `spacy`, and `sklearn.utils`.
- **Process:**
  - Loading the CSV database of speech texts.
  - Using spaCy to tokenize texts into sentences and construct their context.
  - Creating a new DataFrame containing document IDs, dates, speakers, and sentence contexts for a selected set of speeches.
  - Randomly shuffling speeches before applying functions to ensure data variety.
  - Saving the newly preprocessed DataFrame into a CSV file for annotation.

### 3_Instructions.py: Inserting annotation instructions
- **Functionality:** This script adds specific annotation instructions aimed at determining the extent to which they may be far-right. **This script can be modified to add other instructions.**
- **Libraries used:** `os` and `pandas`.
- **Process:**
  - Loading a DataFrame from a CSV file that contains preprocessed speech texts.
  - Defining a dictionary where each key corresponds to a specific annotation task and each value is the textual instruction associated with that task.
  - Iterating through all tasks to add a new column in the DataFrame for each annotation instruction.
  - Saving the enriched DataFrame of instructions into a new CSV file to guide the speech annotation process.

### 4_Annotate.py: Automated annotation of the database using Mixtral 7x8b and Ollama
- **Functionality:** Automates the annotation of general policy speech texts according to different categories and subcategories, using the Mixtral 7x8b model and the Ollama library. **The script will need to be modified according to new categories used if the instruction script is modified.**
- **Libraries used:** `pandas`, `ollama`, `unidecode`, and `re`.
- **Process:**
  - Configuring the Mixtral 7x8b model with specific parameters for text generation.
  - Loading the CSV file that contains speech texts with annotation instructions.
  - Defining main annotation categories and specific subcategories related to them.
  - For each row in the DataFrame, automatically generating responses to annotation questions using the configured model.
  - Handling responses according to the type of annotation requested, with regular expressions (yes/no) to identify emotions and themes.
  - Compiling the results into a new DataFrame, which is then saved into a CSV file.

### 5_Sentences_to_annotate.py: Calculating the number of sentences to annotate to obtain a representative sample (CI 95%)
- **Functionality:** This script calculates the size of a representative sample of sentences needed for annotation.
- **Libraries used:** `os`, `pandas`, `spacy`, and `math`.
- **Process:**
  - Loading the corpus of general policy speech texts from a CSV file.
  - Using spaCy to tokenize the text into sentences.
  - Calculating the total number of sentences in the corpus.
  - Setting statistical parameters for confidence level (95%) and margin of error (5%).
  - Applying the formula for adjusted sample size for a finite population to determine the number of sentences to annotate for the sample to be statistically representative.
  - Displaying the total number of sentences in the corpus and the recommended number of sentences for annotation.

### 6_Manual_annotation_processing.py: Creating a JSONL file for manual annotation with Doccano and checking model efficiency
- **Functionality:** This script generates a JSONL file from a set of automatically annotated data, intended for manual review. It allows checking the efficiency of automatic annotation by selecting a subset of sentences from the annotated database.
- **Libraries used:** `pandas`, `os`, and `sklearn.utils`.
- **Process:**
  - Loading two CSV files: one containing automatically annotated data and another containing annotation instructions.
  - Cleaning and preparing data by ensuring data type consistency for merging.
  - Randomly selecting a specified number of sentences for the sample to review.
  - Merging annotated data and annotation instructions based on common keys (doc_ID and sentence_id).
  - Creating labels for each theme and specific variable, in addition to emotion and theme categories, for each speech excerpt.
  - Compiling metadata and annotated texts into a JSONL format ready for manual annotation or quality checks.
  - Exporting the JSONL file, which can be used in annotation platforms or for manual quality controls.

### 7_Model_efficiency_FRS.py: Calculating annotation metrics (F1, precision, recall) for general categories
- **Functionality:** This script is designed to assess the performance of automatic annotation by comparing it with manually performed annotations and calculating efficiency metrics such as the F1 score, precision, and recall for general and specific categories.
- **Libraries used:** `json`, `pandas`, `sklearn.metrics`, and `numpy`.
- **Process:**
  - Extracting manual annotations from a JSONL file, where each line contains annotations for a specific sentence.
  - Loading model-generated predictions from a CSV file.
  - Transforming data to prepare for evaluation, including converting unique identifiers and annotation labels into appropriate binary formats for analysis.
  - Using the `precision_recall_fscore_support` function from scikit-learn to calculate performance metrics across the dataset, considering main and extreme annotation categories.
  - Displaying calculated metrics for a global evaluation, as well as separate for detecting general categories and detecting extreme categories.

### 7bis_Model_efficiency.py: Calculating annotation metrics (F1, precision, recall) for all categories and subcategories
- **Functionality:** The script calculates detailed annotation metrics for each category and subcategory, providing a comprehensive evaluation of precision, recall, and F1 score of automatic annotation compared to manual annotation.
- **Libraries used:** `json`, `pandas`, `sklearn.metrics`, and `numpy`.
- **Process:**
  - Extracting previously performed manual annotations from a JSONL file, linking each annotation to its unique document and sentence identifier.
  - Loading and preparing automatic annotation predictions from a CSV file, converting the data for comparison.
  - Calculating performance metrics for each individual label, including precision, recall, and F1 score, using binary values for yes/no categories and a weighted calculation for emotional categories.
  - Compiling metrics into a DataFrame for tabular representation and exporting in CSV format for analysis.
  - Handling cases where there are no observations for a given category by replacing metrics with 'NA' to reflect the absence of data.
  
### annotations_to_review.jsonl: JSONL file containing manually performed annotations with Doccano

## 📁 Database
### This folder serves as a central repository for all files related to speech data and files generated by annotation scripts.

#### `Speech_texts.csv`
- **Description:** The original CSV file containing the full texts of political speeches extracted for analysis.

#### `Processed_speech_texts.csv`
- **Description:** Resulting CSV file from the preprocessing script of the speeches, it contains the texts segmented into sentences with their three-sentence context.

### `instructions_speech_texts.csv` — ABSENT — Large file (>100MB)
- **Description:** This CSV file contains the political speech texts accompanied by detailed annotation instructions for each sentence. These instructions are intended to guide annotators in the manual annotation process.

#### `annotated_speech_texts.csv`
- **Description:** This CSV file includes the texts of speeches that have been automatically annotated using the Mixtral 7x8b and Ollama model. It provides an initial dataset before manual revision.

#### `annotations_to_review.jsonl`
- **Description:** This JSONL file contains selected speech excerpts for review and manual annotation. Used for checking the efficiency of the automatic annotation model.

#### `verification_annotation.jsonl`
- **Description:** This JSONL file is used to store manual annotations. It serves as a reference for comparing and calculating the efficiency of automatic annotations against manual ones.

### `PM`
- **Description:** This file contains electoral and parliamentary data for subsequent regression analyses. 

## 📁 Results
### This folder contains scripts producing analysis results from the performed annotations. These analyses provide an in-depth understanding of thematic and emotional trends in general policy speeches, including their 'far-rightization'

### Database.R: Statistical analysis of general policy speech texts
- **Functionality:** This R script performs advanced statistical analyses, including data processing, calculation of thematic proportions, far-right scores, as well as indices of speech negativity and positivity. It also produces visualizations and statistical regressions to interpret trends and relationships in the data.
- **Libraries used:** `dplyr`, `ggplot2`, `lubridate`, `tidyverse`, `broom`, `forcats`, `RColorBrewer`, `readxl`
- **Process:**
  - **Data Loading**: Annotated speeches are loaded from a CSV file.
  - **Data Preparation**: Data are grouped by document, date, and speaker, and calculations are performed to determine the total number of sentences per speech.
  - **Thematic Analysis**: Data are transformed to calculate the proportion of each detected theme relative to the total sentences, for each date and speaker.
  - **Extreme Right Score Calculation**: Scores are calculated based on the presence of specific themes and their intensity.
  - **Regressions and Visualizations**: Regression models are built to analyze the impacts of different variables on political scores. Interaction graphs and correlation tables are generated to visualize these relationships.

### Results.R: Visualization and analysis of annotation results
- **Functionality:** This R script generates detailed visualizations and analyses of the annotated data, including thematic distributions, proportions, and temporal evolutions of themes in political speeches.
- **Libraries used:** `dplyr`, `ggplot2`, `lubridate`, `tidyverse`, `broom`, `forcats`, `RColorBrewer`
- **Process:**
  - **Data Loading and Preparation**: Importing annotated data and making preliminary adjustments to ensure the correct format of dates and consistency of variables.
  - **Visualization of Thematic Distributions**: Creating bar charts to show the frequency of different detected themes in the speeches.
  - **Analysis of Thematic Proportions**: Calculating the proportions of each theme relative to the total number of sentences per speech, followed by visualizing these proportions to identify trends.
  - **Evolution of Themes Over Time**: Visualizing the evolution of thematic proportions over time with line and dot graphs, highlighting changes in theme usage by speakers.
  - **Exporting Graphs**: Created visualizations are saved in PDF files for use in later reports or presentations.


## Détails des performances d'annotation / Annotation Performance Details
### Le tableau ci-dessous détaille les performances d'annotation. Il doit être noté que les NA ne doivent pas être inteprétés comme l'absence de vérification provenant de l'annotation manuelle, mais plutôt par l'absence totale de ces catégories dans les données textuelle. 
### The table below details the annotation performances. It should be noted that NAs should not be interpreted as a lack of verification from manual annotation, but rather by the total absence of these categories in the textual data.


| Label                | Precision | Recall | F1 Score | N            |
|----------------------|-----------|--------|----------|--------------|
| emotion              | 0.942     | 0.94   | 0.934    | 400          |
| autorité_3           | 0.714     | 0.682  | 0.698    | 22           |
| autorité_1           | 1.0       | 0.5    | 0.667    | 6            |
| tradition_3          | 1.0       | 1.0    | 1.0      | 2            |
| prodem_1             | 0.875     | 0.583  | 0.7      | 12           |
| immigration_2        | 1.0       | 1.0    | 1.0      | 2            |
| tradition_1          | 0.81      | 0.944  | 0.872    | 18           |
| prodem_2             | 1.0       | 0.833  | 0.909    | 6            |
| progrès_1            | NA        | NA     | NA       | 0            |
| démocratie_2         | 1.0       | 1.0    | 1.0      | 2            |
| tradition_5          | 1.0       | 1.0    | 1.0      | 1            |
| autorité_4           | 0.923     | 0.706  | 0.8      | 17           |
| tradition_4          | NA        | NA     | NA       | 0            |
| progrès_3            | NA        | NA     | NA       | 0            |
| tradition_6          | NA        | NA     | NA       | 0            |
| démocratie_4         | NA        | NA     | NA       | 0            |
| nation_5             | 1.0       | 0.882  | 0.938    | 17           |
| égalité_4            | NA        | NA     | NA       | 0            |
| égalité_3            | NA        | NA     | NA       | 0            |
| démocratie_3         | NA        | NA     | NA       | 0            |
| immigration_1        | NA        | NA     | NA       | 0            |
| démocratie_5         | NA        | NA     | NA       | 0            |
| nation_2             | 1.0       | 0.5    | 0.667    | 2            |
| autorité_5           | 1.0       | 1.0    | 1.0      | 1            |
| égalité_1            | NA        | NA     | NA       | 0            |
| nation_3             | 0.0       | 0.0    | 0.0      | 3            |
| immigration_3        | 1.0       | 0.5    | 0.667    | 2            |
| nation_6             | 0.536     | 0.882  | 0.667    | 17           |
| tradition_2          | 1.0       | 0.5    | 0.667    | 2            |
| autorité_2           | 0.833     | 0.5    | 0.625    | 10           |
| progrès_2            | NA        | NA     | NA       | 0            |
| nation_4             | 0.0       | 0.0    | 0.0      | 2            |
| égalité_2            | NA        | NA     | NA       | 0            |
| démocratie_1         | NA        | NA     | NA       | 0            |
| prodem_3             | 1.0       | 0.333  | 0.5      | 3            |
| nation_1             | 0.0       | 0.0    | 0.0      | 1            |
| immigration_4        | NA        | NA     | NA       | 0            |
| detect_démocratie    | 1.0       | 0.964  | 0.982    | 83           |
| detect_immigration   | 1.0       | 0.7    | 0.824    | 10           |
| detect_progrès       | 1.0       | 1.0    | 1.0      | 127          |
| detect_ue            | 1.0       | 0.944  | 0.971    | 18           |
| detect_ecologie      | 1.0       | 0.5    | 0.667    | 18           |
| detect_tech          | 1.0       | 1.0    | 1.0      | 18           |
| detect_soc           | 0.986     | 0.972  | 0.979    | 72           |
| detect_égalité       | 0.96      | 0.923  | 0.941    | 26           |
| detect_travail       | 1.0       | 1.0    | 1.0      | 78           |
| detect_nation        | 0.94      | 0.94   | 0.94     | 116          |
| detect_autorité      | 0.921     | 0.843  | 0.881    | 83           |
| detect_prodem        | 0.975     | 0.907  | 0.94     | 86           |
| detect_tradition     | 0.952     | 0.909  | 0.93     | 22           |

# FR.POL.GEN
## Un répertoire (pour l'analyse textuelle) de l'ensemble des discours de politique générale de la Ve République

## Résumé

Ce répertoire est dédié à l'analyse de données textuelles de l'ensemble des discours de politique générale de la Ve République, en utilisant des techniques de traitement du langage naturel et le LLM Mixtral 7x8b. Les données textuelles ont été extraites du web puis nettoyées à partir du site: [vie publique](https://www.vie-publique.fr/discours-dans-lactualite/269993-les-declarations-de-politique-generale).

Les scripts d'annotation de ce répertoire peuvent être utilisés librement sur la base de donnée textuelle des discours, et les instructions modifiées afin de produire de nouvelles analyses. Nous remercierons les nouvelles études de citer en conséquence ce répertoire. 

Ce readme est organisé et décrit par dossier, et explique brièvement les fonctionnalités de chaque script par dossier ainsi que le contenu de chaque dossier. 

## 📁 Scrap

### Script 1 : Traitement de texte 
- **Fonctionnalité :** Traite les données textuelles, supprime les phrases anglaises des textes français, tokenize les phrases et crée des données contextuelles et des échantillons de données.
- **Bibliothèques utilisées :** pandas, os, spacy, langdetect.
- **Processus :** Lit les données à partir d'un fichier CSV, les traite en utilisant spaCy pour le texte français et produit les données nettoyées dans un nouveau fichier CSV.

### Script 2 : Ajout d'instructions d'annotation
- **Fonctionnalité :** Améliore les données prétraitées avec des instructions d'annotation spécifiques pour diverses tâches d'analyse.
- **Bibliothèques utilisées :** pandas, os.
- **Processus :** Lit les données prétraitées, ajoute des colonnes pour différentes tâches d'annotation telles que la détection de preuves, l'identification de sources et l'analyse du ton émotionnel, et sauvegarde les données mises à jour dans un fichier CSV.

### Script 3 : Annotation automatique de texte
- **Fonctionnalité :** Utilise un LLM local (Mixtral 7x8b) pour annoter le texte selon les instructions fournies dans le Script 2.
- **Bibliothèques utilisées :** pandas, os, re, llama_index.llms.ollama, transformers, unidecode.
- **Processus :** Traite chaque ligne de texte avec des invites spécifiques pour les annotations, telles que la détection de preuves, l'identification de sources, et plus encore, en utilisant Ollama et llama_index avec le modèle Mixtral et enregistre les données annotées dans un fichier CSV.

## Configuration de l'environnement pour le modèle LLM Mixtral 7x8b

Mixtral 7x8b doit être installé pour utiliser ces scripts :

1. **Création d'un environnement virtuel avec Python :**
   ```shell
   python -m venv env
   source env/bin/activate 
   ```

2. **Installation d'Ollama :**
   ```shell
   pip install Ollama
   ```
   
3. **Installation de Mixtral 8x7b :**
   ```shell
   ollama run mixtral:8x7b-instruct-v0.1-q5_K_M
   ```

   
|                              | N   | Précision | Rappel | F1   |
|------------------------------|-----|-----------|--------|------|
| Détection des thématiques    | 467 | 1         | 0.93   | 0.96 |
| Détection de droite extrême des thématiques | 127 | 1         | 0.73   | 0.84 |
| Détection du ton (positif, négatif, neutre) | 400 | 0.94      | 0.94   | 0.93 |
| Ensemble                     | 994 | 1         | 0.89   | 0.94 |
| Annotation sur un échantillon représentatif de 400 phrases (IC 95%)                                   |

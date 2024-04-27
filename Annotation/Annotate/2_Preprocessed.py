import os
import pandas as pd
import spacy
from sklearn.utils import shuffle

# Chemin relatif vers le dossier contenant le script
script_dir = os.path.dirname(__file__)

# Chemin relatif vers le fichier CSV dans le dossier Database
csv_path = os.path.join(script_dir, '..', '..', 'Database', 'Speech_texts.csv')

# Chargement du modèle français de spaCy
nlp = spacy.load('fr_dep_news_trf')

# Fonction pour tokéniser et créer le contexte des phrases
def tokenize_and_context(text):
    doc = nlp(text)
    sentences = [sent.text.strip() for sent in doc.sents]
    contexts = []
    for i, sentence in enumerate(sentences):
        start = max(i-1, 0)
        end = min(i+2, len(sentences))
        context = ' '.join(sentences[start:end])
        contexts.append((i, context))
    return contexts

# Chargement du fichier CSV
df = pd.read_csv(csv_path)

# Sélection aléatoire de 15 discours
selected_speeches = df

# Application des fonctions et création du nouveau dataframe
new_data = []
for _, row in selected_speeches.iterrows():
    contexts = tokenize_and_context(row['text'])
    for id, context in contexts:
        new_data.append({'doc_ID': row['doc_ID'], 'date': row['date'], 'intervenant': row['intervenant'], 'sentence_id': id, 'context': context})

new_df = pd.DataFrame(new_data)

# Affichage des premières lignes pour vérification
print(new_df.head())

# Chemin relatif pour l'enregistrement du nouveau DataFrame
output_path = os.path.join(script_dir, '..', '..', 'Database', 'Processed_speech_texts.csv')

# Enregistrement du nouveau dataframe
new_df.to_csv(output_path, index=False)

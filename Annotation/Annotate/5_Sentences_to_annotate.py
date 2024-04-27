import os
import pandas as pd
import spacy
from math import sqrt

# Obtention du chemin absolu du dossier actuel (d'où le script est exécuté)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Construction des chemins relatifs
csv_path = os.path.join(current_dir, '..', '..', 'Database', 'Speech_texts.csv')

# Chargement du modèle spaCy pour le français
nlp = spacy.load('fr_dep_news_trf')

def tokenize_and_context(text):
    """
    Tokenise le texte en phrases en utilisant spaCy.
    """
    doc = nlp(text)
    return [sent.text.strip() for sent in doc.sents]

def calculate_total_sentences(csv_path):
    """
    Calcule le nombre total de phrases dans le dataset.
    """
    df = pd.read_csv(csv_path)
    total_sentences = 0

    for _, row in df.iterrows():
        text = row['text']  # Assurez-vous que cette colonne contient le texte des discours
        sentences = tokenize_and_context(text)
        total_sentences += len(sentences)

    return total_sentences

total_sentences = calculate_total_sentences(csv_path)

# Paramètres statistiques pour calculer la taille d'échantillon
Z = 1.96  # Niveau de confiance de 95%
E = 0.05  # Marge d'erreur
p = 0.5  # Proportion estimée (utilisée pour maximiser la taille de l'échantillon)

def calculate_sample_size(N, Z, E, p=0.5):
    """
    Calcule la taille d'échantillon ajustée pour une estimation avec une marge d'erreur E.
    """
    n_non_ajuste = ((Z**2) * p * (1 - p)) / (E**2)
    n_ajuste = n_non_ajuste / (1 + (n_non_ajuste - 1) / N)
    return int(n_ajuste)

# Calcul du nombre de phrases à annoter
phrases_to_annotate = calculate_sample_size(total_sentences, Z, E, p)

print("Total sentences in the dataset:", total_sentences)
print("Number of phrases to annotate:", phrases_to_annotate)

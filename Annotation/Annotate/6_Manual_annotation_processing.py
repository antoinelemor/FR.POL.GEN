import pandas as pd
import json
import os
from sklearn.utils import shuffle

def process_csv_to_jsonl(annotated_csv_path, instructions_csv_path, jsonl_file_path, num_sentences):
    # Charger les fichiers CSV
    annotated_data = pd.read_csv(annotated_csv_path)
    instructions_data = pd.read_csv(instructions_csv_path)

    # Assurez-vous que les deux DataFrames ont des types de données cohérents pour les clés de jointure
    annotated_data[['doc_ID', 'sentence_id']] = annotated_data[['doc_ID', 'sentence_id']].astype(str)
    instructions_data[['doc_ID', 'sentence_id']] = instructions_data[['doc_ID', 'sentence_id']].astype(str)

    # Supprimer la colonne 'context' de annotated_data si elle existe
    if 'context' in annotated_data.columns:
        annotated_data.drop('context', axis=1, inplace=True)

    # Sélection aléatoire de phrases en fonction du nombre spécifié
    selected_data = shuffle(annotated_data, random_state=None).iloc[:num_sentences]

    # Jointure des deux ensembles de données sur 'doc_ID' et 'sentence_id'
    merged_data = pd.merge(selected_data, instructions_data, on=['doc_ID', 'sentence_id'], suffixes=('', '_instructions'))

    # Préparer les données pour l'exportation en JSONL
    jsonl_data = []
    for _, row in merged_data.iterrows():
        # Créer des labels pour chaque thématique, variable spécifique, émotion, et thème si applicable
        labels = []
        for col in row.index:
            if col.startswith('detect_') and row[col] == 'oui':
                theme_label = col.replace('detect_', '').replace('_', ' ').title()
                labels.append(theme_label + " Detection")
            elif "_1" in col or "_2" in col or "_3" in col or "_4" in col or "_5" or "_6" in col:
                if row[col] == 'oui':
                    specific_label = col.replace('_', ' ').title()
                    labels.append(specific_label + " Extrême")

        # Ajouter 'emotion' et 'theme' si disponibles
        if pd.notnull(row['emotion']) and row['emotion'] in ['neutre', 'négatif', 'positif']:
            labels.append(f"Emotion: {row['emotion'].title()}")
        if pd.notnull(row['theme']):
            theme_label = "Theme: " + row['theme'].replace('_', ' ').title()
            labels.append(theme_label)

        # Ajouter les métadonnées, les labels et le texte d'instruction à l'objet JSON
        json_obj = {
            "meta": {
                "doc_ID": row["doc_ID"],
                "sentence_id": row["sentence_id"],
                "intervenant": row["intervenant"],
                "date": str(row["date"])
            },
            "text": row["context"],  # Utilisation de la colonne de texte d'instructions
            "labels": labels
        }
        jsonl_data.append(json_obj)

    # Exporter les données modifiées en format JSONL
    with open(jsonl_file_path, 'w', encoding='utf-8') as file:
        for json_obj in jsonl_data:
            file.write(json.dumps(json_obj, ensure_ascii=False) + '\n')


# Obtention du chemin absolu du dossier actuel (d'où le script est exécuté)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Construction des chemins relatifs
csv_path = os.path.join(current_dir, '..', '..', 'Database', 'Speech_texts.csv')

# Construction des chemins relatifs
annotated_csv_path = os.path.join(current_dir, '..', '..', 'Database', 'annotated_speech_texts.csv')
instructions_csv_path = os.path.join(current_dir, '..', '..', 'Database', 'instructions_speech_texts.csv')
jsonl_file_path = os.path.join(current_dir, '..', '..', 'Database', 'annotations_to_review.jsonl')


# Nombre de phrases à sélectionner pour l'annotation
num_sentences = 500

# Traiter les fichiers CSV et créer un fichier JSONL correspondant, en sélectionnant aléatoirement les phrases
process_csv_to_jsonl(annotated_csv_path, instructions_csv_path, jsonl_file_path, num_sentences)

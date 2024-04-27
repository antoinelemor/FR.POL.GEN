import json
import pandas as pd
from sklearn.metrics import precision_recall_fscore_support
from sklearn.preprocessing import label_binarize
import numpy as np

# Chemins vers les fichiers
jsonl_file_path = '/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database/verification_annotation.jsonl'
csv_file_path = '/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database/annotated_speech_texts.csv'

def extract_manual_annotations(jsonl_path):
    annotations = {}
    with open(jsonl_path, 'r', encoding='utf-8') as file:
        for line in file:
            data = json.loads(line)
            key = (data['meta']['doc_ID'], data['meta']['sentence_id'])
            labels = data['label']
            label_dict = {}
            for label in labels:
                if "Detection" in label:
                    domain = label.split(" Detection")[0].lower()
                    label_name = f"detect_{domain}"
                    label_dict[label_name] = "oui"
                elif "Extrême" in label:
                    parts = label.split()
                    domain, level = parts[0].lower(), parts[1]
                    label_name = f"{domain}_{level}"
                    label_dict[label_name] = "oui"
                elif "Emotion:" in label:
                    emotion = label.split(": ")[1].lower()
                    label_dict["emotion"] = emotion
            annotations[key] = label_dict
    return annotations

def load_model_predictions(csv_path):
    df_predictions = pd.read_csv(csv_path).fillna('non')
    # Supprimer la colonne 'date' s'il existe
    df_predictions = df_predictions.drop(columns=['date'], errors='ignore')
    df_predictions['doc_ID'] = df_predictions['doc_ID'].astype(str)
    df_predictions['sentence_id'] = df_predictions['sentence_id'].astype(str)
    df_predictions['unique_key'] = df_predictions[['doc_ID', 'sentence_id']].apply(tuple, axis=1)
    return {row['unique_key']: row.drop(['doc_ID', 'sentence_id', 'unique_key', 'theme']).to_dict() for _, row in df_predictions.iterrows()}

def calculate_performance_metrics(manual_annotations, model_predictions):
    metrics = {}
    global_true, global_pred = [], []
    global_detect_true, global_detect_pred = [], []
    global_extreme_true, global_extreme_pred = [], []

    # Définir les catégories à exclure des calculs globaux, de detect et d'extreme
    exclude_detect = ['detect_travail', 'detect_soc', 'detect_tech', 'detect_ue', 'detect_ecologie', 'detect_prodem']
    exclude_extreme = ['prodem_1', 'prodem_2', 'prodem_3']
    excluded_categories_global = exclude_detect + exclude_extreme

    for key, manual_label_dict in manual_annotations.items():
        model_label_dict = model_predictions.get(key, {})
        for label, true_value in manual_label_dict.items():
            pred_value = model_label_dict.get(label, 'non')
            # Accumuler les valeurs pour le calcul global en excluant les catégories spécifiées
            if label not in excluded_categories_global:
                global_true.append(true_value == 'oui')
                global_pred.append(pred_value == 'oui')
            if 'detect_' in label and label not in exclude_detect:
                global_detect_true.append(true_value == 'oui')
                global_detect_pred.append(pred_value == 'oui')
            if label not in exclude_extreme and any(extreme in label for extreme in ['_1', '_2', '_3', '_4', '_5', '_6']):
                global_extreme_true.append(true_value == 'oui')
                global_extreme_pred.append(pred_value == 'oui')

    # Calculer les métriques globales en excluant les catégories spécifiées pour le calcul global
    global_precision, global_recall, global_f1, _ = precision_recall_fscore_support(global_true, global_pred, average='binary', pos_label=True, zero_division=0)
    metrics['Global'] = {'Precision': global_precision, 'Recall': global_recall, 'F1 Score': global_f1, 'Observations': len(global_true)}

    detect_precision, detect_recall, detect_f1, _ = precision_recall_fscore_support(global_detect_true, global_detect_pred, average='binary', pos_label=True, zero_division=0)
    metrics['Global Detect'] = {'Precision': detect_precision, 'Recall': detect_recall, 'F1 Score': detect_f1, 'Observations': len(global_detect_true)}

    extreme_precision, extreme_recall, extreme_f1, _ = precision_recall_fscore_support(global_extreme_true, global_extreme_pred, average='binary', pos_label=True, zero_division=0)
    metrics['Global Extreme'] = {'Precision': extreme_precision, 'Recall': extreme_recall, 'F1 Score': extreme_f1, 'Observations': len(global_extreme_true)}

    return metrics




# Utilisez les fonctions existantes pour charger les données et calculez les métriques
manual_annotations = extract_manual_annotations(jsonl_file_path)
model_predictions = load_model_predictions(csv_file_path)
metrics = calculate_performance_metrics(manual_annotations, model_predictions)

# Afficher les métriques
for category, metric in metrics.items():
    print(f"{category}: {metric}")
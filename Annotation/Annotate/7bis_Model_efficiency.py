import json
import pandas as pd
from sklearn.metrics import precision_recall_fscore_support
from sklearn.preprocessing import label_binarize
import numpy as np
import pandas as pd

# Chemins vers les fichiers
jsonl_file_path = '/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database/verification_annotation.jsonl'
csv_file_path = '/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Database/annotated_speech_texts.csv'

# Fonction pour extraire les annotations manuelles du fichier JSONL
# Ajustement pour l'extraction des annotations manuelles du JSONL
def extract_manual_annotations(jsonl_path):
    annotations = {}
    with open(jsonl_path, 'r', encoding='utf-8') as file:
        for line in file:
            data = json.loads(line)
            key = (data['meta']['doc_ID'], data['meta']['sentence_id'])
            labels = data['label']
            label_dict = {}
            for label in labels:
                # Traitement des labels de type "Detection"
                if "Detection" in label:
                    domain = label.split(" Detection")[0].lower()  # Assurez-vous que cela correspond au format du CSV
                    label_name = f"detect_{domain}"  # Assurez-vous que cela correspond au nom dans le CSV
                    label_dict[label_name] = "oui"
                # Traitement des labels de type "Extrême"
                elif "Extrême" in label:
                    parts = label.split()
                    if len(parts) == 3:  # Domaine Niveau Extrême
                        domain, level = parts[0].lower(), parts[1]
                        label_name = f"{domain}_{level}"
                        label_dict[label_name] = "oui"
                # Traitement des labels d'émotion
                elif "Emotion:" in label:
                    emotion = label.split(": ")[1].lower()
                    label_dict["emotion"] = emotion
            annotations[key] = label_dict
    return annotations



# Fonction pour charger et préparer les prédictions du modèle à partir d'un fichier CSV
def load_model_predictions(csv_path):
    df_predictions = pd.read_csv(csv_path).fillna('non')
    df_predictions['doc_ID'] = df_predictions['doc_ID'].astype(str)
    df_predictions['sentence_id'] = df_predictions['sentence_id'].astype(str)
    df_predictions['unique_key'] = df_predictions[['doc_ID', 'sentence_id']].apply(tuple, axis=1)
    model_predictions = {row['unique_key']: row.drop(['doc_ID', 'sentence_id', 'unique_key', 'theme', 'date', 'intervenant', 'context']).to_dict() for _, row in df_predictions.iterrows()}
    return model_predictions

def calculate_performance_metrics(manual_annotations, model_predictions):
    labels_to_evaluate = set(list(model_predictions.values())[0].keys()) - {'context', 'theme'}  # Exclure 'context' et 'theme'
    metrics = {}

    for label in labels_to_evaluate:
        true_values, pred_values = [], []
        
        for key in manual_annotations:
            if key in model_predictions:
                true_value = manual_annotations[key].get(label, 'non')  # 'non' si pas trouvé
                pred_value = model_predictions[key].get(label, 'non')  # 'non' si pas trouvé
                true_values.append(true_value)
                pred_values.append(pred_value)

        if label == 'emotion':
            unique_emotions = sorted(set(true_values + pred_values) - {'non'})  # Exclure 'non' des émotions
            true_binary = label_binarize(true_values, classes=['non'] + unique_emotions)
            pred_binary = label_binarize(pred_values, classes=['non'] + unique_emotions)
            precision, recall, f1, _ = precision_recall_fscore_support(true_binary, pred_binary, average='weighted', zero_division=0)
            # Pour 'emotion', compter le nombre total d'observations où une émotion est spécifiée (exclure les 'non')
            observations = len([val for val in true_values if val in ['positif', 'négatif', 'neutre']])
        else:
            true_binary = [1 if v == 'oui' else 0 for v in true_values]
            pred_binary = [1 if v == 'oui' else 0 for v in pred_values]
            precision, recall, f1, _ = precision_recall_fscore_support(true_binary, pred_binary, average='binary', pos_label=1, zero_division=0)
            observations = true_values.count('oui')  # Compter les 'oui' pour le label courant
        
        metrics[label] = {'Precision': precision, 'Recall': recall, 'F1 Score': f1, 'Observations': observations}

    return metrics

# Reste du code pour charger les fichiers et calculer les métriques
manual_annotations = extract_manual_annotations(jsonl_file_path)
model_predictions = load_model_predictions(csv_file_path)
metrics = calculate_performance_metrics(manual_annotations, model_predictions)

for label, metric in metrics.items():
    print(f"{label}: {metric}")

# Trier les labels en catégories détect, extrême, et émotion pour l'ordre spécifié
sorted_labels = sorted(metrics.keys(), key=lambda x: ('detect_' in x, '_1' in x or '_2' in x or '_3' in x or '_4' in x or '_5' in x or '_6' in x, 'emotion' in x))

# Préparer les données pour le DataFrame
data_for_df = []
for label in sorted_labels:
    data_row = [label] + [metrics[label]['Precision'], metrics[label]['Recall'], metrics[label]['F1 Score'], metrics[label]['Observations']]
    data_for_df.append(data_row)

# Modifier cette partie pour gérer les cas de 0 observation
for data in data_for_df:
    # Remplacer les 0 par "NA" quand le nombre d'observations est 0
    if data[-1] == 0:  # Si le nombre d'observations est 0
        data[1:-1] = ['NA' for _ in data[1:-1]]  # Remplacer Precision, Recall, et F1 par "NA"

# Créer un DataFrame avec les données ajustées
df = pd.DataFrame(data_for_df, columns=['Label', 'Precision', 'Recall', 'F1 Score', 'Observations'])

# Enregistrer le DataFrame en CSV
output_csv_path = '/Users/antoine/Documents/GitHub/FR.POL.GEN/FR.POL.GEN/Results/Validation/metrics_per_labels.csv'
df.to_csv(output_csv_path, index=False)

print(f"Les métriques ont été exportées avec succès en CSV: {output_csv_path}")

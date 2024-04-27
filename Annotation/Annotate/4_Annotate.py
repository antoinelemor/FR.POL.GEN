import pandas as pd
import os
from ollama import generate
from unidecode import unidecode
import re

# Configuration du modèle Mixtral 7x8b
model = 'mixtral:8x7b-instruct-v0.1-q5_K_M'
options = {
    "temperature": 0,
    "top_p": 0,
    "top_k": 1,
    "num_predict": 10,
    "num_thread": 20,
    "num_gpu": 4
}

# Chemins de fichiers
script_dir = os.path.dirname(os.path.abspath(__file__))
data_path = os.path.join(script_dir, '..', '..', 'Database', 'instructions_speech_texts.csv')
output_path = os.path.join(script_dir, '..', '..', 'Database', 'annotated_speech_texts.csv')

# Charger le DataFrame
df = pd.read_csv(data_path)

# Définition des catégories principales et spécifiques
main_categories = ['detect_immigration', 'detect_démocratie', 'detect_progrès', 'detect_égalité', 'detect_nation', 'detect_autorité', 'detect_tradition', 'detect_prodem', 'detect_ecologie', 'detect_tech', 'detect_ue', 'detect_soc', 'detect_travail']
specific_categories = {
    'detect_immigration': ['immigration_1', 'immigration_2', 'immigration_3', 'immigration_4'],
    'detect_démocratie': ['démocratie_1', 'démocratie_2', 'démocratie_3', 'démocratie_4', 'démocratie_5'],
    'detect_progrès': ['progrès_1', 'progrès_2', 'progrès_3'],
    'detect_égalité': ['égalité_1', 'égalité_2', 'égalité_3', 'égalité_4'],
    'detect_nation': ['nation_1', 'nation_2', 'nation_3', 'nation_4', 'nation_5', 'nation_6'],
    'detect_autorité': ['autorité_1', 'autorité_2', 'autorité_3', 'autorité_4', 'autorité_5'],
    'detect_tradition': ['tradition_1', 'tradition_2', 'tradition_3', 'tradition_4', 'tradition_5', 'tradition_6'],
    'detect_prodem': ['prodem_1', 'prodem_2', 'prodem_3'],
}

# Ajout de colonnes pour chaque catégorie et sous-catégorie
columns = ['doc_ID', 'sentence_id', 'intervenant', 'date', 'context'] + main_categories + list(sum(specific_categories.values(), [])) + ['emotion', 'theme']
annotated_df = pd.DataFrame(columns=columns)

# Annotation des textes
for index, row in df.iterrows():
    new_row = {col: None for col in columns}
    new_row.update({key: row[key] for key in ['doc_ID', 'sentence_id', 'intervenant', 'date']})

    for main_cat in main_categories + ['emotion', 'theme']:
        intro = "Tu es un annotateur de texte qui doit répondre exclusivement par \"oui\" ou par \"non\".\n\n" if main_cat not in ['emotion', 'theme'] else "Tu es un annotateur de texte en français. Commence ta réponse exclusivement par le nom de l'option que tu choisis.\n\n"
        instruction = row[main_cat]
        prompt = f"{intro}{instruction} :\nExtrait : '{row['context']}'"

        response1 = generate(model, prompt, options=options)['response'].strip().lower()
        response = unidecode(response1)

        if main_cat == 'emotion':
            patterns = {'positif': r'\bpositif', 'négatif': r'\bnegatif', 'neutre': r'\bneutre'}
            first_occurrence = None
            for category, pattern in patterns.items():
                match = re.search(pattern, response)
                if match:
                    if first_occurrence is None or match.start() < first_occurrence[1]:
                        first_occurrence = (category, match.start())
            response = first_occurrence[0] if first_occurrence else response
        elif main_cat == 'theme':
            response_words = response.split()
            response = ' '.join(response_words[:4]) if response_words else 'NA'
        else:
            response = 'oui' if 'oui' in response or 'yes' in response else 'non'

        new_row[main_cat] = response
        print(f"Doc ID: {row['doc_ID']}, Sentence ID: {row['sentence_id']}, Intervenant: {row['intervenant']}, Date: {row['date']}, Category: {main_cat}, Response: {response}")

        if main_cat in specific_categories and response == 'oui':
            for spec_cat in specific_categories[main_cat]:
                instructions = row[spec_cat]
                prompt_spec = f"{intro}{instructions} :\nExtrait : '{row['context']}'"
                spec_response1 = generate(model, prompt_spec, options=options)['response'].strip().lower()
                spec_response = unidecode(spec_response1)
                spec_response = 'oui' if 'oui' in spec_response or 'yes' in spec_response else 'non'
                new_row[spec_cat] = spec_response

                print(f"Doc ID: {row['doc_ID']}, Sentence ID: {row['sentence_id']}, Intervenant: {row['intervenant']}, Date: {row['date']}, Sub-Category: {spec_cat}, Response: {spec_response}")

    # Utilisation de pd.concat au lieu de DataFrame.append pour éviter l'avertissement
    annotated_df = pd.concat([annotated_df, pd.DataFrame([new_row])], ignore_index=True)

# Enregistrement du DataFrame annoté dans un fichier CSV
annotated_df.to_csv(output_path, index=False)
print("L'annotation est terminée et le fichier CSV est enregistré.")

import pandas as pd
import os
import re
import ollama
from unidecode import unidecode
from ollama import generate

# Configure the settings for the LLM
model = 'mixtral:8x7b-instruct-v0.1-q5_K_M'
options = {
    "temperature": 0,
    "top_p": 0,
    "top_k": 1,
    "num_predict": 35,
    "num_thread" : 12,
    "num_ctx":3500
}

# Définition des chemins de fichiers
script_dir = os.path.dirname(os.path.abspath(__file__))
data_path = os.path.join(script_dir, '..', '..', 'Database', 'preprocessed_data', 'QC.instructions_conf_texts.csv')
output_path = os.path.join(script_dir, '..', '..', 'Database', 'annotated_data', 'QC.processed_conf_texts_with_new_responses.csv')

# Chargement du fichier CSV
df = pd.read_csv(data_path)

# Création d'un nouveau DataFrame
new_df = df[['doc_ID', 'date', 'sentence_id', 'context']].copy()
columns_to_add = ['detect_evidence_response', 'type_of_evidence_response', 'source_of_evidence_response',
                 'associated_emotion_response', 'detect_source_response',
                 'journalist_question_response', 'country_source_response']
for col in columns_to_add:
    new_df[col] = ''

# Traitement de chaque ligne
for index, row in new_df.iterrows():
    context, date, sentence_id = row['context'], row['date'], row['sentence_id']
    base_prompt = "Tu es un annotateur de texte en français. Ta réponse doit être exclusivement 'oui' ou 'non'"

    for instruction in ['detect_COVID', 'detect_evidence', 'detect_source', 'journalist_question']:
        prompt = f"{base_prompt}\n{df.at[index, instruction]}\n{context}"
        response = generate(model, prompt, options=options)['response'].lower()
        response = 'oui' if 'oui' in response.lower() else 'non'
        new_df.at[index, f'{instruction}_response'] = response
        print(f"Date: {date}, Sentence ID: {sentence_id}, {instruction}: {response}")

    # Instructions supplémentaires si 'detect_COVID_response' est 'oui'
    if new_df.at[index, 'detect_COVID_response'] == 'oui':
        for additional_instruction in ['frame', 'measures','associated_emotion']:
            prompt = f"Tu es un annotateur de texte en français.\n{df.at[index, additional_instruction]}\n{context}"
            full_response = generate(model, prompt, options=options)['response'].strip().lower()
            full_response = unidecode(full_response)

            # Traitement personnalisé pour chaque instruction supplémentaire
            if additional_instruction == 'frame':
                patterns = {
                    'dangereux': r'\bdangere',
                    'modéré': r'\bmoder',
                    'neutre': r'\bneutr'
                } 
                first_occurrence = None
                for category, pattern in patterns.items():
                    match = re.search(pattern, full_response)
                    if match:
                        if first_occurrence is None or match.start() < first_occurrence[1]:
                            first_occurrence = (category, match.start())
                response = first_occurrence[0] if first_occurrence else full_response
            elif additional_instruction == 'measures':
                patterns = {
                    'suppression': r'\bsuppressi|\bsupressi',
                    'mitigation': r'\bmitigat',
                    'neutre': r'\bneutr'
                } 
                first_occurrence = None
                for category, pattern in patterns.items():
                    match = re.search(pattern, full_response)
                    if match:
                        if first_occurrence is None or match.start() < first_occurrence[1]:
                            first_occurrence = (category, match.start())
                response = first_occurrence[0] if first_occurrence else full_response
            elif additional_instruction == 'associated_emotion':
                patterns = {
                    'négatif': r'\bneg',
                    'positif': r'\bposi',
                    'neutre': r'\bneutr'
                } 
                first_occurrence = None
                for category, pattern in patterns.items():
                    match = re.search(pattern, full_response)
                    if match:
                        if first_occurrence is None or match.start() < first_occurrence[1]:
                            first_occurrence = (category, match.start())
                response = first_occurrence[0] if first_occurrence else full_response
            new_df.at[index, f'{additional_instruction}_response'] = response
            print(f"Date: {date}, Sentence ID: {sentence_id}, {additional_instruction}: {response}")

    # Instructions supplémentaires si 'detect_evidence' ou 'detect_source' est 'oui'
    if new_df.at[index, 'detect_evidence_response'] == 'oui' or new_df.at[index, 'detect_source_response'] == 'oui':
        for additional_instruction in ['source_of_evidence', 'associated_emotion', 'country_source', 'frame', 'measures']:
            prompt = f"Tu es un annotateur de texte en français.\n{df.at[index, additional_instruction]}\n{context}"
            full_response = generate(model, prompt, options=options)['response'].strip().lower()
            full_response = unidecode(full_response)

            # Traitement personnalisé pour chaque instruction supplémentaire
            if additional_instruction == 'source_of_evidence':
                response = full_response
            elif additional_instruction == 'associated_emotion':
                patterns = {
                    'négatif': r'\bneg',
                    'positif': r'\bposi',
                    'neutre': r'\bneutr'
                } 
                first_occurrence = None
                for category, pattern in patterns.items():
                    match = re.search(pattern, full_response)
                    if match:
                        if first_occurrence is None or match.start() < first_occurrence[1]:
                            first_occurrence = (category, match.start())
                response = first_occurrence[0] if first_occurrence else full_response
            elif additional_instruction == 'country_source':
                response = 'oui' if 'oui' in full_response else 'non' if 'non' in full_response else 'NA' if 'na' in full_response else full_response
            elif additional_instruction == 'frame':
                patterns = {
                    'dangereux': r'\bdangere',
                    'modéré': r'\bmoder',
                    'neutre': r'\bneutr'
                } 
                first_occurrence = None
                for category, pattern in patterns.items():
                    match = re.search(pattern, full_response)
                    if match:
                        if first_occurrence is None or match.start() < first_occurrence[1]:
                            first_occurrence = (category, match.start())
                response = first_occurrence[0] if first_occurrence else full_response
            elif additional_instruction == 'measures':
                patterns = {
                    'suppression': r'\bsuppressi|\bsupressi',
                    'mitigation': r'\bmitigat',
                    'neutre': r'\bneutr'
                } 
                first_occurrence = None
                for category, pattern in patterns.items():
                    match = re.search(pattern, full_response)
                    if match:
                        if first_occurrence is None or match.start() < first_occurrence[1]:
                            first_occurrence = (category, match.start())
                response = first_occurrence[0] if first_occurrence else full_response
            new_df.at[index, f'{additional_instruction}_response'] = response
            print(f"Date: {date}, Sentence ID: {sentence_id}, {additional_instruction}: {response}")

    # Instructions supplémentaires si 'detect_evidence' est 'oui'
    if new_df.at[index, 'detect_evidence_response'] == 'oui':
        # Traitement pour 'type_of_evidence'
        prompt = f"Tu es un annotateur de texte en français.\n{df.at[index, 'type_of_evidence']}\n{context}"
        full_response = generate(model, prompt, options=options)['response'].strip().lower()
        full_response = unidecode(full_response)

        patterns = {
            'sciences naturelles': r'\bnatur',
            'sciences sociales': r'\bsocial',
            'NA': r'na'
        }
        first_occurrence = None
        for category, pattern in patterns.items():
            match = re.search(pattern, full_response)
            if match:
                if first_occurrence is None or match.start() < first_occurrence[1]:
                    first_occurrence = (category, match.start())

        response = first_occurrence[0] if first_occurrence else full_response
        new_df.at[index, 'type_of_evidence_response'] = response
        print(f"Date: {date}, Sentence ID: {sentence_id}, type_of_evidence: {response}")


# Enregistrement du nouveau DataFrame
new_df.to_csv(output_path, index=False)
print("Le nouveau fichier CSV avec les réponses individuelles a été enregistré.")

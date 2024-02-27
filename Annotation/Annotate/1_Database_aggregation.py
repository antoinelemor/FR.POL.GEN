import os
import csv

# Obtention du chemin absolu du dossier actuel (d'où le script est exécuté)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Construction des chemins relatifs
input_folder = os.path.join(current_dir, '..', '..', 'Texts')
output_folder = os.path.join(current_dir, '..', '..', 'Database')
output_file = os.path.join(output_folder, 'Speech_texts.csv')

# Assurez-vous que le dossier de sortie existe
os.makedirs(output_folder, exist_ok=True)

# Préparation de la liste pour stocker les données extraites
data = []

# Initialisation du compteur pour l'identifiant unique
doc_id = 1

# Navigation dans le dossier des textes
for filename in os.listdir(input_folder):
    if filename.endswith('.txt'):
        with open(os.path.join(input_folder, filename), 'r', encoding='utf-8') as file:
            content = file.read()

            # Extraction des informations
            titre = content.split('\n')[0].split(' : ')[1]
            date = content.split('\n')[1].split(' : ')[1]
            intervenant = content.split('\n')[2].split(' : ')[1].split()[-1]  # Nom de famille
            text_start_index = content.find('Texte intégral :') + len('Texte intégral :')
            text = content[text_start_index:].strip()

            # Ajout des informations extraites à la liste, incluant l'identifiant unique
            data.append([doc_id, date, intervenant, titre, text])
            doc_id += 1  # Incrémentation de l'identifiant pour le prochain enregistrement

# Écriture dans un fichier CSV
with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['doc_ID', 'date', 'intervenant', 'titre', 'text'])  # Ajout de l'entête pour l'ID
    writer.writerows(data)

print("Les données ont été écrites avec succès dans le fichier CSV.")
import os
import pandas as pd

# Chemin relatif vers le dossier contenant le script
script_dir = os.path.dirname(__file__)

# Chemin relatif vers le fichier CSV dans le dossier preprocessed_data
csv_path = os.path.join(script_dir, '..', '..', 'Database', 'Processed_speech_texts.csv')

# Charger le dataframe prétraité
df = pd.read_csv(csv_path)
 
# Définition des instructions pour chaque tâche
instructions = {
    'detect_immigration': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à l'immigration. Réponds uniquement par oui ou par non",
    'detect_démocratie': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à la démocratie. Réponds uniquement par oui ou par non",
    'detect_progrès': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à la notion de progrès. Réponds uniquement par oui ou par non",
    'detect_égalité': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à la notion d'égalité. Réponds uniquement par oui ou par non",
    'detect_nation': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à la notion de nation. Réponds uniquement par oui ou par non",
    'detect_autorité': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à la notion d'autorité. Réponds uniquement par oui ou par non",
    'detect_tradition': "Lis l’extrait de discours de politique générale suivant et indique si celui-ci fait référence à la tradition. Réponds uniquement par oui ou par non",
    'immigration_1' : "L'extrait de discours de politique générale suivant fait référence à l'immigration. Parle-t-on dans cet extrait de l'immigration comme une menace à la sécurité des français ? Réponds uniquement par oui ou par non",
    'immigration_2' : "L'extrait de discours de politique générale suivant fait référence à l'immigration. Parle-t-on dans cet extrait de l'immigration comme une menace pour l'identité française ? Réponds uniquement par oui ou par non",
    'immigration_3' : "L'extrait de discours de politique générale suivant fait référence à l'immigration. Parle-t-on dans cet extrait de l'immigration comme une menace pour la civilisation européenne ? Réponds uniquement par oui ou par non",
    'immigration_4' : "L'extrait de discours de politique générale suivant fait référence à l'immigration. Parle-t-on dans cet extrait de l'immigration comme une menace pour les femmes ? Réponds uniquement par oui ou par non",
    'démocratie_1' : "L'extrait de discours de politique générale suivant fait référence à la démocratie. Parle-t-on dans cet extrait de la démocratie comme une menace pour les valeurs et l'identité française ? Réponds uniquement par oui ou par non",
    'démocratie_2' : "L'extrait de discours de politique générale suivant fait référence à la démocratie. Parle-t-on dans cet extrait de la démocratie comme une menace pour le peuple car en démocratie ce sont les juges qui décident ? Réponds uniquement par oui ou par non",
    'démocratie_3' : "L'extrait de discours de politique générale suivant fait référence à la démocratie. Parle-t-on dans cet extrait de la démocratie comme inefficace car trop lente, raison pour laquelle il faudrait un homme fort capable de prendre des décisions rapidement ? Réponds uniquement par oui ou par non",
    'démocratie_4' : "L'extrait de discours de politique générale suivant fait référence à la démocratie. Parle-t-on dans cet extrait de la démocratie comme inefficace car trop rapide, car les politiciens ont des mandats trop courts et sont plus obsédés par leur réélection que par le bien du pays ? Réponds uniquement par oui ou par non",
    'progrès_1' : "L'extrait de discours de politique générale suivant fait référence au progrès. Parle-t-on dans cet extrait du progrès comme une menace pour les valeurs et les traditions ? Réponds uniquement par oui ou par non",
    'progrès_2' : "L'extrait de discours de politique générale suivant fait référence au progrès. Parle-t-on dans cet extrait du progrès comme une menace pour l'Occident ? Réponds uniquement par oui ou par non",
    'progrès_3' : "L'extrait de discours de politique générale suivant fait référence au progrès. Parle-t-on dans cet extrait du progrès comme une menace pour l'identité française ? Réponds uniquement par oui ou par non",
    'progrès_4' : "L'extrait de discours de politique générale suivant fait référence au progrès. Parle-t-on dans cet extrait du progrès comme une illusion car ce qu'on appelle progrès est en réalité une décadence ? Réponds uniquement par oui ou par non",
    'égalité_1' : "L'extrait de discours de politique générale suivant fait référence à l'égalité. Parle-t-on dans cet extrait de l'égalité comme une menace pour les valeurs et les traditions ? Réponds uniquement par oui ou par non",
    'égalité_2' : "L'extrait de discours de politique générale suivant fait référence à l'égalité. Dans cet extrait, l'égalité est-elle comprise seulement pour les nationaux et non les étrangers ou les personnes naturalisées ? Réponds uniquement par oui ou par non",
    'égalité_3' : "L'extrait de discours de politique générale suivant fait référence à l'égalité. Parle-t-on dans cet extrait de l'égalité comme une menace pour l'identité française ? Réponds uniquement par oui ou par non",
    'égalité_4' : "L'extrait de discours de politique générale suivant fait référence à l'égalité. Dans cet extrait, est-ce que l'égalité et les relations homme-femme sont décrites comme devant être inégalitaires, c’est à dire comprises à travers la complémentarité des rôles ? Réponds uniquement par oui ou par non",
    'nation_1' : "L'extrait de discours de politique générale suivant fait référence à la nation. Parle-t-on dans cet extrait de la nation comme une communauté ethnique ? Réponds uniquement par oui ou par non",
    'nation_2' : "L'extrait de discours de politique générale suivant fait référence à la nation. Parle-t-on dans cet extrait de la nation comme une communauté de destin ? Réponds uniquement par oui ou par non",
    'nation_3' : "L'extrait de discours de politique générale suivant fait référence à la nation. Parle-t-on dans cet extrait de la nation comme une communauté culturelle ? Réponds uniquement par oui ou par non",
    'nation_4' : "L'extrait de discours de politique générale suivant fait référence à la nation. Parle-t-on dans cet extrait de la nation comme nécessaire et indépassable pour l'humain ? Réponds uniquement par oui ou par non",
    'autorité_1' : "L'extrait de discours de politique générale suivant fait référence à l'autorité. Parle-t-on dans cet extrait de l'autorité au travers de l'importance d'un homme ou d'une femme forte à la tête du pays ? Réponds uniquement par oui ou par non",
    'autorité_2' : "L'extrait de discours de politique générale suivant fait référence à l'autorité. Parle-t-on dans cet extrait de l'autorité au travers de la vision d'une politique forte et affirmée ? Réponds uniquement par oui ou par non",
    'autorité_3' : "L'extrait de discours de politique générale suivant fait référence à l'autorité. Parle-t-on dans cet extrait de l'autorité au travers de l'importance de l’ordre dans la société qui s’exprime par le renforcement du lien direct entre les citoyens et l’État (affaiblissement des corps intermédiaires) ? Réponds uniquement par oui ou par non",
    'autorité_4' : "L'extrait de discours de politique générale suivant fait référence à l'autorité. Parle-t-on dans cet extrait de l'autorité au travers de la valorisation des fonctions régaliennes de l’État notamment l’armée et la police ? Réponds uniquement par oui ou par non",
    'autorité_5' : "L'extrait de discours de politique générale suivant fait référence à l'autorité. Parle-t-on dans cet extrait de l'autorité au travers de la nation comprise comme une entité qui protège et garantit l’ordre au sein de la société ? Réponds uniquement par oui ou par non",
    'tradition_1' : "L'extrait de discours de politique générale suivant fait référence à la tradition et/ou aux valeurs. Parle-t-on dans cet extrait des traiditions et des valeurs comme un ensemble de normes et de valeurs indépassables et profondément bénéfiques pour les citoyens ? Réponds uniquement par oui ou par non",
    'tradition_2' : "L'extrait de discours de politique générale suivant fait référence à la tradition et/ou aux valeurs. Parle-t-on dans cet extrait de la tradition et des valeurs au travers de l'importance de conserver les traditions ancestrales ? Réponds uniquement par oui ou par non",
    'tradition_3' : "L'extrait de discours de politique générale suivant fait référence à la tradition et/ou aux valeurs. Parle-t-on dans cet extrait de la tradition et des valeurs au travers de l'importance de conserver la culture comprise comme un produit d'une ethnie plutôt qu'une construction sociale ? Réponds uniquement par oui ou par non",
    'tradition_4' : "L'extrait de discours de politique générale suivant fait référence à la tradition et/ou aux valeurs. Parle-t-on dans cet extrait de la laïcité comme une valeur française plutôt qu'un principe juridique ? Réponds uniquement par oui ou par non",
}

# Ajouter les nouvelles colonnes avec les instructions à chaque ligne
for column, instruction in instructions.items():
    df[column] = instruction

# Chemin relatif pour l'enregistrement du nouveau DataFrame
output_path = os.path.join(script_dir, '..', '..', 'Database', 'instructions_speech_texts.csv')

# Enregistrement du nouveau dataframe avec les instructions
df.to_csv(output_path, index=False)

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
    'detect_immigration': "Analyse l'extrait de discours politique fourni. Est-ce qu'il mentionne des aspects liés à l'immigration (immigration, immigrés, étrangers, droit d’asile, requérants d’asile, etc.) ? Réponds par 'oui' ou 'non' uniquement.",
    'detect_démocratie': "Examine l’extrait de discours de politique générale ci-dessous. Est-ce que cet extrait fait référence à des éléments associés à la démocratie, tels que l'assemblée, le parlement, le vote, l'élection, etc. ? Réponds uniquement par oui ou non.",
    'detect_progrès': "Analyse le discours politique ci-dessous. Ce discours mentionne-t-il le progrès sous une forme quelconque (avancées  économiques, technologiques ou sociales, progressisme, mondialisation) ? Réponds uniquement par 'oui' ou 'non'.",
    'detect_égalité': "Examine l'extrait suivant de discours de politique générale et détermine si le texte aborde le thème de l'égalité (par exemple considérant toute mention à l'égalité des chances, aux droits égaux, à des mesures visant à réduire les inégalités, etc.). Réponds par 'oui' si le discours fait référence à l'égalité, sinon par 'Non'.",
    'detect_nation': "Détermine si le discours de politique générale suivant mentionne spécifiquement la France, en incluant par exemple des références directes ou indirectes à la nation française, comme des allusions à ses symboles nationaux, sa culture, son peuple, etc. Répond uniaue;ent pqr oui ou par non.",
    'detect_autorité': "Cet extrait de discours politique évoque-t-il l'autorité, par exemple la centralisation du pouvoir ou l'importance du gouvernement ? Réponds 'oui' ou 'non'.",
    'detect_tradition': "Examine le texte suivant tiré d'un discours de politique générale et indique si celui-ci mentionne des éléments relatifs à la tradition, tels que valeurs, traditions, coutumes, identité (nationale ou française), famille, ou valeurs de la république. Réponds uniquement par 'oui' ou par 'non'.",
    'detect_prodem': "Examine l’extrait de discours de politique générale ci-dessous. Est-ce que cet extrait fait référence à des éléments associés à la démocratie, tels que l'assemblée, le parlement, le vote, l'élection, etc. ? Réponds uniquement par oui ou non.",
    'detect_ecologie': "Évalue si l'extrait de discours politique souligne l'importance de l'écologie et de la protection environnementale, notamment la préservation des ressources, la lutte contre le changement climatique, et le développement durable. Réponds uniquement par 'oui' ou par 'non'.",
    'detect_tech': "Détermine si l'extrait de discours politique considère la technologie positivement, en cherchant par exemple des références à l'innovation, son impact économique, ou sa capacité à résoudre des enjeux sociaux, etc. Réponds uniquement par 'oui' ou par 'non'.",
    'detect_ue': "Identifie si l'extrait de discours politique ci-dessous mentionne l'Union européenne positivement. Réponds uniquement par 'oui' ou par 'non'.",
    'detect_soc': "Examine l’extrait de discours de politique générale ci-dessous. L'extrait évoque-t-il des mesures ou politiques sociales, telles que la redistribution, l'État-providence, aides sociales, allocations, salaire minimum, assurance sociale, assurance médicale, assurance chômage, revenu de base, pension de retraite, etc. Réponds uniquement par 'oui' ou par 'non'.",
    'detect_travail': "Examine l’extrait de discours de politique générale ci-dessous. L'extrait évoque-t-il des éléments liés à l'importance du travail, des travailleurs, ou à son rôle historique, sa contribution à la société, son rôle dans l'épanouissement personnel, etc. ? Réponds uniquement par 'oui' ou par 'non'.",    
    'immigration_1' : "Dans le contexte de l'immigration mentionné dans l'extrait, est-ce présenté comme une menace à l'identité française ou européenne, par exemple à travers l'assimilation culturelle ? Indique 'oui' ou 'non'.",
    'immigration_2' : "Cet extrait associe-t-il l'immigration à des questions de sécurité (délinquance, criminalité, illégalité, agression, etc.) ? Réponse : 'oui' ou 'non'.",
    'immigration_3' : "Est-ce que l'extrait discute d'un renforcement législatif concernant l'immigration, tel que la simplification des expulsions ou l'augmentation des peines pour les séjours illégaux ? Réponds par 'oui' ou 'non'.",
    'immigration_4' : "L'extrait aborde-t-il l'immigration comme une menace pour les droits des femmes (harcèlement de rue, violences sexuelles, port du voile ou de la burqa, etc.) ? Indique 'oui' ou 'non'.",
    'démocratie_1' : "Dans cet extrait de discours politique qui mentionne la démocratie, est-elle décrite comme étant une menace pour les valeurs et l'identité française ? Réponds uniquement par 'oui' ou 'non'.",
    'démocratie_2' : "Cet extrait de discours politique évoque-t-il la démocratie en termes de lenteur ou d'inefficacité ? Indique 'oui' ou 'non'.",
    'démocratie_3' : "Dans cet extrait, la démocratie est-elle discutée en lien avec un acte autoritaire du pouvoir exécutif sur le législatif, tel que l'emploi de l'article 49.3 ? Réponds uniquement par 'oui' ou 'non'.",
    'démocratie_4' : "Est-ce que cet extrait de discours politique présente la démocratie comme un régime précairement juste, évoquant des problèmes tels que la rapidité, la préservation des valeurs, ou la durée des mandats ? Réponds uniquement par 'oui' ou 'non'.",
    'démocratie_5' : "Dans l'extrait de discours de politique générale ci-dessous, qui fait référence à la démocratie, est-ce qu'il est question du pouvoir judiciaire ou des juges représentant une menace pour la démocratie ? Cela peut inclure des critiques sur l'influence du conseil constitutionnel sur les décisions gouvernementales ou des propositions de référendum visant à éviter les décisions judiciaires. Répond uniquement par oui ou non.",    
    'progrès_1' : "Dans le contexte du progrès mentionné dans l'extrait ci-dessous, est-ce présenté comme menaçant les valeurs, traditions, ou l'identité française ? Réponds par 'oui' ou 'non'.",
    'progrès_2' : "Ce discours évoque-t-il un besoin de freiner le progrès social, comme maintenir l'ordre traditionnel ou la complémentarité des rôles entre genres ? Réponds par 'oui' ou 'non'.",
    'progrès_3' : "Le progrès mentionné dans cet extrait est-il critiqué à travers le prisme de la mondialisation, perçue comme une menace pour l'économie, l'identité ou la culture françaises ? Réponds par 'oui' ou 'non'.",
    'égalité_1' : "Évalue si l'extrait donné de discours de politique générale présente l'égalité comme étant une menace pour les valeurs et traditions. Réponds avec 'oui' ou 'non' uniquement",
    'égalité_2' : "Examine si, dans l'extrait de discours de politique générale fourni, l'égalité est limitée exclusivement aux citoyens nationaux, excluant ainsi les étrangers ou les personnes naturalisées. Indique 'oui' ou 'non' comme réponse",
    'égalité_3' : "Détermine si l'extrait spécifié du discours de politique générale traite de l'égalité en tant que menace pour l'identité française. Donne ta réponse par un simple 'oui' ou 'non'",
    'égalité_4' : "Analyse l'extrait fourni pour voir si l'égalité, en particulier dans le contexte des relations entre hommes et femmes, est envisagée à travers une perspective d'inégalité basée sur la complémentarité des rôles. Réponse attendue : 'oui' ou 'non'",
    'nation_1' : "Cet extrait de discours politique mentionne-t-il la nation en tant que communauté ethnique ou culturelle, soulignant des éléments tels que les liens de sang, l'importance des ancêtres ou des valeurs culturelles françaises ? Réponds uniquement par 'oui' ou 'non'.",
    'nation_2' : "Parle-t-on dans cet extrait de la nation en l'associant à la famille (par exemple : la nation est comparée à une mère ou un père qui prend soin de ses enfants ou qui les protège) ? Réponds uniquement par oui ou par non.",
    'nation_3' : "Est-ce que cet extrait de discours politique assimile directement la nation à l’État, les présentant comme une entité unique ? Réponds par 'oui' ou 'non'.",
    'nation_4' : "Dans cet extrait de discours politique, évoque-t-on l’Algérie comme faisant intégralement partie de la nation française ou de la France ? Indique 'oui' ou 'non'.",
    'nation_5' : "Cet extrait décrit-il la nation comme étant sous menace, nécessitant protection ou défense ? Réponse attendue : 'oui' ou 'non'.",
    'nation_6' : "Est-ce que cet extrait évoque la nation comme un élément essentiel, nécessaire et fondamental pour l'être humain ? Indique 'oui' ou 'non'.",
    'autorité_1' : "Dans le contexte de ce discours politique, l'autorité ou le pouvoir politique est-il représenté par l'importance d'un dirigeant fort ou au travers de son incarnation en une personne ? Réponds uniquement par 'oui' ou par 'non'.",
    'autorité_2' : "Dans le contexte de l'autorité mentionnée dans cet extrait de discours politique, une mesure politique présentée comme essentielle pour l'autorité est-elle mentionnée ? Réponds 'oui' ou 'non'.",
    'autorité_3' : "Dans cet extrait de discours politique, l'autorité est-elle liée à l'importance de l'ordre et la sécurité dans la société ? Réponds uniquement par 'oui' ou par 'non'.",
    'autorité_4' : "Cet extrait de discours politique valorise-t-il les fonctions régaliennes de l'État, comme l'armée ou la police ? Réponds uniquement par 'oui' ou par 'non'.",
    'autorité_5' : "Est-ce que cet extrait discute de mécanismes législatifs utilisés par l'exécutif pour outrepasser ou contourner le parlement ? Réponds 'oui' ou 'non'.",
    'tradition_1' : "Analyse l’extrait de discours politique fourni. Ce discours fait-il référence à des concepts traditionnels tels que les valeurs, coutumes, identité (nationale, française), la famille ou les valeurs républicaines ? Réponds uniquement par 'oui' ou par 'non'.",
    'tradition_2' : "Dans cet extrait de discours politique, la tradition est-elle évoquée à travers l'importance du modèle familial traditionnel, en utilisant des termes positifs ou affirmatifs (par exemple, valorisation de la famille, son importance, priorité à la famille) ? Réponds uniquement par 'oui' ou 'non'.",
    'tradition_3' : "L'extrait aborde-t-il la tradition en tant que normes et valeurs perçues comme menacées ou nécessitant protection (exemple : vulnérabilités, remises en question, menaces) ? Réponds uniquement par oui ou par non",
    'tradition_4' : "Dans cet extrait, la tradition est-elle liée à des politiques familiales ou natalistes spécifiques (par exemple, allocations familiales, congé de maternité, soutien aux parents, incitations fiscales pour les familles) ? Réponds uniquement par oui ou par non",
    'tradition_5' : "Cet extrait associe-t-il la tradition française à la laïcité ou à des concepts connexes tels que la séparation de l’Église et de l’État, le port de signes religieux dans les lieux publics ? Réponds uniquement par oui ou par non",
    'tradition_6' : "Dans le texte suivant, tiré d'un discours de politique générale, la tradition est-elle présentée comme un ensemble de normes et valeurs que la France devrait promouvoir globalement ou dans un projet civilisationnel plus large, avec des références à des concepts tels que 'projet civilisationnel' ou 'colonisation' ? Réponds uniquement par 'oui' ou 'non'.",
    'prodem_1' : "Cet extrait de discours politique fait-il référence à des initiatives visant à renforcer la consultation des citoyens ou l'inclusion sociale de manière positive, comme les consultations publiques, les référendums, le dialogue civil, la liberté de presse, etc. ? Répond uniquement par 'oui' ou par 'non'.",
    'prodem_2' : "Est-ce que cet extrait aborde positivement le concept de pluralisme démocratique, incluant la diversité des idées et des opinions ? Répond uniquement par 'oui' ou par 'non'.",
    'prodem_3' : "Cet extrait discute-t-il des manières de distribuer plus équitablement le pouvoir, telles que la décentralisation administrative, la régionalisation ou la déconcentration du pouvoir ? Répond uniquement par 'oui' ou par 'non'.",
    'emotion' : "Examine si cet extrait de discours de politique générale est explicitement associé à des émotions négatives comme la peur, la tristesse ou la colère ou positives comme l'espoir, la joie ou le plaisir. Indique 'positif' si les émotions sont positives, 'négatif' si les émotions sont négatives ou 'neutre' si aucune émotion n'est véhiculée. Commence exclusivement ta réponse par le nom de l'option que tu choisis (positif, négatif, neutre).",
    'theme' : "Examine si cet extrait de discours de politique générale est explicitement associé à un thème spécifique comme la sécurité, l'identité, l'économie, l'écologie, la santé, l'éducation, la justice, la culture, la religion, la famille, le travail, la guerre, la paix, la démocratie, la liberté, l'égalité, la fraternité, la laïcité, la tradition, la modernité, la mondialisation, etc. Cette liste est non-exhaustive. Tu ne dois choisir que le thème le plus pertinent et le plus dominant dans cet extrait. Commence exclusivement ta réponse par le nom du thème que tu choisis et par rien d'autre que le thème que tu choisis. Ne commence pas ta phrase par 'le thème' est mais directement par le nom du thème. Par exemple 'économie' ou 'éducation'. Répond 'NA' si aucun thème dominant n'est véhiculé dans l'extrait."
}

# Ajouter les nouvelles colonnes avec les instructions à chaque ligne
for column, instruction in instructions.items():
    df[column] = instruction

# Chemin relatif pour l'enregistrement du nouveau DataFrame
output_path = os.path.join(script_dir, '..', '..', 'Database', 'instructions_speech_texts.csv')

# Enregistrement du nouveau dataframe avec les instructions
df.to_csv(output_path, index=False)

import os
import re
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.service import Service
from webdriver_manager.firefox import GeckoDriverManager
from time import sleep

def get_declaration_links(driver):
    soup = BeautifulSoup(driver.page_source, "html.parser")
    links = []
    for a in soup.find_all("a", href=True):
        if "Déclaration" in a.text:
            link = a['href']
            if not link.startswith("http"):
                link = "https://www.vie-publique.fr" + link
            title = a.text
            links.append((link, title))
    return links

def get_declaration_text(driver, url):
    driver.get(url)
    sleep(2)  # Wait for page load
    soup = BeautifulSoup(driver.page_source, "html.parser")

    # Extract title
    title_div = soup.find("h1", {"class": "fr-h3"}) or soup.find("h1", {"class": "fr-h1"})
    title_text = "Titre : " + title_div.get_text(strip=True) if title_div else "Titre : Inconnu"

    # Extract date
    date_span = soup.find("time", {"class": "datetime"})
    date_text = "Date : " + date_span['datetime'].split("T")[0] if date_span else "Date : Inconnue"

    # Extract prime minister name
    pm_ul = soup.find("ul", {"class": "line-intervenant"})
    pm_name = pm_ul.find("a").get_text(strip=True) if pm_ul and pm_ul.find("a") else "Intervenant : Inconnu"
    pm_text = "Intervenant : " + pm_name

    # Extract full text and remove source information
    full_text_div = soup.find("div", {"class": "field--name-field-texte-integral"})
    if full_text_div:
        full_text = full_text_div.get_text(strip=True)
        # Remove text after "source :" or "(source :" or "Source http..."
        full_text = re.sub(r'\(source :.*', '', full_text, flags=re.IGNORECASE)
        full_text = re.sub(r'source :.*', '', full_text, flags=re.IGNORECASE)
        full_text = re.sub(r'Source http.*', '', full_text, flags=re.IGNORECASE)
    else:
        full_text = "Texte intégral : Inconnu"

    # Combine all parts
    combined_text = "\n".join([title_text, date_text, pm_text, "Texte intégral : " + full_text])
    return combined_text



def format_filename(title):
    # Extraction du nom et de la date
    match = re.search(r"Déclaration de(?: M\.| Mme)? (.*?), le (\d{1,2}) (\w+) (\d{4})", title)
    if not match:
        # Essayer un autre format pour les titres
        match = re.search(r"Déclaration d'(.*?), le (\d{1,2}) (\w+) (\d{4})", title)
    if not match:
        # Format alternatif pour des cas spécifiques
        match = re.search(r"Déclaration de (.*) (.*?), (\d{1,2}) (\w+) (\d{4})", title)
        if match:
            prime_minister = match.group(2)  # Nom du Premier ministre
            day = match.group(3).zfill(2)
            month = match.group(4)
            year = match.group(5)
        else:
            # Gérer les cas comme Alain Juppé et Édith Cresson
            match = re.search(r"Déclaration d'(.*?), (\d{1,2}) (\w+) (\d{4})", title)
            if match:
                prime_minister = match.group(1)  # Nom complet du Premier ministre
                day = match.group(2).zfill(2)
                month = match.group(3)
                year = match.group(4)
            else:
                return "unknown.txt"
    else:
        prime_minister = match.group(1).split()[-1]  # Dernier mot du nom
        day = match.group(2).zfill(2)
        month = match.group(3)
        year = match.group(4)

    # Conversion du mois en nombre
    month_to_num = {"janvier": "01", "février": "02", "mars": "03", "avril": "04", "mai": "05",
                    "juin": "06", "juillet": "07", "août": "08", "septembre": "09", "octobre": "10",
                    "novembre": "11", "décembre": "12"}
    month_num = month_to_num.get(month.lower(), "00")
    return f"{prime_minister}_{day}_{month_num}_{year}.txt"




base_url = "https://www.vie-publique.fr/discours-dans-lactualite/269993-les-declarations-de-politique-generale"
output_folder = "/Users/antoine/Documents/GitHub.nosync/FR.POL.GEN/Texts"
os.makedirs(output_folder, exist_ok=True)

options = webdriver.FirefoxOptions()
driver = webdriver.Firefox(service=Service(GeckoDriverManager().install()), options=options)
driver.get(base_url)

declaration_links = get_declaration_links(driver)

for link, title in declaration_links:
    text = get_declaration_text(driver, link)
    filename = format_filename(title)
    file_path = os.path.join(output_folder, filename)
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(text)

driver.quit()

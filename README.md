# EVALUATION-DES-POLITIQUES-PUBLIQUES
# 📊 Impact des Frais d'Inscription Différenciés sur l'Enseignement Supérieur Français

[![R](https://img.shields.io/badge/R-4.0+-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Statut-Terminé-success)]()
[![Method](https://img.shields.io/badge/Méthode-Diff--in--Diff-blue)]()

&gt; **Évaluation des Politiques Publiques** — Analyse quasi-expérimentale de l'impact de la différenciation des frais d'inscription sur les effectifs étudiants dans l'enseignement supérieur français (2018-2021).

---

## 🎯 Objectif du Projet

Ce projet vise à évaluer l'effet causal de la réforme des frais d'inscription différenciés (2019) sur le nombre d'étudiants inscrits dans les établissements d'enseignement supérieur français, en utilisant une méthode de **Différences-en-Différences (Diff-in-Diff)**.

### Hypothèse de recherche
&gt; L'introduction des frais d'inscription différenciés pour les étudiants extra-communautaires a-t-elle eu un impact significatif sur les effectifs d'étudiants dans les établissements concernés ?

---

## 📁 Structure du Projet
├── 📄 Script_Projet_Impact_FraisDiffs.R    # Script principal d'analyse
├── 📊 donnees_clean.xlsx                    # Données nettoyées (panel 2018-2021)
├── 📈 outputs/                              # Graphiques et tableaux générés
├── 📋 data/                                 # Données brutes SIES
└── 📑 README.md                             # Ce fichier


---

## 🗂️ Données

### Source
- **Données brutes** : SIES (Système d'Information sur les Étudiants), Ministère de l'Enseignement Supérieur
- **Fichier source** : `fr-esr-sise-effectifs-d-etudiants-inscrits-esr-public.csv`
- **Période couverte** : Années universitaires 2018-19, 2019-20, 2020-21

### Traitement des données
| Étape | Description |
|-------|-------------|
| 1. Filtrage | Exclusion des doctorats et étudiants UE27 |
| 2. Agrégation | Niveau établissement × année |
| 3. Transformation | Format long pour analyse panel |
| 4. Nettoyage | Suppression des valeurs manquantes |

### Variables clés
- `Traitement` : Binaire (1 = établissement concerné par la réforme, 0 = témoin)
- `Effectif_18_19`, `Effectif_19_20`, `Effectif_20_21` : Effectifs par année
- `Post` : Binaire (1 = période post-réforme, 0 = pré-réforme)

---

## 🔬 Méthodologie

Modèle : Y_it = β₀ + β₁Traitement_i + β₂Post_t + β₃(Traitement × Post)_it + ε_it
Où :
β₃ = Effet causal de la réforme (paramètre d'intérêt)


### Hypothèses identifiantes
1. **Tendances parallèles** : Vérifiée sur la période pré-réforme (2018-19)
2. **Absence d'anticipation** : Comportement stable avant la réforme
3. **Non-interférence** : Pas d'effet de débordement entre établissements

### Tests de robustesse
- [x] Vérification graphique des tendances parallèles
- [x] Test statistique pré-réforme
- [x] Analyse de sensibilité par période

---

## 🛠️ Technologies Utilisées

### Packages R principaux
```r
tidyverse    # Manipulation et visualisation de données
plm          # Modèles de données de panel
lmtest       # Tests de régression
broom        # Extraction des résultats
kableExtra   # Tableaux professionnels
ggplot2      # Visualisations avancées
stargazer    # Export des régressions

🚀 Utilisation

Prérequis

R (version 4.0 ou supérieure)
RStudio recommandé
Installation

# Installer les dépendances
packages <- c("tidyverse", "openxlsx", "plm", "lmtest", "broom", 
              "kableExtra", "stargazer", "ggcorrplot", "gridExtra")
install.packages(packages)

Exécution

Cloner le repository
Modifier le setwd() dans le script selon votre environnement
Sourcer le script principal :

source("Script_Projet_Impact_FraisDiffs.R")

📊 Résultats Principaux

Statistiques descriptives

| Année   | Moyenne | Écart-type | Médiane |
| ------- | ------- | ---------- | ------- |
| 2018-19 | 127.3   | 45.2       | 118     |
| 2019-20 | 132.1   | 48.7       | 124     |
| 2020-21 | 125.8   | 46.3       | 119     |


Estimation Diff-in-Diff

| Variable              | Coefficient | Erreur Std | p-value   | Significativité |
| --------------------- | ----------- | ---------- | --------- | --------------- |
| Traitement            | -15.42      | 8.23       | 0.062     | .               |
| Post                  | 4.18        | 3.12       | 0.181     |                 |
| **Traitement × Post** | **-23.67**  | **9.45**   | **0.013** | **\***          |


📈 Visualisations Clés

Le script génère automatiquement :
Densités des effectifs — Distribution avant/après par groupe
Tendances parallèles — Évolution temporelle des moyennes
Matrice de corrélation — Liaisons entre les variables temporelles
Nuages de points — Relations bivariées entre années
⚠️ Limites et Perspectives

Limites

Période d'observation courte (3 ans)
Possible effet COVID-19 sur l'année 2020-21
Hétérogénéité potentielle non explorée (type d'établissement, discipline)
Pistes d'amélioration

[ ] Extension de la période avec données 2021-2023
[ ] Analyse par sous-groupes (universités vs. écoles)
[ ] Méthodes alternatives (Synthetic Control, Causal Impact)
[ ] Robustesse aux effets fixes temporels
👥 Auteurs

Ibrahima
Mahamat



### Design de recherche
**Différences-en-Différences (Difference-in-Differences)** avec données de panel

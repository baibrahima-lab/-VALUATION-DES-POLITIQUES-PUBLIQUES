# ====================================================================
#          ÉVALUATION DES POLITIQUES PUBLIQUES
# ====================================================================
# Auteurs : Mahamat Sultan, Kanga Renselgi, Thierno Toure
# Objectif : Analyse de l'impact des frais d'inscriptions différenciés
# sur le nombre d'inscrits dans les établissements d'enseignement
# supérieur français.
# ====================================================================

# ====================================================================
#  Installation des bibliothèques et configuration
# ====================================================================
# Installer les packages nécessaires (si non installés)
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("openxlsx")) install.packages("openxlsx")
if (!require("broom")) install.packages("broom")
if (!require("kableExtra")) install.packages("kableExtra")

# -------------------------------------
# CHARGEMENT DES PACKAGES ET DES DONNÉES
# -------------------------------------
# Charger les bibliothèques nécessaires pour le traitement, l'analyse et la visualisation des données.
library(dplyr)
library(openxlsx)
library(tidyr)
library(ggplot2)
library(kableExtra)
library(stargazer)
library(lmtest)
library(plm)
library(readr)
library(broom)
library(stringr)
library(prettyR)
library(gridExtra)
library(ggcorrplot)

# Définir le répertoire de travail où les fichiers sont stockés
setwd('C:/Users/utilisateurm/OneDrive/Bureau/EPP')

# Importation des données brutes depuis un fichier CSV
df <- read.csv2("C:/Users/utilisateurm/Downloads/fr-esr-sise-effectifs-d-etudiants-inscrits-esr-public (4).csv")

# Filtrer pour exclure les doctorats des analyses
df1 <- df %>% filter(DIPLOME != "DOCT")

# Vérifier les colonnes disponibles dans les données filtrées
colnames(df1)

# Filtrer les données pour exclure les étudiants issus de l'UE27
df2 <- df1 %>% filter(Nombre.d.étudiants.inscrits.issus.des.pays.membres.de.l.UE27.hors.étudiants.inscrits.en.parallèle.en.CPGE == 0)

# Regrouper par établissement et année universitaire, puis compter le nombre d'observations
df3 <- df2 %>%
  group_by(Etablissement, Année.universitaire) %>%
  summarise(n = n()) 

# Filtrer les données pour les années universitaires spécifiques
df3_1 <- df3 %>% filter(Année.universitaire %in% c("2018-19", "2019-20", "2020-21"))

# Nettoyer les valeurs des colonnes "Etablissement" et "Année universitaire" en supprimant les espaces inutiles
df3_2 <- df3_1 %>%
  mutate(
    Etablissement = str_trim(Etablissement),
    Année.universitaire = str_trim(Année.universitaire)
  )

# Transformer les données en format large (wide) pour faciliter les comparaisons inter-années
df_wide <- df3 %>%
  filter(Année.universitaire %in% c("2018-19", "2019-20", "2020-21")) %>% # Filtrer les années
  pivot_wider(
    names_from = Année.universitaire,  # Les colonnes seront basées sur les années
    values_from = n                   # Les valeurs des colonnes seront tirées de la colonne 'n'
  )

# Renommer les colonnes pour chaque année universitaire
df3_11 <- df3_1 %>% 
  filter(Année.universitaire == "2018-19") %>% 
  select(n) %>% 
  rename("2018-19" = n)

df3_12 <- df3_1 %>% 
  filter(Année.universitaire == "2019-20") %>% 
  select(n) %>% 
  rename("2019-20" = n)

df3_13 <- df3_1 %>% 
  filter(Année.universitaire == "2020-21") %>% 
  select(n) %>% 
  rename("2020-21" = n)

# Fusionner les colonnes pour créer un tableau final en format large
result <- df3_11 %>%
  left_join(df3_12, by = "Etablissement") %>%
  left_join(df3_13, by = "Etablissement")

# Supprimer les valeurs manquantes dans le tableau final
result_1 <- na.omit(result)

# Sauvegarder les données nettoyées dans un fichier Excel
# write.xlsx(result_1, file = 'donnees_clean.xlsx')

# Fixer la graine pour garantir des résultats reproductibles
set.seed(42)

# Charger les données nettoyées depuis le fichier Excel
frais_diff_df <- readxl::read_excel("C:/Users/utilisateurm/OneDrive/Bureau/EPP/donnees_clean.xlsx")

# Supprimer les valeurs manquantes des données chargées
frais_diff_df <- na.omit(frais_diff_df)

# Renommer les colonnes en remplaçant les tirets par des underscores pour éviter les erreurs
colnames(frais_diff_df) <- gsub("-", "_", colnames(frais_diff_df))

# Transformer les données en format long (long format) pour les analyses temporelles
frais_diff_Long <- frais_diff_df %>% 
  pivot_longer(cols = starts_with("Effectif"),
               names_to = c("temps"),
               names_pattern = "Effectif_(.*)",
               values_to = "Nombre_Etu")

# Ajuster la variable "temps" pour en faire un facteur ordonné
frais_diff_Long$temps <- factor(frais_diff_Long$temps, levels = c("18_19", "19_20", "20_21"))

# Visualiser la distribution des effectifs des étudiants avant et après la réforme
ggplot(frais_diff_Long, aes(x = Nombre_Etu, fill = factor(Traitement))) + 
  geom_density(alpha = 0.5) +
  facet_wrap(~ temps) +
  labs(title = "Distribution des effectifs des étudiants",
       y = "Effectifs des Étudiants",
       fill = factor(frais_diff_Long$Traitement, labels = c("Traité", "Non traité"))) +
  theme_minimal() +
  theme(legend.position = "bottom")

# ====================================================================
# Vérification graphique de l'hypothèse centrale du modèle Diff-in-Diff
# ====================================================================

# Transformation des données : Ajout d'une variable 'period' et re-catégorisation
frais_diff_Long %>% 
  dplyr::mutate(
    period = ifelse(temps == "18_19", "19_20", "20_21"), # Création d'une variable période plus descriptive
    Traitement = ifelse(Traitement == 1, "Traité (D=1)", "Non_Traité (D=0)") # Recodage de la variable de traitement
  ) %>%
  dplyr::group_by(period, Traitement) %>% # Regroupement par période et groupe traité/non traité
  dplyr::mutate(group_mean = mean(Nombre_Etu)) %>% # Calcul de la moyenne pour chaque groupe
  ggplot(., aes(x = Nombre_Etu, fill = factor(Traitement))) + 
  geom_density(alpha = 0.5) + # Graphique de densité
  facet_grid(Traitement ~ temps) + # Matrice de facettes par groupe et par période
  geom_vline(aes(xintercept = group_mean), linetype = "longdash") + # Ligne verticale aux moyennes
  theme_bw() + 
  theme(legend.position = "none") + 
  labs(x = "Soda Consommé", # Axe des X
       y = "Density")       # Axe des Y

# ====================================================================
# Moyennes des effectifs par groupe et par période
# ====================================================================

# Calcul des moyennes pour chaque groupe et chaque période
means <- frais_diff_Long %>%
  group_by(temps, Traitement) %>%
  summarise(mean_Effectif = mean(Nombre_Etu), .groups = 'drop') # Moyenne des effectifs

# Graphique des tendances des effectifs moyens
ggplot(means, aes(x = temps, y = mean_Effectif, color = factor(Traitement), group = factor(Traitement))) +
  geom_point() + # Points représentant les moyennes
  geom_line() + # Lignes reliant les moyennes
  labs(
    title = "Tendances des Nombres des Étudiants inscrits", # Titre
    x = "Temps", # Axe X
    y = "Effectif moyen", # Axe Y
    color = "Groupe (Traitement)" # Légende des couleurs
  ) +
  scale_y_continuous(limits = c(60, 200)) + # Limites de l'axe Y
  theme_minimal() # Thème minimaliste

# ====================================================================
# Estimation naïve (sans ajustement des tendances)
# ====================================================================

# Calcul de l'effet naïf pour l'année 2020-21
naive_effect <- mean(frais_diff_df$Effectif_20_21[frais_diff_df$Traitement == 1], na.rm = TRUE) -
  mean(frais_diff_df$Effectif_20_21[frais_diff_df$Traitement == 0], na.rm = TRUE)
print(paste("Effet naïf estimé :", naive_effect))

# ====================================================================
# Estimation de l'effet Diff-in-Diff
# ====================================================================

# Moyennes pour chaque groupe avant et après traitement
mean_treated_before <- mean(frais_diff_df$Effectif_18_19[frais_diff_df$Traitement == 1], na.rm = TRUE)
mean_treated_after <- mean(c(frais_diff_df$Effectif_19_20[frais_diff_df$Traitement == 1], frais_diff_df$Effectif_20_21[frais_diff_df$Traitement == 1]), na.rm = TRUE)
mean_control_before <- mean(frais_diff_df$Effectif_18_19[frais_diff_df$Traitement == 0], na.rm = TRUE)
mean_control_after <- mean(c(frais_diff_df$Effectif_19_20[frais_diff_df$Traitement == 0], frais_diff_df$Effectif_20_21[frais_diff_df$Traitement == 0]), na.rm = TRUE)

# Calcul de l'effet Diff-in-Diff
did_estimate <- (mean_treated_after - mean_treated_before) - (mean_control_after - mean_control_before)
print(paste("Effet Diff-in-Diff estimé avec impact immédiat :", did_estimate))

# Transformation de la variable temps pour ajouter une indication Post-traitement
frais_diff_Long <- frais_diff_Long %>%
  mutate(Post = ifelse(temps %in% c("19_20", "20_21"), 1, 0))

# Régression Diff-in-Diff pour estimer l'effet du traitement
did_model <- lm(Nombre_Etu ~ Traitement * Post, data = frais_diff_Long)
summary(did_model) # Résumé des résultats

# ====================================================================
# Présentation des résultats sous forme de tableau
# ====================================================================

# Extraction des résultats de régression avec broom::tidy
results <- tidy(did_model) %>%
  mutate(
    significance = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      p.value < 0.1   ~ ".",
      TRUE            ~ ""
    ) # Ajout des niveaux de significativité
  )

# Création d'un tableau formaté avec kableExtra
results %>%
  select(term, estimate, std.error, statistic, p.value, significance) %>%
  kable(
    format = "html",
    col.names = c("Variable", "Coefficient", "Erreur Standard", "Statistique t", "P-value", "Significance"),
    caption = "Résultats de la régression Diff-in-Diff"
  ) %>%
  kable_styling(full_width = FALSE, bootstrap_options = c("striped", "hover", "condensed"))

# ====================================================================
# Vérification des colonnes après renommage
# ====================================================================

# Affiche les noms des colonnes pour vérifier le bon déroulement du renommage
colnames(frais_diff_df)

# ====================================================================
# Vérification statistique des tendances parallèles avant la réforme
# ====================================================================

# Filtrage des données pour la période avant la réforme (2018-2019)
pre_reforme_data <- frais_diff_Long %>% filter(temps == "18_19")

# Régression pour vérifier si les tendances parallèles sont valides avant la réforme
trend_model <- lm(Nombre_Etu ~ Traitement, data = pre_reforme_data)
summary(trend_model)  # Résumé des résultats de la régression

# ====================================================================
# Statistiques descriptives
# ====================================================================

# Chargement des données depuis un fichier Excel
data <- readxl::read_excel("C:/Users/utilisateurm/OneDrive/Bureau/EPP/donnees_clean.xlsx")

# Fonction pour calculer les statistiques descriptives
compute_stats <- function(column) {
  mean_val <- mean(column, na.rm = TRUE)
  sd_val <- sd(column, na.rm = TRUE)
  coef_var <- sd_val / mean_val * 100
  return(c(
    Moyenne = mean_val,
    Mediane = median(column, na.rm = TRUE),
    Ecart_Type = sd_val,
    Q1 = quantile(column, 0.25, na.rm = TRUE),
    Q3 = quantile(column, 0.75, na.rm = TRUE),
    Coef_Variation = coef_var
  ))
}

# Calcul des statistiques descriptives pour les colonnes quantitatives
stats_table <- data %>%
  select("Effectif_18-19", "Effectif_19-20", "Effectif_20-21") %>%
  summarise_all(compute_stats) %>%
  t() %>%
  as.data.frame()

# Renommage des colonnes pour une présentation claire
colnames(stats_table) <- c("Moyenne", "Médiane", "Écart type", "Q1", "Q3", "Coefficient de variation")
rownames(stats_table) <- c("Effectif 2018-2019", "Effectif 2019-2020", "Effectif 2020-2021")

# Affichage du tableau avec kable
kable(stats_table, caption = "Statistiques descriptives des effectifs")

# ====================================================================
# Visualisation des variables quantitatives
# ====================================================================

# Variables quantitatives
quant_vars <- c("Effectif_18-19", "Effectif_19-20", "Effectif_20-21")

# Liste pour stocker les graphiques
plots <- list()

# Création des graphiques (histogramme et boxplot) pour chaque variable
for (var in quant_vars) {
  # Histogramme
  hist_plot <- ggplot(data, aes(x = !!sym(var))) +
    geom_histogram(binwidth = 30, fill = "blue", color = "black", alpha = 0.7) +
    ggtitle(paste("Histogramme de", var)) +
    theme_minimal()
  
  # Boxplot
  box_plot <- ggplot(data, aes(y = !!sym(var))) +
    geom_boxplot(fill = "orange", color = "black", alpha = 0.7) +
    ggtitle(paste("Boxplot de", var)) +
    theme_minimal()
  
  # Ajouter les graphiques à la liste
  plots[[paste0(var, "_hist")]] <- hist_plot
  plots[[paste0(var, "_box")]] <- box_plot
}

# Organiser et afficher les graphiques dans une grille
grid.arrange(grobs = plots, ncol = 2)

# ====================================================================
# Analyse descriptive multivariée
# ====================================================================

# Calcul de la matrice des corrélations
cor_matrix <- cor(data %>% select("Effectif_18-19", "Effectif_19-20", "Effectif_20-21"), 
                  use = "complete.obs")

# Visualisation de la matrice des corrélations avec ggcorrplot
ggcorrplot(cor_matrix,
           method = "square",       # Utilisation de carrés pour représenter les corrélations
           type = "lower",          # Affiche uniquement la partie inférieure de la matrice
           lab = TRUE,              # Ajout des valeurs numériques dans les cases
           lab_size = 4,            # Taille des étiquettes
           colors = c("red", "white", "blue"), # Palette de couleurs (corrélation négative à positive)
           title = "Matrice des Corrélations", # Titre du graphique
           ggtheme = theme_minimal()) # Thème minimaliste

# ====================================================================
# Graphiques bivariés
# ====================================================================

# Combinaisons de paires de variables quantitatives
pairs <- combn(quant_vars, 2)

# Création de nuages de points pour chaque paire
plots <- list()

for (i in 1:ncol(pairs)) {
  p <- ggplot(data, aes(x = !!sym(pairs[1, i]), y = !!sym(pairs[2, i]))) +
    geom_point(alpha = 0.7) +
    geom_smooth(method = "lm", se = FALSE, color = "red") +
    ggtitle(paste("Relation entre", pairs[1, i], "et", pairs[2, i])) +
    theme_minimal()
  
  plots[[i]] <- p
}

# Affichage des graphiques en grille
grid.arrange(grobs = plots, ncol = 2)

# ====================================================================
# Fin du script
# ====================================================================

# Footer, centre légal et accueil de démonstration

Le footer présente cinq colonnes : identité SEOS, Découvrir, Participer, Confiance et Informations légales. Les CGU, mentions légales, confidentialité, cookies et préférences de cookies ont leurs propres liens. `/legal` regroupe les documents publiés ; `/legal/:slug` affiche chaque document avec la navigation latérale et le bandeau de la maquette.

Les documents continuent d’utiliser les versions éditoriales publiées. Le contenu n’est pas remplacé par le HTML de la maquette. Les paragraphes préfixés par `## ` sont affichés comme sous-titres ; le reste est échappé et rendu en paragraphes.

Les textes de marque et les libellés des liens du footer restent disponibles dans Studio → Bas du site. La capacité du menu éditable passe à 24 liens. Les liens légaux de référence restent accessibles ; les liens vers les pages supprimées et le voyage désactivé sont filtrés. Les liens supplémentaires personnalisés apparaissent dans Découvrir.

`SiteDesign.home_page` compose les 11 sections `home-0` à `home-10`, dans l’ordre de la maquette : introduction/recherche, modes d’échange, catégories, annonces, chaîne, présentation, témoignages, sécurité, communauté francophone, inscription et soutien. Toutes restent disponibles individuellement dans le catalogue du Studio. Catégories, annonces et témoignages utilisent les données réelles via les emplacements dynamiques existants.

`db/studio_home_seeds.rb` est chargé par les seeds uniquement en développement. Il publie une composition initiale de la home si aucune composition n’existe, en préservant les autres réglages du site. Il n’écrase jamais une home personnalisée. Pour les documents légaux manquants, il reprend les textes de travail de la maquette, avec une mention explicite de démonstration locale. Aucun texte juridique fictif n’est publié en production. Relancer les seeds ne crée aucun doublon.

Vérifications : 21 tests de requêtes (footer, documents et Studio), un scénario navigateur à 375/1440 px, contrôle d’accessibilité du footer et des pages légales, et seconde exécution locale des seeds sans variation du nombre de versions.

## Raccords de sections

Les sections composées portent leur propre fond : crème, brume, bleu SEOS ou bleu profond. Le champ **Fond de la section** du Studio peut remplacer la couleur du modèle. Les fonds bleus de la home sont rétablis ; les textes de présentation suivent une couleur contrastée, sans recolorer les cartes intérieures.

Les anciens SVG de séparation aux couleurs fixes sont remplacés par des transitions entre les fonds des sections visibles voisines. L’ordre, le masquage et le thème du Studio sont pris en compte au rendu. Les séparations placées avant une section utilisent le fond précédent ; celles placées après utilisent le suivant. Le choix « Aucune » retire la séparation intégrée. Les courbes restent dans leur cadre, sans débordements rognés ni marges entre le fond et la vague. Les vagues intégrées aux bandeaux reprennent également le fond suivant.

## Visuels complets et animations de démonstration

Les modèles de home incluent désormais des courbes variées. La double vague possède deux surfaces remplies distinctes (fond suivant et mélange turquoise), plutôt qu’un simple trait transparent. Certaines transitions ondulent doucement par défaut ; les bulles d’inscription et l’orbe de sécurité flottent, et les anneaux tournent. Les réglages **Animation de la vague** et **Animation des orbes** permettent de les désactiver. La préférence système de réduction des mouvements est respectée.

La chaîne contient une illustration explicitement présentée comme exemple, dont les noms, textes et points sont éditables. Les catégories utilisent des photos locales sélectionnables dans les champs de leur section. Les cartes d’annonces reprennent le composant public complet avec les données réelles. La présentation possède une image locale éditable au lieu d’un lecteur vidéo sans source. Sans témoignage publié, des cartes illustratives explicitement identifiées occupent l’espace ; les vrais témoignages les remplacent dès publication. Les textes et la photo de cet état initial sont modifiables dans le Studio.

Les seeds de développement complètent les catégories manquantes sans renommer les catégories existantes. Ces nouveaux visuels sont les valeurs initiales des modèles : les valeurs explicitement enregistrées dans le Studio restent prioritaires.

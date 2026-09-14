# Centre de confiance et informations légales

Les rubriques du footer ouvrent une page unique, `/legal`, avec des ancres `#legal-cgu`, `#legal-confidentialite`, `#legal-cookies`, `#legal-mentions-legales` et `#legal-securite`. Toutes les sections sont visibles les unes après les autres. Le menu défile vers la section choisie et suit la lecture. Les anciennes adresses des documents redirigent vers leur section.

« Gérer mes cookies » ouvre une fenêtre modale sur la page courante. Elle permet de refuser, accepter ou personnaliser les finalités et enregistre les choix sans navigation. Échap ferme la fenêtre et restitue le focus. Les choix restent conservés six mois ; consulter une section ou fermer la fenêtre ne les modifie pas. Sans JavaScript, un formulaire autonome reste disponible. Les réponses contenant les préférences sont privées et non mises en cache.

## Édition par le super admin

- « Modifier cette page » ouvre la page « Confiance et informations légales » du Studio. Le modèle « Centre de confiance et documents légaux » permet de modifier le titre, l’introduction, les libellés du menu, les sur-titres, la présentation de la sécurité et les textes du formulaire des cookies. Les couleurs générales et les styles de section utilisent les réglages du Studio.
- « Modifier ce document », dans une section juridique, crée une nouvelle version préremplie du document dans la gestion des contenus. Les titres, résumés et corps sont modifiables. Une version ne remplace la version publique qu’après publication par le super admin. Les brouillons ne sont pas exposés dans les sections.
- Le texte accepte les titres `##`, listes `-`, gras `**...**`, tableaux simples à colonnes `|`, et met en évidence les mentions entre crochets. Le HTML fourni reste échappé.

Les règles fonctionnelles des consentements et le calcul de confiance restent indépendants des textes de présentation. Les documents existants ont été conservés.


Les liens « Sécurité », « Règles et CGU » et « Centre légal » visent respectivement `#legal-securite`, `#legal-cgu` et `#legal-introduction`. Le footer utilise une navigation native afin de conserver la destination lors des changements de page.

Les exemples complets sont transcrits depuis `config/studio/rendered-maquette.html` dans `config/studio/legal_examples.json` : listes, deux tableaux RGPD et champs à compléter. Ils servent de contenu initial en l’absence de document publié et préremplissent la rédaction super admin. Une publication existante reste prioritaire. La section Sécurité reprend les textes de la maquette dans ses champs Studio.

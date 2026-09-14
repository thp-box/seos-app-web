# Création d’annonce en quatre étapes

Le formulaire de création et de modification utilise une carte centrée sans sidebar, un indicateur d’étapes et des icônes SVG. Il reprend la maquette avec une grille équilibrée de trois choix à l’étape 2.

1. **Intention** : proposer son aide ou rechercher de l’aide.
2. **Échange** : don, échange de services ou Points Services. Le champ d’estimation apparaît pour ce dernier choix et devient obligatoire.
3. **Détails** : titre, catégorie, lieu de réalisation, description, commune, adresse privée, priorité, disponibilités et photos.
4. **Aperçu** : contenu enregistré, mode d’échange, localisation publique, disponibilités et photos ; confirmation de confidentialité puis publication.

Les exemples de titre et description sont proposés uniquement si ces deux champs sont encore vides, et varient avec l’intention. Ils ne sont enregistrés qu’après soumission. Le membre doit les adapter. La commune et l’adresse privée sont initialisées depuis son propre profil ; aucune adresse fictive n’est injectée.

Chaque bouton Continuer enregistre le brouillon. Le retour Précédent affiche les données déjà enregistrées ; les modifications non soumises ne sont pas sauvegardées automatiquement. Les règles de publication existantes restent appliquées au serveur, notamment le profil public, les catégories disponibles, les permissions d’organisation, la revue des catégories sensibles et la confirmation de confidentialité. L’adresse exacte n’est jamais rendue dans l’aperçu public. Les services à distance restent sans marqueur ni distance.

Les champs acceptés par le contrôleur suivent les nouvelles étapes. L’étape 2 exige une estimation pour les points ; l’étape 3 exige titre, description, catégorie et commune pour un service sur place. Les preuves photographiques restent limitées à quatre fichiers JPEG, PNG ou WebP de 5 Mo, avec réencodage et suppression des métadonnées. L’interface ne propose pas de vidéo, car ce format n’est pas pris en charge pour les annonces.

## Vérification

25 exemples ciblés sans échec (seed 49153), dont création jusqu’à publication avec photo et points, exemples, confidentialité de l’adresse, validation serveur, conflits d’édition, permissions, navigation et affichage responsive. Accessibilité contrôlée aux quatre étapes sur 375 et 1440 px. Captures : `tmp/screenshots/listing-wizard-{1,2,3,4}-{375,1440}.png`.

Aucune migration. Reconstruire les assets avec `yarn build` lors de la livraison.

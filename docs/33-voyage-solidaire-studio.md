# Voyage solidaire dans le Studio

Dans **Personnalisation → Pages → Voyage solidaire**, le super-admin peut modifier le titre, l’introduction, les textes du filtre et le message sans résultat. Les sections de présentation et de missions peuvent être déplacées, masquées, dupliquées ou retirées ; tous les modèles du Studio, dont les sections vides, peuvent être ajoutés.

Le bouton **Modifier cette page** est également disponible sur la page publique pour le super-admin. Les changements suivent le circuit habituel : enregistrement du brouillon, aperçu privé, publication. La page publique `/voyage-solidaire` lit la dernière composition publiée ou utilise la présentation initiale.

Le bloc **Voyage solidaire : missions et filtre** affiche automatiquement les missions publiées, non terminées et publiquement visibles des associations vérifiées. Le filtre par pays reste fonctionnel. Les missions et candidatures continuent d’être gérées dans leurs outils métier. Le drapeau d’activation du voyage reste respecté.

Modèles déclaratifs : `config/studio/travel.json`. Les valeurs éditées sont échappées comme celles des autres sections. Aucun HTML libre n’est accepté.

Vérifications : permissions, isolation du brouillon, publication, aperçu Studio, parcours de missions existant, filtre public, mobile/ordinateur et axe WCAG A/AA.

## Supprimer une page

Toutes les pages du Studio peuvent être supprimées, sauf l’accueil et les annonces. Dans l’éditeur visuel : **Créer ou retirer une page → Retirer cette page**. Dans l’éditeur guidé : **Supprimer cette page**. Enregistrer puis publier pour rendre la suppression effective.

La suppression est conservée dans la version du site : elle empêche le retour automatique au contenu initial, retire les liens correspondants de la navigation et du pied de page et rend l’URL publique indisponible (404). Les missions, candidatures et autres données métier restent conservées. Une ancienne sauvegarde peut être reprise et publiée pour restaurer la page. Les liens saisis dans le contenu d’autres sections restent à adapter par l’administrateur.

## Présentation maquette et Points Services

Le bandeau utilise la photo des mains réunies, le titre en deux parties et la vague de la maquette. Les missions apparaissent en cartes illustrées sur trois colonnes (une sur téléphone), avec contribution en PS par jour, hébergement et repas. Les textes, la photo du bandeau et les sections restent éditables dans le Studio.

`daily_contribution_points` est un entier distinct des anciens montants monétaires. Le champ est éditable dans les formulaires de mission ; aucune conversion euros/points n’est appliquée aux données historiques. Les anciens champs monétaires ne sont plus acceptés dans les formulaires métier. La candidature ne déclenche pas de transfert de points.

`db/travel_seeds.rb`, chargé par `db/seeds.rb` uniquement en développement, crée trois missions publiées de l’association fictive « Entraide solidaire — Démo » : éco-lieu (10 PS/jour), projet éducatif (0), refuge (15). Les photos sont locales. Les slugs stables évitent les doublons ; relancer les seeds ne remplace pas les missions existantes modifiées manuellement. Ces missions sont explicitement des données de démonstration, jamais créées en production.

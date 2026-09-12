# Voyage solidaire dans le Studio

Dans **Personnalisation → Pages → Voyage solidaire**, le super-admin peut modifier le titre, l’introduction, les textes du filtre et le message sans résultat. Les sections de présentation et de missions peuvent être déplacées, masquées, dupliquées ou retirées ; tous les modèles du Studio, dont les sections vides, peuvent être ajoutés.

Le bouton **Modifier cette page** est également disponible sur la page publique pour le super-admin. Les changements suivent le circuit habituel : enregistrement du brouillon, aperçu privé, publication. La page publique `/voyage-solidaire` lit la dernière composition publiée ou utilise la présentation initiale.

Le bloc **Voyage solidaire : missions et filtre** affiche automatiquement les missions publiées, non terminées et publiquement visibles des associations vérifiées. Le filtre par pays reste fonctionnel. Les missions et candidatures continuent d’être gérées dans leurs outils métier. Le drapeau d’activation du voyage reste respecté.

Modèles déclaratifs : `config/studio/travel.json`. Les valeurs éditées sont échappées comme celles des autres sections. Aucun HTML libre n’est accepté.

Vérifications : permissions, isolation du brouillon, publication, aperçu Studio, parcours de missions existant, filtre public, mobile/ordinateur et axe WCAG A/AA.

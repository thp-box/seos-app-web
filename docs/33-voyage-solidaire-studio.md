# Voyage solidaire dans le Studio

Dans **Personnalisation → Pages → Voyage solidaire**, le super-admin peut modifier le titre, l’introduction, les textes du filtre et le message sans résultat. Les sections de présentation et de missions peuvent être déplacées, masquées, dupliquées ou retirées ; tous les modèles du Studio, dont les sections vides, peuvent être ajoutés.

Le bouton **Modifier cette page** est également disponible sur la page publique pour le super-admin. Les changements suivent le circuit habituel : enregistrement du brouillon, aperçu privé, publication. La page publique `/voyage-solidaire` lit la dernière composition publiée ou utilise la présentation initiale.

Le bloc **Voyage solidaire : missions et filtre** affiche automatiquement les missions publiées, non terminées et publiquement visibles des associations vérifiées. Le filtre par pays reste fonctionnel. Les missions et candidatures continuent d’être gérées dans leurs outils métier. Le drapeau d’activation du voyage reste respecté.

Modèles déclaratifs : `config/studio/travel.json`. Les valeurs éditées sont échappées comme celles des autres sections. Aucun HTML libre n’est accepté.

Vérifications : permissions, isolation du brouillon, publication, aperçu Studio, parcours de missions existant, filtre public, mobile/ordinateur et axe WCAG A/AA.

## Supprimer une page

Toutes les pages du Studio peuvent être supprimées, sauf l’accueil et les annonces. Dans l’éditeur visuel : **Créer ou retirer une page → Retirer cette page**. Dans l’éditeur guidé : **Supprimer cette page**. Enregistrer puis publier pour rendre la suppression effective.

La suppression est conservée dans la version du site : elle empêche le retour automatique au contenu initial, retire les liens correspondants de la navigation et du pied de page et rend l’URL publique indisponible (404). Les missions, candidatures et autres données métier restent conservées. Une ancienne sauvegarde peut être reprise et publiée pour restaurer la page. Les liens saisis dans le contenu d’autres sections restent à adapter par l’administrateur.

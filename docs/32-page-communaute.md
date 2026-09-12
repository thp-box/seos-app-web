# La communauté

La navigation standard mène désormais à `/communaute`. La page présente l’application (don, échange, Points Services), les associations et les façons de participer. L’annuaire reste accessible à `/associations`.

Dans **Studio → Personnalisation → Pages → La communauté**, le super-admin peut modifier les textes, la photo, les destinations, l’ordre des sections et leur apparence, ajouter ou supprimer des sections. Les changements suivent le circuit existant : brouillon, aperçu et publication. Le menu reste modifiable dans le haut du site.

Le contenu initial est fourni par `SiteDesign.community_page` et les modèles déclaratifs de `config/studio/community.json`. Une page publiée dans le Studio prend le dessus sur ces valeurs. Aucune version publiée n’est modifiée en base. Seul le lien historique exact « L’association » → `/associations` est adapté à la lecture ; les menus personnalisés sont conservés.

Les boutons Inviter, Les quêtes et Témoigner ouvrent les fonctionnalités du compte. Proposer mon association ouvre la gestion des organisations, où se trouve le formulaire. Soutenir SEOS mène au contact pour proposer un soutien matériel, même lorsque les paiements sont désactivés ; cette destination est modifiable dans le Studio.

Vérifications : publication et isolation du brouillon, aperçu Studio, compatibilité du menu, affichage à 375 et 1440 pixels, absence de débordement et contrôle axe WCAG A/AA.

# Interface d’administration SEOS

La navigation, les titres, les cartes, les tableaux et les formulaires partagent une présentation bleu pétrole, ivoire et dorée. Les règles de cette interface sont isolées dans `components/admin_workspace.css` ; les pages publiques ne sont pas concernées. Les menus restent adaptés aux permissions de chaque compte.

## Gestion des organisations

L’entrée Organisations et voyage ouvre une liste de dossiers. Les rubriques séparent les demandes de structures, les propositions de partenariat, les missions autorisées et les paramètres des parcours publics réservés au super admin.

Les listes affichent 20 dossiers par page, avec priorité aux demandes en attente puis aux dernières modifications. La recherche porte sur le nom ou le numéro ; les filtres portent sur le statut et, pour les structures, le projet demandé. Les compteurs présentent les statuts du type de projet sélectionné, avant recherche textuelle.

Chaque dossier possède une fiche d’examen. Sa présentation publique précède la décision motivée. Les outils de création, de modification et les actions exceptionnelles sont repliés. Les permissions de consultation légale, de publication des missions et de récupération des propriétaires restent celles des workflows existants. Le retour de sauvegarde ouvre le dossier concerné.

## Tableau de bord et autres outils

La vue d’ensemble rassemble les indicateurs, les courbes d’activité, la répartition des annonces et les accès aux outils. Les pages Membres, Annonces, Confiance, Points Services, Engagement, Confidentialité et Audit utilisent les mêmes composants visuels. La supervision du super admin conserve ses rubriques et ses contrôles sensibles.

Sur petit écran, la navigation devient repliable, les dossiers et formulaires s’empilent et les tableaux conservent leur zone de défilement. Les transitions respectent la préférence de réduction des mouvements.

## Vérification

Les tests couvrent la pagination, la priorité des dossiers, la recherche combinée aux filtres, les limites de permissions et le parcours navigateur liste → fiche → décision, ainsi que le rendu à 375 et 1440 pixels.

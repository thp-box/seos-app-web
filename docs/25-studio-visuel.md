# Studio admin — Éditeur visuel

## Ouvrir l’éditeur

Dans **Studio admin → Personnalisation → Pages et sections** ou **Kit UI/UX**, cliquer sur **Ouvrir l’éditeur visuel**. Cet écran est réservé au super admin. Le même bouton reste disponible dans l’éditeur guidé.

- À gauche : choisir ou créer une page, ajouter des sections, retrouver les sections masquées et régler l’apparence du site.
- Au centre : le rendu réel de la page, avec ses textes, photos, haut et bas du site. Les emplacements en pointillés servent uniquement à l’édition.
- À droite : les réglages de la section ou de l’élément sélectionné.

## Composer une page

Glisser une section depuis la bibliothèque sur un emplacement en pointillés. Pour déplacer une section existante, la glisser vers un autre emplacement. Les boutons **Ajouter**, **Monter** et **Descendre** permettent les mêmes opérations au clavier ou sur mobile.

Cliquer sur un texte ou une photo dans l’aperçu pour ouvrir ses réglages. Le sélecteur **Élément à modifier** offre également cette sélection sans souris. Les rubriques du formulaire gardent les libellés explicatifs de l’éditeur guidé. Un bloc texte peut rester sans bouton.

**Dupliquer**, **Masquer la section** et **Retirer la section** agissent sur la copie en cours. Une section masquée se retrouve dans **Sections de cette page** et peut être affichée à nouveau. **Annuler** et **Rétablir** parcourent les 40 derniers changements de la session d’édition.

Dans **Créer ou retirer une page**, saisir un nom, puis écrire son contenu. L’adresse est générée automatiquement. Les pages principales ne peuvent pas être retirées par ce bouton. Une nouvelle page vide doit être complétée avant publication. Pour rendre une page accessible depuis le menu, ajouter son adresse `/pages/son-adresse` dans les liens du haut ou du bas du site.

L’accueil historique, s’il n’a pas encore été composé par sections, s’affiche tel quel dans l’aperçu. Une confirmation explique que le premier ajout prépare une nouvelle composition. L’accueil publié reste visible jusqu’à la publication ; les anciennes sauvegardes sont conservées.

## Tailles, vagues et effets organiques

- **Taille et animation de cet élément** : agrandir/réduire un mot ou une photo ; apparition douce, flottement ou respiration. Les photos peuvent recevoir une forme arrondie ou organique.
- **Taille, espacement et effets de la section** : taille des titres, espace autour du contenu, formes des images et animation de la section.
- **Séparation décorative** : vague simple ou double, courbe douce, forme organique, petites ondulations, diagonale ou dégradé ; avant ou après la section.
- **Apparence et effets du site → Vagues et mouvements** : hauteur, forme, amplitude et durée des vagues, plus un bouton **Ambiance organique douce** qui applique des réglages coordonnés.

L’apparition se joue au chargement ; le flottement et la respiration se répètent. L’arrêt global des animations et la préférence système de réduction des mouvements restent prioritaires.

## Voir les modifications

Les couleurs réagissent immédiatement dans l’aperçu. Les autres changements actualisent le rendu après une courte pause de saisie, sans créer de sauvegarde. Les aperçus Téléphone, Tablette et Ordinateur changent la largeur réelle de la page affichée ; l’aperçu est réduit pour tenir dans l’espace disponible. **Agrandir / réduire** masque ou réaffiche les panneaux latéraux.

Le haut et le bas du site se sélectionnent dans l’aperçu ou avec les boutons de la rubrique correspondante. Leurs textes, logos et liens se modifient sur la même page.

## Enregistrer et publier

**Enregistrer** crée une nouvelle copie privée. **Vérifier et mettre en ligne** enregistre puis ouvre la vérification existante : relire les changements, puis confirmer avec **Mettre en ligne**. L’aperçu ne publie rien. Les versions publiées restent immuables ; le contraste et l’état de la publication sont vérifiés par le serveur.

Les changements non enregistrés vivent dans l’écran ouvert. Un avertissement accompagne une tentative de départ. Si l’enregistrement échoue, le contenu reste dans l’éditeur pour permettre de réessayer. Des changements effectués pendant un enregistrement restent signalés comme non enregistrés.

## Périmètre et protections

L’éditeur compose des sections et règle les éléments prévus par chaque modèle. Les tailles, formes et animations sont des choix contrôlés, sans HTML/CSS/JavaScript libre. Les parcours métier, comptes, annonces, échanges et paiements conservent leur fonctionnement et leurs autorisations. Les nouvelles images s’importent dans la bibliothèque existante, puis se choisissent dans l’éditeur visuel.

Les aperçus sont rendus côté serveur à partir d’une proposition validée en mémoire, sans écrire de version ni d’audit. Ils restent privés, non mis en cache et intégrables uniquement sur la même origine. La sauvegarde exige les droits super admin et l’intégrité de la version source. Le serveur conserve les réglages historiques hors du périmètre visuel.


## Recette du 7 septembre 2026

Suite complète : **317 exemples RSpec, 0 échec** (seed 54561), couverture **98,88 % des lignes / 91,10 % des branches**. Après les derniers ajustements des retours vers l’édition et de la taille des titres : **26 exemples ciblés, 0 échec** (seed 43523).

Les scénarios Chrome suivent le glisser-déposer natif entre la bibliothèque et la page, les déplacements, Annuler/Rétablir, la sélection d’un élément dans l’aperçu, l’agrandissement effectif d’un titre, la mise à jour d’une couleur, les vagues et animations, la réduction des mouvements, la création de page, le footer, le rechargement d’une copie et la publication. L’accessibilité de l’espace visuel et son absence de débordement horizontal sont contrôlées. Captures : `tmp/screenshots/visual-studio-{375,1440}.png`.

Les tests serveur couvrent les permissions, les aperçus sans écriture, les pages de départ, la validation des effets et des références, le rejet des documents invalides ou trop volumineux et l’intégrité de la source. RuboCop : 327 fichiers sans infraction lors de la recette générale. Brakeman : 0 avertissement / 0 erreur. Build et contrôle de fraîcheur des assets réussis.


## Session de travail sans confirmation périodique

Le Studio et l’administration ne demandent plus de confirmation du mot de passe toutes les 15 minutes. La navigation, les aperçus, l’enregistrement et la publication restent disponibles avec une session active et les permissions requises. Le mot de passe lui-même n’expire pas.

Une confirmation récente reste requise pour demander ou télécharger des données personnelles et pour associer un compte Google. La consultation de la page de confidentialité reste libre pour le membre connecté. Après confirmation, un membre revient à son compte et un administrateur au Studio.

Depuis le 10 septembre 2026, aucune déconnexion pour inactivité n’est appliquée, pour les membres comme pour les administrateurs. La durée maximale de session reste de 12 heures après connexion, indépendamment de l’activité. La confirmation des opérations sensibles est distincte de cette durée.

Les clics et formulaires de l’aperçu sont interceptés avant les gestionnaires de navigation de Turbo ; sélectionner une catégorie ne doit pas naviguer vers les annonces dans le cadre. Les pages normales de confirmation conservent leur interdiction d’intégration dans une iframe.

Les tests vérifient une confirmation datant de deux heures : accès à l’administration, modification des formes dans Chrome, aperçu, enregistrement et publication. Les opérations sensibles sur les données personnelles conservent leur contrôle.

Recette du 8 septembre 2026 après suppression de la confirmation périodique : **50 exemples ciblés, 0 échec** (28 Studio/administration/confidentialité, seed 4201 ; 22 authentification et accès, seed 42627). Build et fraîcheur des assets validés ; RuboCop sans infraction sur les huit fichiers Ruby concernés ; Brakeman : 0 avertissement et 0 erreur.

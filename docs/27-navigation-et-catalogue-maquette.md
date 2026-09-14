# Navigation et catalogue — alignement sur la maquette

La référence est `docs/maquette.html`, notamment la navigation avec avatar, l’en-tête bleu et sa découpe en vague, et le catalogue avec filtres latéraux et cartes horizontales.

## Présentation

- Navigation centrée, page active soulignée, bouton de publication et avatar du membre. Le compteur provient des notifications réellement non lues ; aucune valeur de démonstration n’est affichée.
- Menu du compte : compte, notifications, annonces, favoris, sessions, Studio selon permission et déconnexion. Utilisable au clavier et refermable avec Échap.
- Liens par défaut : Découvrir, Annonces, L’association, Voyage solidaire. Ce dernier n’apparaît que si la fonctionnalité est ouverte. Les liens explicitement configurés dans le Studio sont conservés.
- En-tête commun bleu, motif organique et vague bicolore pour le catalogue, les associations, le voyage solidaire et le journal.
- Recherche en haut du catalogue, raccourcis, filtres latéraux, catégories repliables, tri et bascule liste/carte lorsque la carte est activée.
- Cartes avec photo à gauche, catégorie, auteur, localisation publique, mode d’échange et favori. Un visuel neutre remplace les photos absentes. Aucune note ou distance fictive.

## Comportement

La sélection d’une catégorie inclut ses descendants disponibles. Les catégories et les modes d’échange acceptent plusieurs choix. Aucune catégorie cochée signifie toutes les catégories ; aucun mode coché donne une liste vide. Les anciens paramètres singuliers restent acceptés. Les raccourcis conservent les autres paramètres et réinitialisent la pagination. Les champs répartis entre recherche, sidebar et tri soumettent un même formulaire GET, sans dépendance JavaScript.

Les favoris s’ajoutent et se retirent depuis les résultats en conservant les filtres. Les autres points d’entrée conservent leur redirection habituelle. Le retour au catalogue accepte uniquement les paramètres de recherche autorisés et ne permet pas de redirection externe.

Les annonces à distance restent dans les résultats, sans marqueur ni distance. Quand la carte est désactivée, aucun chargement cartographique n’est introduit. Les tris disponibles restent ceux du moteur actuel ; les notes, classements et filtres fictifs de la maquette ne sont pas présentés comme opérationnels.

## Validation

Les scénarios couvrent les largeurs mobiles et ordinateur, le zoom à 200 %, l’accessibilité automatique, le menu avatar, les sous-catégories et les favoris avec conservation des filtres. Les parcours existants de publication, conversation, carte, réseau et personnalisation du Studio sont inclus dans la recette ciblée. Les captures sont dans `tmp/screenshots/catalogue-{maquette,results}-{375,768,1440}.png`.

Reconstruction des assets requise avec `yarn build` lors de la livraison. Aucune migration de base de données.

Recette : **41 exemples ciblés, 0 échec** (seed 36098). RuboCop sans infraction ; Brakeman : 0 avertissement et 0 erreur ; build et fraîcheur des assets validés.

## Ajustement après comparaison visuelle

La recherche utilise des icônes SVG et des libellés accessibles masqués, le tri est appliqué au changement (bouton de secours sans JavaScript), les favoris sont en haut des photos et les titres ont une hauteur maîtrisée. Les filtres deviennent des catégories repliables, des cases à cocher et des curseurs.

Le rayon va de « Commune uniquement » à 100 km. Le curseur de points filtre les annonces en Points Services entre 0 et 195 PS, sans exclure les dons ou échanges ; son extrémité droite signifie explicitement « Sans plafond ». La localité latérale est synchronisée avec la recherche ; sans JavaScript, le champ principal reste utilisable.

Le fichier `db/discovery_demo_photos.rb` complète uniquement les trois annonces de démonstration connues en développement avec des photos locales, sans remplacer d’image existante. Il est aussi chargé par les seeds. Les autres annonces sans photo conservent leur illustration neutre.

Recette de cet ajustement : **25 exemples, 0 échec** (seed 13564), dont les sélections multiples, les seuils de points, les curseurs au clavier, la synchronisation des communes et les favoris. RuboCop et fraîcheur du build validés.

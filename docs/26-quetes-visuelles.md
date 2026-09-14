# Quêtes visuelles — 11 septembre 2026

L’espace **Mon compte → Entraide et points → Mes quêtes et témoignages** présente les objectifs sous forme de cartes : icône, fréquence, état, barre de progression native et raccourci vers l’action concernée. Le bandeau affiche le nombre d’objectifs atteints, le niveau actuel et le plafond mensuel du barème publié. Les nombres proviennent du moteur existant ; ils ne constituent pas une promesse de nouveau versement. Pour les séries, le compteur existant reste cumulatif.

Les preuves personnalisées s’ouvrent à la demande. Une preuve déjà envoyée pour la période affiche son état au lieu d’un deuxième formulaire ; les décisions et les points accordés restent consultables dans le suivi. Les témoignages et demandes de mise en avant conservent leur parcours.

Dans **Studio admin → Communauté → Engagement et chaînes**, les personnes ayant `community.manage` disposent d’un catalogue compact. Chaque quête se déplie pour modifier son nom, sa description, son ordre, sa visibilité, son icône, sa couleur et son animation. L’aperçu se met à jour immédiatement, mais seule la soumission enregistre. « Selon l’objectif » choisit une icône adaptée aux quêtes automatiques. Les autres choix imposent l’icône sélectionnée.

La création d’une quête avec preuve ne demande plus d’identifiant technique : il est généré au serveur. Le type de récompense et la fréquence sont définis à la création ; les règles des quêtes existantes restent figées. Les changements sont autorisés et audités comme auparavant. Les montants restent gérés dans les barèmes publiés.

Les apparences sont limitées à une liste d’icônes SVG internes et quatre couleurs. Aucun SVG ou CSS fourni par le navigateur n’est exécuté. Les animations d’entrée, de progression et de survol sont désactivables par quête et respectent `prefers-reduced-motion`.

## Installation et validation

Exécuter `bin/rails db:migrate` puis `yarn build` lors de la livraison. La migration ajoute `icon`, `accent` et `animated` aux quêtes existantes avec des valeurs par défaut ; elle ne modifie pas les récompenses ni les preuves.

Les scénarios navigateur couvrent le mobile et l’ordinateur, l’accessibilité, l’aperçu et sa sauvegarde, l’envoi d’une preuve puis son passage à l’état atteint, et la réduction des mouvements. Les tests serveur contrôlent les permissions, les apparences invalides et la conservation des règles d’attribution.

Recette : **16 exemples ciblés, 0 échec** (seed 53184). Build et fraîcheur des assets validés ; RuboCop corrigé et validé ; Brakeman : 0 avertissement et 0 erreur.

# Menu profil et notifications par rubrique

Le menu de l’avatar reprend la maquette : photo ou initiale, pseudonyme, solde réel, icônes, sélection dorée de la page active et déconnexion. Il comporte les accès tableau de bord, messagerie, quêtes, portefeuille, favoris et profil/paramètres. « Toutes mes notifications » donne accès aux événements des autres rubriques. L’accès au Studio reste réservé aux membres autorisés.

## Compteurs

- Le badge de l’avatar compte les notifications non lues, pas les quêtes disponibles ni les simples visites.
- Les badges du menu, des liens de la sidebar et des catégories repliées utilisent les mêmes données. Profil et paramètres regroupe profil, sécurité et confidentialité. La catégorie contenant le centre de notifications affiche son total global.
- Un compteur nul reste masqué. Les grandes valeurs s’affichent « 99+ ».
- Les compteurs et le solde sont actualisés toutes les 30 secondes lorsque la page est visible, ainsi qu’à l’ouverture du menu et au retour sur la fenêtre. L’endpoint JSON est authentifié, limité au compte courant et non mis en cache. Aucun contenu de message n’est renvoyé par cet endpoint.

## Lecture

Le centre est filtrable par rubrique et paginé. « Ouvrir » marque une notification comme lue et conduit à une destination interne autorisée. Pour un échange, la destination précise reste protégée par son contrôle de participation. « Marquer comme lue » et la lecture groupée restent disponibles.

La lecture groupée est limitée au membre, au filtre choisi et aux notifications présentes avant le clic : une notification arrivée entre-temps n’est pas effacée. Ouvrir le menu ne marque rien comme lu. Lire une conversation marque les notifications des messages et événements effectivement chargés de cet échange ; les autres conversations restent non lues. Les autres rubriques proposent un lien vers leurs notifications non lues et une lecture explicite.

## Événements

Les notifications métier existantes sont classées : messages/échanges, avis, quêtes/mises en avant, points/preuves du portefeuille, témoignages, chaînes, parrainage/confiance, candidatures et restrictions d’annonces. La migration classe également leur historique.

Cette évolution ajoute les notifications de décision administrative sur une annonce ou un profil, de statut d’organisation, de traitement des demandes de données personnelles, de résultat du soutien financier et de changement de mot de passe. Les changements de disponibilité des annonces favorites déclenchent un traitement en arrière-plan pour prévenir leurs favoris, sans divulguer les coordonnées ni le contenu des conversations.

Les événements utilisent une clé de déduplication par membre. La préférence e-mail existante est conservée et indépendante du compteur dans l’application. Les événements sans rubrique particulière restent dans « Autres notifications ».

## Vérifications et exploitation

Migration `20260912190000_categorize_notifications`, index par membre/lecture/catégorie, nouveaux assets à compiler. `NotificationEmailJob` reste responsable des e-mails ; `ListingFavoritesNotificationJob` nécessite les workers pour prévenir les membres ayant enregistré une annonce.

Tests dédiés : `notification_categories_spec.rb` et `profile_menu_spec.rb` (protection entre membres, classement, déduplication, lecture par rubrique, concurrence avec de nouvelles notifications, compteurs réels, actualisation sans rechargement, clavier, mobile et accessibilité). Les tests des parcours métier existants restent applicables.

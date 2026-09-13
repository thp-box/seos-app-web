# Présentation de l’accueil et animations

Dans le Studio visuel, sélectionner « Grande présentation avec photo », puis ouvrir « Diaporama et vidéo ». Chaque diapositive possède une phrase, une image de la bibliothèque et une description accessible. Les boutons permettent d’ajouter ou de supprimer une diapositive (1 à 20). L’enregistrement crée un brouillon ; la publication suit la validation habituelle. Les anciennes photos personnalisées sont reprises lors de la première modification du diaporama.

La phrase et la photo changent ensemble toutes les six secondes. Le visiteur peut mettre le diaporama en pause. Le défilement s’arrête lorsque la page est masquée, pendant l’interaction au clavier dans le header et lorsque la réduction des animations est demandée.

« Comprendre en 2 minutes » ouvre `/#presentation`. Les anciennes adresses `/decouvrir/fonctionnement` et `/pages/fonctionnement` redirigent vers cette ancre. La section « Présentation de SEOS » possède une affiche modifiable et un champ d’adresse directe de vidéo MP4 ou WebM (HTTPS ou fichier local). Sans fichier renseigné, le lecteur montre son affiche. Aucune vidéo finale n’est fournie par cette mise à jour ; aucune légende n’est superposée au lecteur.

Les pages don, échange et Points Services utilisent par défaut leurs deux sections de maquette, disponibles dans le Studio. Les compositions déjà publiées restent prioritaires.

Les vagues de certaines sections initiales (catégories, chaîne, communauté et soutien) ondulent. Leur mouvement reste désactivable par les réglages de section ou les réglages globaux. La chaîne illustre une transmission par une pulsation décalée entre les cartes. Elle ne représente pas des transactions réelles. La bulle de confiance et les portraits flottent doucement ; les orbites restent dans leur cadre. Toutes ces animations respectent la préférence système de réduction des mouvements.

Les badges des pays utilisent des codes textuels stables, sans dépendre des polices d’émojis. Le drapeau luxembourgeois est un SVG local remplaçable dans la bibliothèque du Studio.

## Navigation et styles du Studio

La balise `csp-nonce` du layout public est suivie avec `data-turbo-track="reload"`. Le nonce étant renouvelé à chaque réponse, Turbo recharge le document lors d’un changement de page : sa politique CSP autorise alors les styles de cette nouvelle réponse. Sans ce rechargement, les styles de section injectés dans le corps étaient bloqués après une navigation, produisant des fonds transparents et des SVG noirs. La politique CSP reste stricte, sans réutiliser un nonce de session ni autoriser les styles arbitraires. Le test `footer_design_navigation_spec` couvre Voyage → Concept → Chaîne → Voyage → retour navigateur sur ordinateur et téléphone.

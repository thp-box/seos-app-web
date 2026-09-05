# Références initiales du socle

Captures du 5 septembre 2026 : accueil F-001 et connexion Devise, thème de base SEOS, viewport de 1000 px de haut et capture de la page entière. Linux, Chrome for Testing/ChromeDriver 151.0.7922.77, DPR 1, polices WOFF2 du lockfile Yarn. Les fichiers nommés 320/375/414/768/1024/1280/1440 ont la largeur indiquée.

Ces références portent sur le premier socle implémenté. Elles ne remplacent pas les futures références exhaustives de `docs/maquette.html` : l’accueil complet, les annonces et les composants métier ne sont pas encore intégrés. Elles restent à examiner dans la revue de cette première livraison.

Les tests lisent ces PNG et produisent les images obtenues/diffs dans `tmp/screenshots`. Ils échouent si une référence manque ou si l’écart dépasse 0,5 %. Le mode explicite `CAPTURE_VISUAL_CANDIDATES=1` écrit seulement des candidats dans `tmp/`, jamais ici, et est interdit en CI. Toute modification d’une référence existante doit documenter la décision produit et la revue avant/après.

Les références ont fait l’objet d’une [revue explicite le 5 septembre](../../../../docs/16-revue-visuelle-decouverte.md) pour les liens de navigation et du footer. Deux références du catalogue ont été ajoutées aux largeurs 375 et 1440. Les tests n’écrivent jamais ces fichiers.

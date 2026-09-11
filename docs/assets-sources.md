# Sources des assets du socle

- `app/assets/images/seos-logo.png` : logo PNG extrait à l’identique du bloc CSS base64 de `docs/maquette.html`.
- `app/assets/images/auth-community.jpg` : photo déjà utilisée dans l’écran d’authentification de la maquette, copiée localement depuis [l’image Unsplash](https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1300&q=88). L’attribution définitive et les droits de publication font partie de la revue des médias avant lancement ; cette copie sert à l’intégration de la maquette.
- DM Sans et Playfair Display : paquets `@fontsource-variable` verrouillés dans `yarn.lock`, WOFF2 latin/normal et italique Playfair. Les licences OFL accompagnent les paquets dans `node_modules/@fontsource-variable/*/LICENSE` ; aucun appel Google Fonts côté navigateur.
- `public/errors.css` : page d’erreur autonome à polices système, disponible même si le build applicatif ou la base ne répond pas.

- `app/assets/images/maquette/` : 45 références de photos du prototype, copiées localement ; correspondance URL/fichier dans `config/studio/maquette.json`. Même revue des droits et attributions avant lancement que les médias existants. Extraction reproductible : `scripts/extract-maquette.rb`.

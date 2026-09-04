# Plan de génération Rails 8 et scaffolds

## But du plan

Ce document donne un ordre de construction et des commandes indicatives. Elles ne doivent être exécutées qu'après validation du modèle de données. Un scaffold accélère les formulaires, vues et tests de base ; il ne remplace ni les autorisations, ni les services métier, ni les contraintes de base.

Toutes les commandes sont donc une **checklist documentaire**, pas un script à lancer en bloc. Le panneau complet, ses permissions et ses exceptions CRUD sont spécifiés dans [`07-panel-administration.md`](./07-panel-administration.md).

## État réel du projet

- Rails `8.1.3.1`, Ruby `3.4.7`.
- SQLite pour les bases primary, cache, queue et cable.
- Propshaft pour les assets.
- Hotwire : Turbo et Stimulus.
- esbuild `0.28.2` via `jsbundling-rails`.
- `yarn build` compile aujourd'hui `app/javascript/*.*` vers `app/assets/builds`.
- `bin/dev` lance Rails et `yarn build --watch` via Foreman.
- Le CSS actuel est un fichier natif sous `app/assets/stylesheets` et n'est pas compilé par Yarn.
- RSpec n'est pas installé ; le dossier Minitest ne contient encore aucun test métier.
- Devise, Geocoder, les clients Gmail/OmniAuth et Stripe ne sont pas encore installés.

## Décision assets recommandée

La maquette utilise du CSS natif et n'exige ni Tailwind ni Sass. Pour conserver la direction artistique exacte avec le moins de dépendances possible :

1. placer la source CSS hors du chemin d'assets compilés, par exemple dans `app/javascript/stylesheets` ;
2. importer le point d'entrée CSS depuis `app/javascript/application.js` ;
3. laisser esbuild produire `application.js` **et** `application.css` dans `app/assets/builds` ;
4. garder Propshaft comme serveur et outil de digest ;
5. ne pas conserver en parallèle un autre `application.css` avec le même chemin logique dans `app/assets/stylesheets` ;
6. conserver `yarn build` comme commande unique et `yarn build --watch` dans `Procfile.dev`.

Cette convention répond à l'objectif d'un seul build JS/CSS. Dans l'état actuel du dépôt, il faut toutefois retenir que `yarn build` ne construit que le JavaScript : le déplacement/import CSS fait donc partie de F-001 et doit être vérifié avant toute intégration d'écran.

L'alternative consistant à laisser le CSS applicatif hors du build Yarn est **écartée pour SEOS**. Elle contredirait le contrat demandé : une seule commande `yarn build` doit reconstruire les deux sorties nécessaires à l'interface.

## Commandes de vie du projet

À documenter dans le README applicatif une fois la stratégie choisie :

```bash
bin/setup --skip-server
yarn build
bin/rails db:prepare
bin/dev
```

- `bin/setup` installe les gems et dépendances Yarn puis prépare la base.
- `yarn build` doit réussir avant les tests qui chargent le JavaScript.
- `bin/dev` est la commande quotidienne ; il garde esbuild en watch.
- En production, la tâche `javascript:build` de `jsbundling-rails` est rattachée à `assets:precompile`. Si le CSS est importé par le point d'entrée esbuild, il est produit pendant le même build.

## Générateurs de socle

### RSpec avant tout scaffold

RSpec doit être installé avant les générateurs métier. La cible est `rspec-rails` 8.x compatible avec Rails 8.1, Capybara et Selenium déjà présents. Les versions exactes sont verrouillées dans `Gemfile.lock` au début de F-001.

```bash
bundle install
bundle exec rails generate rspec:install
bundle binstubs rspec-core
```

Configurer les générateurs Rails avec `test_framework: :rspec`. À partir de ce point, chaque modèle/scaffold doit produire ses specs dans `spec/`; ne pas maintenir une seconde suite Minitest vide. La stratégie complète figure dans [`11-strategie-tests-rspec-et-regression.md`](./11-strategie-tests-rspec-et-regression.md).

Ordre recommandé :

```bash
bundle add devise
bin/rails generate devise:install
bin/rails generate devise User
bin/rails active_storage:install
bin/rails action_text:install
```

- Devise fournit inscription, confirmation, sessions et récupération. La version exacte compatible Rails 8.1/Ruby 3.4 est verrouillée au début de F-001.
- Le modèle `User` reste unique pour membre/admin/super-admin ; ne pas créer un second modèle Devise `Admin`.
- Active Storage est requis par avatars, médias d'annonce, vidéos, preuves et photos de mission.
- Action Text est utile pour le corps riche des articles ; il peut être repoussé si le journal de bord n'entre pas dans le premier lot.

Après chaque générateur : lire la migration produite, ajouter contraintes/index, migrer puis lancer les tests avant de continuer.

## Ce qui mérite un scaffold

Un scaffold est adapté aux ressources éditoriales ou administratives dont le CRUD correspond réellement au besoin.

| Ressource | Générateur conseillé | Pourquoi |
|---|---|---|
| Catégorie | Scaffold | CRUD admin simple, hiérarchie limitée |
| Restriction de catégorie | Modèle + écran admin dédié | Blacklist versionnée, période, portée et action contrôlée |
| Annonce | Scaffold puis contrôleurs séparés | Bon point de départ pour formulaires, mais paramètres et autorisations doivent être resserrés |
| Organisation | Scaffold admin | Validation et gestion administratives |
| Adhésion à une organisation | Scaffold admin | Attribution explicite des gestionnaires |
| Partenariat | Scaffold admin | Page publique, période, ordre et statut sans accès implicite aux membres |
| Mission solidaire | Scaffold puis contrôleurs séparés | CRUD proche de l'annonce, permission Association obligatoire |
| Succès/quête | Scaffold admin | Contenu et activation administrables |
| Barème de récompense | Scaffold imbriqué admin | Plusieurs niveaux par quête |
| Article | Scaffold admin | Brouillon/publication/archivage |
| Témoignage | Scaffold admin | Soumission, consentement, revue et publication |
| Contenus de page | Modèles + Studio dédié | Versions, preview, publication et reset atomiques |
| Thème UI/UX | Modèles + Studio super-admin | Tokens allowlistés, défaut immuable et rollback |
| Séparateur organique | Modèle + presets | Plusieurs formes par page, animation contrôlée |
| Feature flag | Modèle + actions super-admin | Carte et rubriques activables, audit et reset |
| Version de document légal | Scaffold super-admin | Contenu versionné et publication immuable |
| Paramètre du site | Scaffold admin restreint | Paramètres non secrets qui ne pilotent pas l'activation d'une feature |
| Configuration SEO/GEO | Modèle versionné super-admin | Canonical, Schema.org, indexabilité et crawlers sans saisie libre |
| Valorisation PS | Modèles versionnés super-admin | Tranches indicatives modifiables sans conversion/achat |
| Règles engagement/chaînes | Modèles versionnés super-admin | Bonus, niveaux, longueur et plafonds simulés avant publication |
| Politique de conservation | Modèle versionné super-admin | Durées bornées, validation juridique et purge simulable |
| Version de calcul Trust | Scaffold super-admin restreint | Configuration versionnée, simulée et activée séparément |
| Référentiel de critères d'avis | Scaffold admin restreint | Libellés et applicabilité par catégorie, sans réécrire les avis passés |

## Scaffolds indicatifs

Les commandes ci-dessous produisent une première structure. Les valeurs par défaut, clés étrangères auto-référentes, contraintes `CHECK`, index uniques, pièces jointes et enums doivent être ajoutés dans les migrations ou modèles avant `db:migrate`.

### Catalogue

```bash
bin/rails generate scaffold Category \
  name:string slug:string parent_id:bigint position:integer active:boolean

bin/rails generate scaffold Listing \
  user:references category:references slug:string title:string description:text \
  intent:string exchange_mode:string estimated_points:integer status:string \
  priority:string availability:text service_location_mode:string \
  address_line:string postal_code:string city:string country_code:string \
  latitude:decimal longitude:decimal published_at:datetime closed_at:datetime \
  removed_at:datetime indexing_status:string seo_lastmod_at:datetime lock_version:integer

bin/rails generate model CategoryRestriction \
  category_id:bigint match_kind:string pattern:string restriction_scope:string status:string \
  reason_code:string reason_details:text starts_at:datetime ends_at:datetime \
  created_by_id:bigint approved_by_id:bigint existing_listings_action:string \
  lock_version:integer
```

Après génération de `Listing`, séparer les routes et contrôleurs : lecture publique, gestion des propres annonces et modération admin. Ne jamais exposer `user_id`, `status`, `published_at` ou `removed_at` dans les paramètres publics.

### Organisations et missions

```bash
bin/rails generate scaffold Organization \
  name:string slug:string kind:string legal_name:string registration_number:string \
  country_code:string website:string description:text public_location:string \
  status:string public_profile_status:string verified_at:datetime verified_by_id:bigint

bin/rails generate scaffold OrganizationMembership \
  organization:references user:references role:string status:string

bin/rails generate scaffold Partnership \
  organization:references kind:string status:string public_title:string \
  public_description:text starts_on:date ends_on:date position:integer \
  approved_by_id:bigint approved_at:datetime removed_at:datetime

bin/rails generate scaffold VolunteerMission \
  organization:references title:string description:text country_code:string \
  region:string private_address:string public_location:string starts_on:date \
  ends_on:date minimum_stay_days:integer help_hours_per_day:decimal \
  days_off_per_week:integer languages:string daily_contribution_cents:integer \
  volunteer_capacity:integer accommodation:text meals:text status:string \
  published_at:datetime removed_at:datetime
```

La limite de 1 500 centimes par jour doit exister côté modèle **et** comme contrainte de base.

### Quêtes et niveaux

```bash
bin/rails generate scaffold Achievement \
  name:string slug:string description:text event_name:string target_count:integer \
  recurrence:string requires_proof:boolean requires_review:boolean \
  active:boolean position:integer

bin/rails generate scaffold AchievementReward \
  achievement:references engagement_rule_version_id:bigint level:string points:integer
```

### Journal de bord et configuration

```bash
bin/rails generate scaffold Article \
  author_id:bigint title:string slug:string summary:text status:string \
  published_at:datetime

bin/rails generate scaffold Testimonial \
  user_id:bigint kind:string quote:text status:string submitted_at:datetime \
  reviewed_by_id:bigint reviewed_at:datetime published_at:datetime \
  removed_at:datetime display_name_snapshot:string public_location_snapshot:string \
  publication_consent_version:string publication_consented_at:datetime

bin/rails generate scaffold LegalDocumentVersion \
  kind:string version:string status:string summary_of_changes:text \
  effective_at:datetime published_at:datetime author_id:bigint

bin/rails generate scaffold SiteSetting \
  key:string value:string value_type:string updated_by_id:bigint
```

Le contrôleur public des articles ne doit exposer que les articles publiés. `SiteSetting` reste réservé au super-admin ou à un sous-ensemble d'admins défini explicitement.

### Studio UI, pages et feature flags

Ces objets ne doivent pas recevoir un CRUD public générique. Le Studio orchestre clone, validation, preview, publication, reset et rollback.

```bash
bin/rails generate model DesignTheme \
  name:string version:string status:string tokens:json system_default:boolean \
  parent_theme_id:bigint created_by_id:bigint validated_by_id:bigint \
  validated_at:datetime published_at:datetime archived_at:datetime lock_version:integer

bin/rails generate model PageDefinition \
  key:string route_key:string template_key:string schema_version:integer \
  active:boolean system_defined:boolean

bin/rails generate model PageVersion \
  page_definition:references design_theme_id:bigint locale:string version:string \
  status:string created_by_id:bigint validated_by_id:bigint validated_at:datetime \
  published_at:datetime archived_at:datetime system_default:boolean lock_version:integer

bin/rails generate model MediaAsset \
  name:string kind:string alt_text:text credit:string license:string source_url:string \
  focal_x:decimal focal_y:decimal status:string uploaded_by_id:bigint archived_at:datetime

bin/rails generate model ContentBlock \
  page_version:references slot_key:string kind:string title:string subtitle:string \
  eyebrow:string body:text cta_label:string cta_url:string cta_style:string \
  layout_preset:string surface_token:string position:integer visible:boolean \
  starts_at:datetime ends_at:datetime media_asset:references \
  seo_title:string seo_description:text

bin/rails generate model SectionDecoration \
  page_version:references after_slot_key:string preset_key:string animation_key:string \
  foreground_token:string background_token:string desktop_height:integer \
  mobile_height:integer flip_horizontal:boolean flip_vertical:boolean \
  variant_seed:integer enabled:boolean position:integer

bin/rails generate model FeatureFlag \
  key:string enabled:boolean default_enabled:boolean configuration:json \
  description:text updated_by_id:bigint lock_version:integer

bin/rails generate model ConfigurationReset \
  actor_id:bigint target:references{polymorphic} scope:string from_version:string \
  to_version:string reason:text snapshot:json
```

Le thème/page système est seedé depuis des constantes/assets versionnés et protégé en base. `public_map_enabled` vaut `true` par défaut. Les services attendus sont `Studio::CloneVersion`, `Studio::Validate`, `Studio::Publish`, `Studio::Reset`, `Studio::Rollback` et `FeatureFlags::Set`.

Les références média/thème restent facultatives lorsque le schéma du bloc ou de la page le permet ; les migrations générées doivent donc être relues avant exécution. Un reset « site entier » peut aussi ne pas viser un seul objet polymorphe : son périmètre exact est conservé dans le snapshot et l'audit.

### SEO/GEO et règles configurables

Ces ressources sont versionnées et publiées par des services métier, jamais modifiées directement lorsqu'elles sont actives.

```bash
bin/rails generate model SeoConfigurationVersion \
  name:string status:string site_name:string canonical_host:string \
  default_title_template:string default_description:text organization_payload:json \
  indexability_rules:json crawler_policy:json created_by_id:bigint \
  approved_by_id:bigint published_at:datetime superseded_at:datetime lock_version:integer

bin/rails generate model PointValuationVersion \
  name:string status:string effective_at:datetime created_by_id:bigint \
  approved_by_id:bigint published_at:datetime superseded_at:datetime lock_version:integer

bin/rails generate model PointValuationBracket \
  point_valuation_version:references points_from:integer points_to:integer \
  euros_from_cents:integer euros_to_cents:integer position:integer

bin/rails generate model EngagementRuleVersion \
  name:string status:string exchange_cycle_size:integer bronze_reward_points:integer \
  silver_reward_points:integer gold_reward_points:integer per_period_cap:integer \
  effective_at:datetime created_by_id:bigint approved_by_id:bigint \
  published_at:datetime superseded_at:datetime lock_version:integer

bin/rails generate model ChainRuleVersion \
  name:string status:string length_mode:string max_links:integer reward_scope:string \
  rewarded_previous_links:integer points_per_validation:integer \
  max_points_per_link:integer max_points_per_member:integer effective_at:datetime \
  created_by_id:bigint approved_by_id:bigint published_at:datetime \
  superseded_at:datetime lock_version:integer

bin/rails generate model RetentionPolicyVersion \
  name:string status:string rules:json effective_at:datetime created_by_id:bigint \
  approved_by_id:bigint published_at:datetime superseded_at:datetime \
  legal_reviewed_at:datetime lock_version:integer
```

Services attendus : `Seo::EvaluateIndexability`, `Seo::BuildStructuredData`, `Seo::BuildSitemaps`, `Rules::Simulate`, `Rules::Publish`, `Rules::Rollback`, `Retention::Simulate` et `Retention::ApplyDuePolicies`.

### Intégrations V1 retenues

| Besoin | Choix prévu | Règle |
|---|---|---|
| Authentification | Devise | Un seul modèle `User`, modules minimaux, RSpec complet |
| Login social | Devise + OmniAuth Google | Google actif en premier ; scopes `openid/email/profile` minimaux |
| Facebook | OmniAuth derrière flag off | Ne pas activer avant validation Ruby 3.4/Rails 8 et maintenance du provider |
| E-mail | Gmail API via client Ruby Google | Action Mailer adapter, OAuth/Workspace, secrets hors base, retries idempotents |
| Géocodage | Gem `geocoder` | Adresse privée en entrée, résultat public arrondi/minimisé, cache et quotas |
| Carte | Leaflet via Yarn/esbuild | Fournisseur de tuiles configurable ; détail seulement pour `in_person/hybrid`, résultats globaux `remote` sans marqueur, coupure totale avec le flag |
| Vidéo | Active Storage + lecteur HTML5 | Aucun tiers ni cookie par défaut |
| Analytics | Compteurs agrégés internes | Aucun analytics tiers au lancement ; futur provider derrière consentement/flag |
| Soutien | Stripe Checkout dormant | `financial_support_enabled = false`, don uniquement, aucun lien avec les PS |

Une « clé Google API » générique ne suffit pas à tous les usages : l'envoi Gmail et le login utilisent des credentials/scopes distincts. Ils vivent dans les credentials Rails ou secrets de déploiement, jamais dans `site_settings` ou le Studio.

## Ce qui ne doit pas être un CRUD naïf

Ces ressources ont des transitions, des unités de Points Services, des données privées ou des règles d'idempotence. Générer seulement le modèle, puis écrire des actions métier dédiées.

```bash
bin/rails generate model Profile \
  user:references first_name:string last_name:string phone:string \
  public_slug:string display_name:string phone_sharing_policy:string bio:text \
  address_line:string postal_code:string \
  city:string country_code:string latitude:decimal longitude:decimal \
  public_city:string public_profile_status:string level:string

bin/rails generate model Identity \
  user:references provider:string uid:string email_snapshot:string token_expires_at:datetime

bin/rails generate model Favorite user:references listing:references

bin/rails generate model AdminPermissionGrant \
  user:references permission:string granted_by_id:bigint granted_at:datetime \
  expires_at:datetime revoked_by_id:bigint revoked_at:datetime reason:text

bin/rails generate model Comment listing:references user:references body:text \
  status:string parent_id:bigint edited_at:datetime removed_at:datetime

bin/rails generate model ServiceRequest \
  listing:references requester_id:bigint provider_id:bigint status:string \
  proposed_points:integer agreed_points:integer scheduled_at:datetime \
  performed_at:datetime requester_confirmed_at:datetime \
  provider_confirmed_at:datetime closed_at:datetime cancelled_at:datetime \
  disputed_at:datetime cancellation_reason:text

bin/rails generate model Message \
  service_request:references sender_id:bigint body:text read_at:datetime \
  moderated_at:datetime removed_at:datetime

bin/rails generate model Review \
  service_request:references author_id:bigint reviewee_id:bigint \
  category:references completion_answer:string would_reengage:string \
  factual_body:text status:string submitted_at:datetime reveal_at:datetime \
  published_at:datetime removed_at:datetime moderation_reason:text

bin/rails generate scaffold ReviewCriterion \
  category_id:bigint key:string label:string help_text:text dimension:string \
  evaluator_role:string position:integer active:boolean \
  introduced_in_algorithm_version_id:bigint retired_at:datetime

bin/rails generate model ReviewRating \
  review:references review_criterion:references criterion_key_snapshot:string \
  rating:integer not_applicable:boolean

bin/rails generate model Notification \
  user:references kind:string notifiable:references{polymorphic} \
  title:string body:text read_at:datetime emailed_at:datetime

bin/rails generate model Report \
  reporter_id:bigint reportable:references{polymorphic} reason:string details:text \
  status:string assigned_to_id:bigint resolved_at:datetime resolution:text due_at:datetime

bin/rails generate model MissionApplication \
  volunteer_mission:references user:references message:text status:string \
  submitted_at:datetime decided_at:datetime
```

Les colonnes `requester_id`, `provider_id`, `sender_id`, `author_id`, `reviewee_id`, `reporter_id` et `assigned_to_id` doivent recevoir des clés étrangères explicites vers `users`.

### Trust Score, recommandations et recours

Ces générateurs créent des modèles, pas des contrôleurs CRUD publics. Les valeurs calculées doivent provenir d'un moteur versionné et idempotent.

```bash
bin/rails generate model TrustProfile \
  user:references public_score:decimal public_confidence:decimal \
  evidence_count:integer effective_evidence_weight:decimal \
  referral_evidence_count:integer referral_effective_weight:decimal \
  exchange_effective_weight:decimal status:string \
  algorithm_version_id:bigint calculated_at:datetime next_recalculation_at:datetime

bin/rails generate model TrustCategoryScore \
  user:references category:references score:decimal confidence:decimal \
  evidence_count:integer effective_evidence_weight:decimal \
  algorithm_version_id:bigint calculated_at:datetime

bin/rails generate model TrustDimensionScore \
  user:references category_id:bigint dimension:string score:decimal \
  confidence:decimal evidence_count:integer algorithm_version_id:bigint \
  calculated_at:datetime

bin/rails generate model TrustEvent \
  subject_id:bigint actor_id:bigint service_request_id:bigint category_id:bigint \
  event_kind:string dimension:string normalized_value:decimal base_weight:decimal \
  occurred_at:datetime source:references{polymorphic} validity_status:string \
  invalidated_by_id:bigint invalidated_at:datetime invalidation_reason:text metadata:json

bin/rails generate model TrustEndorsement \
  endorser_id:bigint endorsed_id:bigint category_id:bigint kind:string \
  relationship_context:string status:string independent_exchanges_required:integer \
  activated_at:datetime expires_at:datetime revoked_at:datetime

bin/rails generate model ReferralCode \
  owner_id:bigint code_digest:string status:string expires_at:datetime claimed_at:datetime

bin/rails generate model Referral \
  referral_code:references referrer_id:bigint referred_user_id:bigint position:integer \
  primary_referrer:boolean status:string trust_weight:decimal claimed_at:datetime \
  objection_deadline_at:datetime confirmed_at:datetime qualified_at:datetime \
  rewarded_at:datetime invalidated_at:datetime invalidation_reason:text \
  risk_review_status:string

bin/rails generate scaffold TrustAlgorithmVersion \
  version:string status:string configuration:json explanation:text \
  approved_by_id:bigint approved_at:datetime activated_at:datetime retired_at:datetime

bin/rails generate model TrustScoreSnapshot \
  user:references category_id:bigint algorithm_version:references score:decimal \
  confidence:decimal evidence_count:integer dimension_values:json reason:string \
  calculated_at:datetime

bin/rails generate model TrustRiskAssessment \
  user:references service_request_id:bigint risk_level:string signals:json \
  status:string reviewed_by_id:bigint reviewed_at:datetime expires_at:datetime

bin/rails generate model TrustAppeal \
  user:references trust_score_snapshot:references kind:string statement:text \
  status:string assigned_to_id:bigint decision:text decided_at:datetime \
  response_due_at:datetime
```

Après génération : ajouter toutes les clés étrangères vers `users`, contraintes d'intervalle (`0..100`, `0..1`, `1..5`), index d'unicité et protections append-only. Les colonnes JSON ne doivent contenir ni coordonnées ni empreintes techniques brutes inutiles.

Pour le parrainage, ajouter `position BETWEEN 1 AND 10`, les unicités sur code/paire/position, l'unicité partielle du parrain principal et un service transactionnel `Referrals::ClaimCodes`. Le nombre maximal de dix ne doit pas être vérifié seulement en JavaScript.

### Registre de points

```bash
bin/rails generate model PointAccount \
  user_id:bigint kind:string balance:integer status:string

bin/rails generate model PointOperation \
  kind:string status:string initiator_id:bigint source:references{polymorphic} \
  idempotency_key:string reason:text committed_at:datetime \
  reversed_operation_id:bigint

bin/rails generate model PointEntry \
  point_operation:references point_account:references amount:integer \
  balance_after:integer
```

Ajouter manuellement la clé étrangère nullable de `point_accounts.user_id` vers `users`. Le compte membre exige un utilisateur, tandis que le compte système utilisé pour équilibrer les émissions n'en possède pas.

Ne jamais générer de contrôleur permettant d'éditer ou supprimer directement `PointEntry`. Les seules entrées doivent provenir d'objets de service comme `Points::Transfer`, `Points::Reward` et `Points::Reverse`, exécutés dans une transaction avec verrouillage.

### Quêtes, chaînes et conformité

```bash
bin/rails generate model UserAchievement \
  user:references achievement:references status:string progress:integer \
  period_key:string submitted_at:datetime reviewed_by_id:bigint \
  reviewed_at:datetime completed_at:datetime rewarded_at:datetime

bin/rails generate model HelpChain \
  creator_id:bigint chain_rule_version:references name:string slug:string status:string \
  started_at:datetime closed_at:datetime

bin/rails generate model ChainService \
  help_chain:references provider_id:bigint beneficiary_id:bigint position:integer \
  description:text recipient_contact_ciphertext:text \
  invitation_token_digest:string invitation_expires_at:datetime status:string \
  confirmed_at:datetime confirmed_ip_digest:string

bin/rails generate model ChainReward \
  chain_service:references recipient_id:bigint chain_rule_version:references \
  points:integer reward_rank:integer point_operation:references

bin/rails generate model TopListingRequest \
  listing:references requester_id:bigint status:string eligibility_reason:string \
  reviewed_by_id:bigint reviewed_at:datetime admin_note:text \
  starts_at:datetime ends_at:datetime

bin/rails generate model DataRequest \
  user:references kind:string status:string details:text verified_at:datetime \
  assigned_to_id:bigint completed_at:datetime response_due_at:datetime

bin/rails generate model CookieConsent \
  user:references visitor_token_digest:string version:integer necessary:boolean \
  analytics:boolean external_media:boolean decided_at:datetime expires_at:datetime

bin/rails generate model NewsletterSubscription \
  user_id:bigint email:string status:string consent_version:string \
  consented_at:datetime source:string confirmed_at:datetime unsubscribed_at:datetime

bin/rails generate model ContactRequest \
  user_id:bigint email:string subject_kind:string message:text status:string \
  assigned_to_id:bigint submitted_at:datetime resolved_at:datetime \
  retention_due_at:datetime ip_digest:string spam_score:decimal

bin/rails generate model FinancialContribution \
  supporter_id:bigint amount_cents:integer currency:string status:string \
  stripe_checkout_session_id:string stripe_payment_intent_id:string \
  email_receipt_requested:boolean completed_at:datetime refunded_at:datetime

bin/rails generate model PaymentEvent \
  provider:string external_event_id:string kind:string payload_digest:string \
  status:string processed_at:datetime error_code:string

bin/rails generate model AuditLog \
  actor_id:bigint action:string auditable:references{polymorphic} \
  metadata:json request_id:string ip_digest:string

bin/rails generate model SensitiveDataAccessLog \
  actor_id:bigint subject_user_id:bigint resource_type:string resource_id:bigint \
  field_group:string reason:text request_id:string accessed_at:datetime

bin/rails generate model ModerationAction \
  actor_id:bigint target:references{polymorphic} kind:string reason_code:string \
  reason_details:text previous_status:string new_status:string expires_at:datetime \
  reversed_action_id:bigint
```

## Contrôleurs métier recommandés

Au lieu d'un CRUD générique :

- `ServiceRequestsController#create`, puis actions membres `accept`, `decline`, `mark_performed`, `confirm`, `cancel`, `dispute` ;
- `MessagesController#create` imbriqué sous une demande ;
- `FavoritesController#create/destroy` idempotent ;
- `PointTransfersController#create` limité à un échange éligible ;
- `ChainServicesController#create` et `ChainValidationsController#show/create` par jeton ;
- `ReportsController#create`, puis espace admin séparé pour le traitement ;
- `UserAchievementsController#submit` et contrôleur admin de revue ;
- `DataRequestsController#create` et suivi par le membre ;
- `ContactRequestsController#create` public, limité à l'équipe et sans création de conversation d'annonce ;
- namespaces `Account`, `Organizations`, `Admin` et `SuperAdmin` pour rendre les permissions lisibles.
- `TrustAppealsController#create` côté membre, puis traitement humain dans `Admin::TrustAppealsController` ;
- `Onboarding::ReferralCodesController#create` pour saisir plusieurs codes et `Referrals::ClaimCodes` pour les valider atomiquement ;
- `Admin::SensitiveDataRevealsController#create` pour une révélation ponctuelle et auditée, sans paramètre générique permettant de lire n'importe quelle colonne ;
- objets dédiés comme `Trust::RecordEvent`, `Trust::Recalculate`, `Trust::SimulateVersion`, `Trust::ResolveAppeal` et `Moderation::ApplyAction`.
- `Seo::SitemapsController`, `Seo::RobotsController` et builders JSON-LD sans paramètres de schéma libres ;
- `SuperAdmin::RuleVersionsController` avec actions `simulate`, `publish`, `rollback`, jamais update d'une version publiée ;
- `FinancialSupportController` absent des routes publiques tant que le flag Stripe est désactivé ; webhook séparé, signé et idempotent.

## Architecture du grand panneau d'administration

Toutes les routes d'administration doivent vivre sous un vrai namespace, même lorsqu'une ressource possède aussi une page publique :

```text
/admin/dashboard
/admin/users
/admin/listings
/admin/service_requests
/admin/point_operations
/admin/trust/profiles
/admin/trust/appeals
/admin/moderation/reports
/admin/category_restrictions
/admin/seo
/admin/privacy/data_requests
/super_admin/administrators
/super_admin/trust_algorithm_versions
/super_admin/rules/point_valuations
/super_admin/rules/engagement
/super_admin/rules/chains
/super_admin/retention_policy_versions
/super_admin/seo_configuration_versions
/super_admin/studio/themes
/super_admin/studio/pages
/super_admin/studio/media
/super_admin/studio/decorations
/super_admin/feature_flags
```

Éviter les actions `collection :admin` mélangées aux routes publiques. Les contrôleurs admin peuvent réutiliser modèles, requêtes et composants, jamais les paramètres permissifs du contrôleur public.

Scaffolder les ressources éditables pour gagner du temps, puis déplacer immédiatement contrôleurs/vues/routes sous `Admin::` ou `SuperAdmin::`. Pour les objets sensibles, générer uniquement le modèle et construire des commandes nommées. La règle générale est :

- catalogue, contenu, configuration non sensible : CRUD contrôlé ;
- utilisateur, profil, annonce, organisation : édition limitée + statut + audit ;
- message, avis confirmé, Trust Event, snapshot, opération et écriture de points : lecture ou modération, jamais édition libre ;
- audit, accès aux données sensibles : lecture seule et aucune suppression depuis l'interface.

## Arborescence de vues proposée

```text
app/views/
  home/
  listings/
  service_requests/
  account/
    dashboard/
    listings/
    wallet/
    achievements/
    chains/
    messages/
    profile/
  organizations/
    volunteer_missions/
  admin/
    dashboard/
    users/
    listings/
    exchanges/
    points/
    trust/
    moderation/
    engagement/
    organizations/
    content/
    privacy/
    platform/
  super_admin/
    studio/
    feature_flags/
  articles/
  legal/
  shared/
```

La maquette monolithique doit devenir des partials réutilisables : navigation, footer, carte d'annonce, badges, avatar, champ, état vide, pagination, modale et notification flash.

## Ordre d'implémentation recommandé

1. RSpec, CI, stratégie visuelle et build JS/CSS unique.
2. Devise, thème SEOS par défaut, layouts et composants fidèles à la maquette.
3. Profil, rôles, permissions, Gmail API et tests d'autorisation.
4. Catégories, blacklist, annonces, pièces jointes et pages publiques.
5. SEO/Schema.org/GEO, sitemaps, canonical et page Contact.
6. Studio UI/contenus, séparateurs organiques et feature flag Carte.
7. Geocoder, Leaflet, liste/carte et tests de confidentialité géographique.
8. Demandes de service, conversation et notifications.
9. Confirmation d'échange, avis structurés, événements de confiance et signalements.
10. Trust Score V1, profil public, explication, contestation et outils de revue admin.
11. Registre de points puis versions de valorisation/bonus avec tests de simulation, concurrence et idempotence.
12. Socle du back-office : utilisateurs, annonces, échanges, confiance, rapports, points et audit.
13. Extension du back-office à chaque ressource créée ; favoris et commentaires.
14. Quêtes, niveaux, Top annonces et parrainage qualifié.
15. Chaînes illimitées/limitées et règles de récompense versionnées.
16. Organisations, partenaires et missions solidaires.
17. Journal de bord, conservation, conformité et Stripe dormant.

## Contrôle après chaque lot

```bash
yarn build
bin/rails db:prepare
bundle exec rspec
bundle exec rspec spec/system
bundle exec rspec --tag visual
bundle exec rspec --tag accessibility
bin/rubocop
bin/brakeman --no-pager
```

Compléter avec les specs modèle, service, policy, query, request, job, mailer, system, visual et accessibilité. Les parcours les plus risqués sont : permissions, confirmation simultanée, solde insuffisant, double soumission, récompense déjà attribuée, jeton de chaîne expiré, reset global et accès à une coordonnée privée.

Pour le Trust Score, ajouter des tests de propriétés : résultat borné, recalcul idempotent, ordre des événements sans effet, paire récurrente plafonnée, vieillissement monotone, absence d'auto-évaluation, changement de version reproductible et aucune sanction importante sans revue humaine.

## À ne pas faire

- Générer tous les scaffolds en une seule fois sans relire les migrations.
- Laisser les routes CRUD admin accessibles hors namespace.
- Donner au back-office un bouton « Modifier » ou « Supprimer » sur un journal append-only.
- Afficher les coordonnées en clair dans une liste, un export ou une recherche globale admin.
- Appliquer une nouvelle formule de confiance sans simulation, version, snapshot et possibilité de retour.
- Autoriser le client à envoyer un rôle, un solde, un statut final ou un montant débité.
- Utiliser `dependent: :destroy` sur les écritures financières et journaux d'audit.
- Ajouter Tailwind ou un framework visuel sans besoin : la maquette possède déjà son design system.
- Charger des médias distants en production sans consentement, politique et stratégie de disponibilité.
- Autoriser le Studio à stocker ou exécuter du CSS, JavaScript, SVG ou HTML arbitraire.
- Mettre à jour automatiquement les baselines visuelles lorsqu'une spec échoue.

## Références techniques à vérifier au démarrage du code

- [Devise — documentation et compatibilité Rails](https://github.com/heartcombo/devise)
- [Google Workspace — client Ruby de l'API Gmail](https://developers.google.com/workspace/gmail/api/downloads)
- [Geocoder — intégration Rails et fournisseurs](https://github.com/alexreisner/geocoder)
- [OpenStreetMap Foundation — politique d'utilisation des tuiles](https://operations.osmfoundation.org/policies/tiles)
- [Stripe — accepter des dons](https://support.stripe.com/questions/how-to-accept-donations-through-stripe)

Les versions exactes, la maintenance des gems et les conditions des fournisseurs sont revérifiées au début de la feature concernée, puis verrouillées dans `Gemfile.lock`/`yarn.lock`. Ces liens justifient une orientation technique, pas l'activation juridique ou opérationnelle d'un prestataire.

import { application } from "./application"
import DisclosureController from "./disclosure_controller"
import DialogController from "./dialog_controller"
application.register("disclosure", DisclosureController)
application.register("dialog", DialogController)
import VisualStudioController from "./visual_studio_controller"
application.register("visual-studio", VisualStudioController)
import QuestPreviewController from "./quest_preview_controller"
application.register("quest-preview", QuestPreviewController)
import CatalogueController from "./catalogue_controller"
application.register("catalogue", CatalogueController)
import ListingWizardController from "./listing_wizard_controller"
application.register("listing-wizard", ListingWizardController)
import CopyLinkController from "./copy_link_controller"
application.register("copy-link", CopyLinkController)
import NotificationBadgesController from "./notification_badges_controller"
application.register("notification-badges", NotificationBadgesController)
import HeroCarouselController from "./hero_carousel_controller"
application.register("hero-carousel", HeroCarouselController)
import ChainPathController from "./chain_path_controller"
application.register("chain-path", ChainPathController)
import LegalTabsController from "./legal_tabs_controller"
application.register("legal-tabs", LegalTabsController)
import CookiePreferencesController from "./cookie_preferences_controller"
application.register("cookie-preferences", CookiePreferencesController)

import BackToTopController from "./back_to_top_controller"
application.register("back-to-top", BackToTopController)

import DirectoryDisplayController from "./directory_display_controller"
application.register("directory-display", DirectoryDisplayController)

import OrganizationRequestController from "./organization_request_controller"
application.register("organization-request", OrganizationRequestController)

import NotificationReadController from "./notification_read_controller"
application.register("notification-read", NotificationReadController)

import WorkspaceTabsController from "./workspace_tabs_controller"
application.register("workspace-tabs", WorkspaceTabsController)

import MissionFormController from "./mission_form_controller"
application.register("mission-form", MissionFormController)

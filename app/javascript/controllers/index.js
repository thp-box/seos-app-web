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

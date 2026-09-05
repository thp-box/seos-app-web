import { application } from "./application"
import DisclosureController from "./disclosure_controller"
import DialogController from "./dialog_controller"
application.register("disclosure", DisclosureController)
application.register("dialog", DialogController)

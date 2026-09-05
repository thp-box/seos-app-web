import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["panel", "trigger"]
  open() { this.panelTarget.showModal() }
  close() { this.panelTarget.close() }
  restoreFocus() { this.triggerTarget.focus() }
  disconnect() { this.panelTarget.close() }
}

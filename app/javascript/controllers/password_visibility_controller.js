import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"]

  toggle() {
    const revealing = this.inputTarget.type === "password"
    this.inputTarget.type = revealing ? "text" : "password"
    this.showIconTarget.hidden = revealing
    this.hideIconTarget.hidden = !revealing
    this.element.querySelector("button").setAttribute("aria-label", revealing ? "Masquer le mot de passe" : "Afficher le mot de passe")
  }
}

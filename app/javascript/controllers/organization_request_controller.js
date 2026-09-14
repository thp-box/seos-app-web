import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["request", "kind", "help"]
  connect() { this.update() }
  update() {
    const mission = this.requestTarget.value === "community_mission"
    Array.from(this.kindTarget.options).forEach(option => {
      option.hidden = mission && option.value !== "association"
      option.disabled = option.hidden
    })
    if (mission) this.kindTarget.value = "association"
    this.helpTarget.textContent = mission
      ? "Les missions communautaires sont réservées aux associations. Votre structure sera vérifiée avant la publication d’une mission."
      : "Présentez votre structure pour proposer un partenariat. Votre demande sera examinée avant toute publication."
  }
}

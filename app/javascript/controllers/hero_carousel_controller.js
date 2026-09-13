import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "label"]
  connect() {
    this.index = 0
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.paused = this.reduced.matches || this.slideTargets.length < 2
    this.timer = window.setInterval(() => {
      if (!this.paused && !this.reduced.matches && !document.hidden && !this.element.contains(document.activeElement)) this.advance()
    }, 6000)
  }
  disconnect() { window.clearInterval(this.timer) }
  advance() {
    this.slideTargets[this.index].classList.remove("active")
    this.slideTargets[this.index].setAttribute("aria-hidden", "true")
    this.index = (this.index + 1) % this.slideTargets.length
    const slide = this.slideTargets[this.index]
    slide.classList.add("active")
    slide.setAttribute("aria-hidden", "false")
    this.labelTarget.textContent = slide.dataset.label
  }
}

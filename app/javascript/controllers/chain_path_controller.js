import { Controller } from "@hotwired/stimulus"

// One connection per gap, anchored to both cards as they breathe independently.
export default class extends Controller {
  connect() {
    this.cards = Array.from(this.element.querySelectorAll("article"))
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    this.svg.classList.add("chain-connections")
    this.svg.setAttribute("aria-hidden", "true")
    this.paths = this.cards.slice(1).map(() => {
      const path = document.createElementNS(this.svg.namespaceURI, "path")
      this.svg.append(path)
      return path
    })
    this.element.append(this.svg)
    this.refresh = () => { cancelAnimationFrame(this.frame); this.draw() }
    this.resize = new ResizeObserver(this.refresh)
    this.resize.observe(this.element)
    this.cards.forEach(card => this.resize.observe(card))
    this.intersection = new IntersectionObserver(([entry]) => {
      this.visible = entry.isIntersecting
      this.refresh()
    })
    this.intersection.observe(this.element)
    this.motion = matchMedia("(prefers-reduced-motion: reduce)")
    this.motion.addEventListener("change", this.refresh)
    document.addEventListener("visibilitychange", this.refresh)
    this.draw()
  }
  disconnect() {
    cancelAnimationFrame(this.frame)
    this.resize.disconnect()
    this.intersection.disconnect()
    this.motion.removeEventListener("change", this.refresh)
    document.removeEventListener("visibilitychange", this.refresh)
    this.svg.remove()
  }
  draw() {
    const box = this.element.getBoundingClientRect()
    const cards = this.cards.map(card => card.getBoundingClientRect())
    this.svg.setAttribute("viewBox", `0 0 ${box.width} ${box.height}`)
    this.paths.forEach((path, index) => {
      const a = cards[index], b = cards[index + 1]
      const vertical = b.top >= a.bottom - 12
      const x1 = (vertical ? a.x + a.width / 2 : a.right) - box.x
      const y1 = (vertical ? a.bottom : a.y + a.height / 2) - box.y
      const x2 = (vertical ? b.x + b.width / 2 : b.left) - box.x
      const y2 = (vertical ? b.top : b.y + b.height / 2) - box.y
      const mx = (x1 + x2) / 2, my = (y1 + y2) / 2
      path.setAttribute("d", vertical
        ? `M${x1},${y1} C${x1},${my} ${x2},${my} ${x2},${y2}`
        : `M${x1},${y1} C${mx},${y1} ${mx},${y2} ${x2},${y2}`)
    })
    if (this.visible && !document.hidden && this.cards.some(card => card.getAnimations().some(animation => animation.playState === "running"))) {
      this.frame = requestAnimationFrame(() => this.draw())
    }
  }
}

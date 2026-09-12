import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  connect() {
    this.timer = setInterval(() => this.refresh(), 30000)
  }
  disconnect() {
    clearInterval(this.timer)
    this.request?.abort()
  }
  async refresh() {
    if (document.hidden || this.loading) return
    this.loading = true
    this.request = new AbortController()
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" }, cache: "no-store", signal: this.request.signal, redirect: "error" })
      if (!response.ok || !response.headers.get("content-type")?.includes("application/json")) return
      const data = await response.json()
      const total = Object.values(data.categories).reduce((sum, count) => sum + count, 0)
      document.querySelectorAll("[data-notification-category]").forEach(badge => {
        const count = badge.dataset.notificationCategory === "all" ? total : badge.dataset.notificationCategory.split(",").reduce((sum, key) => sum + (data.categories[key] || 0), 0)
        badge.hidden = count === 0
        badge.textContent = count > 99 ? "99+" : count
        badge.setAttribute("aria-label", `${count} notifications non lues`)
      })
      document.querySelectorAll("[data-notification-context-category]").forEach(element => { element.hidden = !data.categories[element.dataset.notificationContextCategory] })
      document.querySelectorAll("[data-notification-balance]").forEach(element => { element.textContent = `${data.balance} Points Services` })
    } catch { /* La page reste utilisable en cas de coupure réseau. */ }
    finally { this.loading = false }
  }
}

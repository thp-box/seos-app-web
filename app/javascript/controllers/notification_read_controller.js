import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, token: String }
  connect() {
    this.check = () => {
      clearTimeout(this.timer)
      if (!document.hidden && !this.done) this.timer = setTimeout(() => this.markRead(), 400)
    }
    document.addEventListener("visibilitychange", this.check)
    this.check()
  }
  disconnect() {
    clearTimeout(this.timer)
    document.removeEventListener("visibilitychange", this.check)
    this.request?.abort()
  }
  async markRead() {
    if (document.hidden || this.done || this.loading) return
    this.loading = true
    this.request = new AbortController()
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH", credentials: "same-origin", redirect: "error", cache: "no-store",
        signal: this.request.signal,
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || "" },
        body: JSON.stringify({ token: this.tokenValue })
      })
      if (!response.ok) return
      const data = await response.json()
      this.done = true
      document.dispatchEvent(new CustomEvent("notifications:read", { detail: data }))
    } catch { /* Le bouton de lecture manuelle reste disponible en cas de coupure. */ }
    finally { this.loading = false }
  }
}

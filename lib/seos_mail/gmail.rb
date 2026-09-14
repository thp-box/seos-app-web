require "net/http"
require "json"
require "base64"
module SeosMail
  class Gmail
    class ProviderError < IOError; end
    class UncertainDelivery < StandardError; end
    attr_accessor :settings
    def initialize(settings = {})
      @settings = settings
    end
    def deliver!(mail)
      mail.message_id ||= "#{SecureRandom.uuid}@#{ENV.fetch('SEOS_MAIL_DOMAIN', 'seos.test')}"
      record = nil
      created = false
      ::MailDelivery.transaction(requires_new: true) do
        record = ::MailDelivery.find_by(message_id: mail.message_id)
        unless record
          record = ::MailDelivery.create!(message_id: mail.message_id)
          created = true
        end
      end
      return if record.status == "sent"
      token = access_token
      unless created
        response = api(:get, "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=#{URI.encode_www_form_component("rfc822msgid:#{mail.message_id}")}", token)
        found = response.fetch("messages", []).first
        raise UncertainDelivery, "Envoi incertain : vérifier la boîte d’envoi avant toute nouvelle tentative." unless found
        record.update!(status: "sent", provider_id: found.fetch("id"))
        return
      end
      response = api(:post, "https://gmail.googleapis.com/gmail/v1/users/me/messages/send", token, { raw: Base64.urlsafe_encode64(mail.encoded, padding: false) })
      record.update!(status: "sent", provider_id: response.fetch("id"))
    end
    private
    def access_token
      uri = URI("https://oauth2.googleapis.com/token")
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(client_id: ENV.fetch("GMAIL_CLIENT_ID"), client_secret: ENV.fetch("GMAIL_CLIENT_SECRET"), refresh_token: ENV.fetch("GMAIL_REFRESH_TOKEN"), grant_type: "refresh_token")
      perform(uri, request).fetch("access_token")
    end
    def api(method, url, token, payload = nil)
      uri = URI(url)
      request = (method == :post ? Net::HTTP::Post : Net::HTTP::Get).new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json if payload
      perform(uri, request)
    end
    def perform(uri, request)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15, write_timeout: 15) { |http| http.request(request) }
      raise ProviderError, "Le fournisseur de messagerie a refusé la requête (#{response.code})." unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    rescue JSON::ParserError, KeyError
      raise ProviderError, "Réponse de messagerie invalide."
    end
  end
end

require 'lita-slack'
require 'slack-ruby-client'

module Lita
  module Handlers
    class SlackStatus < Handler
      route /^s(?:tatus)? ?save (\S+) (:.+:)(?: (.+))?$/, :save,
        help: { 'status save [name] [emoji] [text(optional)]' => 'save status' }
      route /^sss (\S+) (:.+:)(?: (.+))?$/, :save_and_set,
        help: { 'sss [name] [emoji] [text(optional)]' => 'save status and set(sss)' }
      route /^s(?:tatus)? ?rename (\S+) (\S+)$/, :rename,
        help: { 'status rename [from] [to]' => 'rename status' }
      route /^s(?:tatus)? ?delete (\S+)$/, :delete,
        help: { 'status delete [name]' => 'delete status' }
      route /^s(?:tatus)? ?l(?:ist)?$/, :list,
        help: { 'status list' => 'list status' }
      route /^s(?:tatus)? ?s(?:et)? (\S+)(?: (.+))?$/, :set,
        help: { 'status set [name] [text(optional)]' => 'set status' }
      route /^s(?:tatus)? ?c(?:lear)?$/, :clear,
        help: { 'status clear' => 'clear status' }

      config :admin_slack_token, required: true

      def save(response)
        name, emoji, text = response.matches.flatten
        redis.hset("users/#{response.user.id}/statuses", name, {emoji: emoji, text: text}.to_json)
        response.reply 'ok'
      end

      def save_and_set(response)
        name, emoji, text = response.matches.flatten
        redis.hset("users/#{response.user.id}/statuses", name, {emoji: emoji, text: text}.to_json)

        response.reply set_profile(response.user.id, emoji: emoji, text: text)
      end

      def list(response)
        statuses = redis.hgetall("users/#{response.user.id}/statuses")
        return response.reply '(empty)' if statuses.empty?

        message = statuses.map do |name, status_json|
          status = JSON.parse(status_json)
          status_str = [status['emoji'], status['text']].compact.join(' ')
          "#{name} => #{status_str} (`#{name} #{status_str}`)"
        end.join("\n")

        response.reply message
      end

      def delete(response)
        name = response.matches.flatten.first
        if redis.hdel("users/#{response.user.id}/statuses", name) == 1
          response.reply 'ok'
        else
          response.reply "not found: #{name}"
        end
      end

      def rename(response)
        from_name, to_name = response.matches.flatten
        status_json = redis.hget("users/#{response.user.id}/statuses", from_name)
        return response.reply "not found: #{name}" unless status_json

        redis.hset("users/#{response.user.id}/statuses", to_name, status_json)
        redis.hdel("users/#{response.user.id}/statuses", from_name)
        response.reply 'ok'
      end

      def set(response)
        name, text = response.matches.flatten
        status_json = redis.hget("users/#{response.user.id}/statuses", name)
        return response.reply "not found: #{name}" unless status_json

        status = JSON.parse(status_json)

        response.reply set_profile(response.user.id, emoji: status['emoji'], text: text || status['text'])
      end

      def clear(response)
        response.reply set_profile(response.user.id, emoji: nil, text: nil)
      end

      private

      def set_profile(user_id, emoji: , text:)
        resp = slack_client.users_profile_set(
          user: user_id,
          profile: {
            status_emoji: emoji.to_s,
            status_text:  text.to_s
          }.to_json
        )
        resp['ok'] ? 'ok' : "error: #{resp['error']}"
      end

      def slack_client
        @slack_client ||= Slack::Web::Client.new(token: config.admin_slack_token)
      end

      Lita.register_handler(self)
    end
  end
end

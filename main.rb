#!/usr/bin/env ruby

require 'discordrb'
require 'json'
require 'pry' # don't @ me

EMOJIBOT_CLIENT_ID = "671861772923305996"
EMOJILIST_FILENAME = "emojilist.json"
EMOJI_REGEX = /:[\w'_-]+:/

class EmojiBot
  def initialize(token, client_id = EMOJIBOT_CLIENT_ID)
    @bot = Discordrb::Bot.new(token: token, client_id: client_id)
    @emojilist = JSON.parse(File.read(EMOJILIST_FILENAME))

    _configure_service
  end

  def run
    @bot.run
  end

  def _configure_service
    @bot.message(with_text: "Ping!") do |event|
      event.respond("Pong!")
    end

    @bot.message(contains: EMOJI_REGEX) do |event|
      potential_emoji = event.message.content.scan(EMOJI_REGEX)
      urls = potential_emoji.map { |e| @emojilist[e.gsub(":","").downcase] || e }
      event.respond(urls.join(" "))
    end
  end
end


if __FILE__ == $0
  raise "Provide a token with the DISCORD_BOT_TOKEN env var" unless token = ENV["DISCORD_BOT_TOKEN"]

  EmojiBot.new(token).run
end

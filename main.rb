#!/usr/bin/env ruby

require 'discordrb'
require 'open-uri'
require 'json'
require 'pry' # don't @ me

EMOJILIST_FILENAME = "emojilist.json"
EMOJI_LIMIT = ENV["EMOJI_LIMIT"] || 50
UNPOPULATED_EMOJI_REGEX = /(?!<):[\w'_-]+:(?!\d*>)/ #ignore hydrated emoji
EMOJI_REGEX = /:[\w'_-]+:/

class EmojiBot
  def initialize(token, client_id)
    @bot = Discordrb::Bot.new(token: token, client_id: client_id)
    @emojilist = JSON.parse(File.read(EMOJILIST_FILENAME))

    configure_services
  end

  def run
    @bot.run
  end

  def configure_services
    _identify_and_add_emoji
    _list_emoji
    _delete_emoji
    _enhance_emoji

    _help
  end

  def _help
    @bot.message(contains: /^emojibot help$/) do |event|
      return if event.message.author.bot_account?
      event.respond("""
Source: https://github.com/jackellenberger/DiscordIWantMyEmoji
Commands:
    `/:emojiname:/` - add emojiname if present on list of known emoji, deleting old emoji if necessary
    `/^list emoji$/` - list emoji
    `/^rm :emojiname:$/` - delete emojiname from this server
    `/^enhance :emojiname:$/` - show the url for emojiname and expand it so it's a bit easier to see
          """)
    end
  end

  def _identify_and_add_emoji
    @bot.message(contains: UNPOPULATED_EMOJI_REGEX) do |event|
      return if event.message.author.bot_account?

      outgoing_message = nil
      incoming_message = event.text
      potential_emoji = incoming_message.scan(UNPOPULATED_EMOJI_REGEX).uniq

      potential_emoji.map do |potential_emoji_name|
        name = potential_emoji_name.gsub(":", "").downcase
        url = @emojilist[name]
        url = @emojilist[name.gsub("_", "-")] unless url #try dashes given underscores
        url = @emojilist[name.gsub("-", "_")] unless url #try underscores given dashes
        url = @emojilist[name.gsub(/[-_]/, "")] unless url #try no spacers

        next if !url || @bot.find_emoji(name)

        if url.end_with? "gif"
          # TODO: fix gifs, they 400
          event.respond("Ugh Jack is still working on adding gifs, but here's this #{url}")
          next
        end

        # Delete an old emoji if we need to
        if event.server.emoji.length >= EMOJI_LIMIT
          id_to_delete, name_to_delete = event.server.emoji.sort.first
          Discordrb::API::Server.delete_emoji(
            @bot.token,
            event.server.id,
            id_to_delete,
          )
          puts "Deleted emoji: #{name_to_delete}"
        end


        # Add the new emoji
        image_type = url.end_with?("gif") ? "gif" : "jpg"
        emoji_data = "data:image/#{image_type};base64,"
        emoji_data += Base64.strict_encode64(open(url).read)

        response = Discordrb::API::Server.add_emoji(
          @bot.token,
          event.server.id,
          emoji_data,
          name,
        )

        new_emoji = Discordrb::Emoji.new(JSON.parse(response&.body), @bot, event.server)
        puts "Added new emoji: #{new_emoji.mention}"

        outgoing_message = incoming_message.gsub(potential_emoji_name, new_emoji.mention)
      end

      event.respond("\"#{outgoing_message}\"") if outgoing_message
    end
  end


  def _delete_emoji
    @bot.message(contains: /^(delete|rm) <?:[\w'_-]+:(\d*>)?$/) do |event|
      return if event.message.author.bot_account?

      event.text.scan(EMOJI_REGEX).each do |emoji_name|
        if emoji_to_delete = @bot.find_emoji(emoji_name.gsub(":", ""))
          Discordrb::API::Server.delete_emoji(
            @bot.token,
            event.server.id,
            emoji_to_delete.resolve_id,
          )
        end
      end
    end
  end

  def _list_emoji
    @bot.message(contains: /^list emoji$/) do |event|
      return if event.message.author.bot_account?

      if (emoji = event.server.emoji).any?
        event.respond(emoji.values.map(&:mention).join(" "))
      else
        event.respond("None!")
      end
    end
  end

  def _enhance_emoji
    @bot.message(contains: /^enhance <?:[\w'_-]+:(\d*>)?$/) do |event|
      return if event.message.author.bot_account?

      event.text.scan(EMOJI_REGEX).each do |potential_emoji_name|
        name = potential_emoji_name.gsub(":", "").downcase
        url = @emojilist[name]
        url = @emojilist[name.gsub("_", "-")] unless url #try dashes given underscores
        url = @emojilist[name.gsub("-", "_")] unless url #try underscores given dashes
        url = @emojilist[name.gsub(/[-_]/, "")] unless url #try no spacers

        event.respond(url) if url
      end
    end
  end
end


if __FILE__ == $0
  raise "Provide a token with the DISCORD_BOT_TOKEN env var" unless token = ENV["DISCORD_BOT_TOKEN"]
  raise "Provide a bot client id with the DISCORD_BOT_CLIENT_ID env var" unless client_id = ENV["DISCORD_BOT_CLIENT_ID"]

  EmojiBot.new(token, client_id).run
end

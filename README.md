# Discord but I want my emoji

Discord has an emoji limit of 50, but I have like 22,000 that I want to use??? c'mon Discord, how much could _one_ extra server cost? Anyway, this project uses [emojme](https://github.com/jackellenberger/emojme) (i know, i know, _don't you do anything else?_) to create a json blob of emoji names and urls, then with a little Discord bot (:itme: amiright) it listens on messages with unpopulated emoji, e.g. "Hey where are all my emoji :clamboozled:" and pops in the slack url for that particular emoji, which Discord graciously opens.

This relies heavily on the fact that Slack don't protect their emoji behind any sort of authorization, any organizations emoji are theoretically out there in the ether, waiting to be scraped, and I _am_ waiting to be paid for that work.

This is crippled heavily by the fact that an emoji's UUID isn't easily reversible. Like, cmon, `https://emoji.slack-edge.com/T7ZGGRLGN/clamboozled/40721258d4758e1a.png`? What is `40721258d4758e1a`? There are letters now? There are even more permutations than when I last complained about this. But anyway, as long as you can _get_ links to emoji you can _use_ links to emoji, so that's what I've done.

It's worth noting that this requires a redeploy every time you update your emoji list (unlike my hubot projects), but idc I did this in an afternoon.

### Requirements

* Ruby of some description
* Node 10, but just to generate the emojilist don't even trip
* `jq`? Do people now have jq? Again just for the generation

### Usage

1. set up your emoji list.
  * Either make a json object by hand (you pleb) of '{"emojiName": "url"}', or
  * run `generate-emojilist.sh $subdomain $token`
    - `$subdomain` being your slack subdomain, as in `butts.slack.com` (sell this to me please), whatever it says in the upper left of your slack browser.
    - `$token` is your slack user token, [they can't keep making me explain how to get this](https://github.com/jackellenberger/emojme#finding-a-slack-token)
1. Deploy this bot somewhere. Your computer. Your employer's computer. Your neighbor's router. `bundle exec main.rb`
  * You will need to set your DISCORD_BOT_TOKEN environment variable to get that workin.
1. Talk to emojibot. Share your secrets with them.
1. Send me your emojilists. Information wants to be free.

### Permissions

Bestow the following permissions on your bot for it to function:
- Send Messages - For when you want to list emoji, etc
- Embed Links - For when you want to expand emoji to their source urls
- Manage Emojis - Adding and deleting Emoji - Yes, this will delete your emoji if you run out.

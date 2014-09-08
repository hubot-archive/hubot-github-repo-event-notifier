# Description:
#   Notifies about any available GitHub repo event via webhook #
# Configuration:
#   HUBOT_GITHUB_EVENT_NOTIFIER_ROOM  - The default room to which message should go (optional)
#   HUBOT_GITHUB_EVENT_NOTIFIER_TYPES - Comma-separated list of event types to notify on
#     (See: http://developer.github.com/webhooks/#events)
#
#   You will have to do the following:
#   1. Create a new webhook for your `myuser/myrepo` repository at:
#      https://github.com/myuser/myrepo/settings/hooks/new
#
#   2. Select the individual events to minimize the load on your Hubot.
#
#   3. Add the url: <HUBOT_URL>:<PORT>/hubot/gh-repo-events[?room=<room>]
#      (Don't forget to urlencode the room name, especially for IRC. Hint: # = %23)
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/gh-repo-events?room=<room>
#
# Notes:
#   Currently tested with the following event types in HUBOT_GITHUB_EVENT_NOTIFIER_TYPES:
#     - issue
#     - pull_request
#
# Authors:
#   spajus
#   patcon
#   parkr
#   pmgarman

url           = require('url')
querystring   = require('querystring')
eventActions  = require('./event-actions/all')
eventTypesRaw = process.env['HUBOT_GITHUB_EVENT_NOTIFIER_TYPES']
eventTypes    = []

regexGithubUser = /(?:I'm|I am) @?([a-z0-9]+) on GitHub/i
regexNotGithubUser = /(?:I'm|I am) not on GitHub/i

if eventTypesRaw?
  # create a list like: "issues:* pull_request:comment pull_request:close fooevent:baraction"
  # -- if any action is omitted, it will be appended with an asterisk (foo becomes foo:*) to
  # indicate that any action on event foo is acceptable
  eventTypes = eventTypesRaw.split(',').map e -> (e.indexOf(":") > -1 ? e : e+":*") 

else
  console.warn("github-repo-event-notifier is not setup to receive any events (HUBOT_GITHUB_EVENT_NOTIFIER_TYPES is empty).")

module.exports = (robot) ->
  robot.respond regexGithubUser, (msg) ->
    match = regexGithubUser.exec msg.text
    user = msg.user
    if match
      console.log "User @#{msg.user.mention_name} asked to link their GitHub account #{match[1]}"
      (user.accounts ?= {})['github'] = match[1]
      msg.reply "Ok, I'll remember you as #{match[1]} on GitHub."

  robot.respond regexNotGithubUser, (msg) ->
    delete (msg.user.accounts ?= {})['github']
    msg.reply "Ok, you're not on GitHub."

  robot.router.post "/hubot/gh-repo-events", (req, res) ->
    query = querystring.parse(url.parse(req.url).query)

    data = req.body
    room = query.room || process.env["HUBOT_GITHUB_EVENT_NOTIFIER_ROOM"]
    eventType = req.headers["x-github-event"]
    console.log "Processing event type #{eventType}..."

    try

      filter_parts = eventTypes
        .filter(function (e) {
          # should always be at least two parts, from eventTypes creation above
          parts = e.split(":")
          event_part = parts[0]
          action_part = parts[1]

          if(event_part != eventType) {
            return false # remove anything that isn't this event
          }

          if(action_part == "*") {
            return true # wildcard on this event
          }

          if(!data.hasOwnProperty('action')) {
            return true # no action property, let it pass
          }

          if(action_part == data.action) {
            return true # action match
          }

          return false # no match, fail

        })


      if filter_parts.length > 0
        announceRepoEvent robot, data, eventType, (what) ->
          robot.messageRoom room, what
      else
        console.log "Ignoring #{eventType} event as it's not allowed."
    catch error
      robot.messageRoom room, "Whoa, I got an error: #{error}"
      console.log "github repo event notifier error: #{error}. Request: #{req.body}"

    res.end ""

announceRepoEvent = (robot, data, eventType, cb) ->
  if eventActions[eventType]?
    eventActions[eventType](robot, data, cb)
  else
    cb("Received a new #{eventType} event, just so you know.")

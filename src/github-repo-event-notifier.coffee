# Description:
#   Notifies about any available GitHub repo event via webhook #
# Configuration:
#   HUBOT_GITHUB_EVENT_NOTIFIER_ROOM  - The default room to which message should go (optional)
#   HUBOT_GITHUB_EVENT_NOTIFIER_TYPES - Comma-separated list of event types to notify on
#   (See: http://developer.github.com/webhooks/#events)
#
#   You will have to do the following:
#   1. Create a new webhook for your `myuser/myrepo` repository at:
#    https://github.com/myuser/myrepo/settings/hooks/new
#
#   2. Select the individual events to minimize the load on your Hubot.
#
#   3. Add the url: <HUBOT_URL>:<PORT>/hubot/gh-repo-events[?room=<room>]
#    (Don't forget to urlencode the room name, especially for IRC. Hint: # = %23)
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
#     - page_build
#     - pull_request
#     - push
#
# Authors:
#   spajus
#   patcon
#   parkr

inspect = (require('util')).inspect
url = require('url')
querystring = require('querystring')
eventActions = require('./event-actions/all')
eventTypesRaw = process.env['HUBOT_GITHUB_EVENT_NOTIFIER_TYPES']
eventTypes = []

if eventTypesRaw?
  ###
  create a list like: "issues:* pull_request:comment pull_request:close fooevent:baraction"

  If any action is omitted, it will be appended with an asterisk (foo becomes foo:*) to
  indicate that any action on event foo is acceptable
  ###

  eventTypes = eventTypesRaw.split(',').map (e) ->
    append = ""

    # append :* to any elements missing it
    if e.indexOf(":") == -1
      append = ":*"

    return "#{e}#{append}"
else
  console.warn("github-repo-event-notifier is not setup to receive any events (HUBOT_GITHUB_EVENT_NOTIFIER_TYPES is empty).")

module.exports = (robot) ->
  robot.router.post "/hubot/gh-repo-events", (req, res) ->
    query = querystring.parse(url.parse(req.url).query)

    data = req.body
    robot.logger.debug "github-repo-event-notifier: Received POST to /hubot/gh-repo-events with data = #{inspect data}"
    room = query.room || process.env["HUBOT_GITHUB_EVENT_NOTIFIER_ROOM"]
    eventType = req.headers["x-github-event"]
    robot.logger.debug "github-repo-event-notifier: Processing event type: \"#{eventType}\"..."

    try

      filter_parts = eventTypes
        .filter (e) ->
          # should always be at least two parts, from eventTypes creation above
          parts = e.split(":")
          event_part = parts[0]
          action_part = parts[1]

          if event_part != eventType
            return false # remove anything that isn't this event

          if action_part == "*"
            return true # wildcard on this event

          if !data.hasOwnProperty('action')
            return true # no action property, let it pass

          if action_part == data.action
            return true # action match

          return false # no match, fail

      if filter_parts.length > 0
        announceRepoEvent data, eventType, (what) ->
          robot.messageRoom room, what
      else
        console.log "Ignoring #{eventType}:#{data.action} as it's not allowed."
    catch error
      robot.messageRoom room, "Whoa, I got an error: #{error}"
      console.log "Github repo event notifier error: #{error}. Request: #{req.body}"

    res.end ""

announceRepoEvent = (data, eventType, cb) ->
  if eventActions[eventType]?
    eventActions[eventType](data, cb)
  else
    cb("Received a new #{eventType} event, just so you know.")

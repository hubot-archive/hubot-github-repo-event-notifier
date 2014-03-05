# Description:
#   Notifies about any GitHub repo event available via webhook
#
# Configuration:
#   HUBOT_GITHUB_EVENT_NOTIFIER_TYPES - Comma-separated list of event types to notify on
#     (See: http://developer.github.com/webhooks/#events)
#
#   You will have to do the following:
#   1. Create a new webhook for your `myuser/myrepo` repository at:
#      https://github.com/myuser/myrepo/settings/hooks/new
#
#   2. Select the individual events to minimize the load on your Hubot.
#
#   3. Add the url: <HUBOT_URL>:<PORT>/hubot/gh-repo-events?room=<room>
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

url = require('url')
querystring = require('querystring')

event_types = process.env.HUBOT_GITHUB_EVENT_NOTIFIER_TYPES.split(',')

module.exports = (robot) ->
  robot.router.post "/hubot/gh-repo-events", (req, res) ->
    query = querystring.parse(url.parse(req.url).query)

    data = req.body
    room = query.room

    try
      for event_type in event_types
        if data[event_type]?
          announceRepoEvent data, event_type, (what) ->
            robot.messageRoom room, what
    catch error
      robot.messageRoom room, "Whoa, I got an error: #{error}"
      console.log "github repo event notifier error: #{error}. Request: #{req.body}"

    res.end ""

announceRepoEvent = (data, event_type, cb) ->
  if data.action == 'opened'
    mentioned_line = ''

    # body can be null in certain circumstances
    if data[event_type].body?
      mentioned = data[event_type].body.match(/(^|\s)(@[\w\-\/]+)/g)

      if mentioned
        unique = (array) ->
          output = {}
          output[array[key]] = array[key] for key in [0...array.length]
          value for key, value of output

        mentioned = mentioned.filter (nick) ->
          slashes = nick.match(/\//g)
          slashes is null or slashes.length < 2

        mentioned = mentioned.map (nick) -> nick.trim()
        mentioned = unique mentioned

        mentioned_line = "\nMentioned: #{mentioned.join(", ")}"

    cb "New #{event_type.replace('_', ' ')} \"#{data[event_type].title}\" by #{data[event_type].user.login}: #{data[event_type].html_url}#{mentioned_line}"

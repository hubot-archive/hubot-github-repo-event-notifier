# Description:
#   Notifies about any GitHub repo event available via webhook
#
# Configuration:
#   HUBOT_GITHUB_EVENT_NOTIFIER_TYPES - Comma-separated list of event types to notify on
#     (See: http://developer.github.com/webhooks/#events)
#
#   You will have to do the following:
#   1. Get an API token: curl -u 'username' -d '{"scopes":["repo"],"note":"Hooks management"}' \
#                         https://api.github.com/authorizations
#   2. Add <HUBOT_URL>:<PORT>/hubot/gh-repo-events?room=<room> url hook via API:
#      curl -H "Authorization: token <your api token>" \
#      -d '{"name":"web","active":true,"events":["pull_request"],"config":{"url":"<this script url>","content_type":"json"}}' \
#      https://api.github.com/repos/<your user>/<your repo>/hooks
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/gh-repo-events?room=<room>
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
      announceRepoEvent data, (what) ->
        robot.messageRoom room, what
    catch error
      robot.messageRoom room, "Whoa, I got an error: #{error}"
      console.log "github repo event notifier error: #{error}. Request: #{req.body}"

    res.end ""

announceRepoEvent = (data, cb) ->
  if data.action == 'opened'
    mentioned_line = ''

    for type in event_types
      if data[type].body?
        mentioned = data[type].body.match(/(^|\s)(@[\w\-\/]+)/g)

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

      cb "New #{type} \"#{data[type].title}\" by #{data[type].user.login}: #{data[type].html_url}#{mentioned_line}"

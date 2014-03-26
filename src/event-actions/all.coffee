#! /usr/bin/env coffee

eventTypeToTitle = 
  "issue": 'issue'
  "pull_request": 'pull request'

unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

userByGitHub = (robot, nick) ->
  result = null
  lowerNick = nick.toLowerCase()
  for k of (robot.brain.users or { })
    accounts = robot.brain.users[k]['accounts']
    if accounts? and 'github' of accounts and accounts['github'].toLowerCase() is lowerNick
      result = robot.brain.users[k]
  result
  

extractMentionsFromBody = (robot, body) ->
  mentioned = body.match(/(^|\s)@([\w\-\/]+)/g)

  if mentioned?
    mentioned = mentioned.filter (nick) ->
      slashes = nick.match(/\//g)
      slashes is null or slashes.length < 2

    mentioned = mentioned.map (nick) -> 
      nick = nick.trim()
      user = userByGitHub(robot, nick)
      if user?
        "@" + user.mention_name
      else
        "@" + nick

    mentioned = unique mentioned

    "\nMentioned: #{mentioned.join(", ")}"
  else
    ""

buildNewIssueOrPRMessage = (robot, data, eventType, callback) ->
  pr_or_issue = data[eventType]
  title = eventTypeToTitle[eventType]
  if data.action == 'opened'
    mentioned_line = ''
    if pr_or_issue.body?
      mentioned_line = extractMentionsFromBody(robot, pr_or_issue.body)
    callback "New #{title} \"#{pr_or_issue.title}\" by #{pr_or_issue.user.login}: #{pr_or_issue.html_url}#{mentioned_line}"

module.exports =
  issues: (robot, data, callback) ->
    buildNewIssueOrPRMessage(robot, data, 'issue', callback)

  pull_request: (robot, data, callback) ->
    buildNewIssueOrPRMessage(robot, data, 'pull_request', callback)

  issue_comment: (robot, data, callback) ->
    issue = data['issue']
    comment = data['comment']
    mentioned_line = ''
    if comment.body?
      mentioned_line = extractMentionsFromBody(robot, comment.body)
    callback "New comment on \"#{issue.title}\" by #{comment.user.login}: #{issue.html_url}#{mentioned_line}"

  page_build: (robot, data, callback) ->
    build = data.build
    if build?
      if build.status is "built"
        callback "#{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "Page build for #{data.repository.full_name} errored: #{build.error.message}."


#! /usr/bin/env coffee

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
  if data.action == 'opened' || data.action == 'closed' || data.action == 'reopened'
    mentioned_line = ''
    if pr_or_issue.body?
      mentioned_line = extractMentionsFromBody(robot, pr_or_issue.body)
    callback "#{data.action} #{eventType.replace('_', ' ')} \"#{pr_or_issue.title}\" by #{pr_or_issue.user.login}: #{pr_or_issue.html_url}#{mentioned_line}"

module.exports =
  issues: (robot, data, callback) ->
    buildNewIssueOrPRMessage(robot, data, 'issue', callback)

  issue_comment: (robot, data, callback) ->
    issue = data['issue']
    comment = data['comment']
    mentioned_line = ''
    if comment.body?
      mentioned_line = extractMentionsFromBody(robot, comment.body)
    callback "New comment on \"#{issue.title}\" by #{comment.user.login}: #{issue.html_url}#{mentioned_line}"

  pull_request: (robot, data, callback) ->
    buildNewIssueOrPRMessage(robot, data, 'pull_request', callback)

  pull_request_review_comment: (robot, data, callback) ->
    buildNewIssueOrPRMessage(data, 'pull_request_review_comment', callback)

  push: (robot, data, callback) ->
    if ! data.created
      commit_messages = data.commits.map((commit)-> commit.message).join("\n")
      callback "#{data.commits.length} new commit(s) pushed by #{data.pusher.name}:\n#{commit_messages}See them here: #{data.compare}"

  commit_comment: (robot, data, callback) ->
    callback "#{data.comment.user.login} commented on a commit, see it here: #{data.comment.html_url}"

  member: (robot, data, callback) ->
    callback "#{data.member.login} has been #{data.action} as a contributor!"

  watch: (robot, data, callback) ->
    callback "#{data.sender.login} has #{data.action} watching #{data.repository.full_name}."

  create: (robot, data, callback) ->
    callback "The #{data.ref} #{data.ref_type} has been created."

  delete: (robot, data, callback) ->
    callback "The #{data.ref} #{data.ref_type} has been deleted."

  fork: (robot, data, callback) ->
    callback "A new fork of #{data.repository.full_name} has been created at #{data.forkee.full_name}."

  team_add: (robot, data, callback) ->
    callback "The #{data.team.name} team now has #{data.team.permission} access to #{data.repository.full_name}"

  release: (robot, data, callback) ->
    callback "#{data.release.name} has been #{data.action}! See it here: #{data.release.html_url}"

  page_build: (robot, data, callback) ->
    build = data.build
    if build?
      if build.status is "built"
        callback "#{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "Page build for #{data.repository.full_name} errored: #{build.error.message}."

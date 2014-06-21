#! /usr/bin/env coffee

unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

extractMentionsFromBody = (body) ->
  mentioned = body.match(/(^|\s)(@[\w\-\/]+)/g)

  if mentioned?
    mentioned = mentioned.filter (nick) ->
      slashes = nick.match(/\//g)
      slashes is null or slashes.length < 2

    mentioned = mentioned.map (nick) -> nick.trim()
    mentioned = unique mentioned

    "\nMentioned: #{mentioned.join(", ")}"
  else
    ""

buildNewIssueOrPRMessage = (data, eventType, callback) ->
  pr_or_issue = data[eventType]
  if data.action == 'opened'
    mentioned_line = ''
    if pr_or_issue.body?
      mentioned_line = extractMentionsFromBody(pr_or_issue.body)
    callback "New #{eventType.replace('_', ' ')} \"#{pr_or_issue.title}\" by #{pr_or_issue.user.login}: #{pr_or_issue.html_url}#{mentioned_line}"

module.exports =
  issues: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'issue', callback)

  issue_comment: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'issue_comment', callback)

  pull_request: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'pull_request', callback)

  pull_request_review_comment: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'pull_request_review_comment', callback)

  push: (data, callback) ->
    if ! data.created
      callback "#{data.commits.length} new commit(s) pushed by #{data.pusher.name}, see them here: #{data.compare}"

  commit_comment: (data, callback) ->
    callback "#{data.comment.user.login} commented on a commit, see it here: #{data.comment.html_url}"

  member: (data, callback) ->
    callback "#{data.member.login} has been #{data.action} as a contributor!"

  watch: (data, callback) ->
    callback "#{data.watch.user.login} is now watching #{data.watch.repository.full_name}."

  create: (data, callback) ->
    callback "The #{data.ref} #{data.ref_type} has been created."

  delete: (data, callback) ->
    callback "The #{data.ref} #{data.ref_type} has been deleted."

  fork: (data, callback) ->
    callback "A new fork of #{data.repository.full_name} has been created at #{data.forkee.full_name}."

  team_add: (data, callback) ->
    callback "The #{data.team.name} team now has #{data.team.permission} access to #{data.repository.full_name}"

  release: (data, callback) ->
    callback "#{data.release.name} has been #{data.action}! See it here: #{data.release.html_url}"

  page_build: (data, callback) ->
    build = data.build
    if build?
      if build.status is "built"
        callback "#{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "Page build for #{data.repository.full_name} errored: #{build.error.message}."

#! /usr/bin/env coffee

#commit_comment,create,delete,deployment,deployment_status,fork,gollum,issue_comment,issues,member,membership,page_build,pull_request_review_comment,pull_request,push,repository,release,status,ping,team_add,watch

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

formatUrl = (adapter, url, text) ->
  switch adapter
    when "mattermost" || "slack"
      "<#{url}|#{text}>"
    else
      url

module.exports =
  commit_comment: (data, callback, adapter) ->
    comment = data.comment
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    commit_link = formatUrl adapter, comment.html_url, comment.commit_id

    callback "[#{repo_link}] New comment by #{comment.user.login} on commit #{commit_link}: \n\"#{comment.body}\""

  create: (data, callback, adapter) ->
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    ref_type = data.ref_type
    ref = data.ref

    callback "[#{repo_link}] New #{ref_type} #{ref} created"

  delete: (data, callback, adapter) ->
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    ref_type = data.ref_type

    ref = data.ref.split('refs/heads/').join('')

    callback "[#{repo_link}] #{ref_type} #{ref} deleted"

  deployment: (data, callback, adapter) ->
    deploy = data.deployment
    repo = data.repository

    callback "New deployment #{deploy.id} from: #{repo.full_name} to: #{deploy.environment} started by: #{deploy.creator.login}"

  deployment_status: (data, callback, adapter) ->
    deploy = data.deployment
    deploy_status = data.deployment_status
    repo = data.repository

    callback "Deployment #{deploy.id} from: #{repo.full_name} to: #{deploy.environment} - #{deploy_status.state} by #{deploy.status.creator.login}"

  fork: (data, callback, adapter) ->
    forkee = data.forkee
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name

    callback "#{repo_link} forked by #{forkee.owner.login}"

  # Needs to handle more then just one page
  gollum: (data, callback, adapter) ->
    pages = data.pages
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    sender = data.sender

    page = pages[0]

    callback "[#{repo_link}] Wiki page: #{page.page_name} #{page.action} by #{sender.login}"

  issues: (data, callback, adapter) ->
    issue = data.issue
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    issue_link = formatUrl adapter, issue.html_url, "\##{issue.number} \"#{issue.title}\""
    action = data.action
    sender = data.sender

    msg = "[#{repo_link}] Issue #{issue_link}"

    switch action
      when "assigned"
        msg += " assigned to: #{issue.assignee.login} by #{sender.login} "
      when "unassigned"
        msg += " unassigned #{data.assignee.login} by #{sender.login} "
      when "opened"
        msg += " opened by #{sender.login} "
      when "closed"
        msg += " closed by #{sender.login} "
      when "reopened"
        msg += " reopened by #{sender.login} "
      when "labeled"
        msg += " #{sender.login} added label: \"#{data.label.name}\" "
      when "unlabeled"
        msg += " #{sender.login} removed label: \"#{data.label.name}\" "

    callback msg

  issue_comment: (data, callback, adapter) ->
    issue = data.issue
    comment = data.comment
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    comment_link = formatUrl adapter, comment.html_url, "#{issue_pull} \##{issue.number}"

    issue_pull = "Issue"

    if comment.html_url.indexOf("/pull/") > -1
      issue_pull = "Pull Request"

    callback "[#{repo_link}] New comment on #{comment_link} by #{comment.user.login}: \n\"#{comment.body}\""

  member: (data, callback, adapter) ->
    member = data.member
    repo = data.repository

    callback "Member #{member.login} #{data.action} from #{repo.full_name}"

  # Org level event
  membership: (data, callback, adapter) ->
    scope = data.scope
    member = data.member
    team = data.team
    org = data.organization

    callback "#{org.login} #{data.action} #{member.login} to #{scope} #{team.name}"

  page_build: (data, callback, adapter) ->
    build = data.build
    repo = data.repository
    if build?
      if build.status is "built"
        callback "#{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "Page build for #{data.repository.full_name} errored: #{build.error.message}."

  pull_request_review_comment: (data, callback, adapter) ->
    comment = data.comment
    pull_req = data.pull_request
    base = data.base
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    comment_link = formatUrl adapter, comment.html_url, pull_req.title

    callback "[#{repo_link}] New comment on Pull Request #{comment_link} by #{comment.user.login}: \n\"#{comment.body}\""

  pull_request: (data, callback, adapter) ->
    pull_num = data.number
    pull_req = data.pull_request
    base = data.base
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    pull_request_link = formatUrl adapter, pull_req.html_url, "\##{data.number} \"#{pull_req.title}\""
    sender = data.sender

    action = data.action

    msg = "[#{repo_link}] Pull Request #{pull_request_link}"

    switch action
      when "assigned"
        msg += " assigned to: #{data.assignee.login} by #{sender.login} "
      when "unassigned"
        msg += " unassigned #{data.assignee.login} by #{sender.login} "
      when "opened"
        msg += " opened by #{sender.login} "
      when "closed"
        if pull_req.merged
          msg += " merged by #{sender.login} "
        else
          msg += " closed by #{sender.login} "
      when "reopened"
        msg += " reopened by #{sender.login} "
      when "labeled"
        msg += " #{sender.login} added label: \"#{data.label.name}\" "
      when "unlabeled"
        msg += " #{sender.login} removed label: \"#{data.label.name}\" "
      when "synchronize"
        msg +=" synchronized by #{sender.login} "

    callback msg

  push: (data, callback, adapter) ->
    commit = data.after
    commits = data.commits
    head_commit = data.head_commit
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    pusher = data.pusher

    if !data.deleted
      if commits.length == 1
        commit_link = formatUrl adapter, head_commit.url, "\"#{head_commit.message}\""
        callback "[#{repo_link}] New commit #{commit_link} by #{pusher.name}"
      else if commits.length > 1
        message = "[#{repo_link}] #{pusher.name} pushed #{commits.length} commits:"
        for commit in commits
          commit_link = formatUrl adapter, commit.url, "\"#{commit.message}\""
          message += "\n#{commit_link}"
        callback message

  # Org level event
  repository: (data, callback, adapter) ->
    repo = data.repository
    org = data.organization
    action = data.action

    callback "#{repo.full_name} #{action}"

  release: (data, callback, adapter) ->
    release = data.release
    repo = data.repository
    repo_link = formatUrl adapter, repo.html_url, repo.name
    action = data.action

    callback "[#{repo_link}] Release #{release.tag_name} #{action}"

  # No clue what to do with this one.
  status: (data, callback, adapter) ->
    commit = data.commit
    state = data.state
    branches = data.branches
    repo = data.repository

    callback ""

  watch: (data, callback, adapter) ->
    repo = data.repository
    sender = data.sender

    callback "#{repo.full_name} is now being watched by #{sender.login}"
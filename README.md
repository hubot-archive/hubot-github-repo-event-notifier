# Hubot: hubot-github-repo-event-notifier

Notifies about any available GitHub repo event via webhook.

See [`src/github-repo-event-notifier.coffee`](src/github-repo-event-notifier.coffee) for full documentation.

[NPM package on npmjs.org](https://www.npmjs.org/package/hubot-github-repo-event-notifier)

## Installation

Add **hubot-github-repo-event-notifier** to your `package.json` file:

```json
"dependencies": {
  "hubot": ">= 2.5.1",
  "hubot-scripts": ">= 2.4.2",
  "hubot-github-repo-event-notifier": ">= 0.0.0",
  "hubot-hipchat": "~2.5.1-5",
}
```

You can also run `npm install hubot-github-repo-event-notifier --save` to have npm do this for you.

Add **hubot-github-repo-event-notifier** to your `external-scripts.json`:

```json
["hubot-github-repo-event-notifier"]
```

Run `npm install`

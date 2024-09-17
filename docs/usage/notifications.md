# Notifications

Much of the functionality of StackHPC Release Train is built around GitHub Actions workflows.
Some of these are triggered automatically based on an event such as pushing to a branch in a GitHub repository.
Others are triggered manually, such as using a "workflow dispatch" from GitHub's web UI or API.

Failure of a manually triggered workflow will result in an email being sent to the user who triggered the workflow.
Failure of an automatically triggered workflow will result in an email being sent to the user who *created* the workflow file.
This is not ideal, and makes that person a bottleneck and single point of failure.
To make failures of automatically triggered workflows more visible, notifications are sent to the `#release-train-alerts` Slack channel.

These notifications are implemented in the [slack-alert](https://github.com/stackhpc/stackhpc-release-train/tree/main/.github/actions/slack-alert/) GitHub action.
The `slack-alert` action uses the "workflow builder" approach described in [slack-github-action](https://github.com/slackapi/slack-github-action/).
Slack's [workflow builder](https://slack.com/intl/en-gb/help/articles/360035692513-Guide-to-Slack-Workflow-Builder) feature allows for flexible integration of Slack with various other services, based on various events.
The [Release train status](https://slack.com/shortcuts/Ft07L987AQ91/1f20fd53512385abf199c9357071cb02) workflow has a webhook URL event trigger, with a single action that sends a message to the `#release-train-alerts` Slack channel.
The Slack webhook URL is set in the `SLACK_WEBHOOK_URL` GitHub Actions secret, and the `#release-train-alerts` channel ID is set in the `SLACK_CHANNEL_ID` GitHub Actions variable.

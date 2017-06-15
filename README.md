# lita-slack-status

## Installation

Add lita-slack-status to your Lita instance's Gemfile:

``` ruby
gem "lita-slack-status"
```

## Configuration

```ruby
Lita.configure do |config|
  # admin token are require to update users profile
  # https://api.slack.com/custom-integrations/legacy-tokens
  config.handlers.slack_status.admin_slack_token = ENV["ADMIN_SLACK_TOKEN"]
end

```

## Usage

```
status save foo :sushi: eating sushi
status set foo
status list
```

OR

```
sss foo :sushi: eating sushi
ss foo
sl
```

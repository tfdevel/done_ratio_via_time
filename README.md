# Done ratio over time

## About

The plugin adds ability to calculate "% Done" field automatically. The field is calculated as percent of spent time from estimated. The plugin supports ability to calculate completeness based on child tasks. Also, plugin adds special type of references “Take time of” and “Time is taken in” that can be used.
There are 3 levels at which can be configured how to calculate “% Done”:
1.	Redmine level.
2.	Project level.
3.	Task level.

## Supported languages

English
Русский

## Requirements

Redmine 3 (tested 3.4.2)


## Installation

```bash
git clone https://github.com/tfdevel/done_ratio_via_time.git {REDMINE_FOLDER}/plugins/done_ratio_via_time
```

Install Redis (for ubuntu: apt-get install redis-server)
Go to {REDMINE_FOLDER} and execute:

```bash
bundle install 
```

Install and launch sidekiq service, more on https://github.com/mperham/sidekiq/tree/master/examples

Execute from plugin folder:

```bash
RAILS_ENV=production bundle exec rake redmine:plugins:migrate
```

## How to uninstall

Execute from plugin folder:

```bash
bundle exec rake redmine:plugins:migrate NAME=done_ratio_via_time VERSION=0
```

Execute SQL command:

```sql
DELETE FROM settings WHERE settings.name = 'plugin_done_ratio_via_time';
```

Restart Redmine webserver
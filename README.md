# Done ratio over time

## About

This plugin allows to compute issue done ratio via estimated/spent time ratio.

**Goal**

The plugin is useful if you use real work hours for estimated efforts and accurately register spent efforts in hours. In this case estimated and spent hours ratio could show almost real progress of work. And you don’t need to keep it in mind or use Excel to get information of real progress and to show it to a customer.

For example, if you have estimated work for 40 h and you have already spent 20 h and you have not met any hidden problems and still believe that rest of work would take for 20 h then you are at a middle of work (50% done ratio). If you have found hidden obstacle for implementing this task and now you think that you need 80 h total, then you should set new estimation and issue done ration would be 25%. For automating such cases this plugin was developed.
 
## Features
1. Different computing modes:
  * only this issue - done ration will be calculated using hours (Spnt/Est) from exactly this issue;
  * subtasks - hours from all subtask tree will be used;
  * linked - hours from linked with special relations tasks will be used;
  * this and subtask - this issue and all subtask tree hours;
  * manual - done ratio could be any value defined by user. But if such issue is in tree then estimated and spent values of this issue will be used as usual independently to what user set for done ratio. This is trick mode for case when you need to show to customer good progress but you know that in real life progress is not so good.
  * all – hours from current task all subtasks and specially linked tasks are used. When done ratio is being calculated over the tree the plugin goes through entire tree till the leaf issues (no subsequent issues or issue has “only this” mode). It takes estimated hours, spent hours and dividing Spnt/Est. But if issue has no estimated value then it will not be taken into calculation (done ration undefined for this issue) but all other issues (below and above the tree) with estimated value will be used.
2. Two ways to combine issues for getting overall progress for large task:
  * Subtasks.
  * Specially added new link type - “Take time from”/“Time is taken in”.
3. Prohibit overspent feature. This is helpful if you need to prevent case when spent time is bigger than estimated. If turn this mode ON users will not be able to spend time until change estimated value. And thus, you can control overspending.
4. Full integration with issues, filters, operation plan, Gantt chart. You could use bulk changes to set calculating mode, get overspent issues
5. Global settings allowing small customization. You could set global default computing mode and restrict issue type for which manual mode is applicable and turn on/off prohibit overspend mode. Also if you change default value for computing mode it goes through entire database and update issue dune ration according to new mode (so it will take time for large DB).
6. Per project appliance. You could customize plugin settings in each project.

**Be careful** after you usage of this plugin you will not be able to return issue done ratio  to values which they have before this plugin

## Supported languages

* English
* Русский

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
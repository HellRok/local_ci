<h1 align="center">LocalCI</h1>
<h4 align="center">Run your CI suite locally</h4>

![Gem Version](https://img.shields.io/gem/v/local_ci)
![Total Gem Downloads](https://img.shields.io/gem/dt/local_ci)


LocalCI is a tool for running your [Continuous
Integration](https://en.wikipedia.org/wiki/Continuous_integration) (CI) both
locally and on CI platforms.

## Usage Locally

If you don't have a `Gemfile` you should run `bundle init` before running
`bundle add local_ci --group development,testing --source https://rubygems.org`.

In your `Rakefile` add the following:
```ruby
require "local_ci"

LocalCI::Rake.setup(self)

setup do
  job "Run before everything", "echo 'Run before everything'"
end

teardown do
  job "Run after everything", "echo 'Run after everything'"
end

flow "Example flow" do
  setup do
    job "Run before everything in this flow" do
      run "echo 'Run before everything in this flow'"
    end
  end

  teardown do
    job "Run after everything in this flow" do
      run "echo 'Run after everything in this flow'"
    end
  end

  job "Some Job" do
    run "echo 'do something here'"
  end

  job "Some Other Job" do
    run "echo 'do something here'"
  end
end
```

Test it by running `bunde exec rake ci` and you should see output similar to
this.

![Example output from bundle exec rake ci](/docs/assets/example_output.png)

## Usage on CI Platforms

### Buildkite

[![Build status][buildkite_status]][buildkite]

In your Buildkite project settings, go to the "Steps" and define the "YAML
Steps" like this:

```yaml
steps:
  - label: ":pipeline: Pipeline upload"
    commands:
      - bundle check &> /dev/null || bundle install
      - bundle exec rake ci:generate:buildkite
      - bundle exec rake ci:generate:buildkite | buildkite-agent pipeline upload
```

This will automatically generate a [Buildkite pipeline][buildkite_pipeline] for
you from your `Rakefile`.

### SemaphoreCI

[![Semaphore CI 2.0 Build Status][semaphore_status]][semaphore]

In your project run `bundle exec rake ci:generate:semaphore_ci`, this will
create a `.semaphore/semaphore.yml` file for you.

> [!WARNING]
> You will need to keep this is sync with your `Rakefile`. I recommend setting
> up a pre-push [git hook][git_hook] that checks to see if the file has changed.

```ruby
task "pre-push:semaphore:check" => "ci:generate:semaphore_ci"
task "pre-push:semaphore:check" do
  puts "=== Checking there would be no changes to `.semaphore/semaphore.yml` ==="
  sh "git diff -s --exit-code .semaphore/semaphore.yml"
  puts "[✓] No changes"
rescue RuntimeError
  puts "[x] Changes detected, check `git diff`"
end
```

[buildkite]: https://buildkite.com/oequacki/localci
[buildkite_status]: https://badge.buildkite.com/a184641ab60b84243268370f04177defcb34cfa009c7419041.svg?branch=main
[buildkite_pipeline]: https://buildkite.com/docs/pipelines/configure/defining-steps
[semaphore]: https://localci.semaphoreci.com/projects/local_ci
[semaphore_status]: https://localci.semaphoreci.com/badges/local_ci/branches/main.svg?style=shields
[git_hook]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks

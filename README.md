# DdMonitor.Cli

This would be a cli to manage Datadog monitors. Main purpose is to use this as
part of deploy pipeline where you could set monitor downtime to prevent
false alarms.

## Status

This is still a work in progress.

## Requirement

1. Erlang VM

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dd_monitor_cli` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dd_monitor_cli, "~> 0.1.0"}
  ]
end
```

## Usage

```bash
$ ./dd-monitor --action list-all    
$ ./dd-monitor --action get-monitor --tags <query_param>
$ ./dd-monitor --action get-monitor --tags localhost
$ ./dd-monitor --action get-monitor-id --tags "test tag:env:test"
$ ./dd-monitor --action get-monitor --tags "tag:env:staging tag:roles:myrole localhost"
$ end="$((`date +%s`+3600))"    
$ ./dd-monitor --action set-monitor-downtime --tags "env:staging owner:me" --scope "roles:myrole process:sshd" --end $d
$ ./dd-monitor --action set-monitor-downtime --tags "env:staging owner:me" --scope "roles:myrole process:sshd" --end $d --mesage "make release"
$ ./dd-monitor --action cancel-monitor-downtime --scope "roles:myrole process:sshd" 
```

## TBD:

1. Add tests
2. DRY

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dd_monitor_cli](https://hexdocs.pm/dd_monitor_cli).


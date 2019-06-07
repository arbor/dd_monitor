# DdMonitor.Cli

This would be a cli to manage Datadog monitors. Main purpose is to use this as
part of deploy pipeline where you could set monitor downtime to prevent
false alarms.

## Status

This is still a work in progress.

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
$ ./dd_monitor --action list-all    
$ ./dd_monitor --action get-monitor <query_param>
$ ./dd_monitor --action get-monitor test
$ ./dd_monitor --action get-monitor-id "test" "tag:env:test"
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dd_monitor_cli](https://hexdocs.pm/dd_monitor_cli).


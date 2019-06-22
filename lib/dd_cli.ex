defmodule DdMonitor.CLI do
  @moduledoc """
  Documentation for DdMonitor.Cli.
  """

  alias Ddog.Monitor
  alias Ddog.Helper

  @doc """
  start

  ## Examples

      iex> ./dd_monitor
      The simulator supports following commands:

      --action get-monitr tag:env:staging - get a monitor by query tag
      --action list-all - list all monitors

  """
  def main(args) do
    args |> parse_args |> process
  end

  def parse_args(args) do
    options = %{:action => nil, :tags => nil, :scope => nil, :end => nil, :message => nil}

    {opts, args} =
      OptionParser.parse_head!(args,
        strict: [action: :string, tags: :string, scope: :string, end: :string, message: :string]
      )

    {Enum.into(opts, options), args}
  end

  @commands %{
    "--action list-all" => "list all monitors",
    "--action get-monitor --tags \"tag:env:staging\" \"name\"" =>
      "get monitor details by query tag",
    "--action get-monitor-id --tags \"tag:env:test\" \"name\"" => "get a monitor id by query tag",
    "--action set-monitor-downtime --scope dev --tags \"tag:env:test\" \"name\" --end <POSIX_TIMESTAMP> --message \"run deployment\"" =>
      "set monitor downtime by tag, scope, message and time end POSIX timestamp",
    "--action cancel-monitor-downtime --scope dev" => "cancel monitor downtime by scope"
  }

  defp print_help_message do
    IO.puts("\nThe simulator supports following commands:\n")

    @commands
    |> Enum.map(fn {command, description} -> IO.puts("  #{command} - #{description}") end)
  end

  def process({options, _}) do
    IO.inspect(options)

    cond do
      Map.get(options, :action) == "list-all" ->
        list_all_monitors()
        |> Helper.prettify()
        |> IO.puts()

      Map.get(options, :action) == "get-monitor" ->
        # TODO: DRY below block
        tags =
          case Map.get(options, :tags) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :tags))
          end

        get_monitor(%{
          query: Helper.build_query(tags)
        })
        |> Helper.prettify()
        |> IO.puts()

      Map.get(options, :action) == "get-monitor-id" ->
        # TODO: DRY below block
        tags =
          case Map.get(options, :tags) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :tags))
          end

        get_monitor(%{
          query: Helper.build_query(tags)
        })
        |> Monitor.get_monitor_details()
        |> Helper.prettify()
        |> IO.puts()

      Map.get(options, :action) == "set-monitor-downtime" ->
        # TODO: DRY below block Map.get blocks
        end_downtime =
          case downtime = Map.get(options, :end) do
            nil ->
              print_help_message()

            _ ->
              downtime
          end

        tags =
          case Map.get(options, :tags) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :tags))
          end

        scope =
          case Map.get(options, :scope) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :scope))
          end

        set_monitor_downtime(%{
          monitor_tags: Helper.build_query(tags),
          scope: scope,
          end: end_downtime,
          message: Map.get(options, :message)
        })
        |> Helper.prettify()
        |> IO.puts()

      Map.get(options, :action) == "cancel-monitor-downtime" ->
        scope =
          case Map.get(options, :scope) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :scope))
          end

        cancel_monitor_downtime(%{
          scope: scope
        })
        |> Helper.prettify()
        |> IO.puts()

      true ->
        print_help_message()
    end
  end

  def list_all_monitors do
    Monitor.call(:list_all)
    |> decode_response
    |> parse!
  end

  def get_monitor(%{query: _query_param} = query) do
    Monitor.call(:search, query)
    |> decode_response
    |> parse!
  end

  #  defp build_monitor_downtime_body(params) do
  def set_monitor_downtime(body) do
    Monitor.call(:set_monitor_downtime, body)
    |> decode_response
    |> parse!
  end

  def cancel_monitor_downtime(body) do
    Monitor.call(:cancel_monitor_downtime_by_scope, body)
    |> decode_response
    |> parse!
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    IO.puts("Error fetching from Datadog: #{error["message"]}")
    System.halt(2)
  end

  defp parse!(body) do
    Poison.decode!(body)
  end
end

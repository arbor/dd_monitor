defmodule DdMonitor.CLI do
  @moduledoc """
  Documentation for DdMonitor.Cli.
  """

  require IEx

  import HTTPoison

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
    options = %{:action => nil, :tags => nil, :scope => nil}

    {opts, args} =
      OptionParser.parse_head!(args,
        strict: [action: :string, tags: :string, scope: :string]
      )

    {Enum.into(opts, options), args}
  end

  @commands %{
    "--action list-all" => "list all monitors",
    "--action get-monitor --tags \"tag:env:staging\" \"name\"" =>
      "get monitor details by query tag",
    "--action get-monitor-id --tags \"tag:env:test\" \"name\"" => "get a monitor id by query tag",
    "--action set-monitor-downtime --scope dev --tags \"tag:env:test\" \"name\"" =>
      "set monitor downtime by tag and scope"
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
        list_all_monitors() |> prettify() |> IO.puts()

      Map.get(options, :action) == "get-monitor" ->
        # TODO: DRY below block
        tags =
          case Map.get(options, :tags) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :tags))
          end

        get_monitor(%{
          query: build_query(tags)
        })
        |> prettify()
        |> IO.puts()

      Map.get(options, :action) == "get-monitor-id" ->
        # TODO: DRY below block
        tags =
          case Map.get(options, :tags) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :tags))
          end

        get_monitor(%{
          query: build_query(tags)
        })
        |> get_monitor_id()
        |> prettify()
        |> IO.puts()

      Map.get(options, :action) == "set-monitor-downtime" ->
        # TODO: DRY below block Map.get blocks
        tags =
          case Map.get(options, :tags) do
            nil -> ""
            _ -> OptionParser.split(Map.get(options, :tags))
          end

        scope =
          case Map.get(options, :scope) do
            nil ->
              ""

            _ ->
              OptionParser.split(Map.get(options, :scope))
          end

        set_monitor_downtime(%{
          query: build_query(tags),
          scope: scope
        })
        |> IO.puts()

      true ->
        print_help_message()
    end
  end

  def headers do
    headers = [{"Content-type", "application/json"}]
    headers
  end

  def api_key do
    api_key = System.get_env("DATADOG_API_KEY") || raise("ENV variable not set: DATADOG_API_KEY")
    api_key
  end

  def app_key do
    app_key = System.get_env("DATADOG_APP_KEY") || raise("ENV variable not set: DATADOG_APP_KEY")
    app_key
  end

  def auth do
    %{"api_key" => api_key(), "application_key" => app_key()}
  end

  def base_url(uri, query_params = %{query: _param}) do
    search_url = "/api/v1/monitor/" <> uri
    URI.merge(base_url(), search_url) |> to_string |> build_monitor_url(query_params)
  end

  defp build_monitor_url(url, query_params) do
    "#{url}?#{build_uri(query_params)}"
  end

  def base_url(action) when action == "downtime" do
    "https://api.datadoghq.com/api/v1/downtime"
  end

  def base_url do
    "https://api.datadoghq.com/api/v1/monitor"
  end

  def build_uri(uri) do
    auth()
    |> Enum.into(uri)
    |> URI.encode_query()
  end

  def build_uri() do
    auth()
    |> Enum.into(%{})
    |> URI.encode_query()
  end

  def build_request(params, body \\ %{}) do
    %HTTPoison.Request{
      method: params.method,
      headers: headers(),
      url: params.url(),
      body: body |> Poison.encode!()
    }
  end

  # This accepts list of tags passed and returns a
  # Datadog search query format of "tag1 tag2 tag3"
  defp build_query(param) when is_list(param) do
    param
    |> Enum.reduce(fn x, acc -> "#{x} #{acc}" end)
  end

  @doc """
  list_all_monitors

  ## Examples

      iex> list_all_monitors()
      [
        %{
        "created" => "2014-11-06T18:22:10.544515+00:00",
        "created_at" => 1415298130000,
        "creator" => %{
          "email" => "test@example.com",
          "handle" => "test@example.com",
          "id" => 1,
          "name" => "Test User"
        },
        "deleted" => nil,
        "id" => 1,
        "matching_downtimes" => [],
        "message" => "test message",
        "modified" => "2018-02-15T14:31:43.167965+00:00",
        "multi" => false,
        "name" => "check mem (< 2GB)",
        "options" => %{
          "escalation_message" => nil,
          "no_data_timeframe" => 30,
          "notify_audit" => true,
          "notify_no_data" => true,
          "renotify_interval" => 0,
          "silenced" => %{},
          "timeout_h" => 0
        },
        "org_id" => 123,
        "overall_state" => "OK",
        "overall_state_modified" => "2019-05-16T13:32:27.582211+00:00",
        "query" => "avg(last_15m):avg:system.mem.free{host:localhost} < 1",
        "tags" => [],
        "type" => "metric alert"
        }
      ]
  """

  def list_all_monitors() do
    # TODO: Move below to another function
    url = base_url() <> "?" <> build_uri()

    req =
      build_request(%{
        method: :get,
        headers: headers(),
        url: url
      })

    {:ok, %{status_code: _status_code, body: body}} = request(req)
    body |> parse!
  end

  @doc """
  get_monitory(%{query: params})

  ## Examples


      iex> get_monitor(%{query: "tag:\"env:test\" name"})
      %{
        "counts" => %{
          "muted" => [%{"count" => 14, "name" => false}],
          "status" => [%{"count" => 14, "name" => "OK"}],
          "tag" => [
            %{"count" => 14, "name" => "env:test"},
            %{"count" => 13, "name" => "account:test"},
          ],
          "type" => [
            %{"count" => 6, "name" => "integration"},
            %{"count" => 4, "name" => "process"},
            %{"count" => 2, "name" => "host"},
            %{"count" => 1, "name" => "event"},
            %{"count" => 1, "name" => "metric"}
          ]
        },
        "metadata" => %{
          "page" => 0,
          "page_count" => 14,
          "per_page" => 30,
          "total_count" => 14
        },
        "monitors" => [
          %{
            "classification" => "integration",
            "creator" => %{
              "handle" => "test@example.com",
              "id" => 52,
              "name" => "Test User"
            },
            "id" => 80,
            "last_triggered_ts" => 1559714659,
            "metrics" => ["nginx.net.conn_dropped_per_s"],
            "name" => "[name test]",
            "notifications" => [%{"handle" => "test", "name" => "test"}],
            "org_id" => 1,
            "overall_state_modified" => 1559797460,
            "scopes" => ["roles:name", "test"],
            "status" => "OK",
            "tags" => ["type:infrastructure", "env:test",
             "roles:name", "account:test",
             "monitor_id:nginx_dropped_connections", "env:test"],
            "type" => "metric alert"
          },
          ...
      }
  """
  def get_monitor(%{query: _query_param} = query) do
    url = base_url("search", query)

    req =
      build_request(%{
        method: :get,
        headers: headers(),
        url: url
      })

    {:ok, %{status_code: _status_code, body: body}} = request(req)
    body |> parse!
  end

  def get_monitor(%{query: _query_param} = query) do
    url = base_url("downtime")

    req =
      build_request(%{
        method: :post,
        headers: headers(),
        url: url
      })
  end

  defp parse!(body) do
    Poison.decode!(body)
  end

  defp prettify(monitors) when is_list(monitors) do
    Poison.encode!(%{monitors: monitors}, pretty: true)
  end

  defp prettify(monitor) when is_map(monitor) do
    Poison.encode!(%{monitor: monitor}, pretty: true)
  end

  defp get_monitor_id(%{"monitors" => monitors}) do
    monitors
    |> List.flatten()
    |> Enum.map(
      &%{
        id: &1["id"],
        name: &1["name"],
        metrics: &1["metrics"],
        status: &1["status"],
        tags: &1["tags"]
      }
    )
  end

  #  defp build_monitor_downtime_body(params) do
  def set_monitor_downtime(params) do
    IO.puts(params |> Poison.encode!())
    # Time.add(now, 60)
    #    %{
    #    scope: "env:prod",
    #    start: '"${start}"',
    #    end: '"${end}"'
    #    }
  end
end

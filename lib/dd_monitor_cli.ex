defmodule DdMonitorCli do
  @moduledoc """
  Documentation for DdMonitorCli.
  """

  require IEx

  import HTTPoison

  @doc """
  start

  ## Examples

      iex> start
      :response

  """

  def start do
    IEx.pry()
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
    url = URI.merge(base_url(), search_url) |> to_string
    # TODO: Move below to another function
    url <> "?" <> build_uri(query_params)
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

  def build_request(params) do
    %HTTPoison.Request{
      method: params.method,
      headers: headers(),
      url: params.url()
    }
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

  def parse!(body) do
    Poison.decode!(body)
  end
end

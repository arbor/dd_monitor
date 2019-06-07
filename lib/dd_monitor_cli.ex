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

  defp headers do
    headers = [{"Content-type", "application/json"}]
    headers
  end

  defp api_key do
    api_key = System.get_env("DATADOG_API_KEY") || raise("ENV variable not set: DATADOG_API_KEY")
    api_key
  end

  defp app_key do
    app_key = System.get_env("DATADOG_APP_KEY") || raise("ENV variable not set: DATADOG_APP_KEY")
    app_key
  end

  defp auth do
    Poison.encode!(%{"api_key" => api_key(), "application_key" => app_key()})
  end

  defp monitor_url do
    "https://api.datadoghq.com/api/v1/monitor?api_key=#{api_key()}&application_key=#{app_key()}"
  end

  defp query(search_param \\ %{}) do
    "https://api.datadoghq.com/api/v1/monitor/search?api_key=#{api_key()}&application_key=#{
      app_key()
    }&query=${query}"
  end

  def build_request(params) do
    %HTTPoison.Request{
      method: params.method,
      headers: headers(),
      url: params.url(),
      body: params.body()
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
    req =
      build_request(%{
        method: :get,
        headers: headers(),
        url: monitor_url(),
        body: auth()
      })

    {:ok, %{status_code: _status_code, body: body}} = request(req)
    Poison.decode!(body)
  end
end

defmodule WhoOwnsWhat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    WhoOwnsWhat.Release.migrate()

    children = [
      # Start the Telemetry supervisor
      WhoOwnsWhatWeb.Telemetry,
      # Start the Ecto repository
      WhoOwnsWhat.Repo,
      {WhoOwnsWhat.Application.Worker, restart: :temporary},
      # Start the PubSub system
      {Phoenix.PubSub, name: WhoOwnsWhat.PubSub},
      # Start Finch
      {Finch, name: WhoOwnsWhat.Finch},
      # Start the Endpoint (http/https)
      WhoOwnsWhatWeb.Endpoint
      # Start a worker by calling: WhoOwnsWhat.Worker.start_link(arg)
      # {WhoOwnsWhat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WhoOwnsWhat.Supervisor]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WhoOwnsWhatWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defmodule Worker do
    use Task

    def start_link(arg) do
      Task.start_link(__MODULE__, :run, [arg])
    end

    def run(_arg) do
      if Application.get_env(:who_owns_what, :preload_data) do
        WhoOwnsWhat.Data.Import.properties("./data/mprop.csv.gz")
        WhoOwnsWhat.Data.Import.ownership_groups("./data/parcels_ownership_groups.csv.gz")
        WhoOwnsWhat.Data.Import.properties_fts()
      end
    end
  end
end

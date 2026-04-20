defmodule WhoOwnsWhatWeb.Router do
  use WhoOwnsWhatWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WhoOwnsWhatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  scope "/", WhoOwnsWhatWeb do
    pipe_through :browser

    live "/", HomeLive.Index, :index
    live "/about", HomeLive.About, :about
    live "/properties", PropertyLive.Index, :index
    live "/properties/:id", PropertyLive.Show, :show
    live "/owner_groups", OwnerGroupLive.Index, :index
    live "/owner_groups/:id", OwnerGroupLive.Show, :show
    get "/owner_groups/:id/csv", PageController, :owner_groups_csv
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:who_owns_what, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WhoOwnsWhatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  else
    scope "/admin" do
      pipe_through [:browser, :admins_only]
      live_dashboard "/dashboard", metrics: WhoOwnsWhatWeb.Telemetry
    end
  end

  defp admin_basic_auth(conn, _opts) do
    username = Application.fetch_env!(:who_owns_what, :admin_username)
    password = Application.fetch_env!(:who_owns_what, :admin_password)
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end

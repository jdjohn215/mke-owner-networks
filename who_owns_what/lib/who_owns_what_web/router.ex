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
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WhoOwnsWhatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  else
    if System.get_env("AUTH_USERNAME") && System.get_env("AUTH_PASSWORD") do
      scope "/admin" do
        pipe_through [:browser, :admins_only]
        live_dashboard "/dashboard"
      end
    end
  end

  defp admin_basic_auth(conn, _opts) do
    username = System.fetch_env!("AUTH_USERNAME")
    password = System.fetch_env!("AUTH_PASSWORD")
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end

defmodule WhoOwnsWhat.Repo do
  use Ecto.Repo,
    otp_app: :who_owns_what,
    adapter: Ecto.Adapters.SQLite3
end

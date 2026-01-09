defmodule MortalDrinksElixir.WebInterface do
  @moduledoc """
  Embedd phoenix WebUI with only several modules here.
  """

  defmodule Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
      plug(:put_root_layout, {MortalDrinksElixir.WebInterface.Scaffold, :live})
    end

    scope "/" do
      pipe_through(:browser)
      live("/", MortalDrinksElixir.WebInterface.DashboardLive)
    end
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :mord_ex

    socket("/live", Phoenix.LiveView.Socket)

    # When static resource is too large
    plug(Plug.Static, from: {:mord_ex, "/priv/static"}, at: "/", only: ~w(assets))

    plug(Plug.Session,
      store: :cookie,
      key: "_mortal_drinks_key",
      signing_salt: "SECRET_SALT_CHANGE_ME_PLEASE"
    )

    if code_reloading? do
      socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
      plug(Phoenix.LiveReloader)
      plug(Phoenix.CodeReloader)
    end

    plug(Router)
  end

  defmodule ErrorHTML do
    def render(template, _assigns) do
      Phoenix.Controller.status_message_from_template(template)
    end
  end
end

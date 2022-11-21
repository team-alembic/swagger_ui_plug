defmodule SwaggerUI.Plug do
  # Elixir code based on https://github.com/open-api-spex/open_api_spex/blob/master/lib/open_api_spex/plug/swagger_ui.ex
  # HTML template from https://github.com/swagger-api/swagger-ui/blob/master/dist/index.html

  @moduledoc """
  Module plug that serves SwaggerUI.

  The full path to the API spec must be given as a plug option.

  ## Configuring SwaggerUI

  SwaggerUI can be configured through plug `opts`.
  All options will be converted from `snake_case` to `camelCase` and forwarded to the `SwaggerUIBundle` constructor.
  See the [swagger-ui configuration docs](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/) for details.
  Should dynamic configuration be required, the `config_url` option can be set to an API endpoint that will provide additional config.
  """
  @behaviour Plug

  @html """
  <!DOCTYPE html>
  <!-- HTML for static distribution bundle build -->
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title><%= Map.get(config, :title, "Swagger UI") %></title>
      <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.15.5/swagger-ui.css" >
      <style>
        html
        {
          box-sizing: border-box;
          overflow: -moz-scrollbars-vertical;
          overflow-y: scroll;
        }
        *,
        *:before,
        *:after
        {
          box-sizing: inherit;
        }
        body {
          margin:0;
          background: #fafafa;
        }
      </style>
    </head>
    <body>
    <div id="swagger-ui"></div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.15.5/swagger-ui-bundle.js" charset="UTF-8"> </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.15.5/swagger-ui-standalone-preset.js" charset="UTF-8"> </script>
    <script>
    window.onload = function() {
      // Begin Swagger UI call region
      const api_spec_url = new URL(window.location);
      api_spec_url.pathname = "<%= config.path %>";
      api_spec_url.hash = "";
      const ui = SwaggerUIBundle({
        url: api_spec_url.href,
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "StandaloneLayout",
        requestInterceptor: function(request){
          server_base = window.location.protocol + "//" + window.location.host;
          if(request.url.startsWith(server_base)) {
            request.headers["x-csrf-token"] = "<%= csrf_token %>";
          } else {
            delete request.headers["x-csrf-token"];
          }
          return request;
        }
        <%= for {k, v} <- Map.drop(config, [:path, :oauth, :title]) do %>
        , <%= camelize(k) %>: <%= encode_config(camelize(k), v) %>
        <% end %>
      })
      // End Swagger UI call region
      <%= if config[:oauth] do %>
        ui.initOAuth(
          <%= config.oauth
              |> Map.new(fn {k, v} -> {camelize(k), v} end)
              |> Jason.encode!()
          %>
        )
      <% end %>
      window.ui = ui
    }
    </script>
    </body>
    </html>
  """

  @ui_config_methods [
    "operationsSorter",
    "tagsSorter",
    "onComplete",
    "requestInterceptor",
    "responseInterceptor",
    "modelPropertyMacro",
    "parameterMacro",
    "initOAuth",
    "preauthorizeBasic",
    "preauthorizeApiKey"
  ]

  @doc """
  Initializes the plug.

  ## Options

    * `:path` - Required. The URL path to the API definition.
    * `:oauth` - Optional. Config to pass to the `SwaggerUIBundle.initOAuth()` function.
    * `:title` - Optional. Sets the HTML document title
    * all other opts - forwarded to the `SwaggerUIBundle` constructor

  ## Example

      get "/swaggerui", SwaggerUi.Plug,
        path: "/api/openapi",
        default_model_expand_depth: 3,
        display_operation_id: true
  """
  @impl Plug
  def init(opts) when is_list(opts) do
    Map.new(opts)
  end

  @impl Plug
  def call(conn, config) do
    csrf_token = Plug.CSRFProtection.get_csrf_token()
    html = render(config, csrf_token)

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end

  require EEx

  EEx.function_from_string(:defp, :render, @html, [
    :config,
    :csrf_token
  ])

  defp camelize(identifier) do
    identifier
    |> to_string
    |> String.split("_", parts: 2)
    |> case do
      [first] -> first
      [first, rest] -> first <> Macro.camelize(rest)
    end
  end

  defp encode_config("tagsSorter", "alpha" = value) do
    Jason.encode!(value)
  end

  defp encode_config("operationsSorter", value) when value == "alpha" or value == "method" do
    Jason.encode!(value)
  end

  defp encode_config(key, value) do
    case Enum.member?(@ui_config_methods, key) do
      true -> value
      false -> Jason.encode!(value)
    end
  end
end

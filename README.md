# Swagger UI Plug

Serve SwaggerUI from a Plug/Phoenix application.

## Installation

The package can be installed by adding `swagger_ui_plug` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swagger_ui_plug, "~> 1.0"}
  ]
end
```


## Usage

Add a route for `SwaggerUI.Plug` with the path to your OpenAPI spec, and any additional options.

```elixir
  scope "/api" do
    ...
    get "/swaggerui", SwaggerUi.Plug,
      path: "/api/openapi",
      default_model_expand_depth: 3,
      display_operation_id: true
  end
```

See the full docs at <https://hexdocs.pm/swagger_ui_plug>.


## Credits

Thanks to the original contributors to [OpenApiSpex.Plug.SwaggerUI](https://github.com/open-api-spex/open_api_spex/blame/master/lib/open_api_spex/plug/swagger_ui.ex)

@mbuhot, @zorbash, @jonathanhood, @moxley, @m0rt3nlund, @reneweteling, @superhawk610

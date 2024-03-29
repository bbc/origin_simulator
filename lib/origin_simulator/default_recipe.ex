defmodule OriginSimulator.DefaultRecipe do
  alias OriginSimulator.Recipe

  def recipe do
    %Recipe{
      headers: %{
        "cache-control" => "public, max-age=30",
        "content-encoding" => "gzip"
      },
      stages: [
        %{
          "at" => 0,
          "status" => 200,
          "latency" => "100ms"
        }
      ],
      body: default_html_body()
    }
  end

  defp default_html_body do
    ~s"""
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://unpkg.com/@picocss/pico@1.*/css/pico.classless.min.css">
        <title>BBC Origin Simulator - Default Content</title>
      </head>
      <body>
        <main>
          <header>
            <hgroup>
              <h1>BBC Origin Simulator</h1>
              <h2>A tool to simulate a (flaky) upstream origin during load and stress tests.</h2>
            </hgroup>
          </header>
          <hr/>
          <h5>Welcome!</h5>
          <p>This is the default content, just to get you started. <mark>You should create and add your own recipe!</mark></p>
          <p>Here's a basic example, once loaded, it fetches the BBC News front page, stores it in a cache and serves it continuosly with a simulated latency of 100 milliseconds.</p>
            <pre>
              <code>
                {
                  "origin": "https://www.bbc.co.uk/news",
                  "headers": {
                     "cache-control": "public, max-age=30",
                     "content-encoding": "gzip"
                  },
                  "stages": [{"at": 0, "status": 200, "latency": "100ms"}]
                }</code>
            </pre>
          <p>You can read more about Origin Simulator <a href="https://github.com/bbc/origin_simulator">here</a>, but to quickly start adding a recipe run:
            <pre><code>curl -X POST -d @my_recipe.json http://my.origin-simulator.xyz/_admin/add_recipe</code></pre>
          </p>
          <p>
            To see the current recipe use:
            <pre><code>curl http://my.origin-simulator.xyz/_admin/current_recipe</code></pre>
          </p>
          <p>Happy testing!</p>
        </main>
      </body>
    </html>
    """
  end
end

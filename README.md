# OriginSimulator [![Build Status](https://travis-ci.org/bbc/origin_simulator.svg?branch=master)](https://travis-ci.org/bbc/origin_simulator)

A tool to simulate a (flaky) upstream origin during load and stress tests.

In our constant quest to improve our services to be more fault tolerant and handle faulty conditions without nasty surprises, we are trying to make load and stress test more automated and reproducible.

This tool is designed to be a simple helper to simulate an upstream service behaving unexpectedly for a programmable prolonged period of time. We can then use a load test to see how our downstream service react.

OriginSimulator can also be used to simulate continuous responses with a given latency from a fake service.

These are the moving parts of a simple load test:

```
┌────────────────────┐        ┌────────────────────┐        ┌────────────────────┐
│                    ├────────▶                    ├────────▶                    │
│  Load Test Client  │        │       Target       │        │  OriginSimulator   │
│                    ◀────────┤                    ◀────────┤                    │
└────────────────────┘        └────────────────────┘        └────────────────────┘
```

Where:
* A **Load Test Client**, could be a tool like [WRK2](https://github.com/giltene/wrk2), [AB](https://httpd.apache.org/docs/2.4/programs/ab.html) or [Vegeta](https://github.com/tsenart/vegeta).
* The load test **Target** is the service you want to test, such as NGINX, custom app or whatever fetches data from an upstream source.
* **OriginSimulator** can simulate an origin and can be programatically set to behave slow or unstable.

## Scenarios

A JSON recipe defines the different stages of the scenario. This is an example of specifying an origin with stages:

```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        {
            "at": 0,
            "latency": "50ms",
            "status": 404
        },
        {
            "at": "4s",
            "latency": "2s",
            "status": 503
        },
        {
            "at": "6s",
            "latency": "100ms",
            "status": 200
        }
    ]
}
```

Where `at` represents the time points (in milliseconds) for a state mutation, and latency the simulated response time in milliseconds. In this case:

```
  0s                     4s                   6s                  ∞
  *──────────────────────*────────────────────*───────────────────▶

       HTTP 404 50ms           HTTP 503 2s       HTTP 200 100ms
```

The recipe can also be a list of simulation scenarios, as descirbed in [multi-route origin simulation](#multi-route-origin-simulation) below.

```json
[
	{
		"origin": "...",
		"stages": "...",
		..
	},
	{
		"origin": "...",
		"stages": "...",
		..
	},
	{
		"origin": "..",
		"stages": "...",
		..
	}
]
```

## Latency

Any stage defines the simulated latency in ms. Is possible to simulate random latency using an array of values. 
In the example below any response will take a random amount of time within the range 1000..1500:

```json
{
    "random_content": "428kb",
    "stages": [
        {
            "at": 0,
            "latency": "1000ms..1500ms",
            "status": 200
        }
    ]
}
```


## Sources

OriginSimulator can be used in three ways.

* Serving cached content from an origin.

```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        {
            "at": 0,
            "latency": "100ms",
            "status": 200
        }
    ]
}
```

* Serving random sized content.

In this example we are requiring a continuous successful response with no simulated latency, returning a 428kb payload

```json
{
    "random_content": "428kb",
    "stages": [
        {
            "at": 0,
            "latency": "100ms",
            "status": 200
        }
    ]
}
```

* Serving content posted to it.

In this example content is posted along with the recipe. Where the payload body section can be any content such as HTML or JSON.

```json
{
    "body": "{\"hello\":\"world\"}",
    "stages": [
        {
            "at": 0,
            "latency": "100ms",
            "status": 200
        }
    ]
}
```

It's also possible to define random content inside the posted body. This can be useful to
simulate JSON contracts, structured text, etc.

```json
{
    "body": "{\"data\":\"<<256kb>>\", \"metadata\":\"<<128b>>and<<16b>>\", \"collection\":[\"<<128kb>>\", \"<<256kb>>\"]}\"}",
    "stages": [
        {
            "at": 0,
            "latency": "100ms",
            "status": 200
        }
    ]
}
```

## Multi-route origin simulation

OriginSimulator can also provide multiple origins simulation. Each origin is specified with a recipe and accessible through a `route` (request path) on the simulator. This is an example of specifying multiple origins with different routes:

```json
[
  {
    "route": "/",
    "origin": "https://www.bbc.co.uk/",
    "stages": [
      {
        "at": 0,
        "status": 200,
        "latency": "100ms"
      }
    ]
  },
  {
    "route": "/news*",
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
      {
        "at": 0,
        "status": 200,
        "latency": 0
      }
    ]
  },
  {
    "route": "/sport",
    "origin": "https://www.bbc.co.uk/sport",
    "stages": [
      {
        "at": 0,
        "status": 200,
        "latency": "1s"
      },
      {
        "at": "5s",
        "status": 200,
        "latency": "100ms"
      }
    ]
  }
]
```

Where `route` is the request path on the simulator from which the corresponding origin can be accessed. A wildcard route may be used to match paths of the same domain, e.g. `/news*` (above) for `/news/business-51443421`. 

The wildcard root route (`/*`) is the default If no route is specified for a scenario.

Multiple origins of mixed sources can also be specified:

```
[
  {
    "route": "/data/api",
    "body": "{\"data\":\"<<256kb>>\", \"metadata\":\"<<128b>>and<<16b>>\", \"collection\":[\"<<128kb>>\", \"<<256kb>>\"]}\"}",
    "stages": [
        {
            "at": 0,
            "latency": "100ms",
            "status": 200
        }
    ]
  },
  {
    "route": "/news",
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
      {
        "at": 0,
        "status": 404,
        "latency": "50ms"
      },
      {
        "at": "2s",
        "status": 503,
        "latency": "2s"
      },
      {
        "at": "4s",
        "status": 200,
        "latency": "100ms"
      }
    ]
  }
]
```

## Usage

You can post recipes using `curl` and the `mix upload_recipe` task.

First run the Elixir app:
```
$ env MIX_ENV=prod iex -S mix
Erlang/OTP 21 [erts-10.1.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

Interactive Elixir (1.7.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

The app is now ready, but still waiting for a recipe:
```shell
$ curl http://127.0.0.1:8080/current_recipe
"Recipe not set, please POST a recipe to /add_recipe"⏎

$ curl -i http://127.0.0.1:8080/
HTTP/1.1 406 Not Acceptable
cache-control: max-age=0, private, must-revalidate
content-length: 2
content-type: text/plain; charset=utf-8
date: Sat, 12 Jan 2019 23:18:10 GMT
server: Cowboy
```

Let's add a simple recipe:
```shell
$ cat examples/demo.json
{
    "origin": "https://www.bbc.co.uk",
    "stages": [
        { "at": 0,    "status": 200, "latency": "200ms"},
        { "at": "10s", "status": 500, "latency": "500ms"},
        { "at": "30s", "status": 200, "latency": "200ms"}
    ]
}

$ cat examples/demo.json | curl -X POST -d @- http://127.0.0.1:8080/add_recipe
```

All done! Now at different times the server will respond with the indicated HTTP status code and response time:
```
$ curl -i http://127.0.0.1:8080/
HTTP/1.1 404 Not Found
...

$ curl -i http://127.0.0.1:8080/
HTTP/1.1 503 Service Unavailable
...

$ curl -i http://127.0.0.1:8080/
HTTP/1.1 200 OK
...
```

At any time you can reset the scenario by simply POSTing a new one to `/add_recipe`. 

In multiple origins scenario, new origins and routes can be added to the existing ones through `/add_recipe`. Existing scenarios can also be updated. For example you can "take down" an origin by updating its recipe with 500 status.

#### Using `mix upload_recipe`
`mix upload_recipe demo` will upload the recipe located at `examples/demo.json` to origin simulator running locally.

If you have deployed origin simulator, you can specify the host when uploading the recipe. For example:
`mix upload_recipe "http://origin-simulator.com" demo`

#### Admin routes

* /_admin/status

Check if the simulator is running, return `ok!`

* /_admin/add_recipe

Post (POST) recipe: update or create new origins

* /_admin/current_recipe

List existing recipe for all origins and routes

* /_admin/restart

Reset the simulator: remove all recipes

* /_admin/routes

List all origins and routes

* /_admin/routes_status

List all origin and routes with the corresponding current status and latency values

## Performance

OriginSimulator should be performant, it leverages on the concurrency and parallelism model offered by the Erlang BEAM VM and should sustain significant amount of load.

Our goal was to have performance comparable to Nginx serving static files. To demonstate this, we have run a number of load testsusing Nginx/OpenResty as benchmark. We used [WRK2](https://github.com/giltene/wrk2) as load test tool and ran the tests on AWS EC2 instances.

For the tests we used two EC2 instances. The load test client ran on a c5.2xlarge instance. We tried c5.large,c5.xlarge,c5.2xlarge and i3.xlarge instanses for the Simulator and OpenResty targets. Interestingly the results didn't show major performance improvements with bigger instances, full results are [available here](https://gist.github.com/ettomatic/6d2ad680fc331b942a5f535f76eb9d02). In the next sections we'll use the results against i3.xlarge.

The Nginx/OpenResty configuration is very simple and available [here](confs/openresty.conf). While not perfect, we tried to keep it simple, the number of workers has been updated depending of the instance type used.

#### Successful responses with no additional latency

In this scenario we were looking for maximum throughput. Notice how OpenResty excels on smaller files were results were pretty equal for bigger files.

recipe:
```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0, "status": 200, "latency": "0ms"}
    ]
}
```
*Throughput with 0ms additional latency*

| payload size | OriginSimulator | OpenResty |
|--------------|----------------:|----------:|
| 50kb         |          17,000 |    24,000 |
| 100kb        |          12,000 |    12,000 |
| 200kb        |           6,000 |     6,000 |
| 428kb        |           2,900 |     2,800 |
|              |                 |           |

![No latency char](/gnuplot/throughput_no_latency.png)

#### Successful responses with 100ms additional latency

In this scenario we had almost identical results with 100 concurrent connections, only after 5,000 connections we started seeing Openresty failing down, this is possibly due to misconfiguration.

recipe:
```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0, "status": 200, "latency": "100ms"}
    ]
}
```

*payload 428kb 100ms added latency*

| concurrent connections | throughput | OriginSimulator |  OpenResty |
|-----------------------:|-----------:|-----------------|-----------:|
|                    100 |        900 | 104.10ms        |   101.46ms |
|                  1,000 |      1,000 | 214.73ms        |   225.70ms |
|                  3,000 |      2,000 | 220.50ms        | 244.30ms * |
|                  5,000 |      1,400 | 161.81ms        | 397.67ms * |
|                 10,000 |      2,000 | 168.18ms        | 384.92ms * |

> **NOTE:** * OpenResty started increasingly timing out and 500ing after 3K
concurrent requests.

![100ms latency chart](/gnuplot/response_time_100ms_latency.png)

#### Successful responses with 1s additional latency

With 1s of latency we could see any difference in terms of performance.

recipe
```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0, "status": 200, "latency": "1s"}
    ]
}
```

*payload 428kb 1s added latency*

| concurrent connections | throughput | OriginSimulator | OpenResty |
|-----------------------:|-----------:|----------------:|----------:|
|                    100 |        100 |           1.03s |     1.02s |
|                    500 |        500 |           1.05s |     1.03s |
|                    600 |        600 |           1.24s |     1.20s |
|                  2,000 |      1,000 |           1.10s |  1.11s ** |
|                  4,000 |      2,000 |         1.09s * |  1.10s ** |

> **NOTE:** * OriginSimulator had a few timeouts at 4K concurrent connections. ** OpenResty started increasingly timing out and 500ing after 2K
concurrent requests.

![100ms latency chart](/gnuplot/response_time_1s_latency.png)

## Load Tests

For details on Load Test results visit the [Load Tests](docs/load-test-results/) results docs.

## Docker

> **NOTE:** if you plan to use OriginSimulator from Docker for Mac via `docker-compose up` you might notice slow response times.
> This is down to [Docker for Mac networking integration with the OS](https://github.com/docker/for-mac/issues/2814), which is still the case in 18.09.0.
>
> So don't use this setup for load tests, and why would you in any case!

### Docker releases

To generate a release targeted for Centos:

``` shell
docker build -t origin_simulator .
docker run --mount=source=/path/to/build,target=/build,type=bind -it origin_simulator
```

You'll find the package in `./build`

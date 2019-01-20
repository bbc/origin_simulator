# OriginSimulator

A tool to simulate a flacky upstream origin during load and stress tests.

Every year, when a big snow day happens, we experience some unexpected slow down in some of our services. In our constant quest to improve our services to be more fault tolerant and handle faulty conditions without nasty surprises, we are trying to make load and stress test mnre automated and reproducible.

This tool is designed to be a simple helper to simulate an upstream service going funny for a programmable prolonged period of time. We can then use a load test to see how our downstream service react.

OriginSimulator could also be used to simply simulate a continuous given latency in a fake service.

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
* The load test **Target** is the app you want to test, Something like NGINX or whatever fetches data from an upstream source.
* **OriginSimulator** fetches the data from the original endpoint, caches it and then acts as a slow and unstable service just having a bad day.

## Scenarios

A JSON recipe defines the different stages of the scenario:

```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        {
            "at": 0,
            "latency": 50,
            "status": 404
        },
        {
            "at": 4000,
            "latency": 2000,
            "status": 503
        },
        {
            "at": 6000,
            "latency": 100,
            "status": 200
        }
    ]
}
```

Where `at` represent the time points (in milliseconds) for a state mutation, and latency the simulated response time in milliseconds. In this case:
```
  0s                     4s                   6s                  ∞
  *──────────────────────*────────────────────*───────────────────▶

       HTTP 404 50ms           HTTP 503 2s       HTTP 200 100ms
```

You can also define **fixed lenght random content**. In this example we are requiring a continuous successful response with no simulated latency, returning a 428kb payload:

```json
{
    "random": 428,
    "stages": [
        { "at": 0, "status": 200, "latency": 0}
    ]
}

```
## Usage

First run the Elixir app:
```
$ env MIX_ENV=prod iex -S mix
Erlang/OTP 21 [erts-10.1.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

Interactive Elixir (1.7.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

The app is now ready, but still waiting for a recipe:
```shell
$ curl http://127.0.0.1:8084/current_recipe
"Not set, please POST a recipe to /add_recipe"⏎

$ curl -i http://127.0.0.1:8084/
HTTP/1.1 406 Not Acceptable
cache-control: max-age=0, private, must-revalidate
content-length: 2
content-type: text/plain; charset=utf-8
date: Sat, 12 Jan 2019 23:18:10 GMT
server: Cowboy
```

Let's add a simple recipe:
```shell
$ cat examples/sample_recipe.json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0,    "status": 404, "latency": 50},
        { "at": 4000, "status": 503, "latency": 2000},
        { "at": 9000, "status": 200, "latency": 100}
    ]
}

$ cat examples/sample_recipe.json | curl -X POST -d @- http://127.0.0.1:8084/add_recipe
```

All done! Now at different times the server will respond with the indicated HTTP status code and response time:
```
$ curl -i http://127.0.0.1:8084/
HTTP/1.1 404 Not Found
...

$ curl -i http://127.0.0.1:8084/
HTTP/1.1 503 Service Unavailable
...

$ curl -i http://127.0.0.1:8084/
HTTP/1.1 200 OK
...
```

At any time you can reset the scenario by simply POSTing a new one to `/add_recipe`.

## Performance

OriginSimulator should be performant, it leverages on the concurrency and parallelism model offered by the Erlang BEAM VM and should sustain significant amount of load.

To demonstate this, we have run a number of load testsusing Nginx/OpenResty as benchmark. We used [WRK2](https://github.com/giltene/wrk2) as load test tool and ran the tests on AWS EC2 instances.

For the tests we used two EC2 instances. The load test client ran on a c5.2xlarge instance. We tried c5.large,c5.xlarge,c5.2xlarge and i3.xlarge instanses for the Simulator and OpenResty targets. Interestingly the results didn't show major performance improvements with bigger instances, full results are [available here](https://gist.github.com/ettomatic/6d2ad680fc331b942a5f535f76eb9d02). In the next sections we'll use the results against i3.xlarge.

#### Successful responses with no additional latency

In this scenario we were looking for maximum throughput. Notice how Opernresty excels on smaller files were results were pretty equal for bigger files.

recipe:
```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0, "status": 200, "latency": 0}
    ]
}
```
*Throughput with 0ms additional latency*

|payload size|OriginSimulator|OpenResty|
|---|---:|---:|
|50kb|17,000|24,000|
|100kb|12,000|12,000|
|200kb|6,000|6,000|
|428kb|2,900|2,800|

<img src="/img/throughput_no_latency.png" width="500" alt="No latency chart">


#### Successful responses with 100ms additional latency

In this scenario we had almost identical results with 100 concurrent connections, only after 5,000 connections we started seeing Openresty failing down, this is possibly due to misconfiguration.

recipe:
```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0, "status": 200, "latency": 100}
    ]
}
```

*payload 428kb 100ms added latency*

|concurrent connections|throughput|OriginSimulator|OpenResty|
|---:|---:|---:|---:|
|100|900|104.10|101.46|
|1,000|1,000|214.73|225.70|
|5,000|5,000|161.81|755.43|

<img src="/img/response_time_100ms_latency.png" width="500" alt="100ms latency chart">

#### Successful responses with 1s additional latency

With 1s of latency we could see any difference in terms of performance.

recipe
```json
{
    "origin": "https://www.bbc.co.uk/news",
    "stages": [
        { "at": 0, "status": 200, "latency": 1000}
    ]
}
```

*payload 428kb 1s added latency*

|concurrent connections|throughput|OriginSimulator|OpenResty|
|---:|---:|---:|---:|
|100|100|1.03|1.02|
|500|500|1.05|1.03|
|600|600|-|1.20|


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

You'll find the package in `/build`

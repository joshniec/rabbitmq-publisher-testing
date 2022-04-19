# rabbitmq-publisher-testing

A simple local docker environment for benchmarking publishing messages to a RabbitMQ cluster.

This docker compose environment creates a local 3 node cluster exposing the management dashboard on localhost:15672.

HAProxy is used as a frontend load balancer for the 3 node RabbitMQ cluster backend.

## Requirements

- Bunny ruby gem
- Docker

## Starting Docker Environment

```bash
# start docker compose environment
$ docker compose up -d
# verify docker containers are running
$ docker ps
```

## Benchmark Script

In `./scripts/client_publisher_confirms.rb`

A sample benchmarking script is provided. This script benchmarks the time it would take to publish messages to a RabbitMQ cluster (fronted by HAProxy) using two methods:

- "fire and forget", just publish the message. If it gets lost the client will never know
- "publisher confirms", publish the message, the cluster will confirm back to the client when the message has been mirrored and written to disk on other nodes in the cluster.

Times reported by ruby's `Benchmark` module are:

- user: user CPU time (time spent executing code)
- system: system CPU time (time spent in the kernel)
- total: both user and system CPU time added together
- real: actual time (wall clock) it took to execute the code

### Example Invocation

```bash
❯ ruby scripts/client_publisher_confirms.rb
       user     system      total        real
publish_noconfirm  5.553742   1.730238   7.283980 (  7.286267)
publisher_confirms  7.428271   1.914889   9.343160 (  9.332591)
```

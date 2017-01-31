Intro
=====

Write a simple web crawler.

Spec
====

- Crawler is limited to one domain. E.g. when crawling example.com it crawls all pages within the domain, but not external links, for example to the Facebook and Twitter accounts.
- Given a URL, it outputs a site map, showing which static assets each page depends on, and the links between pages.
- Write it as you would a production piece of code.
- Bonus points for tests and making it as fast as possible!

Architecture
============

1. URL Frontier Queue (Apache Kafka)
2. Fetch module (worker.rb)
3. Parse module (page.rb)
4. Sitemap store (Redis)

This crawler uses Apache Kafka as a messaging queue.

An arbitrary number of workers can be attached to the queue, from which URLs are read, crawled and new links inserted at the back of the queue again.

Sitemap data for each page is stored in Redis.

The system is failure-tolerant and guarantees that every URL will be crawled at least once.

If a worker should die while crawling a URL, Kafka's Consumer Groups feature will automatically assign the URL to a new worker. There may be duplicated work but never lost URLs.

Speed and Scalability
=====================

Due to the distributed architecture you can run the workers on as many machines as you like. So the crawler component is as fast as you need it to be.

At very high concurrency levels Redis might conceivably be a bottleneck. It could be replaced by a distributed data store backend such as Cassandra.

Rendering performance has not been optimized at all and might be quite slow for large sites.

Installation
============

Requirements:

- Apache Kafka
- Redis
- Ruby >= 2.3.0

`bundle`

Configuration
=============

See `config.yml`. You will probably need to add your local Kafka and Redis configurations there.

Start Workers
=============

`bundle exec ruby start.rb`

Note that the workers will run forever, or until you quit using Ctrl-C.

Render Sitemap
==============

Sitemaps are output in JSON format. You can run this in a separate shell from your workers, or even on another machine.

`bundle exec ruby render.rb`

Run tests
=========

`bundle exec rspec`

Limitations
===========

The following URL responses are treated as an empty page with no links:

- Any status code other than 200
- Any Content-Type other than text/html

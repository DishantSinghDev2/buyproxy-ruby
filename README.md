# BuyProxy Ruby SDK — Residential Proxy API Client Gem

[![Gem](https://img.shields.io/gem/v/buyproxy?logo=rubygems&logoColor=white)](https://rubygems.org/gems/buyproxy)
[![downloads](https://img.shields.io/gem/dt/buyproxy)](https://rubygems.org/gems/buyproxy)
[![CI](https://github.com/DishantSinghDev2/buyproxy-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/DishantSinghDev2/buyproxy-ruby/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

The official **Ruby gem** for [BuyProxy](https://www.buyproxy.org): generate **residential, mobile, ISP and datacenter proxies**, check bandwidth, top up by card or crypto, and manage **reseller** customers. Zero runtime dependencies; works with **Rails**, **Faraday**, **HTTParty** and `Net::HTTP`.

**Keywords:** residential proxies · rotating proxies · mobile proxies · ISP proxies · datacenter proxies · SOCKS5 · proxy API · web scraping · proxy reseller

## Features

- Zero runtime dependencies
- Idiomatic keyword arguments and snake_case models
- Automatic retries with back-off for rate limits and transient errors
- Helpers for **Faraday**, **HTTParty** and `Net::HTTP`

## Installation

```bash
gem install buyproxy
# or in your Gemfile:
bundle add buyproxy
```

Ruby 3.0+. No runtime dependencies (uses `Net::HTTP`).

## Quick start

```ruby
require "buyproxy"

bp = BuyProxy::Client.new(api_key: ENV["BUYPROXY_API_KEY"]) # or omit — reads BUYPROXY_API_KEY

plan = bp.plans.list.first
result = bp.plans.generate(plan.id, country: "US", city: "Austin", count: 5)

puts result.first.url # http://user-country-us-city-austin:pass@gw.buyproxy.org:6969
```

Pass `sticky_minutes: 10` to keep the same IP for ten minutes, or `protocol: "socks5"` for SOCKS5.

## Using the proxies with your stack

### Faraday

```ruby
conn = Faraday.new(proxy: result.first.to_faraday)
puts conn.get("https://api.ipify.org").body
```

### HTTParty

```ruby
puts HTTParty.get("https://api.ipify.org", **result.first.to_httparty).body
```

### Net::HTTP

```ruby
uri = URI("https://api.ipify.org")
http = Net::HTTP.new(uri.host, uri.port, *result.first.to_net_http)
http.use_ssl = true
puts http.get(uri.request_uri).body
```

### Rails

```ruby
# config/initializers/buyproxy.rb
BUYPROXY = BuyProxy::Client.new(api_key: Rails.application.credentials.dig(:buyproxy, :api_key))
```

## Buy bandwidth (card & crypto)

```ruby
# Buy 10 GB of Core Residential by card — send the customer to pay_url
checkout = bp.topup.card(product_key: "residential", gb: 10)
puts checkout.pay_url

# Or subscribe to a plan (monthly or yearly)
bp.topup.card(plan: "pro", interval: "year")

# Crypto (pay-as-you-go top-ups only)
bp.topup.crypto(product_key: "residential", gb: 50)

# Wait for the payment to settle — GB appears on bp.balances.list right after
tx = bp.transactions.wait(checkout.transaction_id)
puts tx.status # "succeeded"
```

Card payments run through Stripe Checkout; crypto is available for pay-as-you-go top-ups.

## Reseller API

Build a proxy product on top of BuyProxy: buy bandwidth in bulk into a **reseller pool**, create isolated **customers**, and allocate GB to them. Needs a `bp_live_` key on a Business plan or higher.

```ruby
reseller = BuyProxy::Client.new(api_key: "bp_live_…")

reseller.reseller.pool.topup_card(product_key: "residential", gb: 500)        # buy into your pool
customer = reseller.reseller.customers.create(label: "Acme Inc")             # isolated sub-account

reseller.reseller.customers.allocate(customer.username, product_key: "residential", gb: 20, idempotency_key: "order-1042")

detail = reseller.reseller.customers.get(customer.username)
result = reseller.reseller.customers.generate(customer.username, plan_id: detail.plans.first.id, country: "DE")

reseller.reseller.customers.update(customer.username, status: "suspended")
```

## Error handling

```ruby
begin
  bp.plans.generate(plan_id)
rescue BuyProxy::InsufficientBandwidthError
  puts "Out of GB — top up first"
rescue BuyProxy::RateLimitError => e
  puts "Slow down; retry in #{e.retry_after}s"
rescue BuyProxy::AuthenticationError
  puts "Check your API key"
end
```
Every error inherits from `BuyProxy::Error` and exposes `#status` and `#body`.

## Configuration

```ruby
BuyProxy::Client.new(
  api_key: "bp_key_…",                    # default: ENV["BUYPROXY_API_KEY"]
  base_url: "https://www.buyproxy.org",
  timeout: 30,
  max_retries: 2,                          # 429s always; 5xx only for safe requests
  transport: MyTransport.new               # responds to #call(method, uri, headers, body, timeout)
)
```

## API overview

| Capability | Call |
|---|---|
| Catalog & prices | `bp.products.list` |
| Account | `bp.account.get` |
| Spendable GB per product | `bp.balances.list` |
| Plans | `bp.plans.list` |
| Generate proxies | `bp.plans.generate(plan_id, **params)` |
| Card checkout | `bp.topup.card(...)` |
| Crypto checkout | `bp.topup.crypto(...)` |
| Payments | `bp.transactions.list` · `.get(id)` · `.wait(id)` |
| Create an account | `bp.auth.signup` · `.verify_otp` · `.resend_otp` |
| Reseller summary | `bp.reseller.me` |
| Customers | `bp.reseller.customers.list/create/get/update/usage/allocate/generate` |
| Reseller pool | `bp.reseller.pool.get/topup_card/topup_crypto` |

Full endpoint reference: <https://www.buyproxy.org/docs/api-reference/introduction> · OpenAPI spec: <https://www.buyproxy.org/openapi.yaml>

## FAQ

**How do I get an API key?**
Create a free account at [buyproxy.org](https://www.buyproxy.org/signup), then open **Dashboard → API keys**. Personal keys start with `bp_key_`; reseller keys (Business plan and above) start with `bp_live_`. You can create the *account* from code (`signup` + `verify otp`), but keys are issued from the dashboard.

**What's the difference between a personal and a reseller key?**
A personal key (`bp_key_…`) manages your own bandwidth: balances, plans, generating proxies, top-ups and payments. A reseller key (`bp_live_…`) manages *your customers*: create isolated sub-accounts, buy bandwidth into a pool, allocate it, suspend or reactivate, and generate proxies on their behalf.

**Which proxy types are available?**
Core Residential, Premium Residential, ISP Rotating, Mobile, Datacenter IPv4 and IPv6 — call the catalog endpoint for the live list and per-GB prices (from **$1.99/GB**).

**Do generated proxies expire, and when is bandwidth used?**
Generating a proxy is free and instant; bandwidth is only consumed when traffic flows through it. Lines are on-demand — generate fresh ones rather than storing them.

**What are the rate limits?**
60 requests per minute per API key. The SDK honours `Retry-After` and retries rate-limited requests automatically.

**Is it free to use the SDK?**
Yes — the SDK is MIT-licensed. You pay only for the proxy bandwidth you buy.

## Other BuyProxy SDKs

[Node.js](https://github.com/DishantSinghDev2/buyproxy-node) · [Python](https://github.com/DishantSinghDev2/buyproxy-python) · [Go](https://github.com/DishantSinghDev2/buyproxy-go) · [PHP](https://github.com/DishantSinghDev2/buyproxy-php) · [Ruby](https://github.com/DishantSinghDev2/buyproxy-ruby) · [Java](https://github.com/DishantSinghDev2/buyproxy-java) · [.NET](https://github.com/DishantSinghDev2/buyproxy-dotnet) · [Rust](https://github.com/DishantSinghDev2/buyproxy-rust) · [CLI](https://github.com/DishantSinghDev2/buyproxy-cli)

All SDKs are checked against the same request log, so behaviour is identical across languages — see [buyproxy-sdks](https://github.com/DishantSinghDev2/buyproxy-sdks).

## Development

```bash
bundle install
bundle exec rake test
```

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Security reports: [SECURITY.md](SECURITY.md).

## Links

- Website: <https://www.buyproxy.org>
- Documentation: <https://www.buyproxy.org/docs/sdks>
- Pricing: <https://www.buyproxy.org/pricing>
- Support: <support@buyproxy.org>

## License

[MIT](LICENSE) © BuyProxy

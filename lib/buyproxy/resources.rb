# frozen_string_literal: true

require 'cgi'

module BuyProxy
  module Resources
    # @api private
    class Base
      def initialize(client)
        @client = client
      end

      private

      attr_reader :client

      def seg(value)
        CGI.escape(value.to_s).gsub('+', '%20')
      end
    end

    class Products < Base
      # Every product with its product_key, minimum GB and live price. No API key needed.
      def list
        Models::Catalog.from_hash(client.request('GET', '/v1/products', public: true, retry_5xx: true))
      end
    end

    # Create an account without a browser: signup, then verify_otp with the emailed code.
    class Auth < Base
      def signup(email:, password:, name: nil)
        Models::SignupResult.from_hash(
          client.request('POST', '/api/auth/signup', body: { email: email, password: password, name: name }.compact, public: true)
        )
      end

      def verify_otp(email:, code:)
        Models::VerifyResult.from_hash(client.request('POST', '/api/auth/verify-otp', body: { email: email, code: code }, public: true))
      end

      def resend_otp(email:)
        client.request('POST', '/api/auth/resend-otp', body: { email: email }, public: true)
        nil
      end
    end

    class Account < Base
      def get
        Models::Account.from_hash(client.request('GET', '/v1/account', retry_5xx: true))
      end
    end

    class Balances < Base
      # Spendable GB per product, including GB still being added after a payment.
      def list
        client.request('GET', '/v1/balances', retry_5xx: true)['balances'].map { |b| Models::Balance.from_hash(b) }
      end
    end

    class Plans < Base
      def list
        client.request('GET', '/v1/plans', retry_5xx: true)['plans'].map { |p| Models::Plan.from_hash(p) }
      end

      # Generate proxy lines against one of your plans. Lines are on-demand — don't store them.
      # Omit sticky_minutes for a fresh IP per request (rotating).
      def generate(plan_id, protocol: nil, count: nil, country: nil, state: nil, city: nil, isp: nil, sticky_minutes: nil)
        body = { protocol: protocol, count: count, country: country, state: state, city: city, isp: isp,
                 stickyMinutes: sticky_minutes }.compact
        GeneratedProxies.new(client.request('POST', "/v1/plans/#{seg(plan_id)}/generate", body: body)['lines'], protocol || 'http')
      end
    end

    class Topup < Base
      # Card checkout via Stripe: card(product_key: 'residential', gb: 10) or card(plan: 'pro', interval: 'year').
      # Open pay_url to pay.
      def card(product_key: nil, gb: nil, plan: nil, interval: nil)
        body =
          if plan
            { kind: 'plan', plan: plan, interval: interval }.compact
          elsif product_key && gb
            { kind: 'topup', productKey: product_key, gb: gb }
          else
            raise ArgumentError, 'Pass either product_key: and gb: (a top-up) or plan: (a subscription).'
          end
        Models::CardCheckout.from_hash(client.request('POST', '/v1/topup/card', body: body))
      end

      # Crypto top-up (pay-as-you-go only). Open url to pay.
      def crypto(product_key:, gb:)
        Models::CryptoCheckout.from_hash(client.request('POST', '/v1/topup/crypto', body: { kind: 'topup', productKey: product_key, gb: gb }))
      end
    end

    class Transactions < Base
      def list(limit: nil)
        client.request('GET', '/v1/transactions', query: { limit: limit }, retry_5xx: true)['transactions']
              .map { |t| Models::Transaction.from_hash(t) }
      end

      def get(id)
        Models::Transaction.from_hash(client.request('GET', "/v1/transactions/#{seg(id)}", retry_5xx: true))
      end

      # Poll until the payment settles ('succeeded' or 'failed').
      def wait(id, timeout: 600, interval: 3)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          tx = get(id)
          return tx unless tx.status == 'pending'
          raise Error, "Payment #{id} is still pending after waiting" if Process.clock_gettime(Process::CLOCK_MONOTONIC) + interval > deadline

          sleep(interval)
        end
      end
    end

    class Customers < Base
      def list(status: nil)
        client.request('GET', '/v1/customers', query: { status: status }, retry_5xx: true)['customers']
              .map { |c| Models::Customer.from_hash(c) }
      end

      # Creates an isolated sub-account with no bandwidth — fund it with allocate.
      def create(label:)
        Models::Customer.from_hash(client.request('POST', '/v1/customers', body: { label: label }))
      end

      def get(username)
        Models::CustomerDetail.from_hash(client.request('GET', "/v1/customers/#{seg(username)}", retry_5xx: true))
      end

      # Rename and/or suspend ('suspended') / reactivate ('active').
      def update(username, label: nil, status: nil)
        Models::Customer.from_hash(client.request('PATCH', "/v1/customers/#{seg(username)}", body: { label: label, status: status }.compact))
      end

      def usage(username)
        Models::CustomerUsage.from_hash(client.request('GET', "/v1/customers/#{seg(username)}/usage", retry_5xx: true))
      end

      # Move GB from your pool onto a customer. Pass idempotency_key to make retries safe.
      def allocate(username, product_key:, gb:, idempotency_key: nil)
        Models::Allocation.from_hash(
          client.request('POST', "/v1/customers/#{seg(username)}/allocate", body: { productKey: product_key, gb: gb },
                                                                             headers: idempotency_key ? { 'Idempotency-Key' => idempotency_key } : {},
                                                                             retry_5xx: !idempotency_key.nil?)
        )
      end

      def generate(username, plan_id:, protocol: nil, count: nil, country: nil, state: nil, city: nil, isp: nil, sticky_minutes: nil)
        body = { planId: plan_id, protocol: protocol, count: count, country: country, state: state, city: city, isp: isp,
                 stickyMinutes: sticky_minutes }.compact
        GeneratedProxies.new(client.request('POST', "/v1/customers/#{seg(username)}/generate", body: body)['lines'], protocol || 'http')
      end
    end

    class Pool < Base
      # Your unallocated bandwidth, per product.
      def get
        client.request('GET', '/v1/pool', retry_5xx: true)['pool'].map { |p| Models::PoolEntry.from_hash(p) }
      end

      def topup_card(product_key:, gb:)
        Models::CardCheckout.from_hash(client.request('POST', '/v1/pool/topup/card', body: { productKey: product_key, gb: gb }))
      end

      def topup_crypto(product_key:, gb:)
        Models::CryptoCheckout.from_hash(client.request('POST', '/v1/pool/topup/crypto', body: { productKey: product_key, gb: gb }))
      end
    end

    # Reseller API — needs a bp_live_ key on a Business plan or higher.
    class Reseller < Base
      attr_reader :customers, :pool

      def initialize(client)
        super
        @customers = Customers.new(client)
        @pool = Pool.new(client)
      end

      def me
        Models::ResellerSummary.from_hash(client.request('GET', '/v1/me', retry_5xx: true))
      end
    end
  end
end

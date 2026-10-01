# frozen_string_literal: true

# Generated from the BuyProxy API schema — do not edit by hand.
module BuyProxy
  module Models
    # A product in the catalog.
    class Product
      attr_reader :product_key, :product_id, :name, :description, :min_gb, :price_per_gb_cents, :currency

      def initialize(**attrs)
        @product_key = attrs[:product_key]
        @product_id = attrs[:product_id]
        @name = attrs[:name]
        @description = attrs[:description]
        @min_gb = attrs[:min_gb]
        @price_per_gb_cents = attrs[:price_per_gb_cents]
        @currency = attrs[:currency]
      end

      def self.from_hash(h)
        new(
          product_key: h['productKey'],
          product_id: h['productId'],
          name: h['name'],
          description: h['description'],
          min_gb: h['minGb'],
          price_per_gb_cents: h['pricePerGbCents'],
          currency: h['currency']
        )
      end

      def to_h
        {
          product_key: @product_key,
          product_id: @product_id,
          name: @name,
          description: @description,
          min_gb: @min_gb,
          price_per_gb_cents: @price_per_gb_cents,
          currency: @currency
        }
      end
    end

    # Top-ups of thresholdGb or more get floor(gb × rate) extra GB free.
    class VolumeBonus
      attr_reader :threshold_gb, :rate

      def initialize(**attrs)
        @threshold_gb = attrs[:threshold_gb]
        @rate = attrs[:rate]
      end

      def self.from_hash(h)
        new(
          threshold_gb: h['thresholdGb'],
          rate: h['rate']
        )
      end

      def to_h
        {
          threshold_gb: @threshold_gb,
          rate: @rate
        }
      end
    end

    # A subscription plan's price.
    class PlanPrice
      attr_reader :plan, :monthly_price_cents, :included_gb

      def initialize(**attrs)
        @plan = attrs[:plan]
        @monthly_price_cents = attrs[:monthly_price_cents]
        @included_gb = attrs[:included_gb]
      end

      def self.from_hash(h)
        new(
          plan: h['plan'],
          monthly_price_cents: h['monthlyPriceCents'],
          included_gb: h['includedGb']
        )
      end

      def to_h
        {
          plan: @plan,
          monthly_price_cents: @monthly_price_cents,
          included_gb: @included_gb
        }
      end
    end

    # The public product catalog with live prices.
    class Catalog
      attr_reader :products, :volume_bonus, :plans

      def initialize(**attrs)
        @products = attrs[:products]
        @volume_bonus = attrs[:volume_bonus]
        @plans = attrs[:plans]
      end

      def self.from_hash(h)
        new(
          products: (h['products'] || []).map { |x| Product.from_hash(x) },
          volume_bonus: VolumeBonus.from_hash(h['volumeBonus']),
          plans: (h['plans'] || []).map { |x| PlanPrice.from_hash(x) }
        )
      end

      def to_h
        {
          products: @products,
          volume_bonus: @volume_bonus,
          plans: @plans
        }
      end
    end

    # The account behind the API key.
    class Account
      attr_reader :email, :name, :plan, :plan_expires_at, :balance_gb, :created_at

      def initialize(**attrs)
        @email = attrs[:email]
        @name = attrs[:name]
        @plan = attrs[:plan]
        @plan_expires_at = attrs[:plan_expires_at]
        @balance_gb = attrs[:balance_gb]
        @created_at = attrs[:created_at]
      end

      def self.from_hash(h)
        new(
          email: h['email'],
          name: h['name'],
          plan: h['plan'],
          plan_expires_at: h['planExpiresAt'],
          balance_gb: h['balanceGb'],
          created_at: h['createdAt']
        )
      end

      def to_h
        {
          email: @email,
          name: @name,
          plan: @plan,
          plan_expires_at: @plan_expires_at,
          balance_gb: @balance_gb,
          created_at: @created_at
        }
      end
    end

    # Spendable bandwidth on one product.
    class Balance
      attr_reader :product_key, :product_id, :plan_id, :active_gb, :pending_gb, :total_gb, :expires_at

      def initialize(**attrs)
        @product_key = attrs[:product_key]
        @product_id = attrs[:product_id]
        @plan_id = attrs[:plan_id]
        @active_gb = attrs[:active_gb]
        @pending_gb = attrs[:pending_gb]
        @total_gb = attrs[:total_gb]
        @expires_at = attrs[:expires_at]
      end

      def self.from_hash(h)
        new(
          product_key: h['productKey'],
          product_id: h['productId'],
          plan_id: h['planId'],
          active_gb: h['activeGb'],
          pending_gb: h['pendingGb'],
          total_gb: h['totalGb'],
          expires_at: h['expiresAt']
        )
      end

      def to_h
        {
          product_key: @product_key,
          product_id: @product_id,
          plan_id: @plan_id,
          active_gb: @active_gb,
          pending_gb: @pending_gb,
          total_gb: @total_gb,
          expires_at: @expires_at
        }
      end
    end

    # Which targeting fields a plan supports.
    class Targeting
      attr_reader :country, :state, :city, :isp

      def initialize(**attrs)
        @country = attrs[:country]
        @state = attrs[:state]
        @city = attrs[:city]
        @isp = attrs[:isp]
      end

      def self.from_hash(h)
        new(
          country: h['country'],
          state: h['state'],
          city: h['city'],
          isp: h['isp']
        )
      end

      def to_h
        {
          country: @country,
          state: @state,
          city: @city,
          isp: @isp
        }
      end
    end

    # What a plan's generate call accepts.
    class GenerateCapabilities
      attr_reader :max_count, :max_sticky_minutes, :protocols, :targeting

      def initialize(**attrs)
        @max_count = attrs[:max_count]
        @max_sticky_minutes = attrs[:max_sticky_minutes]
        @protocols = attrs[:protocols]
        @targeting = attrs[:targeting]
      end

      def self.from_hash(h)
        new(
          max_count: h['maxCount'],
          max_sticky_minutes: h['maxStickyMinutes'],
          protocols: h['protocols'] || [],
          targeting: Targeting.from_hash(h['targeting'])
        )
      end

      def to_h
        {
          max_count: @max_count,
          max_sticky_minutes: @max_sticky_minutes,
          protocols: @protocols,
          targeting: @targeting
        }
      end
    end

    # Bandwidth you hold on one product.
    class Plan
      attr_reader :id, :product_id, :product_key, :name, :label, :data_gb_remaining, :data_gb_total, :expires_at, :created_at, :generate

      def initialize(**attrs)
        @id = attrs[:id]
        @product_id = attrs[:product_id]
        @product_key = attrs[:product_key]
        @name = attrs[:name]
        @label = attrs[:label]
        @data_gb_remaining = attrs[:data_gb_remaining]
        @data_gb_total = attrs[:data_gb_total]
        @expires_at = attrs[:expires_at]
        @created_at = attrs[:created_at]
        @generate = attrs[:generate]
      end

      def self.from_hash(h)
        new(
          id: h['id'],
          product_id: h['productId'],
          product_key: h['productKey'],
          name: h['name'],
          label: h['label'],
          data_gb_remaining: h['dataGbRemaining'],
          data_gb_total: h['dataGbTotal'],
          expires_at: h['expiresAt'],
          created_at: h['createdAt'],
          generate: h['generate'] ? GenerateCapabilities.from_hash(h['generate']) : nil
        )
      end

      def to_h
        {
          id: @id,
          product_id: @product_id,
          product_key: @product_key,
          name: @name,
          label: @label,
          data_gb_remaining: @data_gb_remaining,
          data_gb_total: @data_gb_total,
          expires_at: @expires_at,
          created_at: @created_at,
          generate: @generate
        }
      end
    end

    # A Stripe checkout to open in a browser.
    class CardCheckout
      attr_reader :pay_url, :transaction_id

      def initialize(**attrs)
        @pay_url = attrs[:pay_url]
        @transaction_id = attrs[:transaction_id]
      end

      def self.from_hash(h)
        new(
          pay_url: h['payUrl'],
          transaction_id: h['transactionId']
        )
      end

      def to_h
        {
          pay_url: @pay_url,
          transaction_id: @transaction_id
        }
      end
    end

    # A crypto invoice to open in a browser.
    class CryptoCheckout
      attr_reader :url, :transaction_id

      def initialize(**attrs)
        @url = attrs[:url]
        @transaction_id = attrs[:transaction_id]
      end

      def self.from_hash(h)
        new(
          url: h['url'],
          transaction_id: h['transactionId']
        )
      end

      def to_h
        {
          url: @url,
          transaction_id: @transaction_id
        }
      end
    end

    # One payment.
    class Transaction
      attr_reader :id, :kind, :status, :payment_method, :interval, :amount_cents, :currency, :gb, :product_key, :plan, :reseller_pool, :created_at

      def initialize(**attrs)
        @id = attrs[:id]
        @kind = attrs[:kind]
        @status = attrs[:status]
        @payment_method = attrs[:payment_method]
        @interval = attrs[:interval]
        @amount_cents = attrs[:amount_cents]
        @currency = attrs[:currency]
        @gb = attrs[:gb]
        @product_key = attrs[:product_key]
        @plan = attrs[:plan]
        @reseller_pool = attrs[:reseller_pool]
        @created_at = attrs[:created_at]
      end

      def self.from_hash(h)
        new(
          id: h['id'],
          kind: h['kind'],
          status: h['status'],
          payment_method: h['paymentMethod'],
          interval: h['interval'],
          amount_cents: h['amountCents'],
          currency: h['currency'],
          gb: h['gb'],
          product_key: h['productKey'],
          plan: h['plan'],
          reseller_pool: h['resellerPool'],
          created_at: h['createdAt']
        )
      end

      def to_h
        {
          id: @id,
          kind: @kind,
          status: @status,
          payment_method: @payment_method,
          interval: @interval,
          amount_cents: @amount_cents,
          currency: @currency,
          gb: @gb,
          product_key: @product_key,
          plan: @plan,
          reseller_pool: @reseller_pool,
          created_at: @created_at
        }
      end
    end

    # Unallocated reseller bandwidth on one product.
    class PoolEntry
      attr_reader :product_key, :product_id, :label, :gb

      def initialize(**attrs)
        @product_key = attrs[:product_key]
        @product_id = attrs[:product_id]
        @label = attrs[:label]
        @gb = attrs[:gb]
      end

      def self.from_hash(h)
        new(
          product_key: h['productKey'],
          product_id: h['productId'],
          label: h['label'],
          gb: h['gb']
        )
      end

      def to_h
        {
          product_key: @product_key,
          product_id: @product_id,
          label: @label,
          gb: @gb
        }
      end
    end

    # Reseller account summary.
    class ResellerSummary
      attr_reader :email, :customer_count, :active_customer_count, :pool

      def initialize(**attrs)
        @email = attrs[:email]
        @customer_count = attrs[:customer_count]
        @active_customer_count = attrs[:active_customer_count]
        @pool = attrs[:pool]
      end

      def self.from_hash(h)
        new(
          email: h['email'],
          customer_count: h['customerCount'],
          active_customer_count: h['activeCustomerCount'],
          pool: (h['pool'] || []).map { |x| PoolEntry.from_hash(x) }
        )
      end

      def to_h
        {
          email: @email,
          customer_count: @customer_count,
          active_customer_count: @active_customer_count,
          pool: @pool
        }
      end
    end

    # A reseller sub-account.
    class Customer
      attr_reader :username, :label, :status, :created_at

      def initialize(**attrs)
        @username = attrs[:username]
        @label = attrs[:label]
        @status = attrs[:status]
        @created_at = attrs[:created_at]
      end

      def self.from_hash(h)
        new(
          username: h['username'],
          label: h['label'],
          status: h['status'],
          created_at: h['createdAt']
        )
      end

      def to_h
        {
          username: @username,
          label: @label,
          status: @status,
          created_at: @created_at
        }
      end
    end

    # GB allocated but still being added to a plan.
    class PendingAllocation
      attr_reader :product_id, :product_key, :gb

      def initialize(**attrs)
        @product_id = attrs[:product_id]
        @product_key = attrs[:product_key]
        @gb = attrs[:gb]
      end

      def self.from_hash(h)
        new(
          product_id: h['productId'],
          product_key: h['productKey'],
          gb: h['gb']
        )
      end

      def to_h
        {
          product_id: @product_id,
          product_key: @product_key,
          gb: @gb
        }
      end
    end

    # A plan plus the customer's remaining GB.
    class CustomerPlan
      attr_reader :id, :product_id, :product_key, :name, :label, :data_gb_remaining, :data_gb_total, :expires_at, :created_at, :generate, :remaining_gb

      def initialize(**attrs)
        @id = attrs[:id]
        @product_id = attrs[:product_id]
        @product_key = attrs[:product_key]
        @name = attrs[:name]
        @label = attrs[:label]
        @data_gb_remaining = attrs[:data_gb_remaining]
        @data_gb_total = attrs[:data_gb_total]
        @expires_at = attrs[:expires_at]
        @created_at = attrs[:created_at]
        @generate = attrs[:generate]
        @remaining_gb = attrs[:remaining_gb]
      end

      def self.from_hash(h)
        new(
          id: h['id'],
          product_id: h['productId'],
          product_key: h['productKey'],
          name: h['name'],
          label: h['label'],
          data_gb_remaining: h['dataGbRemaining'],
          data_gb_total: h['dataGbTotal'],
          expires_at: h['expiresAt'],
          created_at: h['createdAt'],
          generate: h['generate'] ? GenerateCapabilities.from_hash(h['generate']) : nil,
          remaining_gb: h['remainingGb']
        )
      end

      def to_h
        {
          id: @id,
          product_id: @product_id,
          product_key: @product_key,
          name: @name,
          label: @label,
          data_gb_remaining: @data_gb_remaining,
          data_gb_total: @data_gb_total,
          expires_at: @expires_at,
          created_at: @created_at,
          generate: @generate,
          remaining_gb: @remaining_gb
        }
      end
    end

    # A customer with their plans.
    class CustomerDetail
      attr_reader :username, :label, :status, :created_at, :plans, :pending

      def initialize(**attrs)
        @username = attrs[:username]
        @label = attrs[:label]
        @status = attrs[:status]
        @created_at = attrs[:created_at]
        @plans = attrs[:plans]
        @pending = attrs[:pending]
      end

      def self.from_hash(h)
        new(
          username: h['username'],
          label: h['label'],
          status: h['status'],
          created_at: h['createdAt'],
          plans: (h['plans'] || []).map { |x| CustomerPlan.from_hash(x) },
          pending: (h['pending'] || []).map { |x| PendingAllocation.from_hash(x) }
        )
      end

      def to_h
        {
          username: @username,
          label: @label,
          status: @status,
          created_at: @created_at,
          plans: @plans,
          pending: @pending
        }
      end
    end

    # Consumption on one plan.
    class UsagePlan
      attr_reader :id, :product_id, :product_key, :remaining_gb, :total_gb, :used_gb, :expires_at

      def initialize(**attrs)
        @id = attrs[:id]
        @product_id = attrs[:product_id]
        @product_key = attrs[:product_key]
        @remaining_gb = attrs[:remaining_gb]
        @total_gb = attrs[:total_gb]
        @used_gb = attrs[:used_gb]
        @expires_at = attrs[:expires_at]
      end

      def self.from_hash(h)
        new(
          id: h['id'],
          product_id: h['productId'],
          product_key: h['productKey'],
          remaining_gb: h['remainingGb'],
          total_gb: h['totalGb'],
          used_gb: h['usedGb'],
          expires_at: h['expiresAt']
        )
      end

      def to_h
        {
          id: @id,
          product_id: @product_id,
          product_key: @product_key,
          remaining_gb: @remaining_gb,
          total_gb: @total_gb,
          used_gb: @used_gb,
          expires_at: @expires_at
        }
      end
    end

    # A snapshot of a customer's consumption.
    class CustomerUsage
      attr_reader :plans, :pending

      def initialize(**attrs)
        @plans = attrs[:plans]
        @pending = attrs[:pending]
      end

      def self.from_hash(h)
        new(
          plans: (h['plans'] || []).map { |x| UsagePlan.from_hash(x) },
          pending: (h['pending'] || []).map { |x| PendingAllocation.from_hash(x) }
        )
      end

      def to_h
        {
          plans: @plans,
          pending: @pending
        }
      end
    end

    # The result of an allocation.
    class Allocation
      attr_reader :product_key, :product_id, :gb, :already_applied, :pool_remaining_gb

      def initialize(**attrs)
        @product_key = attrs[:product_key]
        @product_id = attrs[:product_id]
        @gb = attrs[:gb]
        @already_applied = attrs[:already_applied]
        @pool_remaining_gb = attrs[:pool_remaining_gb]
      end

      def self.from_hash(h)
        new(
          product_key: h['productKey'],
          product_id: h['productId'],
          gb: h['gb'],
          already_applied: h['alreadyApplied'],
          pool_remaining_gb: h['poolRemainingGb']
        )
      end

      def to_h
        {
          product_key: @product_key,
          product_id: @product_id,
          gb: @gb,
          already_applied: @already_applied,
          pool_remaining_gb: @pool_remaining_gb
        }
      end
    end

    # The result of signup.
    class SignupResult
      attr_reader :ok, :cooldown_seconds

      def initialize(**attrs)
        @ok = attrs[:ok]
        @cooldown_seconds = attrs[:cooldown_seconds]
      end

      def self.from_hash(h)
        new(
          ok: h['ok'],
          cooldown_seconds: h['cooldownSeconds']
        )
      end

      def to_h
        {
          ok: @ok,
          cooldown_seconds: @cooldown_seconds
        }
      end
    end

    # The verified user.
    class VerifiedUser
      attr_reader :email, :name

      def initialize(**attrs)
        @email = attrs[:email]
        @name = attrs[:name]
      end

      def self.from_hash(h)
        new(
          email: h['email'],
          name: h['name']
        )
      end

      def to_h
        {
          email: @email,
          name: @name
        }
      end
    end

    # The result of OTP verification.
    class VerifyResult
      attr_reader :ok, :is_new, :user

      def initialize(**attrs)
        @ok = attrs[:ok]
        @is_new = attrs[:is_new]
        @user = attrs[:user]
      end

      def self.from_hash(h)
        new(
          ok: h['ok'],
          is_new: h['isNew'],
          user: VerifiedUser.from_hash(h['user'])
        )
      end

      def to_h
        {
          ok: @ok,
          is_new: @is_new,
          user: @user
        }
      end
    end

  end
end

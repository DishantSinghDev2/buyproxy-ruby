# frozen_string_literal: true

require_relative 'test_helper'

class ClientTest < Minitest::Test
  ACCOUNT = { 'email' => 'a@b.co', 'name' => 'A', 'plan' => 'pro', 'planExpiresAt' => nil, 'balanceGb' => 4.2, 'createdAt' => 't' }.freeze

  def client(transport, key: 'bp_key_x')
    BuyProxy::Client.new(api_key: key, transport: transport, max_retries: 2)
  end

  def test_sends_key_json_and_user_agent
    t = FakeTransport.new(FakeTransport.json(200, { 'lines' => ['u:p@gw.buyproxy.org:6969'] }))
    out = client(t).plans.generate('plan 1', protocol: 'socks5', count: 1)
    req = t.requests.first
    assert_equal 'https://www.buyproxy.org/v1/plans/plan%201/generate', req[:url]
    assert_equal 'bp_key_x', req[:headers]['X-API-Key']
    assert_match(/\Abuyproxy-ruby\//, req[:headers]['User-Agent'])
    assert_equal '{"protocol":"socks5","count":1}', req[:body]
    assert_equal 'socks5', out.first.protocol
  end

  def test_models_use_snake_case
    a = client(FakeTransport.new(FakeTransport.json(200, ACCOUNT))).account.get
    assert_equal 4.2, a.balance_gb
    assert_nil a.plan_expires_at
  end

  def test_requires_key_except_public_endpoints
    ENV.delete('BUYPROXY_API_KEY')
    t = FakeTransport.new(FakeTransport.json(200, { 'products' => [], 'volumeBonus' => { 'thresholdGb' => 100, 'rate' => 0.1 }, 'plans' => [] }))
    bp = BuyProxy::Client.new(api_key: '', transport: t)
    assert_raises(BuyProxy::AuthenticationError) { bp.account.get }
    assert_equal 100, bp.products.list.volume_bonus.threshold_gb
    assert_equal 1, t.requests.size
  end

  def test_statuses_map_to_errors
    { 401 => BuyProxy::AuthenticationError, 402 => BuyProxy::InsufficientBandwidthError, 404 => BuyProxy::NotFoundError }.each do |status, klass|
      err = assert_raises(klass) { client(FakeTransport.new(FakeTransport.json(status, { 'error' => 'nope' }))).account.get }
      assert_equal status, err.status
      assert_includes err.message, 'nope'
    end
  end

  def test_retries_429_then_succeeds
    t = FakeTransport.new(FakeTransport.json(429, { 'error' => 'slow' }, { 'retry-after' => '0' }), FakeTransport.json(200, ACCOUNT))
    assert_equal 'pro', client(t).account.get.plan
    assert_equal 2, t.requests.size
  end

  def test_rate_limit_error_after_retries
    t = FakeTransport.new(*Array.new(3) { FakeTransport.json(429, { 'error' => 'slow' }, { 'retry-after' => '0' }) })
    assert_raises(BuyProxy::RateLimitError) { client(t).account.get }
    assert_equal 3, t.requests.size
  end

  def test_post_not_retried_on_503_unless_idempotent
    t = FakeTransport.new(FakeTransport.json(503, { 'error' => 'down' }))
    assert_raises(BuyProxy::ServerError) { client(t).reseller.customers.allocate('c', product_key: 'premium', gb: 1) }
    assert_equal 1, t.requests.size

    ok = { 'productKey' => 'premium', 'productId' => 'x', 'gb' => 1, 'alreadyApplied' => false, 'poolRemainingGb' => 0 }
    t = FakeTransport.new(FakeTransport.json(503, { 'error' => 'down' }), FakeTransport.json(201, ok))
    a = client(t).reseller.customers.allocate('c', product_key: 'premium', gb: 1, idempotency_key: 'k1')
    refute a.already_applied
    assert_equal 'k1', t.requests[1][:headers]['Idempotency-Key']
    assert_equal '{"productKey":"premium","gb":1}', t.requests[1][:body]
  end

  def test_topup_card_validates_arguments
    assert_raises(ArgumentError) { client(FakeTransport.new).topup.card }
  end

  def test_wait_polls_until_settled
    tx = ->(s) { FakeTransport.json(200, { 'id' => 'st_1', 'kind' => 'topup', 'status' => s, 'paymentMethod' => 'card', 'interval' => nil, 'amountCents' => 1, 'currency' => 'usd', 'gb' => 1, 'productKey' => nil, 'plan' => nil, 'resellerPool' => false, 'createdAt' => 't' }) }
    t = FakeTransport.new(tx.call('pending'), tx.call('succeeded'))
    assert_equal 'succeeded', client(t).transactions.wait('st_1', interval: 0.01).status
  end

  def test_key_kind
    assert_equal 'reseller', client(FakeTransport.new, key: 'bp_live_x').key_kind
    assert_equal 'personal', client(FakeTransport.new, key: 'bp_key_x').key_kind
  end
end

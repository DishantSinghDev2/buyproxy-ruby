# frozen_string_literal: true

require_relative 'lib/buyproxy/version'

Gem::Specification.new do |spec|
  spec.name = 'buyproxy'
  spec.version = BuyProxy::VERSION
  spec.authors = ['BuyProxy']
  spec.email = ['support@buyproxy.org']

  spec.summary = 'Official BuyProxy Ruby SDK — residential, mobile, ISP and datacenter proxies.'
  spec.description = 'Generate rotating and sticky proxies with geo-targeting, manage reseller customers, and top up ' \
                     'bandwidth by card or crypto. Zero runtime dependencies; works with Rails, Faraday, HTTParty and Net::HTTP.'
  spec.homepage = 'https://www.buyproxy.org/docs/sdks'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/DishantSinghDev2/buyproxy-ruby',
    'bug_tracker_uri' => 'https://github.com/DishantSinghDev2/buyproxy-ruby/issues',
    'changelog_uri' => 'https://github.com/DishantSinghDev2/buyproxy-ruby/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://www.buyproxy.org/docs/api-reference/introduction',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir['lib/**/*.rb', 'README.md', 'LICENSE', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end

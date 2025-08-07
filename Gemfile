# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "irb"
gem "rake"
gem "minitest"
if RUBY_VERSION >= '2.6'
  gem "rdoc"
else
  # Workaround for psych and RubyGems version error: rdoc >= 6.4.0 depends on psych >= 4.0.0
  # https://github.com/rubygems/rubygems/issues/4976
  gem "rdoc", "< 6.4.0"
end

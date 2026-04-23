# philiprehberger-state_bag

[![Tests](https://github.com/philiprehberger/rb-state-bag/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-state-bag/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-state_bag.svg)](https://rubygems.org/gems/philiprehberger-state_bag)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-state-bag)](https://github.com/philiprehberger/rb-state-bag/commits/main)

Thread-local state bag for implicit context propagation

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-state_bag"
```

Or install directly:

```bash
gem install philiprehberger-state_bag
```

## Usage

```ruby
require "philiprehberger/state_bag"

Philiprehberger::StateBag.set(:user_id, 42)
Philiprehberger::StateBag.get(:user_id)
# => 42
```

### Default Values

```ruby
Philiprehberger::StateBag.get(:missing, 'fallback')
# => "fallback"
```

### Scoped Overrides

```ruby
Philiprehberger::StateBag.set(:locale, 'en')

Philiprehberger::StateBag.with(locale: 'de') do
  Philiprehberger::StateBag.get(:locale)
  # => "de"
end

Philiprehberger::StateBag.get(:locale)
# => "en"
```

### Fetch and Delete

```ruby
require "philiprehberger/state_bag"

Philiprehberger::StateBag.set(:user, "Alice")
Philiprehberger::StateBag.fetch(:user)             # => "Alice"
Philiprehberger::StateBag.fetch(:missing, "default") # => "default"
Philiprehberger::StateBag.fetch(:missing) { |k| "no #{k}" } # => "no missing"

Philiprehberger::StateBag.delete(:user)  # => "Alice"
Philiprehberger::StateBag.key?(:user)    # => false
```

### Inspection

```ruby
Philiprehberger::StateBag.set(:a, 1)
Philiprehberger::StateBag.key?(:a)   # => true
Philiprehberger::StateBag.size       # => 1
Philiprehberger::StateBag.empty?     # => false
Philiprehberger::StateBag.keys       # => [:a]
Philiprehberger::StateBag.values     # => [1]
Philiprehberger::StateBag.to_h       # => {:a=>1}
Philiprehberger::StateBag.clear
```

### Deep access

```ruby
Philiprehberger::StateBag.set(:request, { id: "abc", user: { email: "x@y.com" } })
Philiprehberger::StateBag.dig(:request, :user, :email) # => "x@y.com"
Philiprehberger::StateBag.dig(:request, :missing)      # => nil
```

### Bulk Operations

```ruby
Philiprehberger::StateBag.merge(user_id: 42, locale: 'en', request_id: 'req-1')
# => {:user_id=>42, :locale=>"en", :request_id=>"req-1"}

Philiprehberger::StateBag.slice(:user_id, :locale)
# => {:user_id=>42, :locale=>"en"}

Philiprehberger::StateBag.each { |k, v| puts "#{k}=#{v}" }

Philiprehberger::StateBag.replace(user_id: 99)
Philiprehberger::StateBag.to_h
# => {:user_id=>99}
```

## API

| Method | Description |
|--------|-------------|
| `.set(key, val)` | Store a value in the thread-local state bag |
| `.get(key, default = nil)` | Retrieve a value or return the default |
| `.with(**overrides, &block)` | Execute block with temporary state, restoring after |
| `.fetch(key, default = UNSET, &block)` | Retrieve a value; raises KeyError if missing with no default/block |
| `.dig(*keys)` | Dig into nested hash-valued entries; returns nil on any miss |
| `.delete(key)` | Remove a key and return its value |
| `.clear` | Remove all entries from the state bag |
| `.to_h` | Return a snapshot of the current state |
| `.key?(key)` | Check if a key exists in the state bag |
| `.size` | Number of entries in the state bag |
| `.empty?` | True if the state bag has no entries |
| `.keys` | Array of all keys in the state bag |
| `.values` | Array of all values in the state bag |
| `.merge(**entries)` | Bulk-set multiple keys; returns a snapshot |
| `.replace(hash)` | Replace the entire state with the given hash; returns a snapshot |
| `.slice(*keys)` | Return a hash containing only the given keys |
| `.each(&block)` | Iterate key-value pairs; returns an Enumerator without a block |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-state-bag)

🐛 [Report issues](https://github.com/philiprehberger/rb-state-bag/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-state-bag/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)

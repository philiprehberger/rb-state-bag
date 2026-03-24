# philiprehberger-state_bag

[![Tests](https://github.com/philiprehberger/rb-state-bag/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-state-bag/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-state_bag.svg)](https://rubygems.org/gems/philiprehberger-state_bag)
[![License](https://img.shields.io/github/license/philiprehberger/rb-state-bag)](LICENSE)

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
require 'philiprehberger/state_bag'

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

### Inspection

```ruby
Philiprehberger::StateBag.set(:a, 1)
Philiprehberger::StateBag.key?(:a)   # => true
Philiprehberger::StateBag.to_h       # => {:a=>1}
Philiprehberger::StateBag.clear
```

## API

| Method | Description |
|--------|-------------|
| `.set(key, val)` | Store a value in the thread-local state bag |
| `.get(key, default = nil)` | Retrieve a value or return the default |
| `.with(**overrides, &block)` | Execute block with temporary state, restoring after |
| `.clear` | Remove all entries from the state bag |
| `.to_h` | Return a snapshot of the current state |
| `.key?(key)` | Check if a key exists in the state bag |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::StateBag do
  before { described_class.clear }

  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.set and .get' do
    it 'stores and retrieves a value' do
      described_class.set(:name, 'alice')
      expect(described_class.get(:name)).to eq('alice')
    end

    it 'returns default for missing key' do
      expect(described_class.get(:missing, 'fallback')).to eq('fallback')
    end

    it 'returns nil for missing key without default' do
      expect(described_class.get(:missing)).to be_nil
    end

    it 'overwrites existing values' do
      described_class.set(:key, 'a')
      described_class.set(:key, 'b')
      expect(described_class.get(:key)).to eq('b')
    end

    it 'stores nil as a value' do
      described_class.set(:key, nil)
      expect(described_class.get(:key)).to be_nil
      expect(described_class.key?(:key)).to be true
    end

    it 'stores numeric values' do
      described_class.set(:count, 42)
      expect(described_class.get(:count)).to eq(42)
    end

    it 'stores array values' do
      described_class.set(:list, [1, 2, 3])
      expect(described_class.get(:list)).to eq([1, 2, 3])
    end

    it 'stores hash values' do
      described_class.set(:nested, { a: 1 })
      expect(described_class.get(:nested)).to eq({ a: 1 })
    end

    it 'supports string keys' do
      described_class.set('str_key', 'value')
      expect(described_class.get('str_key')).to eq('value')
    end

    it 'treats symbol and string keys independently' do
      described_class.set(:key, 'symbol')
      described_class.set('key', 'string')
      expect(described_class.get(:key)).to eq('symbol')
      expect(described_class.get('key')).to eq('string')
    end

    it 'returns the stored value from set' do
      result = described_class.set(:x, 'val')
      expect(result).to eq('val')
    end
  end

  describe '.with' do
    it 'sets values during block execution' do
      described_class.with(user: 'bob') do
        expect(described_class.get(:user)).to eq('bob')
      end
    end

    it 'restores previous values after block' do
      described_class.set(:user, 'alice')
      described_class.with(user: 'bob') do
        expect(described_class.get(:user)).to eq('bob')
      end
      expect(described_class.get(:user)).to eq('alice')
    end

    it 'removes keys that did not exist before' do
      described_class.with(temp: 'value') do
        expect(described_class.key?(:temp)).to be true
      end
      expect(described_class.key?(:temp)).to be false
    end

    it 'restores on exception' do
      described_class.set(:key, 'original')
      begin
        described_class.with(key: 'temp') { raise 'boom' }
      rescue RuntimeError
        nil
      end
      expect(described_class.get(:key)).to eq('original')
    end

    it 'returns block value' do
      result = described_class.with(x: 1) { 42 }
      expect(result).to eq(42)
    end

    it 'supports multiple overrides at once' do
      described_class.with(a: 1, b: 2, c: 3) do
        expect(described_class.get(:a)).to eq(1)
        expect(described_class.get(:b)).to eq(2)
        expect(described_class.get(:c)).to eq(3)
      end
    end

    it 'restores multiple keys after block' do
      described_class.set(:a, 'orig_a')
      described_class.set(:b, 'orig_b')

      described_class.with(a: 'new_a', b: 'new_b') do
        expect(described_class.get(:a)).to eq('new_a')
      end

      expect(described_class.get(:a)).to eq('orig_a')
      expect(described_class.get(:b)).to eq('orig_b')
    end

    it 'supports nested with blocks' do
      described_class.set(:level, 0)

      described_class.with(level: 1) do
        expect(described_class.get(:level)).to eq(1)

        described_class.with(level: 2) do
          expect(described_class.get(:level)).to eq(2)
        end

        expect(described_class.get(:level)).to eq(1)
      end

      expect(described_class.get(:level)).to eq(0)
    end

    it 'removes new keys even when exception is raised' do
      begin
        described_class.with(ephemeral: true) { raise 'err' }
      rescue RuntimeError
        nil
      end
      expect(described_class.key?(:ephemeral)).to be false
    end
  end

  describe '.clear' do
    it 'removes all entries' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      described_class.clear
      expect(described_class.to_h).to be_empty
    end

    it 'can be called on empty state without error' do
      described_class.clear
      expect(described_class.to_h).to be_empty
    end
  end

  describe '.to_h' do
    it 'returns a copy of the state' do
      described_class.set(:x, 10)
      hash = described_class.to_h
      hash[:x] = 99
      expect(described_class.get(:x)).to eq(10)
    end

    it 'returns empty hash when no state set' do
      expect(described_class.to_h).to eq({})
    end

    it 'includes all set keys' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      expect(described_class.to_h).to eq({ a: 1, b: 2 })
    end
  end

  describe '.key?' do
    it 'returns true for existing key' do
      described_class.set(:present, 'yes')
      expect(described_class.key?(:present)).to be true
    end

    it 'returns false for missing key' do
      expect(described_class.key?(:absent)).to be false
    end

    it 'returns true even when value is nil' do
      described_class.set(:nilval, nil)
      expect(described_class.key?(:nilval)).to be true
    end

    it 'returns true even when value is false' do
      described_class.set(:flag, false)
      expect(described_class.key?(:flag)).to be true
    end

    it 'returns false after key is cleared' do
      described_class.set(:temp, 'val')
      described_class.clear
      expect(described_class.key?(:temp)).to be false
    end
  end

  describe '.fetch' do
    before { described_class.set(:name, 'Alice') }

    it 'returns value for existing key' do
      expect(described_class.fetch(:name)).to eq('Alice')
    end

    it 'returns default for missing key' do
      expect(described_class.fetch(:missing, 'fallback')).to eq('fallback')
    end

    it 'calls block for missing key' do
      expect(described_class.fetch(:missing) { |k| "no #{k}" }).to eq('no missing')
    end

    it 'raises KeyError when key missing and no default or block' do
      expect { described_class.fetch(:missing) }.to raise_error(KeyError)
    end

    it 'returns nil when value is nil' do
      described_class.set(:empty, nil)
      expect(described_class.fetch(:empty)).to be_nil
    end

    it 'prefers block over default' do
      expect(described_class.fetch(:missing) { 'block' }).to eq('block')
    end
  end

  describe '.dig' do
    it 'digs through nested hashes' do
      described_class.set(:user, { profile: { email: 'x@y' } })
      expect(described_class.dig(:user, :profile, :email)).to eq('x@y')
    end

    it 'returns nil when the top-level key is missing' do
      expect(described_class.dig(:missing, :profile, :email)).to be_nil
    end

    it 'returns nil when a mid-level key is missing' do
      described_class.set(:user, { profile: { email: 'x@y' } })
      expect(described_class.dig(:user, :missing, :email)).to be_nil
    end

    it 'raises TypeError when an intermediate value does not respond to dig' do
      described_class.set(:x, 5)
      expect { described_class.dig(:x, :y) }.to raise_error(TypeError)
    end

    it 'raises ArgumentError when called with no keys' do
      expect { described_class.dig }.to raise_error(ArgumentError, /given 0, expected 1\+/)
    end
  end

  describe '.delete' do
    it 'removes a key and returns its value' do
      described_class.set(:temp, 'data')
      expect(described_class.delete(:temp)).to eq('data')
      expect(described_class.key?(:temp)).to be false
    end

    it 'returns nil for missing key' do
      expect(described_class.delete(:nonexistent)).to be_nil
    end
  end

  describe 'thread isolation' do
    it 'does not leak state between threads' do
      described_class.set(:main, true)
      result = Thread.new { described_class.get(:main) }.value
      expect(result).to be_nil
    end

    it 'allows independent state in different threads' do
      described_class.set(:val, 'main')

      thread_val = Thread.new do
        described_class.set(:val, 'thread')
        described_class.get(:val)
      end.value

      expect(thread_val).to eq('thread')
      expect(described_class.get(:val)).to eq('main')
    end

    it 'does not see keys set in another thread' do
      Thread.new { described_class.set(:other_thread, 'data') }.join
      expect(described_class.key?(:other_thread)).to be false
    end
  end

  describe '.size, .empty?, .keys' do
    it 'reports 0 and empty for a fresh bag' do
      expect(described_class.size).to eq(0)
      expect(described_class.empty?).to be true
      expect(described_class.keys).to eq([])
    end

    it 'reports size after sets' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      expect(described_class.size).to eq(2)
      expect(described_class.empty?).to be false
      expect(described_class.keys).to contain_exactly(:a, :b)
    end
  end

  describe '.values' do
    it 'returns all values after multiple sets' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      described_class.set(:c, 3)
      expect(described_class.values).to contain_exactly(1, 2, 3)
    end

    it 'returns an empty array when the bag is empty' do
      expect(described_class.values).to eq([])
    end

    it 'is isolated across threads (other thread sees empty values)' do
      described_class.set(:main, 'main-val')
      thread_values = Thread.new { described_class.values }.value
      expect(thread_values).to eq([])
    end

    it 'reflects current state after delete' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      described_class.delete(:a)
      expect(described_class.values).to contain_exactly(2)
    end
  end

  describe '.merge' do
    it 'sets multiple keys at once' do
      described_class.merge(a: 1, b: 2, c: 3)
      expect(described_class.to_h).to eq(a: 1, b: 2, c: 3)
    end

    it 'overwrites existing keys' do
      described_class.set(:a, 'old')
      described_class.merge(a: 'new', b: 'added')
      expect(described_class.get(:a)).to eq('new')
      expect(described_class.get(:b)).to eq('added')
    end

    it 'preserves keys not mentioned in the merge' do
      described_class.set(:keep, 'here')
      described_class.merge(other: 'added')
      expect(described_class.get(:keep)).to eq('here')
    end

    it 'returns a snapshot of the state after merging' do
      described_class.set(:existing, 1)
      snapshot = described_class.merge(new_key: 2)
      expect(snapshot).to eq(existing: 1, new_key: 2)
    end

    it 'is a no-op when given no arguments' do
      described_class.set(:a, 1)
      expect(described_class.merge).to eq(a: 1)
      expect(described_class.to_h).to eq(a: 1)
    end
  end

  describe '.replace' do
    it 'replaces all existing keys with the given hash' do
      described_class.set(:old_key, 'value')
      described_class.replace(new_key: 'new_value')
      expect(described_class.to_h).to eq(new_key: 'new_value')
    end

    it 'clears the state when given an empty hash' do
      described_class.set(:a, 1)
      described_class.replace({})
      expect(described_class.empty?).to be true
    end

    it 'returns a snapshot of the new state' do
      result = described_class.replace(x: 1, y: 2)
      expect(result).to eq(x: 1, y: 2)
    end

    it 'is isolated per thread' do
      described_class.set(:main, 'main-val')
      Thread.new { described_class.replace(thread_key: 'thread-val') }.join
      expect(described_class.to_h).to eq(main: 'main-val')
    end

    it 'duplicates the input so later mutations do not leak in' do
      input = { a: 1 }
      described_class.replace(input)
      input[:a] = 999
      expect(described_class.get(:a)).to eq(1)
    end
  end

  describe '.slice' do
    before do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      described_class.set(:c, 3)
    end

    it 'returns a hash of only the requested keys' do
      expect(described_class.slice(:a, :c)).to eq(a: 1, c: 3)
    end

    it 'omits keys that are not present' do
      expect(described_class.slice(:a, :missing)).to eq(a: 1)
    end

    it 'returns an empty hash when no keys match' do
      expect(described_class.slice(:none, :zero)).to eq({})
    end

    it 'returns an empty hash when called with no keys' do
      expect(described_class.slice).to eq({})
    end
  end

  describe '.each' do
    before do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
    end

    it 'yields every key-value pair' do
      collected = {}
      described_class.each { |k, v| collected[k] = v }
      expect(collected).to eq(a: 1, b: 2)
    end

    it 'returns an Enumerator when no block is given' do
      enum = described_class.each
      expect(enum).to be_a(Enumerator)
      expect(enum.to_a).to contain_exactly([:a, 1], [:b, 2])
    end

    it 'iterates over a snapshot (mutation during iteration is safe)' do
      seen = []
      described_class.each do |k, v|
        described_class.set(:c, 99)
        seen << [k, v]
      end
      expect(seen).to contain_exactly([:a, 1], [:b, 2])
    end

    it 'yields nothing when the bag is empty' do
      described_class.clear
      expect { |b| described_class.each(&b) }.not_to yield_control
    end
  end

  describe '.snapshot' do
    it 'returns a Hash containing the current keys' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
      expect(described_class.snapshot).to eq(a: 1, b: 2)
    end

    it 'returns an empty Hash when the bag is empty' do
      expect(described_class.snapshot).to eq({})
    end

    it 'returns a frozen Hash' do
      described_class.set(:a, 1)
      expect(described_class.snapshot).to be_frozen
    end

    it 'is unaffected by subsequent mutations of the store' do
      described_class.set(:a, 1)
      snap = described_class.snapshot
      described_class.set(:a, 999)
      described_class.set(:b, 'new')
      expect(snap).to eq(a: 1)
    end

    it 'is unaffected when keys are deleted from the store' do
      described_class.set(:a, 1)
      snap = described_class.snapshot
      described_class.delete(:a)
      expect(snap).to eq(a: 1)
    end

    it 'cannot be mutated by the caller' do
      described_class.set(:a, 1)
      snap = described_class.snapshot
      expect { snap[:a] = 2 }.to raise_error(FrozenError)
    end
  end

  describe '.restore' do
    it 'replaces the entire state with the given snapshot' do
      described_class.set(:old, 'value')
      described_class.restore(new: 'state')
      expect(described_class.to_h).to eq(new: 'state')
    end

    it 'clears the state when given an empty hash' do
      described_class.set(:a, 1)
      described_class.restore({})
      expect(described_class.empty?).to be true
    end

    it 'returns a snapshot of the new state' do
      result = described_class.restore(x: 1, y: 2)
      expect(result).to eq(x: 1, y: 2)
    end

    it 'does not share references with the input snapshot' do
      input = { a: 1 }
      described_class.restore(input)
      input[:a] = 999
      expect(described_class.get(:a)).to eq(1)
    end

    it 'accepts a frozen snapshot from .snapshot' do
      described_class.set(:a, 1)
      snap = described_class.snapshot
      described_class.set(:a, 2)
      described_class.restore(snap)
      expect(described_class.get(:a)).to eq(1)
    end

    it 'leaves the original snapshot unchanged after subsequent mutations' do
      described_class.set(:a, 1)
      snap = described_class.snapshot
      described_class.restore(snap)
      described_class.set(:a, 99)
      expect(snap).to eq(a: 1)
    end

    it 'raises ArgumentError when given a non-Hash' do
      expect { described_class.restore('not a hash') }
        .to raise_error(ArgumentError, 'snapshot must be a Hash, got String')
    end

    it 'raises ArgumentError when given nil' do
      expect { described_class.restore(nil) }
        .to raise_error(ArgumentError, 'snapshot must be a Hash, got NilClass')
    end

    it 'raises ArgumentError when given an Array' do
      expect { described_class.restore([[:a, 1]]) }
        .to raise_error(ArgumentError, 'snapshot must be a Hash, got Array')
    end

    it 'restores a snapshot taken in another thread' do
      snap = Thread.new do
        described_class.set(:from_thread, 'value')
        described_class.snapshot
      end.value

      described_class.restore(snap)
      expect(described_class.get(:from_thread)).to eq('value')
    end

    it 'is isolated per thread' do
      described_class.set(:main, 'main-val')
      Thread.new { described_class.restore(thread_key: 'thread-val') }.join
      expect(described_class.to_h).to eq(main: 'main-val')
    end
  end

  describe '.update' do
    it 'yields the current value and stores the block result' do
      described_class.set(:counter, 1)
      result = described_class.update(:counter) { |v| v + 1 }
      expect(result).to eq(2)
      expect(described_class.get(:counter)).to eq(2)
    end

    it 'yields nil for a missing key' do
      seen = :unset
      described_class.update(:missing) do |v|
        seen = v
        'first'
      end
      expect(seen).to be_nil
      expect(described_class.get(:missing)).to eq('first')
    end

    it 'stores nil when the block returns nil' do
      described_class.set(:k, 'value')
      described_class.update(:k) { nil }
      expect(described_class.get(:k)).to be_nil
      expect(described_class.key?(:k)).to be true
    end

    it 'raises ArgumentError without a block' do
      expect { described_class.update(:k) }.to raise_error(ArgumentError, 'block required')
    end

    it 'is isolated per thread' do
      described_class.set(:counter, 10)
      Thread.new { described_class.update(:counter) { |v| (v || 0) + 100 } }.join
      expect(described_class.get(:counter)).to eq(10)
    end
  end
end

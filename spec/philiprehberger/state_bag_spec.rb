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
end

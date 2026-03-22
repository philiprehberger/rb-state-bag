# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::StateBag do
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
  end

  describe '.clear' do
    it 'removes all entries' do
      described_class.set(:a, 1)
      described_class.set(:b, 2)
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
  end

  describe '.key?' do
    it 'returns true for existing key' do
      described_class.set(:present, 'yes')
      expect(described_class.key?(:present)).to be true
    end

    it 'returns false for missing key' do
      expect(described_class.key?(:absent)).to be false
    end
  end

  describe 'thread isolation' do
    it 'does not leak state between threads' do
      described_class.set(:main, true)
      result = Thread.new { described_class.get(:main) }.value
      expect(result).to be_nil
    end
  end
end

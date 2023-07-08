# frozen_string_literal: true

require_relative 'state_bag/version'

module Philiprehberger
  module StateBag
    class Error < StandardError; end

    UNSET = Object.new.freeze
    private_constant :UNSET

    # Set a value in the thread-local state bag
    #
    # @param key [Symbol, String] the key to set
    # @param val [Object] the value to store
    # @return [Object] the stored value
    def self.set(key, val)
      store[key] = val
    end

    # Get a value from the thread-local state bag
    #
    # @param key [Symbol, String] the key to retrieve
    # @param default [Object] optional default if key is not found
    # @return [Object] the stored value or default
    def self.get(key, default = nil)
      store.fetch(key, default)
    end

    # Execute a block with temporary state, restoring previous values after
    #
    # @param overrides [Hash] key-value pairs to set during the block
    # @yield the block to execute with the temporary state
    # @return [Object] the return value of the block
    def self.with(**overrides, &block)
      previous = {}
      missing = []

      overrides.each do |k, v|
        if store.key?(k)
          previous[k] = store[k]
        else
          missing << k
        end
        store[k] = v
      end

      block.call
    ensure
      previous.each { |k, v| store[k] = v }
      missing.each { |k| store.delete(k) }
    end

    # Clear all entries from the thread-local state bag
    #
    # @return [void]
    def self.clear
      store.clear
    end

    # Return a snapshot of the current state as a hash
    #
    # @return [Hash] copy of the current state
    def self.to_h
      store.dup
    end

    # Fetch a value from the state bag with strict key checking
    #
    # @param key [Symbol, String] the key to retrieve
    # @param default [Object] optional default if key is not found
    # @yield [key] optional block called when key is not found
    # @return [Object] the stored value, default, or block result
    # @raise [KeyError] if key not found and no default or block given
    def self.fetch(key, default = UNSET, &block)
      if store.key?(key)
        store[key]
      elsif block
        block.call(key)
      elsif default != UNSET
        default
      else
        raise KeyError, "key not found: #{key.inspect}"
      end
    end

    # Remove a key from the state bag
    #
    # @param key [Symbol, String] the key to remove
    # @return [Object] the removed value or nil
    def self.delete(key)
      store.delete(key)
    end

    # Check if a key exists in the state bag
    #
    # @param key [Symbol, String] the key to check
    # @return [Boolean] true if the key exists
    def self.key?(key)
      store.key?(key)
    end

    class << self
      private

      def store
        Thread.current[:philiprehberger_state_bag] ||= {}
      end
    end
  end
end

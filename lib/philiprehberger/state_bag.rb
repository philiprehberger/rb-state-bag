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

    # Dig into nested hash-valued entries using a sequence of keys
    #
    # Mirrors Ruby's Hash#dig. Looks up the first key in the thread-local
    # store, then calls :dig on the resulting value with the remaining keys.
    # Returns nil on any missing key. Raises ArgumentError when no keys are
    # given, and TypeError when an intermediate value does not respond to :dig
    # (matching Hash#dig behavior).
    #
    # @param keys [Array<Symbol, String>] the key path to traverse
    # @return [Object, nil] the nested value, or nil on any miss
    # @raise [ArgumentError] if no keys are given
    def self.dig(*keys)
      raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)' if keys.empty?

      store.dig(*keys)
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

    # Return the number of entries in the state bag.
    #
    # @return [Integer]
    def self.size
      store.size
    end

    # Check whether the state bag is empty.
    #
    # @return [Boolean]
    def self.empty?
      store.empty?
    end

    # Return all keys in the state bag.
    #
    # @return [Array]
    def self.keys
      store.keys
    end

    # Return all values in the state bag.
    #
    # @return [Array]
    def self.values
      store.values
    end

    # Bulk-set multiple entries in the state bag
    #
    # @param entries [Hash] key-value pairs to write
    # @return [Hash] snapshot of the state bag after the merge
    def self.merge(**entries)
      entries.each { |k, v| store[k] = v }
      store.dup
    end

    # Replace the entire state bag with the given hash
    #
    # @param hash [Hash] the new state
    # @return [Hash] snapshot of the state bag after the replacement
    def self.replace(hash)
      store.replace(hash.dup)
      store.dup
    end

    # Return a subset of the state bag containing only the given keys
    #
    # @param keys [Array] keys to extract
    # @return [Hash] subset of the state (keys not present are omitted)
    def self.slice(*keys)
      store.slice(*keys)
    end

    # Iterate over key-value pairs in the state bag
    #
    # @yield [key, value] each key-value pair
    # @return [Enumerator] when no block is given
    # @return [Hash] the state bag snapshot when a block is given
    def self.each(&block)
      return store.dup.each_pair unless block

      store.dup.each_pair(&block)
    end

    # Capture a frozen snapshot of the current state
    #
    # The returned hash is a shallow copy of the thread-local store and is
    # frozen so callers cannot mutate it. Subsequent changes to the state bag
    # do not affect the returned snapshot.
    #
    # @return [Hash] frozen copy of the current state
    def self.snapshot
      store.dup.freeze
    end

    # Replace the current thread-local state with a copy of the given snapshot
    #
    # The snapshot is duplicated before being installed so the state bag does
    # not share references with the caller's hash.
    #
    # @param snapshot [Hash] the snapshot to restore
    # @return [Hash] snapshot of the state bag after the restore
    # @raise [ArgumentError] if snapshot is not a Hash
    def self.restore(snapshot)
      raise ArgumentError, "snapshot must be a Hash, got #{snapshot.class}" unless snapshot.is_a?(Hash)

      store.replace(snapshot.dup)
      store.dup
    end

    class << self
      private

      def store
        Thread.current[:philiprehberger_state_bag] ||= {}
      end
    end
  end
end

#!/usr/bin/ruby
#
#  Provide a caching API for facter facts.
#
#   Copyright 2016 Jeremiah Powell <waveclaw@hotmail.com>
#
#  Based on https://puppet.com/blog/facter-part-3-caching-and-ttl
#
#   See LICENSE for licensing.
#
#
require 'facter'
require 'time'
require 'yaml'

module Facter::Util::Cacheable
  @doc=<<EOF
  Cache a result for a TTL using facter that supports external facts.
  Default Time-to-live is 1 hour (3600 seconds).
EOF
  class << self
    # Get the on disk cached value or hit the callback to find it
    # @param key string The identifier for the data
    # @param ttl integer Time-to-live in seconds which defauls to 1 hr (3600)
    # @param source string Fully-qualified path to altnerative YAML file
    # @return [object] Cached value (hash, string, array, number, etc)
    # @api public
    def cached?(key, ttl = 3600, source = nil)
      cache = nil
      # which cache?
      cache_file = get_cache(key, source)
      # check cache
      if File::exist?(cache_file) then
         begin
           cache = YAML.load_file(cache_file)
           cache_time = File.mtime(cache_file)
         rescue Exception => e
             Facter.debug("#{e.backtrace[0]}: #{$!}.")
             cache = nil
             cache_time = Time.at(0)
         end
       end
       if ! cache || (Time.now - cache_time) > ttl
         cache = nil
       end
       cache
     end

     # Write out a cache of data
     # @param key string The identifier for the data
     # @param ttl integer Time-to-live in seconds which defauls to 1 hr (3600)
     # @param source string Fully-qualified path to altnerative YAML file
     # @return [object] Cached value (hash, string, array, number, etc)
     # @api public
     def cache(key, value, source = nil)
         cache_file = get_cache(key, source)
         begin
           File.open(cache_file, 'w') do |out|
             YAML.dump({key => value}, out)
           end
         rescue Exception => e
           Facter.debug("#{e.backtrace[0]}: #{$!}.")
           cache = nil
         end
     end

     # find a source
     # @param key [symbol] The identifier to use
     # @return file [string] The cachefile location
     # @api private
     def get_cache(key, source)
     if ! source
       if Puppet.features.external_facts?
         cache_dir = Facter.search_external_path[0]
       else
         cache_dir = '/etc/facter/facts.d'
       end
         cache_file = "#{cache_dir}/#{key.to_s}.yaml"
     else
         cache_dir = nil
         cache_file = source
     end
     # side effects are bad, m'kay
     #if cache_dir
     #   if !File::exists?(cache_dir)
     #     Dir.mkdir(cache_dir)
     #   end
     #end
     cache_file
   end
  end
end

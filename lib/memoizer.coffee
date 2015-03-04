Redis = require 'co-subredis'
glob = require 'glob-to-regexp'
module.exports = (options) ->
  options or= {}
  prefix = "co-memoizer:#{options.prefix or Math.random()}:"
  redis = Redis options.redis or {}
  lastCleanup = 0
  cleanupInterval = options.cleanupInterval or 3600000
  cache = {}
  cleanup = ->
    if lastCleanup < Date.now() - cleanupInterval
      lastCleanup = Date.now()
      for own key of cache
        if cache[key].expires < now
          delete cache[key]
  memoize = (key, ttl, fn) ->
    ttl or= options.ttl or 86400000
    now = Date.now()
    expires = cache[key]?.expires
    value
    if expires > now
      value = cache[key]
    else
      value = yield redis.get "#{prefix}#{key}"
      if typeof value is 'string'
        value = JSON.parse value
      else
        value = yield fn key
        redis.psetex "#{prefix}#{key}", ttl, JSON.stringify value
    cache[key] or= {}
    cache[key].value = value
    cache[key].expires = now + ttl
    cleanup()
    value
  memoize.memoize = memoize
  memoize.prefix = prefix
  memoize.unmemoize = (keys) ->
    search = glob "#{keys}"
    unmemoized = cache: []
    for own key of cache
      if search.test key
        delete cache[key]
        unmemoized.cache.push key
    redis.publish "#{prefix}unmemoize", "#{keys}"
    yield redis.del unmemoized.redis = yield redis.keys "#{prefix}#{keys}"
    unmemoized
  redis.on 'message', (channel, message) ->
    if channel is "#{prefix}unmemoize"
      search = glob message
      for own key of cache
        if search.test key
          delete cache[key]
  memoize

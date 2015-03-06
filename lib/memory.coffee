hasOwn = {}.hasOwnProperty
module.exports = class MemoryMemoizer extends require './memoizer'
  constructor: (options, memoizers...) ->
    unless @ instanceof MemoryMemoizer
      return new MemoryMemoizer options
    super.apply @, memoizers
    @cache = {}
    options or= {}
    @ttl = options.ttl|0
  gc: ->
    now = Date.now()
    next = 0
    for own key, cached of @cache
      if now >= cached.expires
        delete @cache[key]
      else if cached.expires <= (next or cached.expires)
        next = cached.expires
    if next
      clearTimeout @_gcTimeout
      @_gcTimeout = setTimeout @gc, next - now
  memoize: (key, ttl, fn) ->
    if ttl instanceof Function
      fn = ttl
      ttl = @ttl
    cached = @cache[key] or= {}
    cached.expires = (@ttl or ttl|0 or 30000)
    if hasOwn.call cached, 'value'
      cached.value
    else
      cached.value = yield super key, ttl, fn
  value: (key, ttl, value) ->
    if @valid value
      @cache[key] =
        expires: Date.now() + (@ttl or ttl|0 or 30000)
        value: value
    else return
    clearTimeout @_gcTimeout
    @_gcTimeout = setTimeout @gc
  remove: (keys) ->
    if typeof keys is 'string'
      delete @cache[key]
    else if keys instanceof RegExp
      for own key of @cache
        if keys.test key
          delete @cache[key]
    else return
    clearTimeout @_gcTimeout
    @_gcTimeout = setTimeout @gc

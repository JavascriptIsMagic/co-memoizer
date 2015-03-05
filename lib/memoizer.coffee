module.exports = class Memoizer extends process.EventEmitter
  constructor: (memoizers...) ->
    unless @ instanceof Memoizer
      return new Memoizer memoizers
    @memoizers = memoizers unless Array.isArray memoizers[0] then memoizers[0]
    for memoizer in @memoizers
      memoizer.emit 'init', @
  valid: (value) -> value
  init: (parent) ->
    parent.on 'value', @emit.bind @, 'value'
    parent.on 'remove', @emit.bind @, 'remove'
  memoize: (key, ttl, fn) ->
    for memoizer, index in @memoizers
      next = @memoizers[index + 1]
      value = yield memoizer.memoize key, ttl, next.memoize.bind next
      if memoizer.valid value
        @emit 'value', key, ttl, value
        return value
    if fn
      yield fn key, ttl
  unmemoize: (key) ->
    @emit 'remove', key

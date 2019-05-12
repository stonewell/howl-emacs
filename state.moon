import bindings from howl
import setfenv, pairs, callable, tostring, pcall, error from _G

_G = _G
_ENV = {}
setfenv 1, _ENV

export active, executing = false, false
export count

export activate = (editor) ->
  unless active
      active = true

export deactivate = ->
  if active
    bindings.pop!
    active = false

export init = ->
  reset!

export reset = ->
  active = false
  count = nil
  bindings.cancel_capture!

export add_number = (number) ->
  count = count or 0
  count = (count * 10) + number
  
return _ENV

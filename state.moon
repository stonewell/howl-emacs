import bindings from howl
import setfenv, pairs, callable, tostring, pcall, error from _G

_G = _G
_ENV = {}
setfenv 1, _ENV

export active, executing = false, false

export activate = (editor) ->
  unless active
      active = true

export deactivate = ->
  if active
    bindings.pop!
    active = false

export init = ->
  active = false
  
return _ENV

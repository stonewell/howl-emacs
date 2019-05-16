import app, signal, config, command from howl
import Editor from howl.ui
import bindings from howl

state = bundle_load 'state'

cancel = (editor) ->
  if editor and editor.selection
    editor.selection.persistent = false
    editor.selection\remove!

  if app.window.command_line.showing
     app.window.command_line\abort_all!

push_mark = (editor) ->
  editor.selection.persistent = true

cut = (editor) ->
  editor\cut!
  cancel editor

copy = (editor) ->
  editor\copy!
  cancel editor

paste = (editor) ->
  editor\paste!
  cancel editor

sel_paste = (editor) ->
  howl.command.run 'editor-paste..'
  cancel editor

ctrl_x_map = {
  ctrl_f: 'open'
  ctrl_s: 'save'
  ctrl_w: 'save-as'
  ctrl_c: 'quit'
  b: 'switch-buffer'
  k: 'buffer-close'
  h: 'editor-select-all'
  o: 'view-next'
  '0': 'view-close'
  '2': 'view-new-below'
  '3': 'view-new-right-of'
}

ctrl_u_map = {
  on_unhandled: (event, source, translations) ->
    char = event.character
    modifiers = event.control or event.alt
    if char and not modifiers
      if char\match '^%d$'
        state.add_number tonumber char

      return -> true
}

key_map = {
  editor: {
      ctrl_b: 'cursor-left'
      ctrl_f: 'cursor-right'
      ctrl_p: 'cursor-up'
      ctrl_n: 'cursor-down'
      alt_v: 'cursor-page-up'
      ctrl_v: 'cursor-page-down'
      ctrl_e: 'cursor-line-end'
      ctrl_a: 'cursor-home'

      ctrl_w: cut
      alt_w: copy
      ctrl_y: paste
      alt_y: sel_paste

      ctrl_d: 'editor-delete-forward'
      ctrl_k: 'editor-cut-to-end-of-line'

      ctrl_s: 'buffer-search-forward'
      ctrl_r: 'buffer-search-backward'

      ctrl_shift_underscore: 'editor-undo'

      alt_g: {
        alt_g: 'cursor-goto-line'
      }

      alt_x: 'run'

      ctrl_l: (editor) -> editor.line_at_center = editor.cursor.line

      ctrl_x: (editor) -> bindings.push ctrl_x_map, {pop: true}

      ctrl_period: push_mark
      ctrl_g: cancel
   }

  commandline: {
    ctrl_g: cancel
  }

  for_os: {
      osx: {
        editor: {
          alt_2262: 'cursor-page-up'

          alt_16785937: copy
          alt_165: sel_paste

          alt_169: {
            alt_169: 'cursor-goto-line'
          }
        }

        alt_16785992: 'run'
      }
   }
}

emacs_commands = {
  {
    name: 'emacs-on'
    description: 'Switches Emacs mode on'
    handler: ->
      unless state.active
        for editor in *howl.app.editors
            editor.selection.includes_cursor = false
            editor.indicator.emacs.label = 'Emacs On'
        bindings.push key_map

        command_line = app.window.command_line
        command_line.old_handle_keypress = command_line.handle_keypress
        command_line.handle_keypress = (event) =>
          val = @old_handle_keypress event
          if not val
             return true if bindings.dispatch event, 'commandline', {key_map}, self
          return val

        state.activate(app.editor)
  }

  {
    name: 'emacs-off'
    description: 'Switches Emacs mode off'
    handler: ->
      if state.active
        state.deactivate!
        for editor in *howl.app.editors
            with editor
              .indicator.emacs.label = ''
        bindings.pop!
  }
}

unload = ->
  command.emacs_off!

  command.unregister cmd.name for cmd in *emacs_commands

  Editor.unregister_indicator 'emacs'

-- Hookup
Editor.register_indicator 'emacs', 'bottom_left'
state.init!

command.register cmd for cmd in *emacs_commands

info = {
  author: 'Jingnan Si',
  description: 'Emacs bundle',
  license: 'MIT',
}

return :info, :unload, :state

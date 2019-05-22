import app, signal, config, command, clipboard,interact from howl
import Editor from howl.ui
import bindings from howl

state = bundle_load 'state'

cancel = (editor) ->
  if editor and editor.selection
    editor.selection.persistent = false
    editor.selection\remove!

  app.editor\cancel_preview!

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

run_history_cmd = ->
  command_line = app.window.command_line
  text = command_line.text
  command_line\clear!
  command_line\write_spillover text
  cmd_string = interact.select_historical_command!
  if cmd_string
    command_line\write cmd_string.stripped

kill_to_end_of_line = (editor) ->
  cur_line = editor.current_line

  if cur_line.size == 0
    editor\delete_line!
  elseif editor.cursor.pos == cur_line.end_pos
    editor\join_lines!
  else
    text = cur_line.text\usub editor.cursor.column_index, -1
    if text.ulen > 0
      cur_line.text = cur_line.text\usub 1, editor.cursor.column_index - 1
      clipboard.push text: text, whole_lines: false

  cancel editor

ctrl_x_map = {
  ctrl_f: 'open'
  ctrl_s: 'save'
  ctrl_w: 'save-as'
  ctrl_c: 'quit'
  b: 'open-recent'
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
      ctrl_k: kill_to_end_of_line

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
    ctrl_n: run_history_cmd
    ctrl_p: run_history_cmd
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
        command_line = app.window.command_line
        command_line.handle_keypress = command_line.old_handle_keypress
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

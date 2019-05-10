import app, signal, config, command from howl
import Editor from howl.ui
import bindings from howl

state = bundle_load 'state'

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

      ctrl_y: 'editor-paste'
      alt_w: 'editor-copy'
      alt_y: 'editor-paste..'

      ctrl_d: 'editor-delete-forward'
      ctrl_k: 'editor-cut-to-end-of-line'
      ctrl_w: 'editor-cut'

      ctrl_s: 'buffer-search-forward'
      ctrl_r: 'buffer-search-backward'

      ctrl_shift_underscore: 'editor-undo'

      alt_g: {
        alt_g: 'cursor-goto-line'
      }

   }

   ctrl_x: {
      ctrl_f: 'open'
      ctrl_s: 'save'
      ctrl_w: 'save-as'
      b: 'switch-buffer'
      k: 'buffer-close'
      h: 'editor-select-all'
      o: 'view-next'
      backslash: 'view-new-right-of'
      minus: 'view-new-below'
      ctrl_c: 'quit'
      c: 'view-close'
   },

   for_os: {
      osx: {
        editor: {
          alt_2262: 'cursor-page-up'

          alt_16785937: 'editor-copy'
          alt_165: 'editor-paste..'

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
            editor.selection.includes_cursor = true
            editor.indicator.emacs.label = 'Emacs On'
        bindings.push key_map
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
state.init 'command', 'command'

command.register cmd for cmd in *emacs_commands

info = {
  author: 'Jingnan Si',
  description: 'Emacs bundle',
  license: 'MIT',
}

return :info, :unload, :state

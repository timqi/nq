local wezterm = require 'wezterm'
local act = wezterm.action

default_cwd = os.getenv("HOME")..'/Downloads'
local scheme = wezterm.get_builtin_color_schemes()['VSCodeDark+ (Gogh)']
scheme.cursor_fg = '#eeeeee'
scheme.cursor_bg = '#44ee44'
scheme.selection_fg = '#444444'
scheme.selection_bg = '#c2c2c2'


return {
  check_for_updates = false,
  selection_word_boundary = " \t\n{}[]()\"'`.,;:|+",
  hide_tab_bar_if_only_one_tab = false,
  color_scheme = 'VSCode',
  color_schemes = { ['VSCode'] = scheme, },
  initial_rows = 240,
  initial_cols = 360,
  window_background_opacity = 0.90,
  font = wezterm.font('Monaco'),
  font_size = 18.0,
  default_cwd = default_cwd,
  window_decorations = "RESIZE",
  window_padding = {left = 4, right = 4, top = 4, bottom = 1,},
  keys = {
      {key='t', mods='CMD', action = act.SpawnCommandInNewTab{cwd = default_cwd}, },
      {key='p', mods='CMD|SHIFT', action = act.ShowLauncherArgs{flags = 'FUZZY|LAUNCH_MENU_ITEMS|COMMANDS'}, },
  },
}


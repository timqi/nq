local wezterm = require 'wezterm'
local act = wezterm.action

default_cwd = os.getenv("HOME")..'/Downloads'

return {
  hide_tab_bar_if_only_one_tab = false,
  color_scheme = 'Dracula',
  window_background_opacity = 0.86,
  font = wezterm.font('Inconsolata'),
  font_size = 22.0,
  harfbuzz_features = {'calt=0', 'clig=0', 'liga=0'},
  default_cwd = default_cwd,
  default_cursor_style = 'BlinkingBlock',
  window_decorations = "RESIZE",
  window_padding = {left = 4, right = 4, top = 4, bottom = 1,},
  keys = {
      {key='t', mods='CMD', action = act.SpawnCommandInNewTab{cwd = default_cwd}, },
      {key='h', mods='CMD|SHIFT', action = act.SplitHorizontal, },
      {key='g', mods='CMD|SHIFT', action = act.SplitVertical, },
      {key='p', mods='CMD|SHIFT', action = act.ShowLauncher, },
  }
}


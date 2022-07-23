local wezterm = require 'wezterm'
local act = wezterm.action

default_cwd = os.getenv("HOME")..'/Downloads'

return {
  hide_tab_bar_if_only_one_tab = false,
  color_scheme = 'Dracula',
  window_background_opacity = 0.90,
  font = wezterm.font('SF Mono'),
  font_size = 19.0,
  harfbuzz_features = {'calt=0', 'clig=0', 'liga=0'},
  default_cwd = default_cwd,
  default_cursor_style = 'BlinkingBlock',
  window_decorations = "RESIZE",
  window_padding = {left = 0, right = 0, top = 0, bottom = 0,},
  keys = {
      {key='t', mods='CMD', action = act.SpawnCommandInNewTab{cwd = default_cwd}, },
      {key='h', mods='CMD|SHIFT', action = act.SplitHorizontal, },
      {key='g', mods='CMD|SHIFT', action = act.SplitVertical, },
      {key='p', mods='CMD|SHIFT', action = act.ShowLauncher, },
  }
}


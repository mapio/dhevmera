local wezterm = require 'wezterm'

local act = wezterm.action

wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(window:active_workspace())
end)

return {
  window_decorations = "TITLE | RESIZE",
  enable_wayland = true,
  initial_cols = 132, 
  initial_rows = 30,
  font_size = 14.0,
  color_scheme = "Gruvbox light, soft (base16)",
  hide_tab_bar_if_only_one_tab = true,
  font = wezterm.font {
    family = 'Fira Code Retina',
    harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
  },
  hyperlink_rules = {
    {
      regex = [[\b\w+://[\w.-]+\.[a-z]{2,15}\S*\b]],
      format = '$0',
    },
    {
      regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
      format = '$0',
    },
  },
  keys = {
    { key = 'L', mods = 'CTRL', action = wezterm.action.ShowLauncher },
    { key = 'n', mods = 'CTRL', action = act.SwitchWorkspaceRelative(1) },
    { key = 'p', mods = 'CTRL', action = act.SwitchWorkspaceRelative(-1) },  
    { key = '0', mods = 'CTRL', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
    {
      key = '9', mods = 'CTRL',
      action = act.PromptInputLine {
        description = wezterm.format {
          { Attribute = { Intensity = 'Bold' } },
          { Foreground = { AnsiColor = 'Fuchsia' } },
          { Text = 'Enter name for new workspace' },
        },
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:perform_action(
              act.SwitchToWorkspace {
                name = line,
              },
              pane
            )
          end
        end),
      },
    },
    {
      key = '"',
      mods = 'CTRL|SHIFT|ALT',
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    }
}
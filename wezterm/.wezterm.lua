-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

wezterm.on("update-status", function(window)
	window:set_right_status(window:active_workspace())
end)

wezterm.on("gui-startup", function()
	local tab, pane, window = mux.spawn_window({})

	window:set_workspace("default")
	-- window:gui_window():maximize()
end)

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.unix_domains = {
	{
		name = "unix",
	},
}

config.default_gui_startup_args = { "connect", "unix" }

config.color_scheme = "MaterialDarker"
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Catppuccin L

config.scrollback_lines = 7500
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
-- config.window_background_opacity = 0.9
-- config.macos_window_background_blur = 16
config.window_padding = {
	left = "16px",
	right = "16px",
	top = "12px",
	bottom = "12px",
}

config.font = wezterm.font_with_fallback({
	"FiraCode Nerd Font Mono",
})

config.font_size = 16
config.line_height = 1.2

config.inactive_pane_hsb = {
	saturation = 0.75,
	brightness = 0.6,
}

config.keys = {
	-- This will create a new split and run your default program inside it
	{
		key = "d",
		mods = "CMD",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "CMD|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CMD",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "w",
		mods = "CMD|SHIFT",
		action = act.CloseCurrentTab({ confirm = true }),
	},
	{ key = "p", mods = "ALT", action = act.PaneSelect },
	{
		key = "[",
		mods = "CMD",
		action = act.ActivatePaneDirection("Prev"),
	},
	{
		key = "]",
		mods = "CMD",
		action = act.ActivatePaneDirection("Next"),
	},
	{ key = "c", mods = "CMD|SHIFT", action = act.ActivateCopyMode },
	-- Show the launcher in fuzzy selection mode and have it list all workspaces
	-- and allow activating one.
	{
		key = "0",
		mods = "ALT",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
		}),
	},
	{
		key = "-",
		mods = "ALT",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|DOMAINS",
		}),
	},
	{
		key = "=",
		mods = "ALT",
		action = act.ShowLauncher,
	},
	{
		key = "h",
		mods = "ALT",
		action = wezterm.action.TogglePaneZoomState,
	},
	-- Prompt for a name to use for a new workspace and switch to it.
	{
		key = "n",
		mods = "CMD|SHIFT",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},
	{
		key = "d",
		mods = "CTRL|SHIFT|ALT",
		action = act.DetachDomain("CurrentPaneDomain"),
	},
}

-- and finally, return the configuration to wezterm
return config

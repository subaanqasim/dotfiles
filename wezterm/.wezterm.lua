-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
-- local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

wezterm.on("update-status", function(window)
	window:set_right_status(window:active_workspace())
end)

wezterm.on("gui-startup", function()
	local tab, pane, window = mux.spawn_window({})

	window:set_workspace("default")
	-- window:gui_window():maximize()
end)

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
local config = wezterm.config_builder()

config.unix_domains = {
	{
		name = "unix",
	},
}

config.default_gui_startup_args = { "connect", "unix" }
config.term = "wezterm"

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
local function get_appearance()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Tokyo Night"
	else
		return "Tokyo Night Day"
	end
end

config.color_scheme = scheme_for_appearance(get_appearance())
-- config.color_scheme = "Tokyo Night"

config.scrollback_lines = 7500
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
-- config.window_background_opacity = 0.95
-- config.macos_window_background_blur = 16
config.window_padding = {
	left = "16px",
	right = "16px",
	top = "24px",
	bottom = "12px",
}

config.font = wezterm.font_with_fallback({
	"GeistMono Nerd Font Mono",
	-- "FiraCode Nerd Font Mono",
})

config.font_size = 16.5
config.line_height = 1.2

config.inactive_pane_hsb = {
	saturation = 0.75,
	brightness = 0.6,
}

local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
	LeftArrow = "Left",
	DownArrow = "Down",
	UpArrow = "Up",
	RightArrow = "Right",
}

local function smart_split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

config.keys = {
	-- move between split panes
	smart_split_nav("move", "h"),
	smart_split_nav("move", "j"),
	smart_split_nav("move", "k"),
	smart_split_nav("move", "l"),
	-- resize panes
	-- smart_split_nav("resize", "LeftArrow"),
	-- smart_split_nav("resize", "DownArrow"),
	-- smart_split_nav("resize", "UpArrow"),
	-- smart_split_nav("resize", "RightArrow"),
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

-- https://github.com/mrjones2014/smart-splits.nvim?tab=readme-ov-file#wezterm
-- smart_splits.apply_to_config(config, {
-- 	-- the default config is here, if you'd like to use the default keys,
-- 	-- you can omit this configuration table parameter and just use
-- 	-- smart_splits.apply_to_config(config)
--
-- 	-- directional keys to use in order of: left, down, up, right
-- 	-- direction_keys = { 'h', 'j', 'k', 'l' },
-- 	-- if you want to use separate direction keys for move vs. resize, you
-- 	-- can also do this:
-- 	direction_keys = {
-- 		move = { "h", "j", "k", "l" },
-- 		resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
-- 	},
-- 	-- modifier keys to combine with direction_keys
-- 	modifiers = {
-- 		move = "CTRL", -- modifier to use for pane movement, e.g. CTRL+h to move left
-- 		resize = "CTRL", -- modifier to use for pane resize, e.g. CTRL+LeftArrow to resize to the left
-- 	},
-- })

-- and finally, return the configuration to wezterm
return config

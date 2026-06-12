-- Fade inactive nvim windows, including when the whole tmux pane loses
-- focus (needs tmux focus-events, which tmux-sensible enables).
return {
  {
    "tadaa/vimade",
    event = "VeryLazy",
    opts = {
      ncmode = "windows",
      -- bg-only dimming: tmux can't fade other panes' colored text, so
      -- nvim keeps full-brightness text too (fadelevel 1 = no text fade)
      -- and signals focus the same way every pane does — via bg color.
      fadelevel = 1,
      enablefocusfading = true,
      -- Faded bg matches tmux window-style (#1f2335) so every inactive
      -- pane — nvim or not — shares one inactive color.
      tint = {
        bg = { rgb = { 31, 35, 53 }, intensity = 1 },
      },
    },
  },
}

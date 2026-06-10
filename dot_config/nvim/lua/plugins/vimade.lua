-- Fade inactive nvim windows, including when the whole tmux pane loses
-- focus (needs tmux focus-events, which tmux-sensible enables).
return {
  {
    "tadaa/vimade",
    event = "VeryLazy",
    opts = {
      ncmode = "windows",
      fadelevel = 0.6,
      enablefocusfading = true,
    },
  },
}

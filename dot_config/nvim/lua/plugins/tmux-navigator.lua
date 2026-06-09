-- Seamless Ctrl+hjkl navigation between nvim splits and tmux panes.
-- Pairs with the matching plugin in ~/.config/tmux/tmux.conf.
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window left (tmux-aware)" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window down (tmux-aware)" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window up (tmux-aware)" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window right (tmux-aware)" },
    },
  },
}

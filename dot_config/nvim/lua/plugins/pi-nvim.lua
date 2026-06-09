-- Pi / Neovim bridge
return {
  {
    "aliou/nvim-pi",
    lazy = false,
    config = function()
      require("pi-nvim").setup({
        load_extension = "auto",
      })
    end,
    keys = {
      { "<leader>po", function() require("pi-nvim").open() end, desc = "Open Pi" },
      { "<leader>pc", function() require("pi-nvim").close() end, desc = "Close Pi" },
      { "<leader>pp", function() require("pi-nvim").toggle() end, desc = "Toggle Pi" },
    },
  },
}

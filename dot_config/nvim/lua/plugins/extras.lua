-- LazyVim extras
-- To discover new extras, run :LazyExtras in Neovim, then add the import line here.
-- Format: { import = "lazyvim.plugins.extras.<category>.<name>" }
return {
  { import = "lazyvim.plugins.extras.coding.yanky" },
  { import = "lazyvim.plugins.extras.editor.overseer" },
  { import = "lazyvim.plugins.extras.editor.refactoring" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.linting.eslint" },
  { import = "lazyvim.plugins.extras.test.core" },
  { import = "lazyvim.plugins.extras.ui.smear-cursor" },
  { import = "lazyvim.plugins.extras.util.chezmoi" },
  { import = "lazyvim.plugins.extras.util.dot" },
  { import = "lazyvim.plugins.extras.util.startuptime" },

  -- workaround: refactoring.nvim 2.0 requires async.nvim
  -- but LazyVim hasn't released the fix yet (LazyVim#7130)
  -- TODO: remove once LazyVim includes this dependency
  { "lewis6991/async.nvim" },
}

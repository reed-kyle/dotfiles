return {
  -- workaround: refactoring.nvim 2.0 requires async.nvim
  -- but LazyVim hasn't released the fix yet (LazyVim#7130)
  -- TODO: remove once LazyVim includes this dependency
  { "lewis6991/async.nvim" },
}

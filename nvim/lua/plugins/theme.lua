local function generated_colorscheme()
  local generated = vim.fn.expand("~/dotfiles/generated/nvim/theme.lua")
  local colorscheme = "nord"

  if vim.fn.filereadable(generated) == 1 then
    local ok, value = pcall(dofile, generated)
    if ok and type(value) == "string" and value ~= "" then
      colorscheme = value
    end
  end

  return colorscheme
end

local function apply_generated_colorscheme()
  local colorscheme = generated_colorscheme()
  local light_schemes = {
    ["rose-pine-dawn"] = true,
    ["catppuccin-latte"] = true,
    ["flexoki-light"] = true,
  }
  local background = light_schemes[colorscheme] and "light" or "dark"

  if vim.o.background ~= background then
    vim.o.background = background
  end

  if vim.g.colors_name ~= colorscheme then
    local ok = pcall(vim.cmd.colorscheme, colorscheme)
    if not ok then
      pcall(vim.cmd.colorscheme, background == "light" and "rose-pine-dawn" or "nord")
    end
  else
    vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
  end
end

return {
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "shaunsingh/nord.nvim",     lazy = true },
  { "rose-pine/neovim",         name = "rose-pine", lazy = true },
  {
    "LazyVim/LazyVim",
    opts = function()
      return { colorscheme = generated_colorscheme() }
    end,
    init = function()
      local uv = vim.uv or vim.loop
      local theme_file = vim.fn.expand("~/dotfiles/generated/nvim/theme.lua")
      local theme_dir = vim.fn.fnamemodify(theme_file, ":h")
      local theme_name = vim.fn.fnamemodify(theme_file, ":t")
      local watcher = uv.new_fs_event()

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          apply_generated_colorscheme()

          if not watcher then
            return
          end

          watcher:start(theme_dir, {}, vim.schedule_wrap(function(err, filename)
            if err or (filename and filename ~= theme_name) then
              return
            end

            vim.defer_fn(apply_generated_colorscheme, 40)
          end))
        end,
      })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        once = true,
        callback = function()
          if watcher then
            watcher:stop()
            watcher:close()
          end
        end,
      })
    end,
  },
}

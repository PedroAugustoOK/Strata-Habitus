vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "lazy", "mason", "notify", "qf", "checkhealth" },
  callback = function(e)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = e.buf, silent = true })
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(e)
    local mark  = vim.api.nvim_buf_get_mark(e.buf, '"')
    local count = vim.api.nvim_buf_line_count(e.buf)
    if mark[1] > 0 and mark[1] <= count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

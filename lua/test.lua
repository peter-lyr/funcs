function M.print(...)
  for _, param in ipairs { ..., } do
    vim.print(M.format('%s:', param), param)
  end
end

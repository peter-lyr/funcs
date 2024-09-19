function M.print(...)
  for _, param in ipairs { ..., } do
    vim.print(M.format('%s:', param), param)
  end
end

function M.get_input(val, prompt, default)
  if not val then
    val = vim.fn.input(prompt .. ': ')
  end
  if not val then
    return default
  end
  return val
end

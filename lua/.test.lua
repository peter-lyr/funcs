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

-- vim.bo[vim.fn.bufnr()].modified
-- vim.api.nvim_get_option_value('modified', { buf = vim.fn.bufnr(), })

-- vim.api.nvim_get_option_value('winfixheight', { win = winid, })

function M.set_bo(bo, val, win)
  if not win then
    win = vim.fn.win_getid()
  end
  vim.bo[win][bo] = val
end

function M.get_bo(bo, win)
  if not win then
    win = vim.fn.win_getid()
  end
  return vim.bo[win][bo]
end

function M.toggle_bo(bo, a, b)
  if M.get_bo(bo) == a then
    M.set_bo(bo, b)
  else
    M.set_bo(bo, a)
  end
end

function M.set_wo(wo, val, win)
  if not win then
    win = vim.fn.win_getid()
  end
  vim.wo[win][wo] = val
end

function M.get_wo(wo, win)
  if not win then
    win = vim.fn.win_getid()
  end
  return vim.wo[win][wo]
end

function M.toggle_wo(wo, a, b)
  if M.get_wo(wo) == a then
    M.set_wo(wo, b)
  else
    M.set_wo(wo, a)
  end
end

function M.git_add_commit_push_do(commit, dir)
  M.run_silent {
    'cd', '/d', dir, '&&',
    'git', 'add', '.', '&&',
    'git', 'commit', '-m', commit, '&&',
    'git', 'push',
  }
end

function M.git_add_commit_push(commit, dir)
  if not dir then
    M.project_cd()
    dir = M.get_cwd()
  end
  M.run_silent {
    'cd', '/d', dir, '&&',
    'git', 'status',
  }
  M.copy_multiple_filenames()
  if not M.is(commit) then
    vim.ui.input({ prompt = 'commit info: ', }, function(c)
      if c then
        M.git_add_commit_push_do(c, dir)
      end
    end)
  else
    M.git_add_commit_push_do(commit, dir)
  end
end

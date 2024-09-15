local M = {}

function M.get_win_buf_nrs()
  local buf_nrs = {}
  for wnr = 1, vim.fn.winnr '$' do
    buf_nrs[#buf_nrs + 1] = vim.fn.winbufnr(wnr)
  end
  return buf_nrs
end

function M.get_win_buf_names()
  local buf_names = {}
  local win_buf_nrs = M.get_win_buf_nrs()
  for bnr in ipairs(win_buf_nrs) do
    buf_names[#buf_names + 1] = vim.api.nvim_buf_get_name(bnr)
  end
  return buf_names
end

function M.is(val)
  if not val or val == 0 or val == '' or val == false or val == {} then
    return nil
  end
  return 1
end

function M.is_buf_modifiable(bnr)
  return not vim.api.nvim_buf_is_valid(bnr) or M.is(vim.api.nvim_get_option_value('modifiable', { buf = bnr, }))
end

function M.put(arr, item)
  arr[#arr + 1] = item
end

function M.get_win_buf_modifiable_nrs()
  local buf_nrs = {}
  for bnr in ipairs(M.get_win_buf_nrs()) do
    if M.is(M.is_buf_modifiable(bnr)) then
      M.put(buf_nrs, bnr)
    end
  end
  return buf_nrs
end

function M.is_cur_last_win()
  return #M.get_win_buf_modifiable_nrs() <= 1 and 1 or nil
end

function M.cmd(str_format, ...)
  local cmd = string.format(str_format, ...)
  local _sta, _ = pcall(vim.cmd, cmd)
  if _sta then
    return cmd
  end
  return nil
end

function M.window_go(dir)
  M.cmd('wincmd %s', dir)
end

function M.window_delete(dir)
  if dir then
    local wid = vim.fn.win_getid()
    M.window_go(dir)
    if wid ~= vim.fn.win_getid() then
      vim.cmd 'q'
    end
    vim.fn.win_gotoid(wid)
  else
    if not M.is(M.is_cur_last_win()) then
      vim.cmd 'q'
    end
  end
end

function M.edit(file)
  M.cmd('e %s', file)
end

function M.jump_or_split(file)
  M.edit(file)
end

function M.clone_if_not_exist(dir, root, repo)
  if not root then
    root = Home
  end
  if not repo then
    repo = dir
  end
end

return M

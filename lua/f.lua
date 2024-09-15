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

return M

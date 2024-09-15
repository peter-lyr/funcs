local M = {}

local pp = require 'plenary.path'

ParamsCnt = 0

if vim.fn.isdirectory(Dp) == 0 then
  vim.fn.mkdir(Dp)
end

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

function M.rep(content)
  content = string.gsub(content, '/', '\\')
  return content
end

function M.rep_slash(content)
  content = string.gsub(content, '\\', '/')
  return content
end

function M.lower(content)
  return vim.fn.tolower(content)
end

function M.new_file(file)
  return pp:new(file)
end

function M.is_file_exists(file)
  file = vim.fn.trim(file)
  if #file == 0 then
    return nil
  end
  local fp = M.new_file(file)
  if fp:exists() then
    return fp
  end
  return nil
end

function M.join_path(dir, ...)
  if ... then
    return M.new_file(dir):joinpath(...).filename
  end
  return dir
end

function M.start(cmd)
  M.cmd([[silent !start cmd /c "%s"]], cmd)
end

function M.start_silent(cmd)
  M.cmd([[silent !start /b /min cmd /c "%s"]], cmd)
end

function M.format(str_format, ...)
  return string.format(str_format, ...)
end

function M.join(arr, sep)
  return vim.fn.join(arr, sep)
end

function M.write_lines_to_file(lines, file)
  vim.fn.writefile(lines, file)
end

function M.get_extra_file(dir, name)
  return M.format('%s\\%s\\%s', Config, dir, name)
end

function M.get_py(name)
  return M.get_extra_file('pys', name)
end

function M.print(...)
  vim.print(...)
end

function M.run_py_do(cmd, silent)
  if silent then
    M.start_silent(cmd)
  else
    M.start(cmd)
  end
end

function M.run_py_get_cmd(file, params)
  ParamsTxt = M.format('%s\\params-%s.txt', Dp, ParamsCnt)
  local cmd = M.format('python "%s"', file)
  if #params > 0 then
    M.write_lines_to_file(params, ParamsTxt)
    cmd = M.format('%s "%s"', cmd, ParamsTxt)
    ParamsCnt = ParamsCnt + 1
  end
  return cmd
end

function M.run_py(file, params)
  M.run_py_do(M.run_py_get_cmd(file, params))
end

function M.run_py_silent(file, params)
  M.run_py_do(M.run_py_get_cmd(file, params), true)
end

function M.clone_if_not_exist(dir, root, repo)
  if not root then
    root = Home
  end
  if not repo then
    repo = dir
  end
  local dir2 = M.join_path(root, dir)
  if not M.is_file_exists(dir2) then
    M.run_py(M.get_py '01-git-clone.py', { root, Name, repo, })
  end
end

M.clone_if_not_exist 'org'

return M

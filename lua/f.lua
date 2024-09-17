local M = {}

local pp = require 'plenary.path'

ParamsCnt = 0
M.win_pos = 0

if vim.fn.isdirectory(Dp) == 0 then
  vim.fn.mkdir(Dp)
end

if vim.fn.isdirectory(DpTemp) == 0 then
  vim.fn.mkdir(DpTemp)
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

function M.is_file(file)
  local fp = M.is_file_exists(M.rep(file))
  if fp and fp:is_file() then
    return 1
  end
  return nil
end

function M.is_dir(file)
  local fp = M.is_file_exists(M.rep(file))
  if fp and fp:is_dir() then
    return 1
  end
  return nil
end

function M.ui_sel(items, opts, callback)
  if type(opts) == 'string' then
    opts = { prompt = opts, }
  end
  if items and #items > 0 then
    vim.ui.select(items, opts, callback)
  end
end

function M.get_telescope_builtins()
  local builtins = {}
  for k, _ in pairs(require 'telescope.builtin') do
    M.put(builtins, k)
  end
  return builtins
end

function M.is_in_tbl(item, tbl)
  return M.is(vim.tbl_contains(tbl, item))
end

function M.get_telescope_extras()
  local telescopes = {}
  local builtins = M.get_telescope_builtins()
  for _, t in ipairs(vim.fn.getcompletion('Telescope ', 'cmdline')) do
    if not M.is_in_tbl(t, builtins) then
      telescopes[#telescopes + 1] = t
    end
  end
  return telescopes
end

function M.telescope_extras()
  local telescopes = M.get_telescope_extras()
  M.ui_sel(telescopes, 'telescope_extras', function(t)
    if t then
      M.cmd('Telescope %s', t)
    end
  end)
end

function M.edit(file)
  if M.is_dir(file) then
    vim.cmd 'Lazy load telescope'
  end
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
  return pp:new(M.rep(file))
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
  return M.format('%s\\%s\\%s', StdConfig, dir, name)
end

function M.get_py(name)
  return M.get_extra_file('pys', name)
end

function M.print(...)
  vim.print(...)
end

function M.printf(...)
  vim.print(string.format(...))
end

function M.start_do(cmd, opts)
  if opts.way == 'silent' then
    M.cmd([[silent !start /b /min cmd /c "%s"]], cmd)
  else
    if opts.way == 'outside' then
      M.cmd([[silent !start cmd /c "%s"]], cmd)
    elseif opts.way == 'term' then
      M.cmd([[sp|te %s]], cmd)
    elseif opts.way == 'inner' then
      M.cmd([[!%s]], cmd)
    end
  end
end

function M.run_py_get_cmd(file, params)
  ParamsTxt = M.format('%s\\params-%s.txt', DpTemp, ParamsCnt)
  local cmd = M.format('python "%s"', file)
  if #params > 0 then
    M.write_lines_to_file(params, ParamsTxt)
    cmd = M.format('%s "%s"', cmd, ParamsTxt)
    ParamsCnt = ParamsCnt + 1
  end
  return cmd
end

function M.start_term(cmd_params)
  M.start_do(M.run_py_get_cmd(M.get_py '02-run-cmd.py', cmd_params), { way = 'term', })
end

function M.start_outside(cmd_params)
  M.start_do(M.run_py_get_cmd(M.get_py '02-run-cmd.py', cmd_params), { way = 'outside', })
end

function M.start_inner(cmd_params)
  M.start_do(M.run_py_get_cmd(M.get_py '02-run-cmd.py', cmd_params), { way = 'inner', })
end

function M.start_outside_pause(cmd_params)
  M.put(cmd_params, '&&')
  M.put(cmd_params, 'pause')
  M.start_outside(cmd_params)
end

function M.start_silent(cmd_params)
  M.start_do(M.run_py_get_cmd(M.get_py '02-run-cmd.py', cmd_params), { way = 'silent', })
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
    M.start_do(M.run_py_get_cmd(M.get_py '01-git-clone.py', { root, Name, repo, }), { way = 'outside', })
  end
end

M.clone_if_not_exist 'org'

function M.win_max_height()
  local cur_winnr = vim.fn.winnr()
  local cur_wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local cur_start_col = cur_wininfo['wincol']
  local cur_end_col = cur_start_col + cur_wininfo['width']
  local winids = {}
  local winids_dict = {}
  for winnr = 1, vim.fn.winnr '$' do
    local wininfo = vim.fn.getwininfo(vim.fn.win_getid(winnr))[1]
    local start_col = wininfo['wincol']
    local end_col = start_col + wininfo['width']
    if start_col > cur_end_col or end_col < cur_start_col then
    else
      local winid = vim.fn.win_getid(winnr)
      if winnr ~= cur_winnr and vim.api.nvim_get_option_value('winfixheight', { win = winid, }) == true then
        winids[#winids + 1] = winid
        winids_dict[winid] = wininfo['height']
      end
    end
  end
  vim.cmd 'wincmd _'
  for _, winid in ipairs(winids) do
    vim.api.nvim_win_set_height(winid, winids_dict[winid] + (#vim.o.winbar > 0 and 1 or 0))
  end
end

function M.win_max_width()
  local cur_winnr = vim.fn.winnr()
  local winids = {}
  local winids_dict = {}
  for winnr = 1, vim.fn.winnr '$' do
    local wininfo = vim.fn.getwininfo(vim.fn.win_getid(winnr))[1]
    local winid = vim.fn.win_getid(winnr)
    if winnr ~= cur_winnr and vim.api.nvim_get_option_value('winfixwidth', { win = winid, }) == true then
      winids[#winids + 1] = winid
      winids_dict[winid] = wininfo['width']
    end
  end
  vim.cmd 'wincmd |'
  for _, winid in ipairs(winids) do
    vim.api.nvim_win_set_width(winid, winids_dict[winid])
  end
end

function M.aucmd(event, desc, opts)
  opts = vim.tbl_deep_extend(
    'force',
    opts,
    {
      group = vim.api.nvim_create_augroup(desc, {}),
      desc = desc,
    })
  return vim.api.nvim_create_autocmd(event, opts)
end

function M.lazy_map(tbls)
  for _, tbl in ipairs(tbls) do
    local opt = {}
    for k, v in pairs(tbl) do
      if type(k) == 'string' and k ~= 'mode' then
        opt[k] = v
      end
    end
    local lhs = tbl[1]
    if type(lhs) == 'table' then
      for _, l in ipairs(lhs) do
        vim.keymap.set(tbl['mode'], l, tbl[2], opt)
      end
    else
      vim.keymap.set(tbl['mode'], lhs, tbl[2], opt)
    end
  end
end

function M.get_file_parent(file)
  if M.is_dir(file) then
    return file
  end
  return M.new_file(file):parent().filename
end

function M.ui(arr, opts, callback)
  if #arr == 1 then
    callback(arr[1])
  else
    M.ui_sel(arr, opts, function(choose)
      if choose then
        callback(choose)
      end
    end)
  end
end

function M.nvimtree_cd(dir)
  if M.is_file_exists(dir) then
    require 'nvim-tree'.change_dir(M.get_file_parent(dir))
    M.project_cd()
  end
end

function M.nvimtree_cd_sel(dirs)
  M.ui(dirs, 'nvimtree_cd', M.nvimtree_cd)
end

function M.get_cur_file()
  return vim.api.nvim_buf_get_name(0)
end

function M.project_cd()
  vim.cmd [[
    try
      if &ft != 'help'
        ProjectRootCD
      endif
    catch
    endtry
  ]]
end

function M.get_cwd()
  return vim.loop.cwd()
end

function M.get_file_parents(file)
  if not file then
    file = M.get_cur_file()
  end
  if not M.is_file_exists(file) then
    return {}
  end
  local dir = M.get_file_parent(file)
  local parents = { dir, }
  for _ = 0, 64 do
    dir = vim.fn.fnamemodify(dir, ':h')
    if not M.is_in_tbl(dir, parents) then
      M.put(parents, dir)
    else
      break
    end
  end
  return parents
end

function M.get_cur_proj_dirs(file)
  if not file then
    file = M.get_cur_file()
  end
  if not M.is_file_exists(file) then
    return
  end
  local parents = M.get_file_parents(file)
  local proj_dirs = {}
  local proj = vim.fn['ProjectRootGet'](file)
  if M.is(proj) then
    M.put(proj_dirs, proj)
  end
  for _, parent in ipairs(parents) do
    proj = vim.fn['ProjectRootGet'](parent)
    if M.is(proj) and not M.is_in_tbl(proj, proj_dirs) then
      M.put(proj_dirs, proj)
    end
  end
  return proj_dirs
end

function M.save_win_pos()
  M.win_pos = vim.fn.win_getid()
end

function M.restore_win_pos()
  vim.fn.win_gotoid(M.win_pos)
end

function M.nvimtree_findfile()
  M.save_win_pos()
  vim.cmd 'NvimTreeFindFile'
  M.restore_win_pos()
end

function M.next_hunk()
  if vim.wo.diff then
    vim.cmd [[call feedkeys("]c")]]
  end
  require 'gitsigns'.next_hunk()
end

function M.prev_hunk()
  if vim.wo.diff then
    vim.cmd [[call feedkeys("[c")]]
  end
  require 'gitsigns'.prev_hunk()
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

function M.set_timeout(timeout, callback)
  return vim.fn.timer_start(timeout, function()
    callback()
  end, { ['repeat'] = 1, })
end

function M.git_add_commit_push_do(commit, dir)
  M.start_term {
    'cd', '/d', dir, '&&',
    'git', 'add', '.', '&&',
    'git', 'commit', '-m', commit, '&&',
    'git', 'push',
  }
end

function M.git_add_commit_push(commit, dir)
  if not dir then
    dir = M.get_cwd()
  end
  M.start_term {
    'cd', '/d', dir, '&&',
    'git', 'status',
  }
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

return M

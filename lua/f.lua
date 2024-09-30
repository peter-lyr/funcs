local M = {}

local pp = require 'plenary.path'

ParamsCnt = 0

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
  for _, bnr in ipairs(win_buf_nrs) do
    vim.g.bnr = bnr
    if M.is_valid(bnr) then
      buf_names[#buf_names + 1] = vim.g.file
    end
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
  return not M.is_valid(bnr) or M.is(vim.api.nvim_get_option_value('modifiable', { buf = bnr, }))
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
    M.lazy_load 'telescope'
  end
  M.cmd('e %s', file)
end

function M.is_term(file)
  return M.in_str('term://', file) or M.in_str('term:\\\\', file)
end

function M.is_valid(bnr)
  vim.g.file = nil
  vim.g.bnr = bnr
  vim.cmd [[
    try
      let g:file = nvim_buf_get_name(g:bnr)
    catch
    endtry
  ]]
  return vim.g.file
end

function M.jump_or_split(file, no_split)
  if not file then
    return
  end
  if type(file) == 'number' then
    if M.is_valid(file) then
      file = vim.g.file
    else
      return
    end
  end
  file = M.rep(file)
  if M.is_dir(file) then
    M.lazy_load 'nvim-tree.lua'
    vim.cmd 'wincmd s'
    M.cmd('e %s', file)
    return
  end
  local file_proj = M.project_get(file)
  local jumped = nil
  for winnr = vim.fn.winnr '$', 1, -1 do
    local bufnr = vim.fn.winbufnr(winnr)
    local fname = M.rep(M.get_file(bufnr))
    if file == fname and (M.is_file_exists(fname) or M.is_term(fname)) then
      vim.fn.win_gotoid(vim.fn.win_getid(winnr))
      jumped = 1
      break
    end
  end
  if not jumped then
    for winnr = vim.fn.winnr '$', 1, -1 do
      local bufnr = vim.fn.winbufnr(winnr)
      local fname = M.rep(M.get_file(bufnr))
      if M.is_file_exists(fname) then
        local proj = M.project_get(fname)
        if not M.is(file_proj) or M.is(proj) and file_proj == proj then
          vim.fn.win_gotoid(vim.fn.win_getid(winnr))
          jumped = 1
          break
        end
      end
    end
  end
  if not jumped and not no_split then
    if M.is(M.get_cur_file()) or vim.api.nvim_get_option_value('modified', { buf = vim.fn.bufnr(), }) == true then
      vim.cmd 'wincmd s'
    end
  end
  M.cmd('e %s', file)
end

function M.jump_or_edit(file)
  M.jump_or_split(file, 1)
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
    return M.rep(M.new_file(dir):joinpath(...).filename)
  end
  return dir
end

function M.format(str_format, ...)
  return string.format(str_format, ...)
end

function M.join(arr, sep)
  return vim.fn.join(arr, sep)
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

M.run_cmd_py = M.get_py '02-run-cmd.py'
M.git_pull_recursive_py = M.get_py '03-git-pull-recursive.py'
M.git_push_recursive_py = M.get_py '04-git-push-recursive.py'
M.git_create_submodule_py = M.get_py '05-git-create-submodule.py'
M.git_repo_list_3digit__py = M.get_py '06-git-repo-list-3digit-.py'

function M.start_do(cmd, opts)
  if opts.way == 'silent' then
    M.cmd([[silent !start /min cmd /c %s]], cmd)
  else
    if opts.way == 'outside' then
      M.cmd([[silent !start cmd /c %s]], cmd)
    elseif opts.way == 'inside' then
      M.cmd([[!%s]], cmd)
    elseif opts.way == 'inside_silent' then
      M.cmd([[silent !%s]], cmd)
    elseif opts.way == 'term' then
      M.cmd([[sp|te %s]], cmd)
    end
  end
end

function M.read_lines_from_file(file)
  return vim.fn.readfile(file)
end

function M.write_lines_to_file(lines, file)
  vim.fn.writefile(lines, file)
end

function M.getlua(luafile)
  local loaded = string.match(M.rep(luafile), '.+lua\\(.+)%.lua')
  if not loaded then
    return ''
  end
  loaded = string.gsub(loaded, '\\', '.')
  return loaded
end

function M.echo(str_format, ...)
  str_format = string.gsub(str_format, "'", '"')
  M.cmd(M.format("ec '" .. str_format .. "'", ...))
end

function M.source_cur()
  local file = M.get_cur_file()
  local ext = string.match(file, '%.([^.]+)$')
  if ext == 'lua' then
    package.loaded[M.getlua(file)] = nil
  end
  M.echo('source %s', file)
  M.cmd('source %s', file)
end

function M.delete_folder(dir)
  M.run_inside_silent {
    'cd', '/d', Home, '&&',
    'echo', M.format('Deleting %s', dir), '&&',
    'rd', '/s', '/q', dir,
  }
end

function M.to_table(any)
  if type(any) ~= 'table' then
    return { any, }
  end
  return any
end

function M.run_py_get_cmd(file, params, opts)
  params = M.to_table(params)
  local cmd = file
  if #params > 0 then
    local params_txt = M.format('%s\\%04d-run-params.txt', DpTemp, ParamsCnt)
    if M.run_cmd_py == file and (not opts or not opts.just) then
      local out_msg_txt = M.format('%s\\%04d-run-out.txt', DpTemp, ParamsCnt)
      local out_sta_txt = M.format('%s\\%04d-run-sta.txt', DpTemp, ParamsCnt)
      vim.fn.delete(out_sta_txt, 'rf')
      local name = 'run-' .. tostring(ParamsCnt)
      local temp_cnt = ParamsCnt
      M.set_interval_timeout(name, 500, 1000 * 160, function()
        if M.is_file(out_sta_txt) then
          return true
        end
        return nil
      end, function()
        vim.fn.delete(out_sta_txt, 'rf')
        local temp = vim.fn.join(params, ' ')
        local temp2 = ''
        for _ = 1, #temp do
          temp2 = temp2 .. '='
        end
        vim.notify(M.format('Successful: number %d\n%s\n%s\n%s',
          temp_cnt, temp, temp2,
          vim.fn.join(M.read_lines_from_file(out_msg_txt), '\n')), nil, { timeout = 1000 * 100, })
      end)
    end
    M.write_lines_to_file(params, params_txt)
    cmd = M.format('%s "%s"', cmd, params_txt)
    if opts and opts.no_output then
      cmd = M.format('%s "no_output"', cmd)
    end
    ParamsCnt = ParamsCnt + 1
  end
  return cmd
end

function M.run_in_term(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { no_output = no_output, }), { way = 'term', })
end

function M.run_outside(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { no_output = no_output, }), { way = 'outside', })
end

function M.run_inside(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { no_output = no_output, }), { way = 'inside', })
end

function M.run_inside_silent(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { no_output = no_output, }), { way = 'inside_silent', })
end

function M.run_outside_pause(cmd_params, opts)
  M.put(cmd_params, '&&')
  M.put(cmd_params, 'pause')
  M.run_outside(cmd_params, opts)
end

function M.run_silent(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { no_output = no_output, }), { way = 'silent', })
end

function M.just_run_in_term(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { just = true, no_output = no_output, }), { way = 'term', })
end

function M.just_run_outside(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { just = true, no_output = no_output, }), { way = 'outside', })
end

function M.just_run_inside(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { just = true, no_output = no_output, }), { way = 'inside', })
end

function M.just_run_inside_silent(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { just = true, no_output = no_output, }), { way = 'inside_silent', })
end

function M.just_run_outside_pause(cmd_params, opts)
  M.put(cmd_params, '&&')
  M.put(cmd_params, 'pause')
  M.just_run_outside(cmd_params, opts)
end

function M.just_run_silent(cmd_params, opts)
  local no_output = opts and opts.no_output
  M.start_do(M.run_py_get_cmd(M.run_cmd_py, cmd_params, { just = true, no_output = no_output, }), { way = 'silent', })
end

function M.just_run_in_term_nooutput(cmd_params)
  M.just_run_in_term(cmd_params, { just = true, no_output = true, })
end

function M.just_run_outside_nooutput(cmd_params)
  M.just_run_outside(cmd_params, { just = true, no_output = true, })
end

function M.just_run_inside_nooutput(cmd_params)
  M.just_run_inside(cmd_params, { just = true, no_output = true, })
end

function M.just_run_inside_silent_nooutput(cmd_params)
  M.just_run_inside_silent(cmd_params, { just = true, no_output = true, })
end

function M.just_run_outside_pause_nooutput(cmd_params)
  M.put(cmd_params, '&&')
  M.put(cmd_params, 'pause')
  M.just_run_outside_pause(cmd_params, { just = true, no_output = true, })
end

function M.just_run_silent_nooutput(cmd_params)
  M.just_run_silent(cmd_params, { just = true, no_output = true, })
end

function M.clone_if_not_exist(dir, repo, root)
  if not root then
    root = Home
  end
  if not repo then
    repo = dir
  end
  local dir2 = M.join_path(root, dir)
  if not M.is_file_exists(dir2) then
    M.run_silent { 'cd', '/d', root, '&&', 'git', 'clone', '--recurse-submodules', '-j', '8', M.format('git@github.com:%s/%s', Name, repo), dir, }
  end
end

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

function M.get_parent(file)
  if not file then
    file = M.get_cur_file()
  end
  return M.new_file(file):parent().filename
end

function M.get_file_parent(file)
  if not file then
    file = M.get_cur_file()
  end
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

function M.get_file(bnr)
  return vim.api.nvim_buf_get_name(bnr)
end

function M.get_cur_file()
  return M.get_file(0)
end

function M.project_cd()
  M.lazy_load 'vim-projectroot'
  vim.cmd [[
    try
      if &ft != 'help'
        ProjectRootCD
      endif
    catch
    endtry
  ]]
end

function M.project_get(file)
  M.lazy_load 'vim-projectroot'
  if file then
    return M.rep(vim.fn['ProjectRootGet'](file))
  end
  return M.rep(vim.fn['ProjectRootGet']())
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
  local proj = M.project_get(file)
  if M.is(proj) then
    M.put(proj_dirs, proj)
  end
  for _, parent in ipairs(parents) do
    proj = M.project_get(parent)
    if M.is(proj) and not M.is_in_tbl(proj, proj_dirs) then
      M.put(proj_dirs, proj)
    end
  end
  return proj_dirs
end

function M.save_win_pos()
  vim.g.win_pos = vim.fn.win_getid()
end

function M.restore_win_pos()
  vim.fn.win_gotoid(vim.g.win_pos)
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

function M.set_timeout(timeout, callback)
  return vim.fn.timer_start(timeout, function()
    callback()
  end, { ['repeat'] = 1, })
end

function M.set_interval(interval, callback)
  return vim.fn.timer_start(interval, function()
    callback()
  end, { ['repeat'] = -1, })
end

function M.clear_interval(timer)
  pcall(vim.fn.timer_stop, timer)
end

function M.set_interval_timeout(name, interval, timeout, callback, callback_done)
  vim.g[name] = M.set_interval(interval, function()
    if callback() then
      M.clear_interval(vim.g[name])
      vim.g[name] = 0
      if callback_done then
        callback_done()
      end
    end
  end)
  M.set_timeout(timeout, function()
    if vim.g[name] > 0 then
      vim.notify(M.format('Time Out[%s]: %d', name, timeout))
      M.clear_interval(vim.g[name])
    end
  end)
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
    'git', '--no-optional-locks', 'status', '--porcelain=v1', '--ignored=matching', '-u',
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

--- function M.get_all_dirs_with_dot_git(file)
---   if not file then
---     file = M.get_cur_file()
---   end
---   local parent = M.get_parent(file)
---   local dirs = {}
---   while 1 do
---     local dot_git = M.join_path(parent, '.git')
---     if M.is_file_exists(dot_git) then
---       M.put(dirs, parent)
---     end
---     local temp = M.get_parent(parent)
---     if parent == temp then
---       break
---     end
---     parent = temp
---   end
--- end
---
--- function M.git_add_commit_push_all(commit, dir)
---   M.get_all_dirs_with_dot_git()
--- end

function M.reset_hunk()
  require 'gitsigns'.reset_hunk()
end

function M.git_reset_buffer()
  require 'gitsigns'.reset_buffer()
end

function M.git_lazy()
  M.just_run_outside 'lazygit'
end

function M.copy_multiple_filenames()
  vim.fn.setreg('w', vim.loop.cwd())
  vim.fn.setreg('a', M.get_cur_file())
  vim.fn.setreg('b', vim.fn.bufname())
  vim.fn.setreg('t', vim.fn.fnamemodify(vim.fn.bufname(), ':t'))
  vim.fn.setreg('e', vim.fn.expand '<cword>')
  vim.fn.setreg('r', vim.fn.expand '<cWORD>')
  vim.fn.setreg('i', vim.fn.trim(vim.fn.getline '.'))
end

function M.git_pull_recursive_do(repo, clone)
  M.run_silent { M.git_pull_recursive_py, repo, clone, }
end

function M.git_pull_recursive(clone)
  M.git_pull_recursive_do(Org, clone)
  M.git_pull_recursive_do(StdConfig, clone)
end

function M.git_push_recursive_do(commit, file)
  local commit_file = DpTemp .. '\\commit.txt'
  M.write_lines_to_file({ commit, }, commit_file)
  M.run_silent { M.git_push_recursive_py, commit_file, file, }
end

function M.git_push_recursive(commit, file)
  if not file then
    file = M.get_cur_file()
  end
  M.run_silent {
    'cd', '/d', M.get_file_parent(file), '&&',
    'git', '--no-optional-locks', 'status', '--porcelain=v1', '--ignored=matching', '-u',
  }
  M.copy_multiple_filenames()
  if not M.is(commit) then
    vim.ui.input({ prompt = 'commit info: ', }, function(c)
      if c then
        M.git_push_recursive_do(c, file)
      end
    end)
  else
    M.git_push_recursive_do(commit, file)
  end
end

function M.git_create_submodule_do(root, path, public, name)
  if not name then
    name = Name
  end
  M.run_silent { M.git_create_submodule_py, root, path, public, name, }
end

function M.git_create_submodule(root, path, public)
  if not root then
    M.project_cd()
    root = M.get_cwd()
  end
  M.run_silent { M.git_repo_list_3digit__py, root, }
  M.copy_multiple_filenames()
  if not M.is(path) then
    vim.ui.input({ prompt = M.format('Create Submodule in %s: ', root), }, function(p)
      if p then
        M.git_create_submodule_do(root, p, public)
      end
    end)
  else
    M.git_create_submodule_do(root, path, public)
  end
end

function M.git_create_submodule_public(root, path)
  M.git_create_submodule(root, path, 'public')
end

function M.git_create_submodule_private(root, path)
  M.git_create_submodule(root, path, 'private')
end

function M.git_pull()
  M.project_cd()
  M.run_silent {
    'cd', '/d', M.get_cwd(), '&&',
    'git', 'pull',
  }
end

function M.set_myft(bnr, ft)
  if not bnr then
    bnr = vim.fn.bufnr()
  end
  if not ft then
    ft = 'myft'
  end
  vim.api.nvim_set_option_value('filetype', ft, { buf = bnr, })
end

function M.execute_out_buffer(cmd)
  local lines = vim.fn.split(vim.fn.trim(vim.fn.execute(cmd)), '\n')
  if #lines == 0 then
    return
  end
  vim.cmd 'wincmd n'
  vim.fn.append(vim.fn.line '$', lines)
  M.set_myft()
end

function M.lazy_load(plugin)
  M.cmd('Lazy load %s', plugin)
end

function M.notifications_buffer()
  M.lazy_load 'nvim-notify'
  M.execute_out_buffer 'Notifications'
end

function M.message_buffer()
  M.execute_out_buffer 'message'
end

function M.get_short(content, max, sep)
  if not sep then
    sep = '…'
  end
  if not max then
    max = vim.fn.floor(vim.o.columns * 3 / 5)
  end
  if #content > (max * 2 + 1) then
    local s1 = ''
    local s2 = ''
    for i = (max * 2 - 1), 0, -1 do
      s2 = string.sub(content, #content - i, #content)
      if vim.fn.strdisplaywidth(s2) <= max then
        break
      end
    end
    for i = (max * 2 - 1), 0, -1 do
      s1 = string.sub(content, 1, i)
      if vim.fn.strdisplaywidth(s1) <= max then
        break
      end
    end
    return s1 .. sep .. s2
  end
  return content
end

function M.yank_clipbaord(text)
  vim.fn.setreg('+', text)
  M.echo('Copied to Clipboard: %s', M.get_short(text))
end

function M.yank_clipbaord_file_full()
  M.yank_clipbaord(M.get_cur_file())
end

function M.yank_clipbaord_file_full_head()
  M.yank_clipbaord(vim.fn.fnamemodify(M.get_cur_file(), ':h'))
end

function M.yank_clipbaord_file_full_tail()
  M.yank_clipbaord(vim.fn.fnamemodify(M.get_cur_file(), ':t'))
end

function M.yank_clipbaord_file_bufname()
  M.yank_clipbaord(vim.fn.bufname())
end

function M.yank_clipbaord_file_bufname_head()
  M.yank_clipbaord(vim.fn.fnamemodify(vim.fn.bufname(), ':h'))
end

function M.yank_clipbaord_file_bufname_tail()
  M.yank_clipbaord(vim.fn.fnamemodify(vim.fn.bufname(), ':t'))
end

function M.yank_clipbaord_cwd()
  M.yank_clipbaord(M.get_cwd())
end

function M.yank_clipbaord_cwd_head()
  M.yank_clipbaord(vim.fn.fnamemodify(M.get_cwd(), ':h'))
end

function M.yank_clipbaord_cwd_tail()
  M.yank_clipbaord(vim.fn.fnamemodify(M.get_cwd(), ':t'))
end

function M.quit_nvim_qt_later()
  M.set_timeout(10, function()
    vim.cmd 'qa!'
  end)
end

function M.start_nvim_qt(file)
  file = file and file or ''
  M.cmd('silent !start nvim-qt.exe %s', file)
end

function M.restart_nvim_qt(file)
  M.start_nvim_qt(file)
  M.quit_nvim_qt_later()
end

function M.refresh()
  M.project_cd()
  vim.cmd 'e!'
end

function M.curline_one_space()
  local temp = vim.fn.getreg '/'
  vim.cmd [[
    try
      .s/ \+/ /g
    catch
    endtry
  ]]
  M.cmd('.s/%s', temp)
end

function M.dec(to_change, min, ori)
  to_change = to_change - 1
  if to_change < min then
    if ori then
      return ori
    else
      return min
    end
  end
  return to_change
end

function M.inc(to_change, max, ori)
  to_change = to_change + 1
  if to_change > max then
    if ori then
      return ori
    else
      return max
    end
  end
  return to_change
end

function M.get_font_name_size()
  local fontname
  local fontsize
  for k, v in string.gmatch(vim.g.GuiFont, '(.*):h(%d+)') do
    fontname, fontsize = k, v
  end
  return fontname, tonumber(fontsize)
end

function M.change_font(name, size)
  M.cmd('GuiFont! %s:h%d', name, size)
end

function M.norm_font_size()
  local fontname, _ = M.get_font_name_size()
  M.change_font(fontname, 9)
end

function M.inc_font_size()
  local fontname, fontsize = M.get_font_name_size()
  fontsize = M.inc(fontsize, 72)
  M.change_font(fontname, fontsize)
end

function M.max_font_size()
  local fontname, _ = M.get_font_name_size()
  M.change_font(fontname, 72)
end

function M.min_font_size()
  local fontname, _ = M.get_font_name_size()
  M.change_font(fontname, 1)
end

function M.dec_font_size()
  local fontname, fontsize = M.get_font_name_size()
  fontsize = M.dec(fontsize, 1)
  M.change_font(fontname, fontsize)
end

function M.K_K_do(k)
  if not k or not KK or not KK[k] then
    return
  end
  KK[k .. 'Done'] = 1
  local tbl = KK[k]
  local exit = '<esc>'
  local modes = {}
  local keys = {}
  for _k, v in pairs(tbl) do
    if #v >= 2 then
      local mode = v['mode']
      _k = string.sub(_k, #_k, #_k)
      if _k ~= '>' then
        vim.keymap.set(mode, _k, v[1], { desc = v[2], nowait = true, })
        M.put(modes, mode)
        M.put(keys, _k)
      end
    end
  end
  vim.keymap.set({ 'n', 'v', }, exit, function()
    KK[k .. 'Done'] = nil
    for i = 1, #modes do
      vim.keymap.del(modes[i], keys[i])
    end
    vim.keymap.del({ 'n', 'v', }, exit)
  end, { desc = 'exit buffer map', })
end

function M.k_k(func, k)
  func()
  if not KK[k .. 'Done'] then
    M.K_K_do(k)
  end
end

function M.get_bufs()
  return vim.api.nvim_list_bufs()
end

function M.in_str(item, str)
  return string.match(str, item)
end

function M.get_term_bufs()
  local bufs = M.get_bufs()
  if not bufs then
    return {}
  end
  local term_bufs = {}
  for _, buf in ipairs(bufs) do
    local bname = vim.fn.bufname(buf)
    if M.is(bname) and M.is_term(bname) then
      M.put(term_bufs, buf)
    end
  end
  return term_bufs
end

function M.has_term_win()
  local bnames = M.get_win_buf_names()
  local a = vim.tbl_filter(function(bname)
    return M.is_term(bname)
  end, bnames)
  return M.is(#a)
end

function M.jump_or_split_term()
  local term_bufs = M.get_term_bufs()
  if #term_bufs == 0 then
    return
  end
  if not vim.g.term_index then
    vim.g.term_index = 1
  end
  vim.g.term_index = M.inc(vim.g.term_index, #term_bufs, 1)
  if M.has_term_win() then
    M.jump_or_edit(term_bufs[vim.g.term_index])
  else
    M.jump_or_split(term_bufs[vim.g.term_index])
  end
end

function M.format_paragraph()
  M.save_pos()
  vim.cmd 'norm vip='
  M.restore_pos()
end

function M.save_pos()
  vim.g.save_pos = vim.fn.getpos '.'
end

function M.restore_pos()
  pcall(vim.fn.setpos, '.', vim.g.save_pos)
end

M.clone_if_not_exist 'org'

return M

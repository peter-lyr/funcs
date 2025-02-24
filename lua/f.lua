local M         = {}
local pp        = require 'plenary.path'
local ps        = require 'plenary.scandir'
-- local f_s_time  = vim.fn.reltime()

vim.g.ui_select = vim.ui.select

if vim.fn.isdirectory(Dp) == 0 then
  vim.fn.mkdir(Dp)
end

if vim.fn.isdirectory(DpTemp) == 0 then
  vim.fn.mkdir(DpTemp)
end

if vim.fn.isdirectory(GitFakeRemoteDir) == 0 then
  vim.fn.mkdir(GitFakeRemoteDir)
end

RunCmdDir = DpTemp .. '\\run-cmd'
RunCmdOldDir = DpTemp .. '\\run-cmd-old'

if vim.fn.isdirectory(RunCmdDir) == 0 then
  vim.fn.mkdir(RunCmdDir)
end

if vim.fn.isdirectory(RunCmdOldDir) == 0 then
  vim.fn.mkdir(RunCmdOldDir)
end

Sta_234_en                   = nil
Sta_234_dos                  = {}
Sta_234_cnts                 = {}

vim.g.winbar                 = ' %#Comment#%{v:lua.WinBarProj()}\\%#WinBar#%{v:lua.WinBarName()} %#WinBarNC#'
vim.g.winbar2                = ' %{v:lua.WinBarName()} %#WinBarNC#'
--- vim.g.statusline = '%{v:lua.Statusline()} %h%m%r%=%<%{&ff}[%{&fenc}] %(%l,%c%V%) %P'
-- vim.opt.winbar               = vim.g.winbar2

DIRS                         = {} -- 见下面

M.session_saved_projects_txt = DpTemp .. '\\session_saved_projects.txt'

function M.hi_winbar()
  vim.cmd 'hi WinBar   guifg=#9927d6 guibg=#77d35e gui=bold'
  vim.cmd 'hi WinBarNC guifg=#893716 guibg=NONE    gui=NONE'
end

M.hi_winbar()
vim.fn.timer_start(100, function()
  M.hi_winbar()
end, { ['repeat'] = 50, })

function M.hi_tabline()
  vim.cmd 'hi TabLineSel  guifg=#a957d6 guibg=#4753ee gui=bold'
  vim.cmd 'hi TabLine     guifg=#397786 guibg=NONE    gui=NONE'
  vim.cmd 'hi TabLineFill guifg=None    guibg=NONE    gui=NONE'
end

M.hi_tabline()
vim.fn.timer_start(100, function()
  M.hi_tabline()
end, { ['repeat'] = 50, })

function M.hi_winsep()
  vim.cmd 'hi WinSeparator guibg=#111111 guifg=gray'
  vim.cmd 'hi NvimTreeWinSeparator guibg=#111111 guifg=gray'
end

M.hi_tabline()
vim.fn.timer_start(100, function()
  M.hi_winsep()
end, { ['repeat'] = 50, })

function M.get_win_buf_nrs()
  local buf_nrs = {}
  for wnr = 1, vim.fn.winnr '$' do
    buf_nrs[#buf_nrs + 1] = vim.fn.winbufnr(wnr)
  end
  return buf_nrs
end

function M.get_all_win_buf_nrs()
  local buf_nrs = {}
  for i = 1, vim.fn.tabpagenr '$' do
    local bufs = vim.fn.tabpagebuflist(i)
    if #bufs > 0 then
      buf_nrs = M.merge_tables(buf_nrs, bufs)
    end
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
  return not M.is_valid(bnr) or M.is(vim.bo[bnr].modifiable)
end

function M.put(arr, item)
  arr[#arr + 1] = item
end

function M.put_uniq(arr, item)
  if not M.in_arr(item, arr) then
    M.put(arr, item)
  end
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
  if vim.fn.tabpagenr '$' > 1 then
    return nil
  end
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

function M.tabclose()
  vim.cmd [[
    try
      tabclose
    catch
    endtry
  ]]
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
    if vim.g.ui_select ~= vim.ui.select then
      require 'telescope'.load_extension 'ui-select'
      vim.g.ui_select = vim.ui.select
    end
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

function M.in_arr(item, tbl)
  return M.is(vim.tbl_contains(tbl, item))
end

function M.get_telescope_extras()
  local telescopes = {}
  local builtins = M.get_telescope_builtins()
  for _, t in ipairs(vim.fn.getcompletion('Telescope ', 'cmdline')) do
    if not M.in_arr(t, builtins) then
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
  local file_proj = M.get_proj(file)
  local jumped = nil
  for winnr = vim.fn.winnr '$', 1, -1 do
    local bufnr = vim.fn.winbufnr(winnr)
    local fname = M.rep(M.get_bnr_file(bufnr))
    if M.lower(file) == M.lower(fname) and (M.is_file_exists(fname) or M.is_term(fname)) then
      vim.fn.win_gotoid(vim.fn.win_getid(winnr))
      jumped = 1
      break
    end
  end
  if not jumped then
    for winnr = vim.fn.winnr '$', 1, -1 do
      local bufnr = vim.fn.winbufnr(winnr)
      local fname = M.rep(M.get_bnr_file(bufnr))
      if M.is_file_exists(fname) then
        local proj = M.get_proj(fname)
        if not M.is(file_proj) or M.is(proj) and M.lower(file_proj) == M.lower(proj) then
          vim.fn.win_gotoid(vim.fn.win_getid(winnr))
          jumped = 1
          break
        end
      end
    end
  end
  if not jumped and not no_split then
    if M.is(M.get_cur_file()) or vim.bo[vim.fn.bufnr()].modified == true then
      vim.cmd 'wincmd s'
    end
  end
  M.cmd('e %s', file)
end

function M.jump_or_edit(file)
  M.jump_or_split(file, 1)
end

function Joe(file)
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

function M.double_backslash(content)
  content = string.gsub(content, '\\', '\\\\')
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
  if not sep then
    sep = '\n'
  end
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
M.cbp2cmake_py = M.get_py '08-cbp2cmake.py'
M.sh_get_folder_path_exe = M.get_py '10-SHGetFolderPath.exe'
M.svn_tmp_gitkeep_py = M.get_py '13-svn_tmp.gitkeep.py'
M.copy2clip_exe = M.get_py '01-copy2clip.exe'
M.git_status_recursive_py = M.get_py '14-git-status-recursive.py'
M.git_commits_py = M.get_py '15-git-commits.py'
M.git_init_py = M.get_py '16-git-init.py'
M.work_summary_day_py = M.get_py '17-work-summary-day.py'
M.work_summary_week_py = M.get_py '18-work-summary-week.py'
M.tts_py = M.get_py '19-tts.py'
M.rename_submodule_py = M.get_py '20-rename-submodule.py'
Week1Date = { 2024, 12, 16, } -- 第一周起始日

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
      vim.g.term_total = M.has_term_win()
    end
  end
end

function M.read_lines_from_file(file)
  if M.is_file_exists(file) then
    return vim.fn.readfile(file)
  end
  return {}
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

function M.source(file)
  if not file then
    file = M.get_cur_file()
  end
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

function M.complex_string_hash(str)
  local prime1 = 16777619
  local offset = 2166136261
  local hash = offset
  for i = 1, #str do
    local char = string.byte(str, i)
    hash = bit.bxor(hash, char)
    hash = hash * prime1
  end
  local hex_chars = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', }
  local hash_str = ''
  for _ = 1, 8 do
    local index = bit.band(hash, 15) + 1
    hash_str = hex_chars[index] .. hash_str
    hash = bit.rshift(hash, 4)
  end
  return hash_str
end

function M.string_hash(str)
  local hash = 0
  for i = 1, #str do
    local char = string.byte(str, i)
    hash = hash * 31 + char
  end
  return hash
end

function M.run_py_get_cmd_check(interval, check_timeout, name, temp_cnt, temp_2, out_sta_txt, out_msg_txt, params, file, opts)
  M.set_interval_timeout(name, interval, check_timeout, function()
    if M.is_file(out_sta_txt) then
      return true
    end
    return nil
  end, function()
    local sta = vim.fn.trim(vim.fn.join(M.read_lines_from_file(out_sta_txt), ''))
    local temp = vim.fn.join(params, ' ')
    local temp2 = ''
    for _ = 1, #temp do
      temp2 = temp2 .. '='
    end
    local log_level = vim.log.levels.INFO
    local timeout = 1000 * 100
    if sta ~= '0' then
      if sta == '234' then -- re run
        if Sta_234_dos[Sta_234_cnts[temp_2]] then
          Sta_234_dos[Sta_234_cnts[temp_2]]()
        end
        M.run_py_get_cmd(file, params, opts)
        timeout = 1000 * 5
      else
        log_level = vim.log.levels.ERROR
      end
    end
    M.notify(M.format('Sta: %s, #%d\n%s\n%s\n%s',
      sta, temp_cnt, temp, temp2,
      vim.fn.join(M.read_lines_from_file(out_msg_txt), '\n')), log_level, { timeout = timeout, })
  end, function()
    interval = interval * 2
    check_timeout = check_timeout * 2
    if interval > 1000 * 60 * 5 then --超过5分后不再检测
      return
    end
    if check_timeout > 1000 * 60 * 60 * 24 then
      check_timeout = 1000 * 60 * 60 * 24
    end
    M.run_py_get_cmd_check(interval, check_timeout, name, temp_cnt, temp_2, out_sta_txt, out_msg_txt, params, file, opts)
  end)
end

function M.run_py_get_cmd(file, params, opts)
  params = M.to_table(params)
  local cmd = file
  if #params > 0 then
    if not vim.g.run_cmd_cnt then
      vim.g.run_cmd_cnt = 0
    end
    if not vim.g.run_cmd_doing then
      vim.g.run_cmd_doing = 1
      vim.fn.system(M.format('move /y "%s" "%s\\run-cmd-%s"', RunCmdDir, RunCmdOldDir, vim.fn.strftime '%Y%m%d-%H%M%S'))
      vim.fn.mkdir(RunCmdDir)
    end
    local temp_3 = vim.inspect(file) .. vim.inspect(params) .. vim.inspect(opts)
    local temp_2 = M.complex_string_hash(temp_3)
    if Sta_234_en and not M.in_arr(temp_2, Sta_234_cnts) then
      Sta_234_cnts[temp_2] = #Sta_234_dos
    end
    Sta_234_en = nil
    local params_txt = M.format('%s\\%04d-run-params.txt', RunCmdDir, vim.g.run_cmd_cnt)
    if M.run_cmd_py == file and (not opts or not opts.just) then
      local out_msg_txt = M.format('%s\\%04d-run-out.txt', RunCmdDir, vim.g.run_cmd_cnt)
      local out_sta_txt = M.format('%s\\%04d-run-sta.txt', RunCmdDir, vim.g.run_cmd_cnt)
      local name = 'run-' .. tostring(vim.g.run_cmd_cnt)
      local temp_cnt = vim.g.run_cmd_cnt
      local interval = 500
      local check_timeout = 1000 * 60 * 3
      M.run_py_get_cmd_check(interval, check_timeout, name, temp_cnt, temp_2, out_sta_txt, out_msg_txt, params, file, opts)
    end
    M.write_lines_to_file(params, params_txt)
    cmd = M.format('%s "%s"', cmd, params_txt)
    if opts and opts.no_output then
      cmd = M.format('%s "no_output"', cmd)
    end
    vim.g.run_cmd_cnt = vim.g.run_cmd_cnt + 1
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

function M.run(cmd)
  M.cmd([[silent !start cmd /c "%s"]], cmd)
end

function M.run__silent(cmd)
  M.cmd([[silent !start /b /min cmd /c "%s"]], cmd)
end

function M.run__pause(cmd)
  M.cmd([[silent !start cmd /c "%s & pause"]], cmd)
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
  if vim.api.nvim_get_option_value('winfixheight', { win = vim.fn.win_getid(), }) == true then
    return
  end
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
  if vim.api.nvim_get_option_value('winfixwidth', { win = vim.fn.win_getid(), }) == true then
    return
  end
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

function M.map_buffer_once(mode, lhs, callback, buffer)
  if not callback then
    return
  end
  if not buffer then
    buffer = vim.fn.bufnr()
  end
  vim.keymap.set(mode, lhs, function()
    vim.keymap.del(mode, lhs, {
      buffer = buffer,
    })
    callback()
  end, {
    buffer = buffer,
    nowait = true,
  })
end

function M.map_buffer_once_q_close()
  M.map_buffer_once({ 'n', 'v', }, 'q', function()
    vim.cmd 'close!'
  end)
end

function M.escape_space(text)
  text = string.gsub(text, ' ', '\\ ')
  return text
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

function M.ui_input(prompt, default, callback)
  vim.ui.input({ prompt = prompt, default = default, }, function(input)
    if input then
      callback(input)
    end
  end)
end

function M.ui(arr, opts, callback)
  M.lazy_load 'telescope'
  if arr and #arr == 1 then
    callback(arr[1])
  else
    M.ui_sel(arr, opts, function(choose, index)
      if choose then
        callback(choose, index)
      end
    end)
  end
end

function M.nvimtree_cd(dir)
  if M.is_file_exists(dir) then
    M.lazy_load 'nvim-tree.lua'
    vim.cmd 'NvimTreeOpen'
    require 'nvim-tree'.change_dir(M.get_file_parent(dir))
    M.project_cd()
    vim.cmd 'NvimTreeFindFile'
  end
end

function M.nvimtree_cd_sel(dirs)
  M.ui(dirs, 'nvimtree_cd', M.nvimtree_cd)
end

function M.telescope_do(dir)
  if M.is_file_exists(dir) then
    M.cmd('Telescope %s cwd=%s', vim.g.telescope_cmd, dir)
    M.project_cd()
  end
end

function M.telescope_sel(dirs, cmd)
  if not dirs then
    return
  end
  if type(cmd) ~= 'number' then
    vim.g.telescope_cmd = cmd
  end
  if type(dirs) ~= 'table' then
    local temp = M.get_sub_dirs(dirs)
    if #temp == 0 then
      M.telescope_do(dirs)
      return
    end
    dirs = temp
  end
  M.ui(dirs, M.format('%s sel', cmd), M.telescope_do)
end

function M.telescope_sel_sel(dirs, cmd)
  vim.g.telescope_cmd = cmd
  M.ui(dirs, M.format('%s sel', cmd), M.telescope_sel)
end

function M.get_filetype(file)
  local ext = string.match(file, '%.([^.]+)$')
  return ext
end

function M.get_bnr_file(bnr)
  return vim.api.nvim_buf_get_name(bnr)
end

function M.get_cur_file()
  return M.get_bnr_file(0)
end

function M.get_cur_tail()
  local cur_file = M.get_bnr_file(0)
  if #cur_file == 0 then
    return ''
  end
  local cur_proj = M.get_proj(cur_file)
  if #cur_proj == 0 then
    return ''
  end
  return string.sub(cur_file, #cur_proj + 2, #cur_file)
end

function M.get_proj_tail()
  local cur_file = M.get_bnr_file(0)
  local cur_proj = M.get_proj(cur_file)
  return vim.fn.fnamemodify(cur_proj, ':t')
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

function M.get_proj(file)
  local proj = ''
  M.lazy_load 'vim-projectroot'
  if file then
    _, proj = pcall(vim.fn['ProjectRootGet'], file)
  else
    _, proj = pcall(vim.fn['ProjectRootGet'])
  end
  return M.rep(proj)
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
    if not M.in_arr(dir, parents) then
      M.put(parents, dir)
    else
      break
    end
  end
  return parents
end

function M.get_file_more_dirs(file)
  return M.merge_tables(M.get_cur_proj_dirs(file), M.get_file_parents(file), DIRS)
end

function M.get_sub_dirs(dir)
  dir = M.get_file_parent(dir)
  return ps.scan_dir(dir, { hidden = false, depth = 1, add_dirs = true, only_dirs = true, })
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
  local proj = M.get_proj(file)
  if M.is(proj) then
    M.put(proj_dirs, proj)
  end
  for _, parent in ipairs(parents) do
    proj = M.get_proj(parent)
    if M.is(proj) and not M.in_arr(proj, proj_dirs) then
      M.put(proj_dirs, proj)
    end
  end
  return proj_dirs
end

function M.get_cur_proj_dirs_tails()
  local projs = M.get_cur_proj_dirs()
  if not projs then
    return {}
  end
  local projs_new = {}
  for _, proj in ipairs(projs) do
    M.put_uniq(projs_new, M.get_tail(proj))
  end
  return projs_new
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
    return
  end
  require 'gitsigns'.next_hunk()
end

function M.prev_hunk()
  if vim.wo.diff then
    vim.cmd [[call feedkeys("[c")]]
    return
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

function M.set_interval_vim_g(name, interval, callback)
  if vim.g[name .. '-interval'] then
    M.clear_interval(vim.g[name .. '-interval'])
  end
  vim.g[name .. '-interval'] = vim.fn.timer_start(interval, function()
    callback()
  end, { ['repeat'] = -1, })
end

function M.set_timeout_vim_g(name, interval, callback)
  if vim.g[name .. '-timeout'] then
    M.clear_interval(vim.g[name .. '-timeout'])
  end
  vim.g[name .. '-timeout'] = vim.fn.timer_start(interval, function()
    callback()
  end, { ['repeat'] = 1, })
end

function M.set_interval_timeout(name, interval, timeout, callback, callback_done, callback_timeout)
  vim.g[name] = M.set_interval(interval, function()
    if callback() then
      M.clear_interval(vim.g[name])
      vim.g[name] = -1
      if callback_done then
        callback_done()
      end
    end
  end)
  local function callback_timeout_do()
    if vim.g[name] > 0 then
      M.notify(M.format('Time Out[%s]: %d', name, timeout))
      M.clear_interval(vim.g[name])
      vim.g[name] = 0
    end
  end

  M.set_timeout(timeout, function()
    if vim.g[name] == -1 then
      return
    else
      local temp = vim.g[name]
      callback_timeout_do()
      if temp ~= 0 and callback_timeout then
        callback_timeout()
      end
    end
  end)
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

function M.reset_hunk_v()
  require 'gitsigns'.reset_hunk { vim.fn.line '.', vim.fn.line 'v', }
end

function M.git_reset_buffer()
  require 'gitsigns'.reset_buffer()
end

function M.undo_stage_hunk()
  require 'gitsigns'.undo_stage_hunk()
end

function M.stage_hunk()
  require 'gitsigns'.stage_hunk()
end

function M.git_lazy()
  M.just_run_outside 'lazygit'
end

function M.get_tail(file)
  if not file then
    file = M.get_cur_file()
  end
  return vim.fn.fnamemodify(file, ':t')
end

function M.copy_multiple_filenames()
  vim.fn.setreg('w', vim.loop.cwd())
  vim.fn.setreg('a', M.get_cur_file())
  vim.fn.setreg('b', vim.fn.bufname())
  vim.fn.setreg('t', vim.fn.fnamemodify(vim.fn.bufname(), ':t'))
  vim.fn.setreg('e', vim.fn.expand '<cword>')
  vim.fn.setreg('r', vim.fn.expand '<cWORD>')
  vim.fn.setreg('i', vim.fn.trim(vim.fn.getline '.'))
  vim.fn.setreg('u', M.just_get_git_remote_url())
end

function M.git_pull_recursive_do_do(repo, clone, checkout)
  clone = clone and 'clone' or 'no'
  checkout = checkout and 'checkout' or 'no'
  M.run_silent { M.git_pull_recursive_py, repo, clone, checkout, }
end

function M.git_pull_recursive_do(dir)
  M.git_pull_recursive_do_do(dir, vim.g.clone, vim.g.checkout)
end

function M.git_pull_recursive(clone, checkout)
  vim.g.clone = clone
  vim.g.checkout = checkout
  M.ui({ Org, StdConfig, L, W, P, Big, }, 'git_pull_recursive_do', M.git_pull_recursive_do)
end

function M.git_pull_recursive_all()
  vim.g.clone = 'clone'
  vim.g.checkout = nil
  for _, repo in ipairs { StdConfig, L, W, P, } do
    M.git_pull_recursive_do(repo)
  end
end

function M.git_push_recursive_do_do(commit, file, opts)
  local commit_file = DpTemp .. '\\commit.txt'
  if type(commit) == 'string' then
    commit = M.split(commit)
  elseif type(commit) ~= 'table' then
    commit = { tostring(commit), }
  end
  M.write_lines_to_file(commit, commit_file)
  M.run_silent { M.git_push_recursive_py, commit_file, file, unpack(opts), }
end

function M.git_push_recursive_do(commit, file, opts)
  M.project_cd()
  if not file then
    file = M.get_cur_file()
  end
  if #file == 0 then
    return
  end
  M.run_silent {
    'cd', '/d', M.get_file_parent(file), '&&',
    'git', 'status',
  }
  M.copy_multiple_filenames()
  if opts and not M.in_arr('commit', opts) then
    commit = '.'
  end
  if not M.is(commit) then
    vim.ui.input({ prompt = 'commit info: ', }, function(c)
      if c then
        Sta_234_dos[#Sta_234_dos + 1] = function()
          M.git_push_recursive_do_do(c, file, opts)
        end
        Sta_234_en = 1
        M.git_push_recursive_do_do(c, file, opts)
      end
    end)
  else
    Sta_234_dos[#Sta_234_dos + 1] = function()
      M.git_push_recursive_do_do(commit, file, opts)
    end
    Sta_234_en = 1
    M.git_push_recursive_do_do(commit, file, opts)
  end
end

function M.git_add_commit_push_recursive()
  M.git_push_recursive_do(nil, nil, { 'add', 'commit', 'push', })
end

function M.git_commit_push_recursive()
  M.git_push_recursive_do(nil, nil, { 'commit', 'push', })
end

function M.git_push_recursive()
  M.git_push_recursive_do(nil, nil, { 'push', })
end

function M.git_create_submodule_do(root, path, public, name)
  if not name then
    name = Name
  end
  M.run_silent { M.git_create_submodule_py, root, path, public, name, }
end

function M.git_create_submodule(root, path, public, show_what)
  if not root then
    M.project_cd()
    root = M.get_cwd()
  end
  show_what = show_what and 'temp' or 'main'
  -- M.run_silent { M.git_repo_list_3digit__py, root, show_what, }
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

function M.git_create_submodule_public_temp(root, path)
  M.git_create_submodule(root, path, 'public', 'temp')
end

function M.git_create_submodule_private_temp(root, path)
  M.git_create_submodule(root, path, 'private', 'temp')
end

function M.git_status_recursive_do(root)
  M.run_silent { M.git_status_recursive_py, root, }
end

function M.get_projs_root()
  local dirs = M.get_cur_proj_dirs()
  if dirs then
    return dirs[#dirs]
  end
end

function M.git_status_recursive()
  -- M.ui(vim.fn.reverse(M.get_cur_proj_dirs()), 'git_status_recursive', M.git_status_recursive_do)
  M.git_status_recursive_do(M.get_projs_root())
end

function M.git_show_commits_do(file)
  M.run_silent { M.git_commits_py, file, }
end

function M.git_show_commits(file)
  if not file then
    file = M.get_cur_file()
  elseif file == 'cwd' then
    file = M.get_projs_root()
  end
  M.git_show_commits_do(file)
end

function M.git_pull()
  M.project_cd()
  M.run_silent {
    'cd', '/d', M.get_cwd(), '&&',
    'git', 'pull',
  }
end

function M.set_ft(ft, bnr)
  if not ft then
    return
  end
  if not bnr then
    bnr = vim.fn.bufnr()
  end
  vim.bo[bnr].filetype = ft
end

function M.set_myft()
  M.set_ft 'myft'
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

function M.repeat_str(text, times)
  if not M.is_number(times) then
    return ''
  end
  local res = ''
  for _ = 1, times do
    res = res .. text
  end
  return res
end

function M.arr2str(arr, level)
  local text = ''
  if not level then
    level = 0
  end
  if #arr > 0 then
    text = M.join(arr, M.format('\n%s', M.repeat_str(' ', 4 * level)))
  end
  local index = 0
  for k, v in pairs(arr) do
    index = index + 1
    if k == index then
      goto continue
    end
    local t = type(v)
    local l = #v
    if t == 'table' then
      v = M.arr2str(v, level + 1)
    else
      v = vim.inspect(v)
    end
    v = M.format('%s[%d]: %s', t, l, v)
    text = M.format('%s\n[%s]:\n    (%s)', text, k, v)
    ::continue::
  end
  return text
end

-- function M.arr2str(arr)
--   local text = vim.inspect(arr)
--   text = string.gsub(text, ' = {', ' = {\n    ')
--   text = string.gsub(text, '", "', '",\n     "')
--   text = string.gsub(text, ' },\n', '\n  },\n')
--   text = string.gsub(text, ' }\n', '\n  }\n')
--   return text
-- end

function M.notify(text, level, opts)
  M.lazy_load 'nvim-notify'
  if type(text) == 'table' then
    text = M.arr2str(text)
  end
  if type(text) ~= 'string' then
    return
  end
  vim.notify(text, level, opts)
end

function M.notifications_buffer()
  M.lazy_load 'nvim-notify'
  M.execute_out_buffer 'Notifications'
end

function M.message_buffer()
  M.execute_out_buffer 'message'
end

function M.execute_output_do(cmd)
  if not cmd or #cmd == 0 then
    return
  end
  M.execute_out_buffer(cmd)
end

function M.execute_output()
  M.ui_input('execute_output', '', M.execute_output_do)
end

function M.bw_all_buffer()
  local all_bnrs = M.get_bufs()
  local cnt = 0
  local s = ''
  for _, bnr in ipairs(all_bnrs) do
    cnt = cnt + 1
    s = s .. bnr .. ' '
    M.cmd('bw %d', bnr)
  end
  M.printf('%d buffers bw!: %s', cnt, s)
end

function M.bw_all_unseen_buffer()
  local win_bnrs = M.get_all_win_buf_nrs()
  local all_bnrs = M.get_bufs()
  -- local bw_bnrs = {}
  local cnt = 0
  local s = ''
  for _, bnr in ipairs(all_bnrs) do
    if not M.in_arr(bnr, win_bnrs) then
      local n = M.get_tail(vim.fn.bufname(bnr))
      if #n > 0 then
        s = M.format('%s [%s]', s, n)
      end
      M.cmd('bw %d', bnr)
      cnt = cnt + 1
      -- M.put(bw_bnrs, bnr)
    end
  end
  M.printf('%d buffers bw!: %s', cnt, s)
  -- vim.print(win_bnrs)
  -- vim.print(bw_bnrs)
  -- vim.print(all_bnrs)
end

function M.bw_all_unseen_buffer_other_tab()
  local win_bnrs = M.get_win_buf_nrs()
  local all_bnrs = M.get_bufs()
  local cnt = 0
  local s = ''
  for _, bnr in ipairs(all_bnrs) do
    if not M.in_arr(bnr, win_bnrs) then
      local n = M.get_tail(vim.fn.bufname(bnr))
      if #n > 0 then
        s = M.format('%s [%s]', s, n)
      end
      M.cmd('bw %d', bnr)
      cnt = cnt + 1
    end
  end
  M.printf('%d buffers bw!: %s', cnt, s)
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
  if type(text) == 'table' then
    text = vim.fn.join(text, '\n')
  end
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

M.kill_nvim_two_exes_bat = M.join_path(DpTemp, 'kill_nvim_two_exes.bat')

function M.quit_nvim_qt_prepare()
  local tbl = {
    M.format('taskkill /f /pid %d', vim.loop.os_getppid()),
    M.format('taskkill /f /pid %d', vim.loop.os_getpid()),
  }
  M.write_lines_to_file(tbl, M.kill_nvim_two_exes_bat)
end

function M.quit_nvim_qt()
  M.quit_nvim_qt_prepare()
  vim.cmd 'wshada!'
  M.run_silent { M.kill_nvim_two_exes_bat, }
end

function M.quit_nvim_qt_later()
  M.quit_nvim_qt_prepare()
  M.set_timeout(10, function()
    M.quit_nvim_qt()
  end)
end

function M.start_nvim_qt(file)
  file = file and file or ''
  if M.in_str('session', file) then
    local sessionoptions = vim.opt.sessionoptions
    if M.in_str('#', file) then
      vim.opt.sessionoptions = 'tabpages,sesdir'
    end
    if M.in_str('!', file) then
      vim.cmd 'SessionsSave!'
      -- M.run__silent(M.format("sed -i -e '/winbar/d' %s", SessionVim))
    end
    if M.in_str('#', file) then
      vim.opt.sessionoptions = sessionoptions
    end
    local exe = vim.fn.system(string.format('tasklist /FI "PID eq %d"', vim.loop.os_getppid()))
    if string.find(exe, 'nvim%-qt.exe') then
      vim.cmd 'silent !start nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim -c "SessionsLoad"'
    else
      vim.cmd [[silent !start nvim.exe -c "SessionsLoad"]]
    end
    --- M.cmd('silent !start nvim.exe -S %s', SessionVim)
    --- vim.cmd [[silent !start nvim-qt.exe -- -c "SessionsLoad"]]
    --- --- M.cmd('silent !start nvim-qt.exe -- -S %s', SessionVim)
    return
  end
  local exe = vim.fn.system(string.format('tasklist /FI "PID eq %d"', vim.loop.os_getppid()))
  file = string.gsub(file, '%%', [[\%%]])
  if string.find(exe, 'nvim%-qt.exe') then
    M.cmd('silent !start nvim-qt.exe -- -u ~/AppData/Local/nvim/init-qt.vim %s', file)
  else
    M.cmd('silent !start nvim.exe %s', file)
  end
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
  if min and to_change < min then
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
  if max and to_change > max then
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

function M.get_term_total()
  local bufs = M.get_bufs()
  local a = vim.tbl_filter(function(buf)
    return M.is_term(M.get_bnr_file(buf))
  end, bufs)
  return #a
end

function M.b(buf)
  M.cmd('b%d', buf)
end

function M.jump_or_split_term()
  local term_bufs = M.get_term_bufs()
  if #term_bufs == 0 then
    M.open_term(M.get_parent())
    return
  end
  if not vim.g.term_index then
    vim.g.term_index = 1
  end
  vim.g.term_index = M.inc(vim.g.term_index, #term_bufs, 1)
  if not M.jump_term() then
    vim.cmd 'split'
  end
  M.b(term_bufs[vim.g.term_index])
  M.set_myft()
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

function M.feed_keys(keys)
  -- M.feed_keys [[A/\<cr>]]
  M.cmd([[
    try
      call feedkeys("%s")
    catch
    endtry
  ]], keys)
end

function M.new_win_ftail_do(new)
  M.project_cd()
  local bdir = vim.fn.fnamemodify(vim.fn.bufname(), ':h')
  vim.cmd(new)
  if bdir ~= '.' then
    vim.fn.setline(1, bdir)
  end
  M.set_ft 'myft-empty-exit'
  M.feed_keys [[A/]]
end

function M.new_win_ftail_down()
  M.new_win_ftail_do 'new'
end

function M.new_win_ftail_up()
  M.new_win_ftail_do 'leftabove new'
end

function M.new_win_ftail_left()
  M.new_win_ftail_do 'leftabove vnew'
end

function M.new_win_ftail_right()
  M.new_win_ftail_do 'vnew'
end

function M.is_number(text)
  return tonumber(text)
end

function M.inc_file_tail(bname)
  bname = M.rep_slash(bname)
  local head = vim.fn.fnamemodify(bname, ':h')
  local tail = vim.fn.fnamemodify(bname, ':t')
  local items = vim.fn.split(tail, '-')
  items = vim.fn.reverse(items)
  local len = 0
  for i, item in ipairs(items) do
    local v = M.is_number(item)
    local format = M.format('%%0%dd', #item)
    vim.g.temp_timestamp = item
    vim.g.temp_date = -1
    --- print(item)
    vim.cmd [[
      try
        let g:temp_date = msgpack#strptime('%Y%m%d', g:temp_timestamp)
        " echomsg 'xxxxxxxxx'
        " echomsg g:temp_date
      catch
        " echomsg 'wwwwwwwww'
      endtry
    ]]
    if v then
      if vim.g.temp_date < 0 then
        items[i] = M.format(format, M.inc(v))
        break
      end
    end
    len = len + #item + 1
  end
  items = vim.fn.reverse(items)
  return M.format('%s%s', head ~= '.' and head .. '/' or '', M.join(items, '-')), #bname - len + 1
end

function M.new_win_finc_do(new)
  M.project_cd()
  local bname = vim.fn.bufname()
  local col
  vim.cmd(new)
  bname, col = M.inc_file_tail(bname)
  vim.fn.setline(1, bname)
  M.set_ft 'myft-empty-exit'
  M.cmd('norm 0%sl', col)
  vim.fn.setpos('.', { 0, 1, col + 1, })
end

function M.new_win_finc_down()
  M.new_win_finc_do 'new'
end

function M.new_win_finc_up()
  M.new_win_finc_do 'leftabove new'
end

function M.new_win_finc_left()
  M.new_win_finc_do 'leftabove vnew'
end

function M.new_win_finc_right()
  M.new_win_finc_do 'vnew'
end

function M.list_buf_info()
  local infos = {}
  for _, buf in ipairs(M.get_bufs()) do
    M.put(infos, M.format('%s %s %s', buf, M.get_bnr_file(buf), vim.bo[buf].filetype))
  end
  M.notify(infos)
end

function M.get_ft_bnr(ft)
  if not ft then
    return nil
  end
  for _, buf in ipairs(M.get_win_buf_nrs()) do
    if ft == vim.bo[buf].filetype then
      return buf
    end
  end
end

function M.cmdline(cmd)
  M.copy_multiple_filenames()
  -- M.feed_keys(M.format(':%s', cmd and cmd or [[\<up>]]))
  M.feed_keys(M.format(':%s', cmd and cmd or ''))
end

vim.api.nvim_create_user_command('Run', function(params)
  M.run__silent(M.join(params['fargs'], ' '))
end, { nargs = '*', })

function M.cmd_outside(cmd)
  M.copy_multiple_filenames()
  M.feed_keys(M.format(':Run %s', cmd and cmd or ''))
end

function M.toggle(val)
  if type(val) == 'boolean' then
    if val == true then
      return false
    end
    return true
  end
  if type(val) == 'number' then
    if val ~= 1 then
      return 0
    end
    return 1
  end
  return val
end

function M.set_opt(opt, val, scope)
  if not scope then
    scope = 'global'
  end
  vim.api.nvim_set_option_value(opt, val, { scope = scope, })
end

function M.get_opt(opt, scope)
  if not scope then
    scope = 'global'
  end
  return vim.api.nvim_get_option_value(opt, { scope = scope, })
end

function M.toggle_opt(opt, a, b, scope)
  if a == nil or b == nil then
    return
  end
  if M.get_opt(opt, scope) == a then
    M.set_opt(opt, b, scope)
  else
    M.set_opt(opt, a, scope)
  end
end

function M.toggle_local(opt)
  M.toggle_opt(opt, true, false, 'local')
end

function M.toggle_global(opt)
  M.toggle_opt(opt, true, false)
end

function M.toggle_winbar()
  M.hi_winbar()
  M.toggle_opt('winbar', '', vim.g.winbar)
end

function M.toggle_diff()
  if M.get_opt('diff', 'local') == true then
    vim.cmd 'diffoff'
  else
    vim.cmd 'diffthis'
  end
end

function M.toggle_vim_g_winbar()
  M.hi_winbar()
  M.toggle_opt('winbar', vim.g.winbar2, vim.g.winbar)
end

--- function M.toggle_statusline()
---   M.toggle_opt('statusline', '', vim.g.statusline)
--- end

function WinBarName()
  local tail = M.get_cur_tail()
  return #tail > 0 and tail or '[No Name]'
end

function WinBarProj()
  -- return M.get_proj_tail()
  return M.get_proj()
end

--- function Statusline()
---   return M.get_cur_file()
--- end

function M.telescope(cmd, dir)
  M.lazy_load 'telescope'
  if dir then
    M.cmd('Telescope %s cwd=%s', cmd, dir)
    return
  end
  M.cmd('Telescope %s', cmd)
end

function M.lsp_document_symbols()
  M.telescope 'lsp_document_symbols'
end

function M.lsp_references()
  M.telescope 'lsp_references'
end

function M.get_file_dirs(file, till_git)
  if not file then
    file = M.get_cur_file()
  end
  file = M.rep(file)
  local file_path = M.new_file(file)
  local dirs = {}
  for _ = 1, 24 do
    file_path = file_path:parent()
    local name = M.rep(file_path.filename)
    if #dirs > 0 and dirs[1] == name then
      break
    end
    table.insert(dirs, 1, name)
    if till_git and M.is_file_exists(M.new_file(name):joinpath '.git'.filename) then
      break
    end
  end
  return dirs
end

function M.cmake_do(root)
  if not M.is_file_exists(root) then
    return
  end
  M.run_outside {
    M.cbp2cmake_py, root,
  }
end

function M.cmake()
  if #M.get_proj() == 0 then
    return
  end
  M.ui(M.get_file_dirs(nil, 'till_git'), 'cmake', M.cmake_do)
end

function M.get_opened_projs()
  local bufs = M.get_bufs()
  if not bufs or #bufs == 0 then
    return
  end
  local projs = {}
  for _, buf in ipairs(bufs) do
    local file = M.get_bnr_file(buf)
    if #file > 0 and M.is_file_exists(file) then
      M.put_uniq(projs, M.get_proj(file))
    end
  end
  return projs
end

function M.get_opened_projs_bufs()
  local bufs = M.get_bufs()
  if not bufs or #bufs == 0 then
    return
  end
  local projs = {}
  for _, buf in ipairs(bufs) do
    local file = M.get_bnr_file(buf)
    if #file > 0 and M.is_file_exists(file) then
      local proj = M.get_proj(file)
      if not projs[proj] then
        projs[proj] = {}
      end
      M.put_uniq(projs[proj], buf)
    end
  end
  return projs
end

function M.get_opened_projs_files()
  local proj_bufs = M.get_opened_projs_bufs()
  if not proj_bufs then
    return
  end
  local files = {}
  for proj, bufs in pairs(proj_bufs) do
    files[proj] = {}
    for _, buf in ipairs(bufs) do
      M.put(files[proj], M.get_bnr_file(buf))
    end
  end
  return files
end

function M.opened_proj_files(file)
  M.jump_or_edit(file)
end

function M.opened_proj_files_sel(proj)
  M.ui(M.get_opened_projs_files()[proj], 'opened_files', M.opened_proj_files)
end

function M.opened_proj_sel()
  M.ui(M.get_opened_projs(), 'opened_projs', M.opened_proj_files_sel)
end

function M.jump_term()
  for i = vim.fn.winnr '$', 1, -1 do
    if M.is_term(M.get_bnr_file(vim.fn.winbufnr(i))) then
      vim.fn.win_gotoid(vim.fn.win_getid(i))
      return true
    end
  end
end

function M.open_term_do(cmd)
  if not M.jump_term() then
    vim.cmd 'split'
  end
  M.cmd('cd %s |te %s', vim.g.term_dir, cmd)
  M.set_myft()
  vim.g.term_total = M.get_term_total()
end

function M.open_term(dir)
  vim.g.term_dir = vim.fn.trim(dir, '\\')
  M.ui({ 'cmd', 'ipython', 'bash', 'powershell', 'lazygit', }, 'which_term', M.open_term_do)
end

function M.merge_tables(...)
  local result = {}
  for _, t in ipairs { ..., } do
    for _, v in ipairs(t) do
      M.put_uniq(result, v)
    end
  end
  return result
end

function M.get_sh_get_folder_path(name)
  local f = io.popen(M.sh_get_folder_path_exe .. ' ' .. (name and name or ''))
  if f then
    local dirs = {}
    for dir in string.gmatch(f:read '*a', '([%S ]+)') do
      dir = M.rep(dir)
      if not M.in_arr(dir, dirs) then
        dirs[#dirs + 1] = dir
      end
    end
    f:close()
    table.sort(dirs)
    return dirs
  end
  return {}
end

DIRS = {
  M.get_sh_get_folder_path 'desktop'[1],
  Home,
  Dp,
  Org,
  Big,
  W,
  L,
  P,
  DpTemp,
  TreeSitter,
  Mason,
  StdConfig,
  StdData,
  LazyPath,
  DataLazyPlugins,
  'C:\\Program Files\\Neovim',
}

function M.open_term_sel()
  local dirs = M.get_file_dirs()
  M.ui(M.merge_tables(DIRS, dirs), 'open_term', M.open_term)
end

function M.nvimtree_cd_sel_DIRS()
  vim.cmd 'NvimTreeOpen'
  M.nvimtree_cd_sel(DIRS)
end

function M.cd(dir)
  if M.is_dir(dir) then
    M.cmd('cd %s', dir)
  end
end

function M.cd_term_cwd(file)
  vim.g.term_total = M.get_term_total()
  if M.is_term(file) then
    M.cd(string.match(file, 'term://(.+)//.+'))
  end
end

function M.split(text, sep)
  if not sep then
    sep = '\n'
  end
  return vim.fn.split(text, sep)
end

function M.null()
end

function M.git_diff(_, index)
  require 'gitsigns'.diffthis(M.format('~%d', index))
end

function M.reverse(arr)
  return vim.fn.reverse(arr)
end

function M.git_diff_sel()
  local git_logs = M.split(vim.fn.system 'git log --oneline')
  M.ui(git_logs, 'git diff sel', M.git_diff)
end

function M.delete_empty_line(text)
  text = string.gsub(text, '\r', '')
  while M.in_str('\n\n', text) do
    text = string.gsub(text, '\n\n', '\n')
  end
  return text
end

function M.git_get_commit_quick(which)
  local commit
  if which == 'regh' then
    commit = M.join({ vim.fn.getreg 'h', }, ' ')
  elseif which == 'reghj' then
    commit = M.join({ vim.fn.getreg 'h', vim.fn.getreg 'j', }, ' ')
  elseif which == 'reghjk' then
    commit = M.join({ vim.fn.getreg 'h', vim.fn.getreg 'j', vim.fn.getreg 'k', }, ' ')
  elseif which == 'reghjkl' then
    commit = M.join({ vim.fn.getreg 'h', vim.fn.getreg 'j', vim.fn.getreg 'k', vim.fn.getreg 'l', }, ' ')
  elseif which == 'yanked' then
    commit = M.delete_empty_line(vim.fn.getreg '"')
  elseif which == 'clipboard' then
    commit = M.delete_empty_line(vim.fn.getreg '+')
  elseif which == 'cword' then
    commit = vim.fn.expand '<cword>'
  elseif which == 'cWORD' then
    commit = vim.fn.expand '<cWORD>'
  elseif which == 'line' then
    commit = vim.fn.trim(vim.fn.getline '.')
  elseif which == 'tail' then
    commit = vim.fn.trim(vim.fn.fnamemodify(vim.fn.bufname(), ':t'))
  elseif M.in_str('treesitter', which) then
    if vim.fn.mode() ~= 'n' then
      M.feed_keys [[\<esc>]]
    end
    require 'nvim-treesitter.incremental_selection'.node_incremental()
    if which == 'treesitter2' then
      require 'nvim-treesitter.incremental_selection'.node_incremental()
    end
    if which == 'treesitter3' then
      require 'nvim-treesitter.incremental_selection'.node_incremental()
      require 'nvim-treesitter.incremental_selection'.node_incremental()
    end
    if which == 'treesitter4' then
      require 'nvim-treesitter.incremental_selection'.node_incremental()
      require 'nvim-treesitter.incremental_selection'.node_incremental()
      require 'nvim-treesitter.incremental_selection'.node_incremental()
    end
    M.feed_keys 'y'
    commit = vim.fn.getreg '"'
  end
  return commit
end

function M.git_add_commit_push_recursive_quick(which)
  local commit = M.git_get_commit_quick(which)
  if not commit or #commit == 0 then
    return
  end
  M.git_push_recursive_do(commit, nil, { 'add', 'commit', 'push', })
end

function M.git_commit_push_recursive_quick(which)
  local commit = M.git_get_commit_quick(which)
  if not commit or #commit == 0 then
    return
  end
  M.git_push_recursive_do(commit, nil, { 'commit', 'push', })
end

M.input_method_py = M.get_py '09-change-input-method.py'

function M.change_language(lang)
  M.cmd([[silent !start /b /min cmd /c "%s %s"]], M.input_method_py, lang)
end

function M.diffview_stash()
  vim.cmd 'DiffviewFileHistory --walk-reflogs --range=stash'
end

function M.diffview_open()
  vim.cmd 'DiffviewOpen -u'
end

function M.diffview_close()
  vim.cmd 'DiffviewClose'
end

function M.diffview_filehistory(mode)
  if mode == 1 then
    vim.cmd 'DiffviewFileHistory'
  elseif mode == 2 then
    vim.cmd 'DiffviewFileHistory --max-count=64'
  elseif mode == 3 then
    vim.cmd 'DiffviewFileHistory --max-count=238778'
  end
end

function M.refresh_later()
  M.set_timeout(100, function()
    M.refresh()
  end)
end

function M.git_archive_do(dir)
  M.feed_keys(':\\<c-u>silent ! cd /d '
    .. M.double_backslash(dir)
    .. ' && git archive --output='
    .. M.double_backslash(M.get_sh_get_folder_path 'desktop'[1])
    .. '\\\\'
    .. vim.fn.fnamemodify(dir, ':t')
    .. '.zip HEAD')
end

function M.git_archive()
  local dirs = M.get_file_dirs()
  M.ui(dirs, 'git_archive', M.git_archive_do)
end

function M.git_reset_hard()
  M.run__silent 'git reset --hard'
  M.refresh_later()
end

function M.git_clean_fd()
  M.run__silent 'git clean -fd'
  M.refresh_later()
end

function M.git_reset_hard_clean_fd()
  M.run__silent 'git reset --hard'
  M.run__silent 'git clean -fd'
  M.refresh_later()
end

function M.todo_telescope_do(cwd)
  if vim.g.todo_what then
    M.cmd('TodoTelescope cwd=%s keywords=%s', cwd, vim.g.todo_what)
  else
    M.cmd('TodoTelescope cwd=%s', cwd)
  end
end

function M.todo_telescope(what)
  local cwd = M.rep(vim.loop.cwd())
  vim.g.todo_what = nil
  if what then
    vim.g.todo_what = what
  end
  M.todo_telescope_do(cwd)
end

function M.todo_telescope_sel(dirs, what)
  vim.g.todo_what = what
  M.ui(dirs, M.format('%s sel', what), M.todo_telescope_do)
end

function M.todo_quickfix_do(cwd)
  if vim.g.todo_what then
    M.cmd('TodoQuickFix cwd=%s keywords=%s', cwd, vim.g.todo_what)
  else
    M.cmd('TodoQuickFix cwd=%s', cwd)
  end
end

function M.todo_quickfix(what)
  local cwd = M.rep(vim.loop.cwd())
  vim.g.todo_what = nil
  if what then
    vim.g.todo_what = what
  end
  M.todo_quickfix_do(cwd)
end

function M.todo_quickfix_sel(dirs, what)
  vim.g.todo_what = what
  M.ui(dirs, M.format('%s sel', what), M.todo_quickfix_do)
end

function M.title_cur_line()
  local title = vim.fn.trim(vim.fn.getline '.')
  --- M.write_lines_to_file({}, title)
  M.cmd('w %s', title)
  M.cmd('e %s', title)
end

function M.mkdir_cur_tail()
  local file = M.get_cur_file()
  local parent = vim.fn.fnamemodify(file, ':p:h')
  local dir = vim.fn.fnamemodify(file, ':t:r')
  M.run__silent(M.format('cd /d "%s" && md "%s"', parent, dir))
end

function M.get_paragraph(lnr)
  local paragraph = {}
  if not lnr then
    lnr = '.'
  end
  local linenr = vim.fn.line(lnr)
  local lines = 0
  for i = linenr, 1, -1 do
    local line = vim.fn.getline(i)
    if #line > 0 then
      lines = lines + 1
      table.insert(paragraph, 1, line)
    else
      M.markdowntable_line = i + 1
      break
    end
  end
  for i = linenr + 1, vim.fn.line '$' do
    local line = vim.fn.getline(i)
    if #line > 0 then
      table.insert(paragraph, line)
      lines = lines + 1
    else
      break
    end
  end
  return paragraph
end

function M.format_number_str(num, str, left, right)
  vim.g.num = num
  vim.g.str = str
  vim.g.left = left
  vim.g.right = right
  vim.cmd [[
    python << EOF
import vim
num = vim.eval('g:num')
s = vim.eval('g:str')
left = vim.eval('g:left')
right = vim.eval('g:right')
p = left + f'%-{num}s' + right
ret = p % s
vim.command(f'''let g:ret = "{ret}"''')
EOF
  ]]
  return vim.g.ret
end

function M.align_table()
  if vim.opt.modifiable:get() == 0 then
    return
  end
  if vim.opt.ft:get() ~= 'markdown' then
    return
  end
  local ll = vim.fn.getpos '.'
  local lines = M.get_paragraph()
  local cols = 0
  for _, line in ipairs(lines) do
    local cells = vim.fn.split(vim.fn.trim(line), '|')
    if string.match(line, '|') and cols < #cells then
      cols = #cells
    end
  end
  if cols == 0 then
    return
  end
  local Lines = {}
  local Matrix = {}
  for _, line in ipairs(lines) do
    local cells = vim.fn.split(vim.fn.trim(line), '|')
    local Cells = {}
    local matrix = {}
    for i = 1, cols do
      local cell = cells[i]
      if cell then
        cell = string.gsub(cells[i], '^%s*(.-)%s*$', '%1')
      else
        cell = ''
      end
      table.insert(Cells, cell)
      table.insert(matrix, { vim.fn.strlen(cell), vim.fn.strwidth(cell), })
    end
    table.insert(Lines, Cells)
    table.insert(Matrix, matrix)
  end
  local Cols = {}
  for i = 1, cols do
    local m = 0
    for j = 1, #Matrix do
      if Matrix[j][i][2] > m then
        m = Matrix[j][i][2]
      end
    end
    table.insert(Cols, m)
  end
  local newLines = {}
  for i = 1, #Lines do
    local Cells = Lines[i]
    local newCell = '|'
    for j = 1, cols do
      local len = Matrix[i][j][1] + (Cols[j] - Matrix[i][j][2])
      local temp
      if len >= 100 then
        temp = string.format(' %-s', Cells[j]) .. M.repeat_str(' ', len - vim.fn.len(Cells[j])) .. ' |'
      else
        temp = string.format(string.format(' %%-%ds |', len), Cells[j])
      end
      newCell = newCell .. temp
      -- newCell = newCell .. M.format_number_str(Matrix[i][j][1] + (Cols[j] - Matrix[i][j][2]), Cells[j], ' ', ' |')
    end
    table.insert(newLines, newCell)
  end
  vim.fn.setline(M.markdowntable_line, newLines)
  M.cmd('norm %dgg0%d|', ll[2], ll[3])
end

function M.is_buf_fts(fts, buf)
  if not buf then
    buf = vim.fn.bufnr()
  end
  if type(fts) == 'string' then
    fts = { fts, }
  end
  if M.is(vim.tbl_contains(fts, vim.api.nvim_buf_get_option(buf, 'filetype'))) then
    return 1
  end
  return nil
end

function M.lsp_format()
  vim.lsp.buf.format()
  if M.is_buf_fts { 'markdown', } then
    M.align_table()
  end
end

function M.system_cd(file)
  local fpath = M.new_file(file)
  if fpath:is_dir() then
    return 'cd /d ' .. file
  else
    return 'cd /d ' .. fpath:parent().filename
  end
end

M.xxd_output_dir_path = DpTemp .. '\\xxd_output'

if vim.fn.isdirectory(M.xxd_output_dir_path) == 0 then
  vim.fn.mkdir(M.xxd_output_dir_path)
end

function M.xxd_g_c(xxd_g_c)
  if not xxd_g_c then
    xxd_g_c = 'bytes: 1, cols: 16'
  end
  local bytes = string.match(xxd_g_c, '^bytes: (%d+),')
  local cols = string.match(xxd_g_c, 'cols: (%d+)$')
  local bin_fname = M.rep(vim.g.xxd_file)
  local bin_fname_tail = vim.fn.fnamemodify(bin_fname, ':t')
  local bin_fname_full__ = string.gsub(vim.fn.fnamemodify(bin_fname, ':h'), '\\', '_')
  bin_fname_full__ = string.gsub(bin_fname_full__, ':', '_')
  local xxd_output_sub_dir_path = M.new_file(M.join_path(M.xxd_output_dir_path, bin_fname_full__))
  if not xxd_output_sub_dir_path:exists() then
    vim.fn.mkdir(xxd_output_sub_dir_path.filename)
  end
  local xxd = xxd_output_sub_dir_path:joinpath(bin_fname_tail .. '.xxd').filename
  local c = xxd_output_sub_dir_path:joinpath(bin_fname_tail .. '.c').filename
  local bak = xxd_output_sub_dir_path:joinpath(bin_fname_tail .. '.bak').filename
  vim.fn.system(string.format('copy /y "%s" "%s"', bin_fname, bak))
  vim.fn.system(string.format('xxd -g %d -c %d "%s" "%s"', bytes, cols, bak, xxd))
  vim.fn.system(string.format('%s && xxd -i -c %d "%s" "%s"', M.system_cd(bak), cols, vim.fn.fnamemodify(bak, ':t'), c))
  vim.cmd('e ' .. xxd)
  vim.cmd 'setlocal ft=xxd'
end

function M.bin_xxd(file)
  if not file then
    file = M.get_cur_file()
  end
  vim.g.xxd_file = file
  M.xxd_g_c()
end

function M.bin_xxd_sel(file)
  if not file then
    file = M.get_cur_file()
  end
  vim.g.xxd_file = file
  M.ui({
    'bytes: 1, cols: 16',
    'bytes: 2, cols: 16',
    'bytes: 4, cols: 16',
    'bytes: 1, cols: 12',
    'bytes: 2, cols: 12',
    'bytes: 4, cols: 12',
    'bytes: 1, cols: 8',
    'bytes: 2, cols: 8',
    'bytes: 4, cols: 8',
    'bytes: 1, cols: 4',
    'bytes: 2, cols: 4',
    'bytes: 4, cols: 4',
    'bytes: 1, cols: 32',
    'bytes: 2, cols: 32',
    'bytes: 4, cols: 32',
    'bytes: 1, cols: 64',
    'bytes: 2, cols: 64',
    'bytes: 4, cols: 64',
    'bytes: 1, cols: 20',
    'bytes: 2, cols: 20',
    'bytes: 4, cols: 20',
    'bytes: 1, cols: 24',
    'bytes: 2, cols: 24',
    'bytes: 4, cols: 24',
    'bytes: 1, cols: 28',
    'bytes: 2, cols: 28',
    'bytes: 4, cols: 28',
  }, 'bin_xxd_sel', M.xxd_g_c)
end

function M.run_under_desktop_do(args)
  if not args then
    return
  end
  local desktop = M.get_sh_get_folder_path 'desktop'[1]
  for _, file in ipairs(vim.g.files) do
    local tail = vim.fn.fnamemodify(file, ':t')
    file = M.get_file({ desktop, }, tail)
    if M.is_file_exists(file) then
      M.run__silent(M.format('cd /d %s & %s %s', desktop, file, args))
    end
  end
end

function M.run_under_desktop(files)
  if not files then
    return
  end
  M.copy_to_desktop(files)
  vim.g.files = files
  M.ui_input('run_under_desktop_do', '', M.run_under_desktop_do)
end

function M.copy_to_desktop(files)
  if not files then
    return
  end
  local desktop = M.get_sh_get_folder_path 'desktop'[1]
  for _, file in ipairs(files) do
    if M.is_file_exists(file) then
      M.run__silent(M.format('copy /y %s %s', file, desktop))
    end
  end
end

function M.delete_from_desktop(files)
  if not files then
    return
  end
  local desktop = M.get_sh_get_folder_path 'desktop'[1]
  for _, file in ipairs(files) do
    local tail = vim.fn.fnamemodify(file, ':t')
    file = M.get_file({ desktop, }, tail)
    if M.is_file_exists(file) then
      M.run__silent(M.format('del /f /s %s', file))
    end
  end
end

function M.git_add_force(files)
  if not files then
    return
  end
  for _, file in ipairs(files) do
    M.run__silent(M.format('git add -f "%s"', file))
  end
end

function M.git_delete_force(files)
  if not files then
    return
  end
  for _, file in ipairs(files) do
    M.run__silent(M.format('git rm -f "%s"', file))
  end
end

function M.system_copy(files)
  if not files then
    return
  end
  M.run__silent(M.format('%s "%s"', M.copy2clip_exe, vim.fn.join(files, '" "')))
end

function M.system_paste(dir)
  if not dir then
    return
  end
  M.run_silent {
    'powershell',
    M.format([[Get-Clipboard -Format FileDropList | ForEach-Object { Copy-Item -Path $_.FullName -Recurse -Destination "%s" }]], dir),
  }
end

function M.findall(patt, str)
  vim.g.patt = patt
  vim.g.str = str
  vim.g.res = {}
  vim.cmd [[
    python << EOF
import re
import vim
try:
  import luadata
except:
  import os
  os.system('pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host mirrors.aliyun.com luadata')
  import luadata
patt = vim.eval('g:patt')
string = vim.eval('g:str')
res = re.findall(patt, string)
if res:
  new_res = eval(str(res).replace('(', '[').replace(')', ']'))
  new_res = luadata.serialize(new_res, encoding='utf-8', indent=' ', indent_level=0)
  vim.command(f"""lua vim.g.res = {new_res}""")
EOF
  ]]
  return vim.g.res
end

function M.get_git_remote_url(proj)
  local remote = ''
  if proj then
    remote = vim.fn.system(string.format('cd %s && git remote -v', proj))
  else
    remote = vim.fn.system 'git remote -v'
  end
  local res = M.findall('.*git@([^:]+):([^/]+)/([^ ]+).*', remote)
  local urls = {}
  local type = nil
  if #res == 0 then
    res = M.findall('https://([^ ]+)', remote)
    for _, r in ipairs(res) do
      local url = r
      if not M.in_arr(url, urls) then
        urls[#urls + 1] = url
        type = 'https'
      end
    end
  else
    for _, r in ipairs(res) do
      local url = string.format('%s/%s/%s', unpack(r))
      if not M.in_arr(url, urls) then
        urls[#urls + 1] = url
        type = 'ssh'
      end
    end
  end
  if #urls > 0 then
    return type, string.format('%s', urls[1])
  end
  return type, ''
end

function M.just_get_git_remote_url(proj)
  local remote = ''
  if proj then
    remote = vim.fn.system(string.format('cd %s && git remote -v', proj))
  else
    remote = vim.fn.system 'git remote -v'
  end
  local res = M.findall([[\s([^\s]*git.*\.com[^\s]+)\s]], remote)
  if #res >= 1 then
    return res[1]
  end
  return ''
end

function M.git_browser()
  local _, url = M.get_git_remote_url()
  if M.is(url) then
    M.run__silent(M.format('start https://%s', url))
  end
end

function M.totable(var)
  if type(var) ~= 'table' then
    var = { var, }
  end
  return var
end

function M.getcreate_dirpath(dirs)
  dirs = M.totable(dirs)
  local dir1 = table.remove(dirs, 1)
  dir1 = M.rep(dir1)
  local dir_path = M.new_file(dir1)
  if not dir_path:exists() then
    vim.fn.mkdir(dir_path.filename)
  end
  for _, dir in ipairs(dirs) do
    dir_path = dir_path:joinpath(dir)
    if not dir_path:exists() then
      vim.fn.mkdir(dir_path.filename)
    end
  end
  return dir_path
end

function M.getcreate_dir(dirs)
  return M.getcreate_dirpath(dirs).filename
end

function M.get_filepath(dirs, file)
  local dirpath = M.getcreate_dirpath(dirs)
  return dirpath:joinpath(file)
end

function M.get_file(dirs, file)
  return M.get_filepath(dirs, file).filename
end

function M.getcreate_filepath(dirs, file)
  local file_path = M.get_filepath(dirs, file)
  if not file_path:exists() then
    file_path:touch()
  end
  return file_path
end

function M.getcreate_file(dirs, file)
  return M.getcreate_filepath(dirs, file).filename
end

function M.just_init_do(git_root_dir)
  M.run_silent {
    'cd', '/d', git_root_dir, '&&',
    M.svn_tmp_gitkeep_py, '&&',
    M.git_init_py, git_root_dir, GitFakeRemoteDir,
  }
end

function M.just_init()
  M.ui(M.get_file_dirs(M.get_cur_file()), 'git init', M.just_init_do)
end

function M.get_session_saved_projects()
  local session_saved_projects = M.read_lines_from_file(M.session_saved_projects_txt)
  local session_saved_projects_new = {}
  for _, path in ipairs(session_saved_projects) do
    local tail = M.rep(vim.fn.fnamemodify(path, ':t'))
    if M.is_file_exists(path) then
      local vim_file = M.get_file({ path, }, tail .. '.vim')
      if M.is_file_exists(vim_file) then
        M.put_uniq(session_saved_projects_new, M.rep(path))
      end
    end
  end
  return session_saved_projects_new
end

function M.save_sessions_at_cwd_do(project_root)
  -- vim.cmd 'SessionsSave!'
  local session_saved_projects = M.get_session_saved_projects()
  local session_vim = vim.fn.fnamemodify(project_root, ':t') .. '.vim'
  M.put_uniq(session_saved_projects, project_root)
  M.write_lines_to_file(session_saved_projects, M.session_saved_projects_txt)
  -- M.run__silent(M.format('copy /y "%s" "%s"', SessionVim, M.get_file({ project_root, }, session_vim)))
  local session_vim_full = M.get_file({ project_root, }, session_vim)
  vim.fn.delete(session_vim_full)
  M.cmd('mksession %s', session_vim_full)
  -- M.run__silent(M.format("sed -i -e '/winbar/d' %s", session_vim))
end

function M.save_sessions_at_cwd()
  M.ui(M.get_cur_proj_dirs(M.get_cur_file()), 'save_sessions_at_cwd', M.save_sessions_at_cwd_do)
end

function M.load_sessions_sel_do(dir)
  local tail = vim.fn.fnamemodify(dir, ':t')
  local vim_file = M.get_file({ dir, }, tail .. '.vim')
  M.cmd('silent source %s', vim_file)
end

function M.get_recent_projects()
  local recent_projects = {}
  local temp = require 'telescope._extensions.project.utils'.get_projects 'recent'
  for _, v in ipairs(temp) do
    M.put_uniq(recent_projects, v.path)
  end
  return recent_projects
end

function M.reload_sessions_sel()
  local session_saved_projects = {}
  local temp = require 'telescope._extensions.project.utils'.get_projects 'recent'
  for _, v in ipairs(temp) do
    local path = v.path
    local tail = vim.fn.fnamemodify(path, ':t')
    if M.is_file_exists(path) then
      local vim_file = M.get_file({ path, }, tail .. '.vim')
      if M.is_file_exists(vim_file) then
        M.put_uniq(session_saved_projects, M.rep(path))
      end
    end
  end
  M.write_lines_to_file(session_saved_projects, M.session_saved_projects_txt)
  M.ui(session_saved_projects, 'load_sessions_sel', M.load_sessions_sel_do)
end

function M.load_sessions_sel()
  local session_saved_projects = M.get_session_saved_projects()
  if #session_saved_projects > 0 then
    M.ui(session_saved_projects, 'load_sessions_sel', M.load_sessions_sel_do)
  else
    M.reload_sessions_sel()
  end
end

function M.work_summary_day_do(day)
  if not day or #day == 0 then
    return
  end
  M.run__silent(M.format('%s %s %s %s', M.work_summary_day_py, W .. '\\work.md', day, vim.g.morning))
end

function M.work_summary_day(morning)
  vim.g.morning = morning
  M.ui_input('work_summary_day', vim.fn.strftime '%Y-%m-%d', M.work_summary_day_do)
end

function M.get_weeks()
  vim.g.Week1Date = Week1Date
  vim.cmd [[
    python << EOF
import vim
import datetime
Week1Date = [eval(i) for i in vim.eval('g:Week1Date')]
week1date = datetime.datetime(*Week1Date)
today = datetime.datetime.now()
D = []
TodayWeek = 0
for i in range(26):
  start = week1date + datetime.timedelta(weeks=i, days=0)
  end = week1date + datetime.timedelta(weeks=i, days=6)
  d = f"""W{i+1:02} {start.strftime('%Y-%m-%d')}~{end.strftime('%Y-%m-%d')}"""
  if 0 <= (today-start).days <= 6:
    TodayWeek = d
  # print(d)
  D.append(d)
D.insert(0, TodayWeek)
vim.command(f'''let g:Week1Date = {D}''')
EOF
  ]]
  return vim.g.Week1Date
end

function M.work_summary_week_do(week)
  if not week or #week == 0 then
    return
  end
  M.run__silent(M.format('%s %s "%s"', M.work_summary_week_py, W .. '\\work.md', week))
end

function M.work_summary_week()
  M.ui(M.get_weeks(), 'work_summary_week', M.work_summary_week_do)
end

function M.work_day_append_do(day)
  vim.fn.append('.', M.format('## %s', day))
end

function M.work_day_append()
  M.ui_input('work_day_append', vim.fn.strftime '%Y-%m-%d', M.work_day_append_do)
end

M.tts_text = ''

M.tts_end_flag_chars = {
  '，', '。', '？', '；', '：', '、', '——', '》', '）', '】', '”', '’', '……',
  ',', '\\.', '?', ';', ':', '"',
}

function M.tts_speak()
  local temp_tts_txt = DpTemp .. '\\tts.txt'
  if M.tts_text == '' then
    return
  end
  M.write_lines_to_file({ M.tts_text, }, temp_tts_txt)
  M.tts_text = ''
end

function M.tts(text)
  -- M.run__silent(M.format('%s "%s"', M.tts_py, text))
  M.tts_text = M.tts_text .. text
  for _, char in ipairs(M.tts_end_flag_chars) do
    if M.in_str(char, text) then
      M.tts_speak()
      break
    end
  end
end

function M.bcomp_a(file)
  if not file then
    file = M.get_cur_file()
  end
  vim.g.bcomp_a_file = file
end

function M.bcomp_l()
  if vim.g.bcomp_a_file and vim.g.bcomp_b_file then
    M.run__silent(M.format('bcomp "%s" "%s"', vim.g.bcomp_a_file, vim.g.bcomp_b_file))
  end
end

function M.bcomp_b(file)
  if not file then
    file = M.get_cur_file()
  end
  vim.g.bcomp_b_file = file
  M.bcomp_l()
end

function M.expand_cfile()
  local cfile = vim.split(vim.fn.expand '<cfile>', '=')
  return cfile[#cfile]
end

function M.get_cfile(depth)
  if not depth then
    depth = 1
  end
  local file = M.expand_cfile()
  if M.in_str('/', file) or M.in_str('\\', file) then
    if M.is_file_exists(file) then
      return file
    end
  end
  local f = M.join_path(M.get_cwd(), file)
  if M.is_file_exists(f) then
    return f
  end
  local dirs = ps.scan_dir(M.get_cwd(), { hidden = false, depth = depth, add_dirs = true, only_dirs = true, })
  for _, dir in ipairs(dirs) do
    f = M.join_path(dir, file)
    if M.is_file_exists(f) then
      return f
    end
  end
  return nil
end

function M.go_cfile(force, fd)
  local cfile = M.get_cfile()
  if not cfile then return end
  cfile = M.new_file(cfile):absolute()
  if not cfile then
    cfile = M.get_cfile(64)
    if not cfile then
      return
    end
  end
  if fd then -- 用telescope去找文件
    if not M.is_dir(cfile) then
      cfile = M.get_parent(cfile)
    end
    vim.g.telescope_cmd = 'fd'
    M.telescope_do(cfile)
    return
  end
  if M.is_dir(cfile) then
    M.nvimtree_cd(cfile)
  elseif M.is_file(cfile) then
    if not force and vim.fn.getfsize(cfile) >= 20 * 1024 * 1024 then
      M.run__silent(cfile)
    else
      M.jump_or_edit(cfile)
    end
  end
end

function M.fix_width_inc()
  vim.cmd '5wincmd >'
  vim.cmd 'set winfixwidth'
end

function M.fix_width_dec()
  vim.cmd '5wincmd <'
  vim.cmd 'set winfixwidth'
end

function M.fix_height_inc()
  vim.cmd '5wincmd +'
  vim.cmd 'set winfixheight'
end

function M.fix_height_dec()
  vim.cmd '5wincmd -'
  vim.cmd 'set winfixheight'
end

function M.unfix_width()
  vim.cmd 'set nowinfixwidth'
end

function M.unfix_height()
  vim.cmd 'set nowinfixheight'
end

function M.unfix_width_windo()
  M.save_win_pos()
  vim.cmd 'windo set nowinfixwidth'
  M.restore_win_pos()
end

function M.unfix_height_windo()
  M.save_win_pos()
  vim.cmd 'windo set nowinfixheight'
  M.restore_win_pos()
end

function MyTabLabel(n)
  local buflist = vim.fn.tabpagebuflist(n)
  local winnr = vim.fn.tabpagewinnr(n)
  local bufnr = buflist[winnr]
  local name = M.get_bnr_file(bufnr)
  local proj = M.get_proj(name)
  local proj_tail = M.get_tail(proj)
  return M.get_short(proj_tail, 28)
end

function MyTabLine()
  local s = '%='
  for i = 0, vim.fn.tabpagenr '$' - 1 do
    if i + 1 == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end
    s = s .. '%' .. tostring(i + 1) .. 'T'
    s = s .. ' %{v:lua.MyTabLabel(' .. (i + 1) .. ')} '
  end
  s = s .. '%#TabLineFill#%T%='
  return s
end

vim.opt.tabline = '%!v:lua.MyTabLine()'

function M.list_inc_do(up_line, cur_line, text)
  local res = M.findall(text, up_line)
  if #res > 0 then
    local temp1 = M.findall(text, cur_line)
    if #temp1 == 0 then
      return text
    end
  end
  return nil
end

function M.list_check(lnr)
  local cur_line
  if not lnr then
    lnr = vim.fn.line '.'
    cur_line = vim.fn.getline(lnr)
  else
    cur_line = ''
  end
  if lnr > 1 then
    local temp1 = M.findall([[(\d+\.) ]], cur_line)
    cur_line = vim.fn.trim(cur_line)
    if #temp1 >= 1 and #temp1[1] >= #cur_line then
      return 1
    end
    if cur_line == '> > > > > > > -' then return 1 end
    if cur_line == '> > > > > > -' then return 1 end
    if cur_line == '> > > > > -' then return 1 end
    if cur_line == '> > > > -' then return 1 end
    if cur_line == '> > > -' then return 1 end
    if cur_line == '> > -' then return 1 end
    if cur_line == '> -' then return 1 end
    if cur_line == '-' then return 1 end
  end
  return nil
end

function M.list_inc(lnr, tab)
  local cur_line
  local no_dup = nil
  if not lnr then
    lnr = vim.fn.line '.'
    cur_line = vim.fn.getline(lnr)
    no_dup = 1
  else
    cur_line = ''
  end
  local temp
  local up_line = vim.fn.getline(lnr - 1)
  if lnr > 1 then
    local num = M.findall([[(\d+)\. ]], up_line)
    if #num > 0 then
      local temp1 = M.findall([[(\d+)\. ]], cur_line)
      if #temp1 == 0 then
        return M.format('%d. ', 1 + tonumber(num[1]))
      end
      if no_dup then
        return ''
      end
    end
    temp = M.list_inc_do(up_line, cur_line, '> > > > > > > - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '> > > > > > - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '> > > > > - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '> > > > - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '> > > - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '> > - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '> - ')
    if temp then return temp end
    temp = M.list_inc_do(up_line, cur_line, '- ')
    if temp then return temp end
  end
  if not tab then
    tab = '\t'
  end
  return tab
end

function M.sub_ref(dir)
  local cur_line = vim.fn.trim(vim.fn.getline '.')
  local cur_lnr = vim.fn.line '.'
  if dir == 1 then
    vim.fn.setline(cur_lnr, '> ' .. cur_line)
    vim.cmd 'norm 2l'
    return
  end
  if string.sub(cur_line, 1, 2) == '> ' then
    vim.fn.setline(cur_lnr, string.sub(cur_line, 3, #cur_line))
    vim.cmd 'norm 2h'
    return
  end
  vim.fn.setline(cur_lnr, cur_line)
end

-- 问豆包
function M.find_extra_substring(str1, str2)
  -- 确定较长和较短的字符串
  local longer_str, shorter_str
  if #str1 > #str2 then
    longer_str = str1
    shorter_str = str2
  else
    longer_str = str2
    shorter_str = str1
  end
  -- 如果较短字符串为空，直接返回较长字符串
  if #shorter_str == 0 then
    return longer_str
  end
  -- 遍历较长字符串，尝试找到与较短字符串匹配的起始位置
  for i = 1, #longer_str - #shorter_str + 1 do
    -- 截取与较短字符串长度相同的子字符串
    local sub_str = string.sub(longer_str, i, i + #shorter_str - 1)
    if sub_str == shorter_str then
      -- 如果匹配成功，检查前面和后面是否有多余的字符
      local before = string.sub(longer_str, 1, i - 1)
      local after = string.sub(longer_str, i + #shorter_str)
      if #before > 0 then
        return before
      elseif #after > 0 then
        return after
      end
    end
  end
  -- 如果没有找到匹配，可能是插入到了中间某个位置
  -- 尝试通过逐步比较字符来找到差异
  local j = 1
  for i = 1, #longer_str do
    if j > #shorter_str or string.sub(longer_str, i, i) ~= string.sub(shorter_str, j, j) then
      local start_index = i
      while i <= #longer_str and (j > #shorter_str or string.sub(longer_str, i, i) ~= string.sub(shorter_str, j, j)) do
        i = i + 1
      end
      return string.sub(longer_str, start_index, i - 1)
    else
      j = j + 1
    end
  end
  return ''
end

function M.get_buf_content(buf)
  if not buf then
    buf = vim.fn.bufnr()
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return M.join(lines, '\n')
end

function M.gui_sel_do(cmd)
  vim.cmd(cmd)
end

function M.gui_sel()
  M.ui({
    'GuiWindowOpacity 1',
    'GuiWindowOpacity 0.9',
    'GuiWindowOpacity 0.8',
    'GuiWindowOpacity 0.5',
    [[Guifont! Hack\ NFM:h9]],
    [[Guifont! Hack\ NFM:h10]],
    [[Guifont! Hack\ NFM:h11]],
    [[Guifont! Hack\ NFM:h12]],
    [[Guifont! Hack\ NFM:h13]],
    [[Guifont! Hack\ NFM:h14]],
    [[Guifont! Hack\ NFM:h15]],
    [[Guifont! Hack\ NFM:h16]],
  }, 'gui', M.gui_sel_do)
end

function M.get_submodules(proj)
  local recent_projects = M.get_recent_projects()
  if not proj then
    proj = M.get_cwd()
  end
  proj = M.lower(M.rep(proj))
  if not recent_projects then
    return {}
  end
  local submodules = {}
  for _, _p in ipairs(recent_projects) do
    local p = M.lower(M.rep(_p))
    local dir = M.lower(M.rep(p))
    local dir_git = M.join_path(dir, '.git')
    if string.sub(p, 1, #proj) == proj and string.sub(p, #proj + 1, #proj + 1) == '\\' and M.is_file_exists(dir_git) then
      dir = M.lower(M.rep(M.get_parent(dir)))
      dir_git = M.lower(M.rep(M.join_path(dir, '.git')))
      while 1 do
        if dir == proj then
          M.put_uniq(submodules, p)
          break
        end
        if M.is_file_exists(dir_git) then
          break
        end
        dir = M.lower(M.rep(M.get_parent(dir)))
        dir_git = M.lower(M.rep(M.join_path(dir, '.git')))
      end
    end
  end
  return submodules
end

function M.get_tails(projs, root)
  if not root then
    root = M.get_cwd()
  end
  root = M.lower(M.rep(root))
  local tails = {}
  for _, proj in ipairs(projs) do
    M.put_uniq(tails, string.sub(proj, #root + 2, #proj))
  end
  return tails
end

function M.get_submodules_tails(proj, submodules)
  if not proj then
    proj = M.get_cwd()
  end
  proj = M.lower(M.rep(proj))
  local submodules_tails = {}
  for _, submodule in ipairs(submodules) do
    M.put_uniq(submodules_tails, string.sub(submodule, #proj + 2, #submodule))
  end
  return submodules_tails
end

function M.rename_submodule_do_do(submodule_new_name)
  -- M.run__silent(M.format('%s "%s" "%s" "%s" "%s"', M.rename_submodule_py, vim.g.submodules_root, vim.g.submodule_old_name, submodule_new_name, vim.g.submodule_remote_url))
  M.run_silent { M.rename_submodule_py, vim.g.submodules_root, vim.g.submodule_old_name, submodule_new_name, vim.g.submodule_remote_url, }
end

function M.rename_submodule_do(submodule_old_name, index)
  local submodule_old_path = vim.g.submodules[index]
  vim.g.submodule_old_name = submodule_old_name
  local roo_remote_url = M.just_get_git_remote_url(vim.g.submodules_root)
  vim.g.submodule_remote_url = M.just_get_git_remote_url(submodule_old_path)
  if roo_remote_url == vim.g.submodule_remote_url then
    M.notify(M.format('same remote url: %s in %s', vim.g.submodule_remote_url, vim.g.submodules_root))
    return
  end
  M.notify(M.format('%s/%s: %s', vim.g.submodules_root, vim.g.submodule_old_name, vim.g.submodule_remote_url))
  M.ui_input('rename to new submodule name', submodule_old_name, M.rename_submodule_do_do)
end

function M.rename_submodule(proj)
  if not proj then
    proj = M.get_cwd()
  end
  vim.g.submodules_root = M.lower(M.rep(proj))
  vim.g.submodules = M.get_submodules()
  local submodules_tails = M.get_tails(vim.g.submodules)
  M.ui(submodules_tails, 'rename_submodule', M.rename_submodule_do)
end

function M.get_files_deep_1(dir)
  if not dir then
    dir = M.get_cwd()
  end
  return ps.scan_dir(dir, { hidden = false, depth = 1, add_dirs = false, only_dirs = false, })
end

function M.get_extension(file)
  return vim.fn.fnamemodify(file, ':e')
end

function M.create_file(fname)
  M.cmd('e %s\\%s', vim.g.create_root_dir, fname)
end

function M.get_markdowns(dir)
  local files = M.get_files_deep_1(dir)
  local tails = M.get_tails(files, dir)
  local markdowns = {}
  for _, tail in ipairs(tails) do
    if M.lower(M.get_extension(tail)) == 'md' then
      M.put_uniq(markdowns, tail)
    end
  end
  table.sort(markdowns)
  return markdowns
end

function M.create_index_file()
  local today = vim.fn.strftime '%Y%m%d'
  local parent = M.get_parent()
  local markdowns = M.get_markdowns(parent)
  local title
  if #markdowns == 0 then
    title = M.format('001-1-%s-', today)
    vim.g.create_root_dir = M.rep(parent)
    M.ui_input(M.format('create new file under %s', parent), title, M.create_file)
  end
  local last_file = markdowns[#markdowns]
  local l = M.split(last_file, '-')
  if #l < 2 then
    return ''
  end
  local index_1 = l[1]
  local index_2 = l[2]
  local date = today
  if #l >= 3 then
    date = l[3]
  end
  title = '--'
  local cnt_1 = tonumber(index_1)
  if not cnt_1 then
    return ''
  end
  local cnt_2 = tonumber(index_2)
  if not cnt_2 then
    return ''
  end
  if cnt_2 > 1 then
    for _, tail in ipairs(markdowns) do
      local res = M.findall(M.format([[%s-\d+-(\d{8})-.*]], index_1), tail)
      if #res > 0 then
        date = res[1]
        break
      end
    end
  end
  local format = M.format('%%0%dd', #index_1)
  local cnt_str = M.format(format, cnt_1)
  local cnt_str_plus_1 = M.format(format, cnt_1 + 1)
  if today ~= date then
    title = M.format('%s-1-%s-', cnt_str_plus_1, today)
  else
    title = M.format('%s-%s-', cnt_str, cnt_2 + 1)
  end
  vim.g.create_root_dir = M.rep(parent)
  M.ui_input(M.format('create new file under %s', parent), title, M.create_file)
end

function M.sel_open_same_index_file_do(file)
  M.cmd('e %s', file)
end

function M.sel_open_same_index_file(file)
  if not file then
    file = M.get_cur_file()
  end
  file = M.get_tail(file)
  local l = M.split(file, '-')
  local index_1 = l[1]
  local parent = M.get_parent()
  local markdowns = M.get_markdowns(parent)
  local files = {}
  for _, tail in ipairs(markdowns) do
    local res = M.findall(M.format([[%s-\d+-.*]], index_1), tail)
    if #res > 0 then
      M.put_uniq(files, res[1])
    end
  end
  M.ui(files, 'open', M.sel_open_same_index_file_do)
  return files
end

function M.toggle_sides(val)
  if val then
    M.toggle_sides_en = val
  end
  if M.toggle_sides_en == 1 then
    vim.opt.tabline = '%!v:lua.MyTabLine()'
    vim.opt.showtabline = 1
    vim.opt.laststatus = 3
    vim.opt.cmdheight = 1
    M.toggle_sides_en = 0
    vim.g.statuslineen = 1
  else
    vim.opt.showtabline = 0
    vim.opt.laststatus = 0
    vim.opt.cmdheight = 0
    M.toggle_sides_en = 1
    vim.g.statuslineen = nil
    -- vim.opt.statusline = M.repeat_str('─', 20)
    vim.opt.statusline = M.repeat_str('═', 20)
  end
end

M.toggle_sides()

-- M.clone_if_not_exist 'org'
-- M.clone_if_not_exist 'big'
M.clone_if_not_exist 'w'
M.clone_if_not_exist 'l'
M.clone_if_not_exist 'p'

-- M.printf('[f.lua time] %.2f ms', vim.fn.reltimefloat(vim.fn.reltime(f_s_time)) * 1000)

return M

local class_func = {}
local ALL_NOTES_DATA = {}

local OS_FILE_SEP = package.config:sub(1, 1)
local PYTHON_PATH_SCRIPT = string.sub(debug.getinfo(1).source, 2, string.len('/lua/mini-notes/init.lua') * -1 ) .. 'scripts' .. OS_FILE_SEP
local DATA_DIR_PATH = string.sub(debug.getinfo(1).source, 2, string.len('/lua/mini-notes/init.lua') * -1 ) .. 'data' .. OS_FILE_SEP
local PYTHON_MAIN_CMD = 'python'

local TEMP_FILE_TITLE_INFO = 'saving_title_out_file.txt'
local TEMP_FILE_DESC_INFO = 'saving_desc_out_file.txt'
local PYTHON_FILE_ADD_BLANK_NOTE = 'add_new_blank_note_to_db.py'
local PYTHON_FILE_GET_ALL_NOTES = 'get_all_notes.py'
local PYTHON_FILE_UPDATE_NOTE = 'update_note_desc_to_db.py'
local DATA_DB_FILENAME = 'notes.db'

local function custom_save_output_file (output_file_path, save_buf)
    local file_handle = io.open(output_file_path, 'w')
    for _, value in ipairs(save_buf) do
	file_handle:write(value, '\n')
    end
    file_handle:close()
end


local function custom_split_string (string_val, sep)
    local result_list = {}
    for str in string.gmatch(string_val, "([^"..sep.."]+)") do
	table.insert(result_list, str)
    end
    return result_list
end


local function create_floating_windows (input_buffer, opt, should_enter_win)
    win_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(win_buf, 0, - 1, false, input_buffer)

    vim.cmd "setlocal nocursorcolumn"
    local win_info = {
	state = 'start',
	bufnr = win_buf,
	winnr = vim.api.nvim_open_win(win_buf, should_enter_win, opt)
    }
    vim.api.nvim_win_set_option(win_info.winnr, "winblend", 10)
    vim.api.nvim_win_set_option(win_info.winnr, "cursorline", true)

    return win_info
end


local function is_current_window_in_table_win_list (all_table_id)
    local current_window_id = vim.fn.win_getid()
    local isFocused = false

    for _, value in ipairs(all_table_id) do
	if value.winnr == current_window_id then
	    isFocused = true
	    break
	end
    end
    return isFocused
end


local function remove_autocmd_group (augroup_id)
    vim.api.nvim_clear_autocmds (
	{
	    event = "BufEnter",
	    group = augroup_id,
	}
    )
end


local function close_all_floating_window (all_table_id)
    for _, value in ipairs(all_table_id) do
	if value.state == 'start' then
	    vim.api.nvim_win_close(value.winnr, true)
	    value.state = 'end'
	end
    end
end


local function custom_trim(string_input)
    return (string_input:gsub("^%s*(.-)%s*$", "%1"))
end


local function read_all_dev_notes (status_bar_win, main_note_list_win)
    local job_read_all_notes = vim.fn.jobstart(
	' ' .. PYTHON_MAIN_CMD .. ' ./' .. PYTHON_FILE_GET_ALL_NOTES .. ' --db_path ' .. DATA_DIR_PATH .. DATA_DB_FILENAME,
	{
	    stdout_buffered = true,
	    cwd = PYTHON_PATH_SCRIPT,
	    on_stdout = function (chanid, data, name)
		local arr_data = {}

		for _, values in ipairs(data) do
		    --local str = string.gsub(values, "[^%S\n]+", "")
		    local str = string.gsub(values, "[\n]+", "")
		    table.insert(arr_data, str)
		end

		ALL_NOTES_DATA = vim.fn.json_decode(arr_data[1])

		local data_list = {}
		for _, values in ipairs(ALL_NOTES_DATA.data) do
		    table.insert(data_list, values.Id .. "| " .. values.Title)
		end

		vim.api.nvim_buf_set_lines(main_note_list_win.bufnr, 0, -1, false, data_list)

		local time_epoch = os.time()
		local time_format = os.date('%Y-%m-%d %H:%M:%S')
		local status_msg_str = '[Notes Read] - ' .. time_format

		vim.api.nvim_buf_set_lines(status_bar_win.bufnr, 0, -1, false, {status_msg_str})
	    end,
	}
    )
    vim.fn.jobwait({job_read_all_notes}, -1)
end


local function add_new_blank_note (status_bar_win, main_note_list_win)
    local job_add_blank_note = vim.fn.jobstart(
	' ' .. PYTHON_MAIN_CMD .. ' ./' .. PYTHON_FILE_ADD_BLANK_NOTE .. ' --db_path ' .. DATA_DIR_PATH .. DATA_DB_FILENAME,
	{
	    stdout_buffered = true,
	    cwd = PYTHON_PATH_SCRIPT,
	    on_stdout = function (chanid, data, name)
		local time_epoch = os.time()
		local time_format = os.date('%Y-%m-%d %H:%M:%S')
		local status_msg_str = '[New Blank Note Added] - ' .. time_format
		vim.api.nvim_buf_set_lines(status_bar_win.bufnr, 0, -1, false, {status_msg_str})
	    end,
	}
    )
    vim.fn.jobwait({job_add_blank_note}, -1)
end


local function dev_custom_save_desc_notes (desc_win_id, note_list_win_id, note_title_win_id ,user_curr_focused_win, status_bar_win)
    local desc_buf_line_str = vim.api.nvim_buf_get_lines(desc_win_id.bufnr, 0, -1, false)
    local title_buf_line_str = vim.api.nvim_buf_get_lines(note_title_win_id.bufnr, 0, -1, false)

    local output_title_file_path = DATA_DIR_PATH .. TEMP_FILE_TITLE_INFO
    custom_save_output_file(output_title_file_path, title_buf_line_str)

    local row, col = unpack(vim.api.nvim_win_get_cursor(note_list_win_id.winnr))
    local notes_buf_line_str = vim.api.nvim_buf_get_lines(note_list_win_id.bufnr, row - 1, row, false)
    local note_id = -1
    local custom_search_result = custom_split_string(notes_buf_line_str[1], '|')
    note_id = tonumber(search_result[1])

    local output_file_path = DATA_DIR_PATH .. TEMP_FILE_DESC_INFO
    custom_save_output_file(output_file_path, desc_buf_line_str)

    local cmd_script = PYTHON_MAIN_CMD .. ' ./' .. PYTHON_FILE_UPDATE_NOTE .. ' --input_desc_file ' .. output_file_path .. ' --note_id ' .. note_id .. ' --input_title_file ' .. output_title_file_path .. ' --db_path ' .. DATA_DIR_PATH .. DATA_DB_FILENAME
    local job_save_notes = vim.fn.jobstart(
	cmd_script,
	{
	    stdout_buffered = true,
	    cwd = PYTHON_PATH_SCRIPT,
	    on_stdout = function (chanid, data, name)
		read_all_dev_notes(status_bar_win,note_list_win_id)

		local time_epoch = os.time()
		local time_format = os.date('%Y-%m-%d %H:%M:%S')
		local status_msg_str = '[Note Updated] - ' .. time_format
		vim.api.nvim_buf_set_lines(status_bar_win.bufnr, 0, -1, false, {status_msg_str})
	    end,
	}
    )
    vim.fn.jobwait({job_save_notes}, -1)
end


function class_func.show(user_settings)
    -- Get the window id of the current window before opening the floating window
    local user_curr_focused_win = vim.fn.win_getid()

    --TODO: Adapt screen size
    --local screen_percentage = 0.70
    --local width = math.floor(vim.o.columns * screen_percentage)
    --local height = math.floor(vim.o.lines * screen_percentage)
    --local top = math.floor(((vim.o.lines - height) / 2) - 1)
    --local left = math.floor((vim.o.columns - width) / 2)

    local main_note_list_win = create_floating_windows(
	{},
	{
	    title = 'Note List',
	    relative = "editor",
	    focusable = true,
	    width = 80,
	    height = 32,
	    row = 5,
	    col = 10,
	    style = "minimal",
	    border = 'single',
	},
	true
    )

    local note_title_info_win = create_floating_windows(
	{},
	{
	    title = 'Note Title',
	    relative = "editor",
	    focusable = true,
	    width = 100,
	    height = 1,
	    row = 5,
	    col = 92,
	    style = "minimal",
	    border = 'single',
	},
	false
    )

    local note_desc_win = create_floating_windows(
	{},
	{
	    title = 'Note Description',
	    relative = "editor",
	    focusable = true,
	    width = 100,
	    height = 32,
	    row = 8,
	    col = 92,
	    border = 'single',
	},
	false
    )

    local search_filter_win = create_floating_windows(
	{},
	{
	    title = 'Note Filter',
	    relative = "editor",
	    focusable = true,
	    width = 80,
	    height = 1,
	    row = 39,
	    col = 10,
	    style = "minimal",
	    border = 'single',
	},
	false
    )


    local status_bar_win = create_floating_windows(
	{},
	{
	    title = 'Status Bar',
	    relative = "editor",
	    focusable = false,
	    width = 182,
	    height = 1,
	    row = 42,
	    col = 10,
	    style = "minimal",
	    border = 'single',
	},
	false
    )

    read_all_dev_notes(status_bar_win,main_note_list_win)

    vim.api.nvim_create_autocmd("CursorMoved",
    {
	callback = function()
	    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	    local current_buf_line_str = vim.api.nvim_buf_get_lines(main_note_list_win.bufnr, row-1, row, false)

	    local note_id = -1
	    local note_title = {}
	    search_result = custom_split_string(current_buf_line_str[1], '|')
	    note_id = tonumber(search_result[1])
	    note_title = {custom_trim(search_result[2])}
	    local note_snippet = {}
	    for _, values in ipairs(ALL_NOTES_DATA.data) do
		if values.Id == note_id then
		    note_snippet = custom_split_string(values.Description, '\n')
		    break
		end
	    end

	    vim.api.nvim_buf_set_lines(note_desc_win.bufnr, 0, -1, false, note_snippet )
	    vim.api.nvim_buf_set_lines(note_title_info_win.bufnr, 0, -1, false, note_title )
	end,
	buffer = main_note_list_win.bufnr
    })

    local all_floating_window_id = {}
    table.insert(all_floating_window_id, main_note_list_win)
    table.insert(all_floating_window_id, note_desc_win)
    table.insert(all_floating_window_id, search_filter_win)
    table.insert(all_floating_window_id, note_title_info_win)
    table.insert(all_floating_window_id, status_bar_win)

    vim.keymap.set('n', user_settings.focus_main_list,
	function ()
	    vim.api.nvim_set_current_win(main_note_list_win.winnr);
	end
    )
    vim.keymap.set('n', user_settings.focus_title,
	function ()
	    vim.api.nvim_set_current_win(note_title_info_win.winnr);
	end
    )
    vim.keymap.set('n', user_settings.focus_desc,
	function ()
	    vim.api.nvim_set_current_win(note_desc_win.winnr);
	end
    )
    vim.keymap.set('n', user_settings.save_note,
	function ()
	    dev_custom_save_desc_notes(note_desc_win, main_note_list_win, note_title_info_win, user_curr_focused_win, status_bar_win)
	    vim.api.nvim_set_current_win(note_desc_win.winnr);
	end
    )
    vim.keymap.set('n', user_settings.refresh_data,
	function ()
	    read_all_dev_notes(status_bar_win,main_note_list_win)
	end
    )

    vim.keymap.set('n', user_settings.add_blank_note,
	function ()
	    add_new_blank_note(status_bar_win, note_title_info_win)
	    vim.api.nvim_set_current_win(main_note_list_win.winnr);
	    read_all_dev_notes(status_bar_win,main_note_list_win)
	end
    )

    local buf_cmd_close_window = '<Cmd>lua vim.api.nvim_set_current_win(' .. user_curr_focused_win .. '); <CR>'
    for _, value in ipairs(all_floating_window_id) do
	vim.api.nvim_buf_set_keymap(value.bufnr, 'n', '<Esc>', buf_cmd_close_window, {noremap = true, silent = true})
    end

    local float_window_augroup = vim.api.nvim_create_augroup("custom_floating_window", {clear = true})
    local autocmd_id_enter_buf = vim.api.nvim_create_autocmd(
	"BufEnter",
	{
	    group = float_window_augroup,
	    callback = function ()
		if is_current_window_in_table_win_list(all_floating_window_id) == false then
		    vim.api.nvim_set_current_win(user_curr_focused_win)
		    remove_autocmd_group(float_window_augroup)
		    close_all_floating_window(all_floating_window_id)
		end
	    end
	}
    )
end

return class_func

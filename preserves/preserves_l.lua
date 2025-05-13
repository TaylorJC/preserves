local M = {}

local lume = require "lume"

-- Where to store our saves
local save_directory
-- Table to save our set data
local save_data = {}
-- Table to store our save file paths; load on init
local save_files = {}

-- Whether we will autosave on value change
local autosave = false
-- Maximum number of autosaves that will be written
local max_autosaves = 5
-- Whether we will enforce type safety
local typesafe = true

-- Stores a save file path to our internal save_files table, then saves that table
local function save_to_path(save_path)
	for k, v in ipairs(save_files) do
		if v == save_path then
			table.remove(save_files, k)
		end
	end

	save_files[#save_files+1] = save_path

	io.output(save_directory .. 'save_files'.. '.lua')
	io.write(lume.serialize(save_files))
	io.flush()
	io.close()
end

-- Returns the number of autosaves that currently exist
local function get_autosave_count()
	if not save_files then
		return 0
	end

	local autosave_count = 0

	-- Get the number of autosaves already made
	for k, v in ipairs(save_files) do
		if v:find('autosave') then
			autosave_count = autosave_count + 1
		end
	end

	return autosave_count
end

-- Recursively search the passed table for any function keys or values
local function fn_in_table(table)
	local k_type
	local v_type
	for k, v in pairs(table) do
		k_type = type(k)
		v_type = type(v)
		
		if k_type == 'function' or v_type == 'function' then
			return true
		end

		if k_type == 'table' then
			if fn_in_table(k) then
				return true
			end
		end

		if v_type == 'table' then
			if fn_in_table(v) then
				return true
			end
		end
	end
end

-- Loads the last save if it exists, else returns false
local function continue()
	if not save_files then
		return false
	end

	-- Get the last save file
	local last_save = save_files[#save_files]

	-- Extract the save name
	local save_name = last_save:sub(last_save:len() - last_save:reverse():find('[/\\]') + 2)

	return M.load(save_name)
end

local function check_type_safety(store_value, value)
	local set_type = type(store_value)
	local val_type = type(value)

	-- Either type is nil = ok
	if set_type == 'nil' or val_type == 'nil' then
		return
	end

	-- Catch differing types
	if set_type ~= val_type then
		error('Type Error: Tried to assign a value of type '..val_type..' with enforced type '..set_type)
	end

	-- Types are the same and not tables, exit
	if set_type ~= 'table' then
		return
	end

	-- Types are the same and tables, check each key value
	-- Okay if the new value does not have the same keys as the existing value
	for k, _ in pairs(store_value) do
		if value[k] then 
			check_type_safety(store_value[k], value[k])
		end
	end
end

local function read_file(path)
    local file = io.open(path, "rb") -- r read mode and b binary mode
	
    if not file then 
		return nil 
	end

    local content = file:read "*all"
    file:close()
    return lume.deserialize(content)
end

-- Initialize the data store with a directory to store the save files
function M.init(save_dir)
	M.configure_save_directory(save_dir)

	save_files = read_file(save_directory .. 'save_files.lua')
end

-- Set whether we should autosave and how many we should keep; defaults to false and 5
function M.configure_autosave(should_autosave, max_num_autosaves)
	local num_autosaves = max_num_autosaves or 5
	local sh_autosave = should_autosave or false

	if type(sh_autosave) ~= 'boolean' then
		error('Autosave value must be a boolean')
	end

	if type(num_autosaves) ~= 'number' then
		error('Maximum number of autosaves should be a number')
	end

	autosave = sh_autosave
	max_autosaves = num_autosaves
end

-- Set the save directory path
function M.configure_save_directory(dir_path)
	if type(dir_path) ~= 'string' then
		error('Directory must be a string')
	end

	if string.len(dir_path) == 0 then
		error('Directory path cannot be empty')
	end

	if string.sub(string.reverse(dir_path), 1, 1) ~= '/' then
		dir_path = dir_path .. '/'
	end

	save_directory = dir_path
end

-- Set type safety checks; defaults to true if given no parameters
function M.configure_type_safety(enforce_typesafety)
	local enf_typesafe = enforce_typesafety or true

	if type(enf_typesafe) ~= 'boolean' then
		error('Enforce type safety must be a boolean')
	end

	typesafe = enf_typesafe
end

-- Register a key in the data store
function M.register(key)
	if type(key) ~= 'string' then
		error('Key must be a string')
	end	

	if M[key] then
		error('Key is already registered')
	end

	M[key] = function(val) if val then M.set(key, val) else return M.get(key) end end
end

-- Add a key value pair to our save data table
function M.set(key, value)
	if type(key) ~= 'string' then
		error('Key must be a string')
	end

	local val_type = type(value)

	-- Check for functions in the value
	if val_type == 'function' then
		error('Value cannot be a function')
	elseif val_type == 'table' then
		if fn_in_table(value) then
			error('Value cannot contain a function')
		end 
	end

	-- Register our key if not already registered
	if not M[key] then
		M.register(key)
	end

	-- Enforce type safety if requested
	if typesafe then
		check_type_safety(save_data[key], value) 
	end
	
	-- Set our key value
	save_data[key] = value

	-- If autosave is on, autosave
	if autosave then
		local save_name = 'autosave_' .. tostring(get_autosave_count() % max_autosaves)
		M.save(save_name)
	end
end

-- Return the value of a given key; nil if it does not exist
function M.get(key)
	if type(key) ~= 'string' then
		error('Key must be a string')
		return nil
	end

	local val = save_data[key]
	
	if val then
		return val
	end

	return nil
end

-- Removes a key from the save data set
function M.clear(key)
	if type(key) ~= 'string' then
		error('Key must be a string')
		return nil
	end

	if save_data[key] then
		save_data[key] = nil
		M[key] = nil
		M['set_'..key] = nil
		return true
	end

	return false
end

-- Returns a table of all save file paths
function M.get_saves()
	return save_files
end

-- Returns a table of all save names
function M.get_save_names()
	local save_names = {}

	-- Extract the save names from the save file paths
	for _, v in ipairs(save_files) do
		save_names[#save_names+1] = v:sub(v:len() - v:reverse():find('[/\\]') + 2)
	end

	return save_names
end

-- Returns all save data
function M.get_data()
	return save_data
end

-- Saves the save data to the given file; defaults to numbered saves of the form 'save_#'
function M.save(save_name)
	local save_file_name = save_name or ('save_' .. tostring(#save_files + 1))
	
	if type(save_file_name) ~= 'string' then
		error('Name must be a string')
		return
	end	

	if save_file_name:find('/\\') then
		error('Name cannot contain path separators "/ \\"')
		return
	end	

	local save_path = save_directory .. save_file_name .. '.lua'

	io.output(save_path)

	io.write(lume.serialize(save_data))

	io.flush()

	io.close()

	save_to_path(save_path)
	
	return true
end

-- Load the given save file; defaults to loading the last save if no name is given
function M.load(save_name)
	if not save_name then
		return continue()
	end

	-- Build the file path out of our given save directory and the save name passed in
	local save_path = save_directory .. save_name

	-- Read our save data
	local loaded_data = read_file(save_path)

	-- If there was actually save data, set it and return true
	if loaded_data then
		save_data = loaded_data
		return true
	else
		return false
	end
end

return M
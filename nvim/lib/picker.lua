local lib = package.user.lib
local tconfig = package.user.config.plugins.telescope.defaults
-- local dict = lib.dict

---@class picker : instance, picker.class
---@field telescope table
---@field opts table
---@field actions table
---@field title string
---@field state table

---@class picker.class : class
---@field new fun(title: str): picker
local picker = class("picker")
lib.picker = picker

function picker:initialize(title)
	assert(title, "No title for picker provided")

	self.telescope = {
		finders = require("telescope.finders"),
		config = require("telescope.config").values,
		sorters = require("telescope.sorters"),
		pickers = require("telescope.pickers"),
		actions = require("telescope.actions"),
		actions_state = require("telescope.actions.state"),
	}

	self.opts = copy(tconfig)
	self.actions = {}
	self.title = title
	self.state = self.telescope.actions_state
end

function picker:close(bufnr)
	self.telescope.actions.close(bufnr)
end

picker.hide = picker.close

function picker:call(what, method, ...)
	return self.telescope[what][method](...)
end

function picker:entry(bufnr)
	local x = self.state.get_selected_entry()
	self:close(bufnr)
	return x
end

picker.get_selected_entry = picker.entry

function picker:entries(bufnr)
	local x = self.state.get_current_picker(bufnr)
	if not x then
		return
	end

	local gotten = x:get_multi_selection()
	if #gotten == 0 then
		gotten = { self:entry(bufnr) }
	else
		self:close(bufnr)
	end

	return gotten
end

picker.get_selected_entries = picker.entries

function picker:table(xs, entry_maker)
	return self.telescope.finders.new_table({
		results = xs,
		entry_maker = entry_maker or function(entry)
			return {
				display = entry,
				value = entry,
				ordinal = entry,
			}
		end,
	})
end

function picker:make(xs, on_enter, opts)
	opts = copy(opts or {})
	local choices = self:table(xs, opts.entry_maker)
	local actions = self.telescope.actions
	local mappings = opts.mappings or opts.keymaps or {}
	local sorter = opts.sorter

	opts.entry_maker = nil
	opts.keymaps = nil
	opts.mappings = nil
	opts.sorted = nil
	local args = {}

	if #mappings > 0 then
		for i = 1, #mappings do
			local cb = self.actions[mappings[i][3]]
			is.Callable(cb, { assert = true, prefix = paste0("mappings[", i, "][3]") })
		end
	end

	opts.attach_mappings = function(prompt_bufnr, map)
		actions.select_default:replace(function()
			local selection = self:entries(prompt_bufnr)
			on_enter(selection)
		end)

		for i = 1, #mappings do
			local mode, ks, cb, o = unpack(mappings[i])
			o = o or {}
			o = is.string(o) and { desc = o } or o
			cb = self.actions[cb]
			map(mode, ks, cb, o)
		end

		return true
	end

	args.sorter = sorter or self.telescope.sorters.get_fzy_sorter()
	args.finder = choices
	args.prompt_title = self.title

	return self.telescope.pickers.new(opts, args)
end

function picker:make_and_find(xs, on_enter, opts)
	local p = self:make(xs, on_enter, opts)
	if p then
		p:find()
		return true
	else
		return false
	end
end

function lib.picker(title, xs, on_enter, opts)
	local p = picker:new(title)
	return p:make(xs, on_enter, opts)
end

function lib.select(title, xs, on_enter, opts)
	lib.picker:new(title):make_and_find(xs, on_enter, opts)
end

lib.telescope = picker
lib.picker = picker

return lib

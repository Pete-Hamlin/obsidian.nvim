local snacks_pick = require "snacks"

local Path = require "obsidian.path"
local abc = require "obsidian.abc"
local Picker = require "obsidian.pickers.picker"

---@param entry string
---@return string
local function clean_path(entry)
  local path_end = assert(string.find(entry, ":", 1, true))
  return string.sub(entry, 1, path_end - 1)
end

---@class obsidian.pickers.MiniPicker : obsidian.Picker
local SnacksPicker = abc.new_class({
  ---@diagnostic disable-next-line: unused-local
  __tostring = function(self)
    return "SnacksPicker()"
  end,
}, Picker)

---@param opts obsidian.PickerFindOpts|? Options.
SnacksPicker.find_files = function(self, opts)
  opts = opts or {}

  ---@type obsidian.Path
  local dir = opts.dir and Path:new(opts.dir) or self.client.dir
  snacks_pick.picker.file {
    title = opts.prompt_title,
    cwd = tostring(dir),
    confirm = function(picker, item)
      picker.close()
      vim.schedule(function()
        if item and opts.callback then
          opts.callback(item)
        end
      end)
    end,
  }
end

---@param opts obsidian.PickerGrepOpts|? Options.
SnacksPicker.grep = function(self, opts)
  opts = opts and opts or {}

  ---@type obsidian.Path
  local dir = opts.dir and Path:new(opts.dir) or self.client.dir

  local pick_opts = {
    name = opts.prompt_title,
    dirs = { tostring(dir) },
    search = opts.query,
    confirm = function(picker, item)
      picker.close()
      vim.schedule(function()
        if item and opts.callback then
          opts.callback(item)
        end
      end)
    end,
  }

  if opts.query and string.len(opts.query) > 0 then
    snacks_pick.picker.grep(pick_opts)
  end
end

---@param values string[]|obsidian.PickerEntry[]
---@param opts obsidian.PickerPickOpts|? Options.
---@diagnostic disable-next-line: unused-local
SnacksPicker.pick = function(self, values, opts)
  self.calling_bufnr = vim.api.nvim_get_current_buf()

  opts = opts and opts or {}

  local entries = {}
  for _, value in ipairs(values) do
    if type(value) == "string" then
      entries[#entries + 1] = value
    elseif value.valid ~= false then
      entries[#entries + 1] = {
        value = value.value,
        text = self:_make_display(value),
        path = value.filename,
        lnum = value.lnum,
        col = value.col,
      }
    end
  end

  local entry = snacks_pick.start {
    source = {
      name = opts.prompt_title,
      items = entries,
      choose = function() end,
    },
  }

  if entry and opts.callback then
    if type(entry) == "string" then
      opts.callback(entry)
    else
      opts.callback(entry.value)
    end
  end
end

return SnacksPicker

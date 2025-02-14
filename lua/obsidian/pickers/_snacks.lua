local snacks = require "snacks"

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
  local item = snacks.picker.files {
    title = opts.prompt_title,
    cwd = tostring(dir),
  }

  if item and opts.callback then
    local path = clean_path(item)
    opts.callback(tostring(dir / path))
  end
end

---@param opts obsidian.PickerGrepOpts|? Options.
SnacksPicker.grep = function(self, opts)
  opts = opts and opts or {}

  ---@type obsidian.Path
  local dir = opts.dir and Path:new(opts.dir) or self.client.dir

  local pick_opts = {
    name = opts.prompt_title,
    cwd = tostring(dir),
    dirs = { tostring(dir) },
    search = opts.query,
  }

  local result = snacks.picker.grep(pick_opts)
  if result and opts.callback then
    local path = clean_path(result)
    opts.callback(tostring(dir / path))
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
      table.insert(entries, {
        text = value,
        value = value,
      })
    elseif value.valid ~= false then
      local name = self:_make_display(value)
      table.insert(entries, {
        value = value.value,
        text = name,
        filename = value.filename,
        pos = { lnum = value.lnum, col = value.col },
      })
    end
  end

  snacks.picker.pick {
    title = opts.prompt_title,
    items = entries,
    layout = {
      preview = false,
    },
    format = function(item, _)
      local ret = {}
      local a = snacks.picker.util.align
      ret[#ret + 1] = { a(item.text, 20) }
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item and opts.callback then
        opts.callback(item.value)
      elseif item then
        if item["buf"] then
          vim.api.nvim_set_current_buf(item["buf"])
        end
        vim.api.nvim_win_set_cursor(0, { item["pos"][1], 0 })
      end
    end,
  }
end

return SnacksPicker

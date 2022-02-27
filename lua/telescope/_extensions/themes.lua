local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify("Themer: The themes picker needs nvim-telescope/telescope.nvim", vim.log.levels.ERROR)
end
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local function get_theme()
  local disable_themes = require("themer.config")("get").disable_telescope_themes
  -- local themes = {}
  -- local theme_dir = debug.getinfo(2, "S").source:sub(2)
  -- theme_dir = theme_dir:gsub("lua/telescope/_extensions/themes.lua", "")
  -- theme_dir = theme_dir .. "lua/themer/modules/themes"

  -- local fd = scan.scan_dir(theme_dir)

  -- if fd then
  --     for _, file in ipairs(fd) do
  --         if string.find(file, "lua") then
  --             local theme = file:gsub(theme_dir .. ".", ""):gsub(".lua", "")
  --             local disable_themes = require("themer.config")("get").disable_telescope_themes
  --             if not vim.tbl_contains(disable_themes, theme) then
  --                 table.insert(themes, theme)
  --             end
  --         end
  --     end
  -- end
  local themes = vim.fn.getcompletion("themer_", "color")
  local sorted_themes = {}

  for i = 1, #themes do
    local theme = themes[i]:gsub("themer_", "")
    if not vim.tbl_contains(disable_themes, theme) then
      table.insert(sorted_themes, theme)
    end
  end

  return sorted_themes
end

local function enter(prompt_bufnr)
  local selected = action_state.get_selected_entry()
  require("themer").setup({ colorscheme = selected[1] })
  local colorscheme = string.format([[require("themer").setup({colorscheme = %s})]], selected[1])
  vim.fn.jobstart(colorscheme)
  actions.close(prompt_bufnr)
end

local function next_color(prompt_bufnr)
  actions.move_selection_next(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  require("themer").setup({ colorscheme = selection[1] })
end

local function prev_color(prompt_bufnr)
  actions.move_selection_previous(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  require("themer").setup({ colorscheme = selection[1] })
end

-- selene: allow(unused_variable)
local function preview(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  require("themer.modules.core")(selection[1])
end

-- selene: allow(unused_variable)
local function themer(opts)
  local colors = get_theme()
  -- selene: allow(shadowing)
  local opts = require("telescope.themes").get_ivy({
    prompt_title = "Themer ColorScheme",
    results_title = "Change colorscheme",
    finder = finders.new_table({
      results = colors,
    }),
    previewer = false,
    attach_mappings = function(prompt_bufnr, map)
      for type, value in pairs(require("themer.config")("get").telescope_mappings) do
        for bind, method in pairs(value) do
          map(type, bind, function()
            if method == "enter" then
              enter(prompt_bufnr)
            elseif method == "next_color" then
              next_color(prompt_bufnr)
            elseif method == "prev_color" then
              prev_color(prompt_bufnr)
            elseif method == "preview" then
              preview(prompt_bufnr)
            end
          end)
        end
      end
      return true
    end,
    sorter = require("telescope.config").values.generic_sorter({}),
    layout_config = {
      width = 0.99,
      height = 0.5,
      preview_cutoff = 20,
      prompt_position = "top",
      horizontal = {
        preview_width = 0.65,
      },
      vertical = {
        preview_width = 0.65,
        width = 0.9,
        height = 0.95,
        preview_height = 0.5,
      },

      flex = {
        preview_width = 0.65,
        horizontal = {},
      },
    },
  })
  local colorschemes = pickers.new(opts)
  colorschemes:find()
end

return telescope.register_extension({
  exports = {
    themes = themer,
  },
})

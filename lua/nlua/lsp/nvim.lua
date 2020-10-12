local nlua_nvim_lsp = {}

--- Returns command to run the language server
-- @param lsp_path absolute path to the ls folder, defaults to the one used by `:LspInstall``
local sumneko_command = function(lsp_path)
  if lsp_path and string.sub(lsp_path, 1, 1) == '~' then
    lsp_path = vim.fn.expand(lsp_path)
  end
  lsp_path = lsp_path or (vim.fn.stdpath('cache') .. '/nvim_lsp/sumneko_lua/lua-language-server')

  -- TODO: Need to figure out where these paths are & how to detect max os... please, bug reports
  local bin_location = jit.os

  return {
    string.format(
      "%s/bin/%s/lua-language-server",
      lsp_path,
      jit.os
    ),
    "-E",
    string.format(
      "%s/main.lua",
      lsp_path
    ),
  }
end

local function get_lua_runtime()
    local result = {};
    for _, path in pairs(vim.api.nvim_list_runtime_paths()) do
        local lua_path = path .. "/lua/";
        if vim.fn.isdirectory(lua_path) then
            result[lua_path] = true
        end
    end

    -- This loads the `lua` files from nvim into the runtime.
    result[vim.fn.expand("$VIMRUNTIME/lua")] = true

    -- TODO: Figure out how to get these to work...
    --  Maybe we need to ship these instead of putting them in `src`?...
    result[vim.fn.expand("~/build/neovim/src/nvim/lua")] = true

    return result;
end

nlua_nvim_lsp.setup = function(nvim_lsp, config)
  nvim_lsp.sumneko_lua.setup({
    -- Lua LSP configuration
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",

          -- TODO: Figure out how to get plugins here.
          -- path = vim.split(package.path, ';'),
          -- path = {package.path},
        },

        completion = {
          -- You should use real snippets
          keywordSnippet = "Disable",
        },

        diagnostics = {
          enable = true,
          disable = config.disabled_diagnostics or {
            "trailing-space",
          },
          globals = vim.list_extend({
              -- Neovim
              "vim",
              -- Busted
              "describe", "it", "before_each", "after_each", "teardown", "pending"
            }, config.globals or {}
          ),
        },

        workspace = {
          library = vim.list_extend(get_lua_runtime(), config.library or {}),
          maxPreload = 1000,
          preloadFileSize = 1000,
        },
      }
    },

    -- Runtime configurations
    filetypes = {"lua"},

    cmd = config.cmd or sumneko_command(config.lsp_path),

    on_attach = config.on_attach,

    callbacks = config.callbacks
  })
end

nlua_nvim_lsp.hover = function()
  vim.lsp.buf.hover()
end

return nlua_nvim_lsp

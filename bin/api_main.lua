local server_info = require("admin_api.admin_server_info")
local full_version = server_info.full_name
local version = server_info.version
local args_util = require("bin.utils.args_util")
local logger = require("bin.utils.logger")
local ngx = ngx
local jit = jit

local cmds = {
    start = "Start the Ngr Admin Server",
    stop = "Stop current Ngr Admin Server",
    restart = "Restart Ngr Admin Server ",
    reload = "Reload the config of Ngr Admin API Server",
    version = "Show the version of Ngr Admin API Server",
    help = "Show help tips"
}

local help_cmds = ""
for k, v in pairs(cmds) do
    help_cmds = help_cmds .. "\n" .. k .. "\t" .. v
end

local help = string.format([[

NgrAdmin v%s, OpenResty/Nginx API Gateway.Support: Go Go Easy Team.

Usage: ngrAdmin COMMAND [OPTIONS]

The commands are:
 %s
]], version, help_cmds)


local function exec(args)
    local cmd = table.remove(args, 1)
    if cmd == "help" or cmd == "-h" or cmd == "--help" then
        return logger:print(help)
    end

    if cmd == "version" or cmd == "-v" or cmd == "--version" then
        return logger:print(full_version)
    end

    if not cmd then
        logger:error("Error Usages. Please check the following tips.\n")
        logger:print(help)
        return
    elseif not cmds[cmd] then
        logger:error("No such command: %s. Please check the following tips.\n", cmd)
        logger:print(help)
        return
    end

    local cmd = require("bin.cmds." .. cmd)
    local cmd_exec = cmd.execute
    local cmd_help = cmd.help

    args = args_util.parse_args(args)
    if args.h or args.help then
        return logger:print(cmd_help)
    end

    --  added default prefix & conf parameters
    if not args.prefix then
        args.prefix = "/usr/local/ngrAdmin"
    end
    if not args.conf then
        args.conf = args.prefix .. "/conf/ngr.json"
    end

    logger:info("ngr_admin: %s", version)
    logger:info("ngx_lua: %s", ngx.config.ngx_lua_version)
    logger:info("nginx: %s", ngx.config.nginx_version)
    if jit and jit.version then
        logger:info("Lua: %s", jit.version)
    end

    xpcall(function() cmd_exec(args) end, function(err)
        local trace = debug.traceback(err, 2)
        logger:error("Error:")
        io.stderr:write(trace.."\n")
        os.exit(1)
    end)
end

return exec

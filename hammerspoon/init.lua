hs.logger.defaultLogLevel = "debug"
function inspect(obj) print(hs.inspect.inspect(obj)) end

-- https://rakhesh.com/mac/using-hidutil-to-map-macos-keyboard-keys/
-- Right Shift => Capslock
-- Right Cmd => F20
keymap_cmd = [[
hidutil property --set '{
    "UserKeyMapping":[
        {"HIDKeyboardModifierMappingSrc":0x7000000E5,"HIDKeyboardModifierMappingDst":0x700000039},
        {"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x70000006F},
    ]}'
]]
os.execute(keymap_cmd)

-- Launcher
pos = {full = {x=0,y=0,w=6,h=6},
    left = {x=0,y=0,w=3,h=6},
    right = {x=3,y=0,w=3,h=6},}
launcher_msg = "-- Launcher --"
app_shortcuts = {}
app_table = {
    j = {a="WezTerm", g=pos.full, gb=pos.full},
    v = {a="Visual Studio Code", g=pos.right, gb=pos.full},
    c = {a="Google Chrome", g=pos.left, gb=pos.full},
    x = {a="Safari", g=pos.left, gb=pos.full},
    s = {a="Slack", g=pos.left, gb=pos.full},
    w = {a="WeChat",},
    m = {a="Activity Monitor",},
    f = {a="Finder",},
    e = {a="Eudb_en",},
    z = {a="zoom.us"},
    n = {a="Notion"},
    p = {a="Preview"},
    t = {a="Telegram"},
}
function handle_app_launch(app, pos)
    -- Move terminal app to the current space
    -- if app["a"] == app_table["j"]["a"] then
    --     local screenUUID = hs.screen.mainScreen():getUUID()
    --     local activeSpace = hs.spaces.activeSpaces()[screenUUID]
    --     local term = hs.application.get(app["a"])
    --     if term and term:mainWindow() then
    --         hs.spaces.moveWindowToSpace(term:mainWindow(), activeSpace)
    --         end
    -- end
    hs.application.launchOrFocus(app["a"])
    local win = hs.window.frontmostWindow() local screen = win:screen()
    if not win or not screen then return end
    if pos ~= nil then hs.grid.set(win, pos, screen); return; end
    if screen:name() == "Built-in Retina Display" then
        if app["gb"] then hs.grid.set(win, app["gb"], screen) end
    elseif app["g"] then
        if hs.grid.get(win, screen).h == 6 then return end
        hs.grid.set(win, app["g"], screen)
    end
end
for key in pairs(app_table) do
    launcher_msg = launcher_msg .. "\n" .. key .. ": " .. app_table[key]["a"]
    app_shortcuts[#app_shortcuts+1] = hs.hotkey.new({}, key, function()
        closeAlert()
        handle_app_launch(app_table[key])
    end);
end

function closeAlert()
    for _, shortcut in ipairs(app_shortcuts) do shortcut:disable() end
    hs.alert.closeAll(); collectgarbage("collect")
end
app_shortcuts[#app_shortcuts+1] = hs.hotkey.new({"ctrl"}, "c", closeAlert)
app_shortcuts[#app_shortcuts+1] = hs.hotkey.new({}, "ESCAPE", closeAlert)
function show_launcher()
    hs.alert.closeAll(); hs.alert.show(launcher_msg, {
        -- http://www.hammerspoon.org/docs/hs.alert.html#defaultStyle
        textFont="Menlo", textSize=22, radius=5
    }, hs.screen.mainScreen(), true)
    for _, shortcut in ipairs(app_shortcuts) do shortcut:enable() end
end
hs.hotkey.bind({"command"}, "d", show_launcher)
hs.hotkey.bind({}, "F20", show_launcher, closeAlert)


-- WinMgr https://github.com/miromannino/miro-windows-manager
-- hs.window.animationDuration = 0
hs.grid.setGrid("6x6"); hs.grid.setMargins("0x0")
pressed={up=false, down=false, left=false, right=false}
local function winAction(direction)
    pressed[direction] = true
    if not hs.window.focusedWindow() then return end
    local win = hs.window.frontmostWindow() local screen = win:screen()
    cell = hs.grid.get(win, screen)
    local fullWidth = function() cell.x=0;cell.w=6 end
    local fullHeight = function() cell.y=0;cell.h=6 end
    local funs = {up=function()
        if pressed.down then fullHeight(); return end
        if cell.h<2 or cell.h>4 then cell.h=3 elseif cell.y==0 then 
            cell.h=(cell.h+1); if cell.h==5 then cell.h=2 end end
        if cell.y ~= 0 then cell.y=0 end
    end, down=function()
        if pressed.up then fullHeight(); return end
        if cell.h<2 or cell.h>4 then cell.h=3 elseif cell.y+cell.h==6 
            then cell.h=(cell.h+1); if cell.h==5 then cell.h=2 end end
        if cell.y+cell.h ~= 6 then cell.y=6-cell.h end
    end, left=function()
        if pressed.right then fullWidth(); return end
        if cell.w<2 or cell.w>4 then cell.w=3 elseif cell.x==0 then
            cell.w=(cell.w+1); if cell.w==5 then cell.w=2 end end
        if cell.x ~= 0 then cell.x=0 end
    end, right=function()
        if pressed.left then fullWidth(); return end
        if cell.w<2 or cell.w>4 then cell.w=3 elseif cell.x+cell.w==6 then
            cell.w=(cell.w+1); if cell.w==5 then cell.w=2 end end
        if cell.w+cell.x ~= 6 then cell.x=6-cell.w end
    end, fullScreen=function()
        -- if cell.x+cell.y==0 and cell.w+cell.h==12 then
        --     cell.x,cell.y,cell.w,cell.h = 1,1,4,4
        -- else cell.x,cell.y,cell.w,cell.h = 0,0,6,6 end
        cell.x,cell.y,cell.w,cell.h = 0,0,6,6
    end}
    funs[direction]()
    hs.grid.set(win, cell, screen)
end
local hyper = {"option", "cmd"}
hs.hotkey.bind(hyper, "j", function() winAction("down") end, function() pressed.down=false end)
hs.hotkey.bind(hyper, "k", function() winAction("up") end, function() pressed.up=false end)
hs.hotkey.bind(hyper, "h", function() winAction("left") end, function() pressed.left=false end)
hs.hotkey.bind(hyper, "l", function() winAction("right") end, function() pressed.right=false end)
hs.hotkey.bind(hyper, "g", function() winAction("fullScreen") end)
hs.hotkey.bind(hyper, "n", function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
end)


-- Bitcoin menubar
menu = hs.menubar.new():setClickCallback(function()
    hs.urlevent.openURL("https://www.binance.com/zh-CN/trade/BTC_USDT?layout=pro")
end)
timer = hs.timer.new(5, function()
    hs.http.asyncGet("https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT", nil,
        function(status, body)
            if status < 0 then menu:setTitle("--") return end
            local json = hs.json.decode(body)
            menu:setTitle(string.format("%.2f", json.price))
        end)
end, true)
timer:start()


--- Reload configuration
hs.hotkey.bind({'shift', 'cmd', 'ctrl'}, 'r', function()
    timer:stop(); hs.reload()
end)
hs.alert.show("Config Loaded")
hs.logger.setGlobalLogLevel(1)


require("mouse")
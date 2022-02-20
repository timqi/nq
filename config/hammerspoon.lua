function inspect(obj) print(hs.inspect.inspect(obj)) end

-- Launcher
launcher_msg = "-- Launcher --"
app_shortcuts = {}
for key, app in pairs({
    j = "Terminal",
    v = "Visual Studio Code",
    c = "Safari",
    s = "Slack",
    w = "WeChat",
    z = "zoom.us",
    t = "Telegram",
    m = "Music",
    n = "Notion",
    a = "Activity Monitor",
    f = "Finder",
}) do app_shortcuts[#app_shortcuts+1] = hs.hotkey.new({}, key, function()
    if not hs.application.launchOrFocus(app) then hs.notify.show("App Lauch Failed", item.app) end
    closeAlert()
end); launcher_msg = launcher_msg .. "\n" .. key .. ": " .. app end
function closeAlert()
    for _, shortcut in ipairs(app_shortcuts) do shortcut:disable() end
    for _, shortcut in ipairs(pasteShortcuts) do shortcut:disable() end
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
hs.hotkey.bind({"ctrl"}, "tab", show_launcher)

-- Double click to show lancher
events = hs.eventtap.event.types
first_ts, first_down, second_down = 0, false, false
reset_double = function() first_ts, first_down, second_down = 0, false, false end
et = hs.eventtap.new({events.flagsChanged, events.keyDown}, function(ev)
    if hs.timer.secondsSinceEpoch() - first_ts > 0.6 then reset_double() end
    local no_flags, only_flag = true, ev:getFlags().shift
    for k, v in pairs(ev:getFlags()) do
        if v then no_flags = false end
        if k ~= "shift" and v then only_flag = false end
    end
    if ev:getType() == events.flagsChanged then
        if no_flags and first_down and second_down then
            show_launcher(); reset_double()
        elseif only_flag and not first_down then
            first_down = true first_ts = hs.timer.secondsSinceEpoch()
        elseif only_flag and first_down then second_down = true
        elseif not no_flags then reset_double() end
    else reset_double() end
end)
et:start()

-- global hotkey switch to or from application
-- app_watcher = hs.application.watcher.new(function(name, t, app)
--     if t == hs.application.watcher.activated and name ~= "kitty" 
--     then previous_app = app end end)
-- app_watcher:start()
-- hs.hotkey.bind({"ctrl"}, "`", function ()
--     local app = hs.window.focusedWindow()
--     if not app then hs.application.launchOrFocus("Kitty") end
--     local app = app:application():name()
--     if app ~= "kitty" then hs.application.launchOrFocus("Kitty")
--     elseif app == "kitty" and previous_app
--     then previous_app:activate() end
-- end)


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


-- Pasteboard manger
hs.pasteboard.watcher.interval(2)
function readPasteboardTable()
    local file = io.open(os.getenv("HOME").."/.pasteboard", "r")
    if file == nil then return {} end
    local content = file:read("*a"); file:close()
    if content == "" then return {} end
    return hs.json.decode(content)
end
pasteShortcuts, pb_watcher = {}, hs.pasteboard.watcher.new(function()
    local text = ""
    for idx, uti in ipairs(hs.pasteboard.contentTypes()) do
        if uti == "public.utf8-plain-text" then text = hs.pasteboard.readString() end
    end
    if text == "" then return end
    local arr = readPasteboardTable()
    for idx, el in ipairs(arr) do if el == text then table.remove(arr, idx) end end
    table.insert(arr, 1, text)
    while #arr >= 8 do table.remove(arr, #arr) end
    local file = io.open(os.getenv("HOME").."/.pasteboard", "w")
    file:write(hs.json.encode(arr))
    file:close()
end)
pb_watcher:start()
function pasteSelect(idx)
    hs.pasteboard.setContents(readPasteboardTable()[idx])
    hs.eventtap.keyStroke({"cmd"}, "v")
    closeAlert()
end
for idx=1,7 do key = string.char(96+idx)
    pasteShortcuts[#pasteShortcuts+1] = hs.hotkey.new({}, key, 
        function() pasteSelect(idx) end)
end
pasteShortcuts[#pasteShortcuts+1] = hs.hotkey.new({}, "ESCAPE", closeAlert)
pasteShortcuts[#pasteShortcuts+1] = hs.hotkey.new({"ctrl"}, "c", closeAlert)
hs.hotkey.bind({"shift", "cmd"}, "v", function()
    hs.alert.closeAll()
    local msg = "-- Pasteboard --"
    for idx, el in ipairs(readPasteboardTable()) do
        msg = msg.."\n"..string.char(96+idx)..": "..el:gsub("[\r\n]+", ""):sub(1, 50)
    end
    hs.alert.show(msg, {radius=5}, hs.screen.mainScreen(), true)
    for _, shortcut in ipairs(pasteShortcuts) do shortcut:enable() end
end)


--- Reload configuration
hs.hotkey.bind({'shift', 'cmd', 'ctrl'}, 'r', function()
    timer:stop(); pb_watcher:stop(); hs.reload()
end)
hs.alert.show("Config Loaded")
hs.logger.setGlobalLogLevel(1)

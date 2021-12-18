--- Reload configuration
hs.hotkey.bind({'shift', 'cmd', 'ctrl'}, 'r', function() hs.reload() end)
hs.alert.show("Config Loaded")

-- Launcher
alert_msg = "Launcher"
app_shortcuts = {}
for key, app in pairs({
    i = "Alacritty",
    v = "Visual Studio Code",
    c = "Google Chrome",
    s = "Slack",
    w = "WeChat",
    p = "Preview",
    o = "zoom.us",
    t = "Telegram",
    m = "QQMusic",
    n = "Notion",
}) do app_shortcuts[#app_shortcuts+1] = hs.hotkey.new({}, key, function()
    if not hs.application.launchOrFocus(app) then hs.notify.show("App Lauch Failed", item.app) end
    close_launcher()
end); alert_msg = alert_msg .. "\n" .. key .. ": " .. app
end
function close_launcher()
    for _, shortcut in ipairs(app_shortcuts) do shortcut:disable() end
    hs.alert.closeSpecific(alert_id)
end
table.insert(app_shortcuts, hs.hotkey.new({"ctrl"}, "c", close_launcher))
table.insert(app_shortcuts, hs.hotkey.new({"ctrl"}, "[", close_launcher))
table.insert(app_shortcuts, hs.hotkey.new({}, "ESCAPE", close_launcher))
table.insert(app_shortcuts, hs.hotkey.new({}, "z", close_launcher))
function show_launcher()
    hs.alert.closeAll()
    alert_id = hs.alert.show(alert_msg, {
        -- http://www.hammerspoon.org/docs/hs.alert.html#defaultStyle
        fillColor = {white = 0, alpha = 0.9},
        strokeColor = {white = 1, alpha = 0.3},
        textColor = {white = 1, alpha = 0.9},
        textFont = "Menlo", textSize = 18, radius = 5,
    }, hs.screen.mainScreen(), true)
    for i, shortcut in ipairs(app_shortcuts) do shortcut:enable() end
end
hs.hotkey.bind({"ctrl"}, "tab", show_launcher)


-- WinMgr https://github.com/miromannino/miro-windows-manager
--hs.window.animationDuration = 0
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
        if cell.x+cell.y==0 and cell.w+cell.h==12 then
            cell.x,cell.y,cell.w,cell.h = 1,1,4,4
        else cell.x,cell.y,cell.w,cell.h = 0,0,6,6 end
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
-- move to next screen
hs.hotkey.bind(hyper, "n", function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
end)


-- Bitcoin menubar
menu = hs.menubar.new():setMenu({
    {title="Binance", fn=function() hs.urlevent.openURL("https://www.binance.com/zh-CN/trade/BTC_USDT?layout=pro") end},
    {title="ExoCharts", fn=function() hs.urlevent.openURL("https://exocharts.com/") end},
    {title="Markets", fn=function() hs.urlevent.openURL("https://www.binance.com/zh-CN/markets") end},
})
timer = hs.timer.new(5, function()
    hs.http.asyncGet("https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT", nil,
        function(status, body)
            if status < 0 then menu:setTitle("--") return end
            local json = hs.json.decode(body)
            menu:setTitle(string.format("%.2f", json.price))
        end)
end, true)
timer:start()



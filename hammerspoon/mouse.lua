--- Gesture detect
logger = hs.logger.new("Mouse")
gestures = require("gestures")

function gesture_alert(msg)
    hs.alert.show(msg, {
        -- http://www.hammerspoon.org/docs/hs.alert.html#defaultStyle
        textFont="Monaco", textSize=32, radius=12, strokeColor={alpha=0.7}
    }, hs.mouse.getCurrentScreen(), 1)
end

patterns = {
    -- ["↱"] = {"Right Space", {"ctrl"}, "Right"},
    -- ["↰"] = {"Left Space", {"ctrl"}, "Left"},

    ["↑"] = {"CMD + ]", function() hs.spaces.openMissionControl() end},
    ["↓"] = {"CMD + Q", function() hs.eventtap.keyStroke({"cmd"}, "w") end},
    ["←"] = {"CMD + [", function() hs.eventtap.keyStroke({"cmd", "shift"}, "[") end},
    ["→"] = {"CMD + ]", function() hs.eventtap.keyStroke({"cmd", "shift"}, "]") end},
    ["o_clockwise"] = {"CMD + R", function() hs.eventtap.keyStroke({"cmd"}, "r") end},
    ["o_counter"] = {"CMD + SHIFT + T", function()
        hs.eventtap.keyStroke({"cmd", "shift"}, "T")
    end},
}

for k, _ in pairs(patterns) do
    gestures.add(k, gestures.createPoints(k))
end

t = hs.eventtap.event.types
canvas, realRightClick, points = nil, false, {}

function doCanvas(type)
    if type == "init" then
        local frame = hs.mouse.getCurrentScreen():fullFrame()
        canvas = hs.canvas.new{x=frame.x, y=frame.y, h=frame.h, w=frame.w}
        canvas:clickActivating(false)
        canvas:show()
    elseif type == "dismiss" then
        canvas:hide(); canvas:delete();
        ----- handle tracking
        for _, v in pairs(points) do v[1], v[2] = v.x, v.y end
        local name, score, cloestIndex = gestures.recognize(points)
        if name == nil or score < 0.8 then
            gesture_alert("No pattern found.")
        else
            logger.d("Found gesture: "..name .. " "..score)
            gesture_alert(patterns[name][1])
            patterns[name][2]()
        end
        canvas, points = nil, {}
    elseif type == "update" then
        local loc = hs.mouse.getRelativePosition()
        table.insert(points, {x=loc.x, y=loc.y})
        canvas:replaceElements({
            type="segments", closed=false, action="stroke",
            strokeCapStyle="round", coordinates=points,
            strokeWidth=7.0, strokeColor={blue=1.0, green=0.7},
        })
    end
end

-- Intercept mouse gesture
gestureListener = hs.eventtap.new(
{t["rightMouseDown"], t["rightMouseUp"], t["rightMouseDragged"]}, function(evt)
    local evtType = evt:getType();
    if evtType == t["rightMouseDown"] then
        if not realRightClick then return true, nil end
    elseif evtType == t["rightMouseUp"] then
        if #points <= 4 and not realRightClick then
            points = {}; realRightClick = true
            hs.eventtap.rightClick(hs.mouse.absolutePosition())
        elseif realRightClick then realRightClick = false
        else doCanvas("dismiss") end
        collectgarbage("collect")
    elseif evtType == t["rightMouseDragged"] then
        if canvas == nil then doCanvas("init") end
        doCanvas("update")
    end
end)
gestureListener:start()


-- Handle mouse event
-- mouseListener = hs.eventtap.new(
--     {t["otherMouseDown"], t["otherMouseUp"], t["otherMouseDragged"]},
--     function(evt)
--         if evt:getType() ~= t["otherMouseDown"] then return false, nil end
--         local num = evt:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
--         logger.d("evtType:", evtType, " btnNum:", num)
--         if num == 4 then hs.eventtap.keyStroke({"cmd"}, "]")
--         elseif num == 3 then hs.eventtap.keyStroke({"cmd"}, "[")
--         elseif num == 2 then hs.spaces.openMissionControl()
--         end
--         return true, nil
--     end
-- )
-- mouseListener:start()

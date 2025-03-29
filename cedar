-- Plinko Receiver (Continuous, Clean Button Detection)

local modem = peripheral.wrap("bottom")
if not modem then error("❌ No modem on bottom") end
rednet.open("bottom")

local front = peripheral.wrap("front")
local stock = peripheral.wrap("back")
local dropper = peripheral.wrap("top")

local VALID_TOKENS = {
    ["01cf97"] = {value = 500},
    ["dd703d"] = {value = 1000},
    ["e61758"] = {value = 5000},
    ["1fafe1"] = {value = 10000},
    ["6d281b"] = {value = 15000},
}

local PAYOUT_MULTIPLIERS = {
    [1] = 5,
    [2] = 2,
    [3] = 0,
    [4] = 0,
    [5] = 2,
    [6] = 5,
}

local function pullOneToken()
    local items = front.list()
    local item = items[1]
    if item and item.nbtHash then
        local prefix = string.sub(item.nbtHash, 1, 6)
        if VALID_TOKENS[prefix] then
            local moved = front.pushItems(peripheral.getName(stock), 1, 1)
            if moved == 1 then
                print("✅ Accepted token: " .. prefix)
                return item.name, prefix
            end
        end
    end
    return nil
end

local function dispenseTokens(name, prefix, count)
    local dispensed = 0
    for slot, item in pairs(stock.list()) do
        if item.name == name and item.nbtHash then
            local hash = string.sub(item.nbtHash, 1, 6)
            if hash == prefix then
                local toMove = math.min(count - dispensed, item.count)
                stock.pushItems(peripheral.getName(dropper), slot, toMove)

                for i = 1, toMove do
                    redstone.setOutput("top", true)
                    sleep(0.2)
                    redstone.setOutput("top", false)
                    sleep(0.1)
                end

                dispensed = dispensed + toMove
                if dispensed >= count then break end
            end
        end
    end
end

print("🎯 Receiver ready. Press button to play!")

local lastTop = redstone.getInput("top")

while true do
    os.pullEvent("redstone")
    local currentTop = redstone.getInput("top")

    if not lastTop and currentTop then
        -- Button was just pressed
        local name, prefix = pullOneToken()
        if name then
            rednet.broadcast("start_plinko")
            print("📡 Sent start. Waiting for result...")

            local result = nil
            repeat
                local l = redstone.getAnalogInput("left")
                local r = redstone.getAnalogInput("right")
                result = math.max(l, r)
                sleep(0.05)
            until result >= 1 and result <= 6

            local mult = PAYOUT_MULTIPLIERS[result] or 0
            print("🎲 Zone:", result, "→ " .. mult .. "x payout")

            if mult > 0 then
                dispenseTokens(name, prefix, mult)
            else
                print("❌ No payout")
            end

            -- Wait for signal clear
            while redstone.getAnalogInput("left") > 0 or redstone.getAnalogInput("right") > 0 do
                sleep(0.1)
            end
        else
            print("❌ Invalid or missing token")
        end
    end

    lastTop = currentTop
end

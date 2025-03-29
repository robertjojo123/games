-- Bank Computer: Accepts 1 token (validated by NBT prefix), stores item name, and dispenses 2 or 5 of matching items if player wins.

local modem = peripheral.wrap("bottom")
modem.open(1)

-- Acceptable token NBT hash prefixes (first 6 chars)
local VALID_PREFIXES = {
    ["01cf97"] = true,
    ["dd703d"] = true,
    ["e61758"] = true,
    ["1fafe1"] = true,
    ["6d281b"] = true,
}

-- Track the last accepted token's item name
local lastToken = {
    name = nil,
}

local function sendMessage(msg)
    modem.transmit(1, 1, msg)
end

local function receiveMessage()
    while true do
        local event, _, ch, _, msg = os.pullEvent("modem_message")
        if ch == 1 then return msg end
    end
end

-- Accept one token from back chest if its NBT prefix is valid, store its name
local function transferSingleToken()
    local input = peripheral.wrap("back")
    local storage = peripheral.wrap("left")
    if not input or not storage then return false end

    for slot, item in pairs(input.list()) do
        if item and item.nbtHash then
            local prefix = string.sub(item.nbtHash, 1, 6)
            if VALID_PREFIXES[prefix] then
                input.pushItems(peripheral.getName(storage), slot, 1)
                lastToken.name = item.name
                print("✔️ Accepted token:", item.name, "Prefix:", prefix)
                return true
            else
                print("❌ Invalid token prefix:", prefix)
            end
        end
    end

    return false
end

-- Dispense matching item (by name) from storage chest to top dropper, N times
local function dispenseMatchingTokens(count)
    if not lastToken.name then
        print("❌ No token info stored.")
        return
    end

    local storage = peripheral.wrap("left")
    local dropper = peripheral.wrap("top")
    if not storage or not dropper then
        print("❌ Chest or dropper not found.")
        return
    end

    local dispensed = 0
    local items = storage.list()

    for slot, item in pairs(items) do
        if dispensed >= count then break end

        if item.name == lastToken.name then
            local toMove = math.min(item.count, count - dispensed)
            storage.pushItems(peripheral.getName(dropper), slot, toMove)

            for i = 1, toMove do
                redstone.setOutput("top", true)
                sleep(0.4)
                redstone.setOutput("top", false)
                sleep(0.1)
            end

            dispensed = dispensed + toMove
        end
    end

    print("✅ Dispensed " .. dispensed .. "x of " .. lastToken.name)
end

-- Main loop
while true do
    local msg = receiveMessage()

    if msg == "request_item" then
        if transferSingleToken() then
            sendMessage("item_transferred")
        else
            sendMessage("no_item")
        end

    elseif type(msg) == "table" and msg.type == "payout" and type(msg.amount) == "number" then
        dispenseMatchingTokens(msg.amount)
    end
end

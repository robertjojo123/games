-- Slot Machine - Final with Accurate Controlled Winrates

local function setOutputStrength(side, strength)
    redstone.setAnalogOutput(side, strength)
end

-- Left: 75% chance for 3 or 4, 25% for 5
local function biasedLeftStrength()
    if math.random(100) <= 75 then
        return math.random(3, 4)
    else
        return 5
    end
end

-- Front: 85% chance to match left, 15% to be different
local function decideFront(left)
    if math.random(100) <= 85 then
        return left
    else
        repeat
            local alt = 2 + math.random(3)
            if alt ~= left then return alt end
        until false
    end
end

-- Right: true winrate-controlled logic based on matchability
local function decideRight(left, front)
    if left == front then
        if left == 5 then
            -- Matchable jackpot: 21.25% of all plays; want 5% wins → 23.5% chance
            if math.random(1000) <= 235 then
                return 5
            end
        else
            -- Matchable 2x: 63.75% of plays; want 35% wins → 54.9% chance
            if math.random(1000) <= 549 then
                return left
            end
        end
    end

    -- Else: no win → return different value
    repeat
        local pick = 2 + math.random(3)
        if pick ~= left or pick ~= front then return pick end
    until false
end

-- Reel animation: cycles in order (3 → 4 → 5) and ends on finalStrength
local function cycleReel(side, duration, finalStrength)
    local sequence = {3, 4, 5}
    local index = 1
    local start = os.clock()

    while os.clock() - start < duration do
        local strength = sequence[index]
        if strength ~= finalStrength then
            setOutputStrength(side, strength)
            sleep(0.6)
            setOutputStrength(side, 0)
            sleep(0.2)
        end
        index = (index % #sequence) + 1
    end

    -- Hold final result
    setOutputStrength(side, finalStrength)
end

-- MAIN LOOP
while true do
    -- Wait for top signal to start
    while not redstone.getInput("top") do
        sleep(0.1)
    end

    -- While signal is on, keep playing
    while redstone.getInput("top") do
        local playTime = 15

        -- Decide final results
        local left = biasedLeftStrength()
        local front = decideFront(left)
        local right = decideRight(left, front)

        -- Set reel durations
        local leftDur = playTime / 3
        local frontDur = (2 * playTime) / 3
        local rightDur = playTime

        -- Animate all reels in parallel
        parallel.waitForAll(
            function() cycleReel("left", leftDur, left) end,
            function() cycleReel("front", frontDur, front) end,
            function() cycleReel("right", rightDur, right) end
        )

        -- Output to terminal (optional)
        print(string.format("L:%d F:%d R:%d", left, front, right))
        if left == front and front == right then
            if right == 5 then
                print(">>> JACKPOT 5x WIN!")
            else
                print(">>> 2x WIN!")
            end
        else
            print("No win.")
        end

        sleep(playTime)

        if not redstone.getInput("top") then break end
    end
end

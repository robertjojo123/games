-- 🧠 Final Roulette Betting Terminal Script with Coin Selection + Bet Zones
-- Supports balance checking, chip placement, touch interaction, clear/spin
-- Auto-generated with hitboxes

local monitor = peripheral.wrap("top")
local radar = peripheral.wrap("right")
local modem = peripheral.wrap("bottom")
rednet.open("bottom")

local ACCOUNT_COMPUTER_ID = 8045
local MIN_DISTANCE, MAX_DISTANCE = 1, 3
local BET_AMOUNTS = {100, 500, 1000, 2500}
local monitorHitboxes = dofile("roulette_hitboxes.lua")

local activePlayer = nil
local playerBalance = 0
local selectedBet = nil
local message = ""
local placedBets = {} -- key = zone, value = total bet

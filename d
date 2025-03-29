-- Turtle Book Auto-Signer for HughJaynis1234

local TITLE = "$500 WC Credit"
local AUTHOR = "HughJaynis1234"
local CONTENT = {
    "Redeem this voucher for $500 World Credit.\n\nIssued by Slot Machine Bank."
}

for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == "minecraft:writable_book" then
        if turtle.setBook then
            turtle.setBook(slot, {
                title = TITLE,
                author = AUTHOR,
                pages = CONTENT
            })
            print("✅ Book signed in slot " .. slot)
            return
        else
            print("❌ This turtle doesn't support setBook()")
            return
        end
    end
end

print("📘 No Book and Quill found.")

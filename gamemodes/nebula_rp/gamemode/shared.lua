--[[
    QUARANTINE RP v1.0
    Built-in Nebula Framework (Helix + DarkRP architecture)
    Standalone gamemode - no external dependencies
]]

QR = QR or {}
QR.Version = "1.0"
QR.Config = {}
QR.Items = {}
QR.Factions = {}

print("[Quarantine RP] Loading v" .. QR.Version .. "...")

-----------------------------------------------------------
-- CONFIG
-----------------------------------------------------------
QR.Config.StartMoney = 500
QR.Config.MaxChars = 3
QR.Config.SalaryInterval = 300
QR.Config.SaveInterval = 300
QR.Config.WalkSpeed = 180
QR.Config.RunSpeed = 280
QR.Config.DeathPenalty = 5

-----------------------------------------------------------
-- NETWORK STRINGS (register all at once on server)
-----------------------------------------------------------
if SERVER then
    util.AddNetworkString("QR_CharMenu")
    util.AddNetworkString("QR_CharCreate")
    util.AddNetworkString("QR_CharSelect")
    util.AddNetworkString("QR_CharSync")
    util.AddNetworkString("QR_Notify")
    util.AddNetworkString("QR_InvSync")
    util.AddNetworkString("QR_InvAction")
end

-----------------------------------------------------------
-- NOTIFY SYSTEM
-----------------------------------------------------------
function QR.Notify(ply, msg, type)
    type = type or 0
    if SERVER then
        if not IsValid(ply) then return end
        net.Start("QR_Notify")
            net.WriteString(msg)
            net.WriteUInt(type, 3)
        net.Send(ply)
    else
        notification.AddLegacy(msg, type, 5)
        surface.PlaySound("buttons/button15.wav")
    end
end

function QR.NotifyAll(msg, type)
    for _, p in ipairs(player.GetAll()) do
        QR.Notify(p, msg, type)
    end
end

if CLIENT then
    net.Receive("QR_Notify", function()
        local msg = net.ReadString()
        local typ = net.ReadUInt(3)
        notification.AddLegacy(msg, typ, 5)
        surface.PlaySound("buttons/button15.wav")
    end)
end

-----------------------------------------------------------
-- UTILITY
-----------------------------------------------------------
function QR.FormatMoney(amount)
    return "$ " .. tostring(amount)
end

function QR.FindPlayer(name)
    if not name or name == "" then return nil end
    name = string.lower(name)
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Name()), name, 1, true) then
            return p
        end
    end
    return nil
end

-----------------------------------------------------------
-- ITEM SYSTEM (Helix-style registration)
-----------------------------------------------------------
function QR.RegisterItem(id, data)
    QR.Items[id] = {
        id = id,
        name = data.name or id,
        desc = data.desc or "",
        category = data.category or "Other",
        model = data.model or "models/props_junk/garbage_metalcan001a.mdl",
        stackable = data.stackable or false,
        maxStack = data.maxStack or 1,
        unique = data.unique or false,
        usable = data.usable or false,
        onUse = data.onUse,
    }
end

function QR.GetItem(id)
    return QR.Items[id]
end

-- Register all items
QR.RegisterItem("passport", {name = "Passport", desc = "Citizen ID card.", category = "Documents", unique = true})
QR.RegisterItem("police_badge", {name = "Police Badge", desc = "Law enforcement badge.", category = "Documents", unique = true})
QR.RegisterItem("military_id", {name = "Military ID", desc = "Military identification.", category = "Documents", unique = true})
QR.RegisterItem("ration", {name = "Ration Pack", desc = "Standard food ration.", category = "Food", stackable = true, maxStack = 10, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 10, ply:GetMaxHealth())) return true end})
QR.RegisterItem("canned", {name = "Canned Food", desc = "Canned food. Still edible.", category = "Food", stackable = true, maxStack = 8, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 20, ply:GetMaxHealth())) return true end})
QR.RegisterItem("vodka", {name = "Vodka", desc = "Homemade vodka.", category = "Food", stackable = true, maxStack = 6, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 5, ply:GetMaxHealth())) ply:ViewPunch(Angle(math.random(-10, 10), math.random(-10, 10), 0)) return true end})
QR.RegisterItem("bandage", {name = "Bandage", desc = "Heals 15 HP.", category = "Medical", stackable = true, maxStack = 5, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 15, ply:GetMaxHealth())) return true end})
QR.RegisterItem("medkit", {name = "Medkit", desc = "Full medical kit. Heals 40 HP.", category = "Medical", stackable = true, maxStack = 3, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 40, ply:GetMaxHealth())) return true end})
QR.RegisterItem("antidote", {name = "Antidote", desc = "Cures infection.", category = "Medical", unique = true, usable = true, onUse = function(ply) ply:SetNWFloat("QR_Infection", 0) ply:SetNWBool("QR_Infected", false) QR.Notify(ply, "Infection cured!") return true end})
QR.RegisterItem("gasmask", {name = "Gas Mask", desc = "Protects from infection zone.", category = "Equipment", unique = true, usable = true, onUse = function(ply) ply:SetNWBool("QR_GasMask", true) QR.Notify(ply, "Gas mask equipped.") return false end})
QR.RegisterItem("lockpick", {name = "Lockpick", desc = "Opens locked doors.", category = "Tools", unique = true, usable = true, onUse = function(ply) local tr = ply:GetEyeTrace() if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_door_rotating" and tr.HitPos:Distance(ply:GetPos()) < 100 then tr.Entity:Fire("Unlock") tr.Entity:Fire("Open") QR.Notify(ply, "Door unlocked!") return true end QR.Notify(ply, "No door nearby.", 1) return false end})
QR.RegisterItem("handcuffs", {name = "Handcuffs", desc = "For arrests.", category = "Tools", unique = true})
QR.RegisterItem("mask", {name = "Balaclava", desc = "Hides your identity.", category = "Equipment", unique = true, usable = true, onUse = function(ply) ply:SetNWBool("QR_Masked", true) QR.Notify(ply, "Balaclava on.") return false end})
QR.RegisterItem("crate", {name = "Contraband Crate", desc = "Unknown contents.", category = "Contraband", usable = true, onUse = function(ply) QR.GiveItem(ply, "medkit", 2) QR.Notify(ply, "Found 2x Medkit!") return true end})
QR.RegisterItem("spice", {name = "Anomalous Dust", desc = "Valuable but dangerous.", category = "Contraband", stackable = true, maxStack = 10, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 15, ply:GetMaxHealth() + 50)) return true end})
QR.RegisterItem("radio", {name = "Radio", desc = "Communication device.", category = "Equipment", unique = true})
QR.RegisterItem("phone", {name = "Phone", desc = "Old cell phone.", category = "Electronics", unique = true})
QR.RegisterItem("parts", {name = "Parts", desc = "Scrap metal and wires.", category = "Components", stackable = true, maxStack = 10})
QR.RegisterItem("anomaly_core", {name = "Anomaly Core", desc = "Pulsating artifact. +50 HP.", category = "Artifacts", unique = true, usable = true, onUse = function(ply) ply:SetHealth(math.min(ply:Health() + 50, ply:GetMaxHealth() + 50)) QR.Notify(ply, "Core activated! +50 HP") return true end})

print("[Quarantine RP] Items loaded: " .. table.Count(QR.Items))

-----------------------------------------------------------
-- FACTION SYSTEM (DarkRP-style jobs)
-----------------------------------------------------------
function QR.RegisterFaction(id, data)
    QR.Factions[id] = {
        id = id,
        name = data.name or id,
        desc = data.desc or "",
        color = data.color or Color(255, 255, 255),
        model = data.model or "models/player/group01/male_01.mdl",
        models = data.models or {},
        weapons = data.weapons or {},
        items = data.items or {},
        health = data.health or 100,
        armor = data.armor or 0,
        salary = data.salary or 50,
        whitelist = data.whitelist or false,
        classes = data.classes or {},
    }
end

QR.RegisterFaction("citizen", {
    name = "Citizen", desc = "Regular survivor.",
    color = Color(150, 150, 150),
    model = "models/player/group01/male_01.mdl",
    models = {"models/player/group01/male_01.mdl", "models/player/group01/male_02.mdl", "models/player/group01/male_03.mdl", "models/player/group01/female_01.mdl"},
    items = {"passport", "ration"}, salary = 50,
    classes = {{id = "worker", name = "Worker", salary = 80}, {id = "merchant", name = "Merchant", salary = 100}, {id = "medic", name = "Medic", salary = 120}},
})

QR.RegisterFaction("police", {
    name = "Police", desc = "Law enforcement.",
    color = Color(50, 100, 255),
    model = "models/player/combine_soldier.mdl",
    models = {"models/player/combine_soldier.mdl", "models/player/combine_soldier_prisonguard.mdl"},
    weapons = {"weapon_pistol", "weapon_stunstick"},
    items = {"police_badge", "handcuffs", "radio"},
    health = 100, armor = 40, salary = 200,
    classes = {{id = "recruit", name = "Recruit", salary = 150}, {id = "sergeant", name = "Sergeant", salary = 250}, {id = "chief", name = "Chief", salary = 700}},
})

QR.RegisterFaction("military", {
    name = "Military", desc = "Checkpoint guards.",
    color = Color(50, 180, 50),
    model = "models/player/swat.mdl",
    models = {"models/player/swat.mdl", "models/player/riot.mdl", "models/player/gasmask.mdl"},
    weapons = {"weapon_pistol", "weapon_smg1", "weapon_shotgun"},
    items = {"military_id", "medkit", "gasmask", "radio"},
    health = 120, armor = 60, salary = 300, whitelist = true,
    classes = {{id = "recruit", name = "Recruit", salary = 250}, {id = "commander", name = "Commander", salary = 800}},
})

QR.RegisterFaction("scientist", {
    name = "Scientists", desc = "Research anomalous activity.",
    color = Color(255, 255, 100),
    model = "models/player/group02/male_02.mdl",
    models = {"models/player/group02/male_02.mdl", "models/player/group02/female_02.mdl"},
    items = {"antidote", "medkit"},
    health = 80, salary = 400, whitelist = true,
    classes = {{id = "intern", name = "Intern", salary = 200}, {id = "doctor", name = "Doctor", salary = 600}},
})

QR.RegisterFaction("raider", {
    name = "Raiders", desc = "Zone bandits.",
    color = Color(200, 50, 50),
    model = "models/player/phoenix.mdl",
    models = {"models/player/phoenix.mdl", "models/player/arctic.mdl", "models/player/guerilla.mdl"},
    weapons = {"weapon_crowbar", "weapon_pistol"},
    items = {"mask", "lockpick", "bandage"},
    health = 110, armor = 20, salary = 0, whitelist = true,
})

QR.RegisterFaction("smuggler", {
    name = "Smugglers", desc = "Black market traders.",
    color = Color(255, 150, 0),
    model = "models/player/group02/male_04.mdl",
    models = {"models/player/group02/male_04.mdl"},
    weapons = {"weapon_pistol"},
    items = {"crate", "lockpick"},
    health = 100, armor = 10, salary = 0, whitelist = true,
})

QR.RegisterFaction("cult", {
    name = "Plague Cult", desc = "Worship the anomaly.",
    color = Color(150, 0, 200),
    model = "models/player/zombie_classic.mdl",
    models = {"models/player/zombie_classic.mdl", "models/player/zombie_fast.mdl"},
    weapons = {"weapon_crowbar"},
    health = 90, salary = 0, whitelist = true,
})

print("[Quarantine RP] Factions loaded: " .. table.Count(QR.Factions))

-----------------------------------------------------------
-- DATABASE (SQLite - Helix style)
-----------------------------------------------------------
if SERVER then
    function QR.DB_Init()
        sql.Query([[
            CREATE TABLE IF NOT EXISTS qr_chars (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                steamid TEXT NOT NULL,
                name TEXT NOT NULL,
                faction TEXT NOT NULL,
                model TEXT NOT NULL,
                money INTEGER DEFAULT 500,
                inventory TEXT DEFAULT '[]',
                deaths INTEGER DEFAULT 0,
                zombie INTEGER DEFAULT 0,
                zombie_lives INTEGER DEFAULT 0,
                hunger REAL DEFAULT 100,
                thirst REAL DEFAULT 100,
                infection REAL DEFAULT 0,
                wanted INTEGER DEFAULT 0,
                created_at INTEGER DEFAULT 0,
                last_played INTEGER DEFAULT 0
            )
        ]])
        print("[Quarantine RP] Database initialized.")
    end

    function QR.DB_GetChars(steamid)
        return sql.Query("SELECT * FROM qr_chars WHERE steamid = " .. sql.SQLStr(steamid)) or {}
    end

    function QR.DB_CreateChar(steamid, name, faction, model)
        local f = QR.Factions[faction]
        if not f then return nil end
        local now = os.time()
        sql.Query(string.format(
            "INSERT INTO qr_chars (steamid, name, faction, model, money, created_at, last_played) VALUES (%s, %s, %s, %s, %d, %d, %d)",
            sql.SQLStr(steamid), sql.SQLStr(name), sql.SQLStr(faction), sql.SQLStr(model), f.salary or 50, now, now
        ))
        return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
    end

    function QR.DB_GetChar(id)
        return sql.QueryRow("SELECT * FROM qr_chars WHERE id = " .. tonumber(id))
    end

    function QR.DB_SaveChar(id, ply)
        if not IsValid(ply) then return end
        local inv = util.TableToJSON(ply.QR_Inventory or {})
        sql.Query(string.format(
            "UPDATE qr_chars SET money = %d, inventory = %s, deaths = %d, zombie = %d, zombie_lives = %d, hunger = %f, thirst = %f, infection = %f, wanted = %d, last_played = %d WHERE id = %d",
            ply:GetNWInt("QR_Money", 0), sql.SQLStr(inv),
            ply:GetNWInt("QR_Deaths", 0), ply:GetNWBool("QR_IsZombie", false) and 1 or 0,
            ply:GetNWInt("QR_ZombieLives", 0), ply:GetNWFloat("QR_Hunger", 100),
            ply:GetNWFloat("QR_Thirst", 100), ply:GetNWFloat("QR_Infection", 0),
            ply:GetNWInt("QR_Wanted", 0), os.time(), tonumber(id)
        ))
    end

    function QR.DB_DeleteChar(id)
        sql.Query("DELETE FROM qr_chars WHERE id = " .. tonumber(id))
    end

    hook.Add("Initialize", "QR_DBInit", function()
        QR.DB_Init()
    end)
end

-----------------------------------------------------------
-- CHARACTER SYSTEM
-----------------------------------------------------------
if SERVER then
    function QR.LoadCharacter(ply, charID)
        local ch = QR.DB_GetChar(charID)
        if not ch or ch.steamid ~= ply:SteamID() then return end
        local f = QR.Factions[ch.faction]
        if not f then return end

        -- Set networked data
        ply:SetNWInt("QR_CharID", tonumber(charID))
        ply:SetNWString("QR_CharName", ch.name)
        ply:SetNWString("QR_Faction", ch.faction)
        ply:SetNWInt("QR_Money", tonumber(ch.money) or 0)
        ply:SetNWInt("QR_Deaths", tonumber(ch.deaths) or 0)
        ply:SetNWBool("QR_IsZombie", tonumber(ch.zombie) == 1)
        ply:SetNWInt("QR_ZombieLives", tonumber(ch.zombie_lives) or 0)
        ply:SetNWFloat("QR_Hunger", tonumber(ch.hunger) or 100)
        ply:SetNWFloat("QR_Thirst", tonumber(ch.thirst) or 100)
        ply:SetNWFloat("QR_Infection", tonumber(ch.infection) or 0)
        ply:SetNWInt("QR_Wanted", tonumber(ch.wanted) or 0)

        -- Load inventory
        ply.QR_Inventory = util.JSONToTable(ch.inventory or "[]") or {}

        -- Apply faction
        ply:SetModel(ch.model or f.model)
        ply:SetMaxHealth(f.health)
        ply:SetHealth(f.health)
        ply:SetArmor(f.armor)
        ply:SetWalkSpeed(QR.Config.WalkSpeed)
        ply:SetRunSpeed(QR.Config.RunSpeed)

        -- Give weapons
        ply:StripWeapons()
        for _, w in ipairs(f.weapons) do ply:Give(w) end
        ply:Give("gmod_tool")
        ply:Give("gmod_camera")
        ply:Give("weapon_physgun")

        -- Sync to client
        net.Start("QR_CharSync")
            net.WriteString(ch.name)
            net.WriteString(ch.faction)
            net.WriteUInt(tonumber(ch.money) or 0, 32)
        net.Send(ply)

        -- Sync inventory
        QR.SyncInventory(ply)

        print("[Quarantine RP] Loaded character: " .. ch.name .. " (" .. ch.faction .. ")")
    end

    function QR.OpenCharMenu(ply)
        local chars = QR.DB_GetChars(ply:SteamID())
        net.Start("QR_CharMenu")
            net.WriteUInt(#chars, 8)
            for _, ch in ipairs(chars) do
                net.WriteUInt(tonumber(ch.id), 16)
                net.WriteString(ch.name)
                net.WriteString(ch.faction)
                net.WriteString(ch.model or "")
            end
        net.Send(ply)
    end

    net.Receive("QR_CharCreate", function(len, ply)
        local name = net.ReadString()
        local faction = net.ReadString()
        local model = net.ReadString()

        if #name < 3 or #name > 32 then
            QR.Notify(ply, "Name must be 3-32 characters!", 1)
            return
        end

        local chars = QR.DB_GetChars(ply:SteamID())
        if #chars >= QR.Config.MaxChars then
            QR.Notify(ply, "Maximum " .. QR.Config.MaxChars .. " characters!", 1)
            return
        end

        if not QR.Factions[faction] then
            QR.Notify(ply, "Invalid faction!", 1)
            return
        end

        if model == "" then
            model = QR.Factions[faction].model
        end

        local charID = QR.DB_CreateChar(ply:SteamID(), name, faction, model)
        if charID then
            QR.LoadCharacter(ply, charID)
            QR.Notify(ply, "Character created: " .. name)
        end
    end)

    net.Receive("QR_CharSelect", function(len, ply)
        local charID = net.ReadUInt(16)
        QR.LoadCharacter(ply, charID)
    end)
end

-- Client character menu
if CLIENT then
    net.Receive("QR_CharSync", function()
        QR.MyName = net.ReadString()
        QR.MyFaction = net.ReadString()
        QR.MyMoney = net.ReadUInt(32)
    end)

    net.Receive("QR_CharMenu", function()
        local count = net.ReadUInt(8)
        local chars = {}
        for i = 1, count do
            table.insert(chars, {
                id = net.ReadUInt(16),
                name = net.ReadString(),
                faction = net.ReadString(),
                model = net.ReadString(),
            })
        end
        QR.ShowCharMenu(chars)
    end)

    function QR.ShowCharMenu(chars)
        if IsValid(QR._charMenu) then QR._charMenu:Remove() end

        local frame = vgui.Create("DFrame")
        frame:SetSize(600, 480)
        frame:Center()
        frame:SetTitle("")
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame:MakePopup()

        frame.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, Color(12, 12, 20, 255))
            surface.SetDrawColor(0, 180, 255, 80)
            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)
            draw.SimpleText("QUARANTINE RP", "DermaLarge", w / 2, 30, Color(0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Select Character", "DermaDefault", w / 2, 55, Color(150, 150, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        QR._charMenu = frame

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:SetPos(15, 75)
        scroll:SetSize(570, 320)

        for _, ch in ipairs(chars) do
            local btn = vgui.Create("DButton", scroll)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 5)
            btn:SetTall(55)
            btn:SetText("")

            btn.Paint = function(self, w, h)
                local bg = self:IsHovered() and Color(35, 35, 55, 255) or Color(20, 20, 35, 255)
                draw.RoundedBox(6, 0, 0, w, h, bg)
                surface.SetDrawColor(self:IsHovered() and Color(0, 180, 255, 100) or Color(50, 50, 70))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(ch.name, "DermaDefaultBold", 15, h / 2 - 8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(ch.faction, "DermaDefault", 15, h / 2 + 10, Color(150, 150, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            btn.DoClick = function()
                net.Start("QR_CharSelect")
                    net.WriteUInt(ch.id, 16)
                net.Send()
                frame:Close()
            end
        end

        if #chars < QR.Config.MaxChars then
            local createBtn = vgui.Create("DButton", frame)
            createBtn:SetPos(15, 410)
            createBtn:SetSize(570, 40)
            createBtn:SetText("")
            createBtn.Paint = function(self, w, h)
                local bg = self:IsHovered() and Color(0, 100, 60, 255) or Color(0, 70, 40, 255)
                draw.RoundedBox(6, 0, 0, w, h, bg)
                draw.SimpleText("+ CREATE CHARACTER", "DermaDefaultBold", w / 2, h / 2, Color(0, 255, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            createBtn.DoClick = function()
                frame:Close()
                QR.ShowCreateMenu()
            end
        end
    end

    function QR.ShowCreateMenu()
        local frame = vgui.Create("DFrame")
        frame:SetSize(500, 380)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        frame.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, Color(12, 12, 20, 255))
            surface.SetDrawColor(0, 180, 255, 80)
            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)
            draw.SimpleText("CREATE CHARACTER", "DermaLarge", w / 2, 25, Color(0, 200, 255), TEXT_ALIGN_CENTER)
        end

        local y = 70

        draw.SimpleText("Name:", "DermaDefault", 20, y + 5, color_white)
        local nameEntry = vgui.Create("DTextEntry", frame)
        nameEntry:SetPos(130, y)
        nameEntry:SetSize(350, 25)
        nameEntry:SetPlaceholderText("First Last")

        y = y + 45
        draw.SimpleText("Faction:", "DermaDefault", 20, y + 5, color_white)
        local factionCombo = vgui.Create("DComboBox", frame)
        factionCombo:SetPos(130, y)
        factionCombo:SetSize(350, 25)
        factionCombo:SetValue("Select faction")
        for id, f in pairs(QR.Factions) do
            factionCombo:AddChoice(f.name, id)
        end

        y = y + 45
        draw.SimpleText("Model:", "DermaDefault", 20, y + 5, color_white)
        local modelEntry = vgui.Create("DTextEntry", frame)
        modelEntry:SetPos(130, y)
        modelEntry:SetSize(350, 25)
        modelEntry:SetPlaceholderText("models/player/...")
        modelEntry:SetValue("models/player/group01/male_01.mdl")

        local createBtn = vgui.Create("DButton", frame)
        createBtn:SetPos(150, 320)
        createBtn:SetSize(200, 40)
        createBtn:SetText("")
        createBtn.Paint = function(self, w, h)
            local bg = self:IsHovered() and Color(0, 150, 80) or Color(0, 120, 60)
            draw.RoundedBox(6, 0, 0, w, h, bg)
            draw.SimpleText("CREATE", "DermaDefaultBold", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER)
        end
        createBtn.DoClick = function()
            local name = nameEntry:GetValue()
            local _, fid = factionCombo:GetSelected()
            local model = modelEntry:GetValue()

            if name == "" or not fid then
                QR.Notify(ply, "Fill in all fields!", 1)
                return
            end

            if model == "" then model = QR.Factions[fid].model end

            net.Start("QR_CharCreate")
                net.WriteString(name)
                net.WriteString(fid)
                net.WriteString(model)
            net.Send()

            frame:Close()
        end
    end
end

-----------------------------------------------------------
-- INVENTORY SYSTEM (Helix-style)
-----------------------------------------------------------
if SERVER then
    function QR.GiveItem(ply, itemClass, quantity)
        quantity = quantity or 1
        if not ply.QR_Inventory then ply.QR_Inventory = {} end

        local item = QR.GetItem(itemClass)
        if not item then return false end

        -- Check unique
        if item.unique then
            for _, inv in ipairs(ply.QR_Inventory) do
                if inv.class == itemClass then
                    QR.Notify(ply, "You already have this item!", 1)
                    return false
                end
            end
        end

        -- Stack existing
        if item.stackable then
            for _, inv in ipairs(ply.QR_Inventory) do
                if inv.class == itemClass then
                    local space = item.maxStack - (inv.qty or 1)
                    local toAdd = math.min(quantity, space)
                    inv.qty = (inv.qty or 1) + toAdd
                    quantity = quantity - toAdd
                    if quantity <= 0 then
                        QR.SyncInventory(ply)
                        return true
                    end
                end
            end
        end

        -- Add new slot
        table.insert(ply.QR_Inventory, {class = itemClass, qty = quantity})
        QR.SyncInventory(ply)
        return true
    end

    function QR.RemoveItem(ply, itemClass, quantity)
        quantity = quantity or 1
        if not ply.QR_Inventory then return false end

        for i = #ply.QR_Inventory, 1, -1 do
            local inv = ply.QR_Inventory[i]
            if inv.class == itemClass then
                if (inv.qty or 1) > quantity then
                    inv.qty = inv.qty - quantity
                    QR.SyncInventory(ply)
                    return true
                else
                    quantity = quantity - (inv.qty or 1)
                    table.remove(ply.QR_Inventory, i)
                    if quantity <= 0 then
                        QR.SyncInventory(ply)
                        return true
                    end
                end
            end
        end
        return false
    end

    function QR.HasItem(ply, itemClass)
        if not ply.QR_Inventory then return false end
        for _, inv in ipairs(ply.QR_Inventory) do
            if inv.class == itemClass and (inv.qty or 1) > 0 then return true end
        end
        return false
    end

    function QR.SyncInventory(ply)
        if not IsValid(ply) then return end
        net.Start("QR_InvSync")
            net.WriteTable(ply.QR_Inventory or {})
        net.Send(ply)
    end

    net.Receive("QR_InvAction", function(len, ply)
        local action = net.ReadString()
        local itemClass = net.ReadString()

        if action == "use" then
            local item = QR.GetItem(itemClass)
            if not item or not item.usable or not item.onUse then return end
            if not QR.HasItem(ply, itemClass) then return end
            local consume = item.onUse(ply)
            if consume then
                QR.RemoveItem(ply, itemClass, 1)
            end
        elseif action == "drop" then
            if not QR.HasItem(ply, itemClass) then return end
            QR.RemoveItem(ply, itemClass, 1)
            QR.Notify(ply, "Dropped: " .. (QR.GetItem(itemClass) and QR.GetItem(itemClass).name or itemClass))
        end
    end)
end

if CLIENT then
    net.Receive("QR_InvSync", function()
        QR.Inventory = net.ReadTable()
    end)

    function QR.OpenInventory()
        if IsValid(QR._invPanel) then QR._invPanel:Remove() end

        local frame = vgui.Create("DFrame")
        frame:SetSize(500, 420)
        frame:Center()
        frame:SetTitle("")
        frame:MakePopup()

        frame.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, Color(12, 12, 20, 255))
            surface.SetDrawColor(0, 180, 255, 80)
            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)
            draw.SimpleText("INVENTORY", "DermaLarge", w / 2, 25, Color(0, 200, 255), TEXT_ALIGN_CENTER)
        end

        QR._invPanel = frame

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:SetPos(10, 55)
        scroll:SetSize(480, 355)

        if not QR.Inventory or #QR.Inventory == 0 then
            local empty = vgui.Create("DLabel", scroll)
            empty:Dock(TOP)
            empty:DockMargin(0, 100, 0, 0)
            empty:SetText("Inventory is empty")
            empty:SetFont("DermaLarge")
            empty:SetTextColor(Color(100, 100, 120))
            empty:SetContentAlignment(5)
            return
        end

        for _, inv in ipairs(QR.Inventory) do
            local item = QR.GetItem(inv.class)
            if not item then continue end

            local btn = vgui.Create("DButton", scroll)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 4)
            btn:SetTall(45)
            btn:SetText("")

            btn.Paint = function(self, w, h)
                local bg = self:IsHovered() and Color(35, 35, 55) or Color(20, 20, 35)
                draw.RoundedBox(6, 0, 0, w, h, bg)
                surface.SetDrawColor(50, 50, 70)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(item.name, "DermaDefaultBold", 12, h / 2 - 8, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(item.category, "DermaDefault", 12, h / 2 + 8, Color(120, 120, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if (inv.qty or 1) > 1 then
                    draw.SimpleText("x" .. inv.qty, "DermaDefaultBold", w - 12, h / 2, Color(255, 200, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end

            btn.DoRightClick = function()
                local menu = DermaMenu()
                if item.usable then
                    menu:AddOption("Use", function()
                        net.Start("QR_InvAction")
                            net.WriteString("use")
                            net.WriteString(inv.class)
                        net.Send()
                    end):SetIcon("icon16/tick.png")
                end
                menu:AddOption("Drop", function()
                    net.Start("QR_InvAction")
                        net.WriteString("drop")
                        net.WriteString(inv.class)
                    net.Send()
                end):SetIcon("icon16/delete.png")
                menu:Open()
            end
        end
    end

    hook.Add("PlayerBindPress", "QR_InvBind", function(ply, bind, pressed)
        if pressed and bind == "gm_showspare2" then
            QR.OpenInventory()
            return true
        end
    end)
end

-----------------------------------------------------------
-- ZOMBIE SYSTEM (3 deaths = zombie for 2 lives)
-----------------------------------------------------------
if SERVER then
    function QR.CheckZombie(ply)
        if ply:GetNWBool("QR_IsZombie", false) then return end

        local deaths = ply:GetNWInt("QR_Deaths", 0) + 1
        ply:SetNWInt("QR_Deaths", deaths)

        if deaths >= 3 then
            QR.TurnZombie(ply)
        else
            QR.Notify(ply, "Death " .. deaths .. "/3. Zombie in: " .. (3 - deaths))
        end
    end

    function QR.TurnZombie(ply)
        ply:SetNWBool("QR_IsZombie", true)
        ply:SetNWInt("QR_ZombieLives", 2)
        ply:SetNWInt("QR_Deaths", 0)

        ply:SetModel("models/player/zombie_classic.mdl")
        ply:SetMaxHealth(150)
        ply:SetHealth(150)
        ply:SetWalkSpeed(200)
        ply:SetRunSpeed(200)

        ply:StripWeapons()
        ply:Give("weapon_crowbar")

        QR.NotifyAll(ply:Name() .. " became a ZOMBIE!", 1)
    end

    function QR.TurnHuman(ply)
        ply:SetNWBool("QR_IsZombie", false)
        ply:SetNWInt("QR_ZombieLives", 0)
        ply:SetNWInt("QR_Deaths", 0)

        local f = QR.Factions[ply:GetNWString("QR_Faction", "citizen")]
        if f then
            ply:SetModel(f.model)
            ply:SetMaxHealth(f.health)
            ply:SetHealth(f.health)
            ply:SetWalkSpeed(QR.Config.WalkSpeed)
            ply:SetRunSpeed(QR.Config.RunSpeed)
            ply:StripWeapons()
            for _, w in ipairs(f.weapons) do ply:Give(w) end
            ply:Give("gmod_tool")
            ply:Give("gmod_camera")
            ply:Give("weapon_physgun")
        end

        QR.NotifyAll(ply:Name() .. " is human again!")
    end

    hook.Add("PlayerDeath", "QR_Death", function(victim, inflictor, attacker)
        if not IsValid(victim) then return end

        if victim:GetNWBool("QR_IsZombie", false) then
            local lives = victim:GetNWInt("QR_ZombieLives", 0) - 1
            victim:SetNWInt("QR_ZombieLives", lives)
            if lives <= 0 then
                QR.TurnHuman(victim)
            else
                QR.Notify(victim, "Zombie life lost! Left: " .. lives)
            end
        else
            QR.CheckZombie(victim)
        end

        -- Death penalty
        local money = victim:GetNWInt("QR_Money", 0)
        local penalty = math.floor(money * QR.Config.DeathPenalty / 100)
        if penalty > 0 then
            victim:SetNWInt("QR_Money", money - penalty)
        end

        -- Wanted for killing
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            local w = attacker:GetNWInt("QR_Wanted", 0)
            if w < 5 then attacker:SetNWInt("QR_Wanted", w + 1) end
        end
    end)

    -- Zombie regen
    timer.Create("QR_ZombieRegen", 2, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("QR_IsZombie", false) and ply:Alive() then
                ply:SetHealth(math.min(ply:Health() + 2, ply:GetMaxHealth()))
            end
        end
    end)
end

-----------------------------------------------------------
-- INFECTION + HUNGER + THIRST + WANTED
-----------------------------------------------------------
if SERVER then
    timer.Create("QR_Stats", 30, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not ply:Alive() then continue end
            if not ply:GetNWInt("QR_CharID", 0) then continue end

            -- Infection (in zone = Vector(5000,0,0) radius 8000)
            local inZone = ply:GetPos():Distance(Vector(5000, 0, 0)) <= 8000
            local hasMask = ply:GetNWBool("QR_GasMask", false)

            if inZone and not hasMask then
                local inf = math.min(ply:GetNWFloat("QR_Infection", 0) + 5, 100)
                ply:SetNWFloat("QR_Infection", inf)
                ply:SetNWBool("QR_Infected", true)
                if inf >= 100 then
                    QR.NotifyAll(ply:Name() .. " died from infection!")
                    ply:Kill()
                    ply:SetNWFloat("QR_Infection", 0)
                    ply:SetNWBool("QR_Infected", false)
                end
            elseif not inZone then
                local inf = ply:GetNWFloat("QR_Infection", 0)
                if inf > 0 then
                    ply:SetNWFloat("QR_Infection", math.max(inf - 2, 0))
                    if inf - 2 <= 0 then ply:SetNWBool("QR_Infected", false) end
                end
            end

            -- Hunger
            local hunger = math.max(ply:GetNWFloat("QR_Hunger", 100) - 0.5, 0)
            ply:SetNWFloat("QR_Hunger", hunger)
            if hunger <= 10 and hunger > 0 then ply:TakeDamage(2) end

            -- Thirst
            local thirst = math.max(ply:GetNWFloat("QR_Thirst", 100) - 0.7, 0)
            ply:SetNWFloat("QR_Thirst", thirst)
            if thirst <= 10 and thirst > 0 then ply:TakeDamage(3) end
        end
    end)

    -- Wanted decay
    timer.Create("QR_WantedDecay", 300, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local w = ply:GetNWInt("QR_Wanted", 0)
            if w > 0 then ply:SetNWInt("QR_Wanted", w - 1) end
        end
    end)

    -- Salary
    timer.Create("QR_Salary", QR.Config.SalaryInterval, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local f = QR.Factions[ply:GetNWString("QR_Faction", "")]
            if f and f.salary > 0 then
                ply:SetNWInt("QR_Money", ply:GetNWInt("QR_Money", 0) + f.salary)
                QR.Notify(ply, "Salary: " .. QR.FormatMoney(f.salary))
            end
        end
    end)

    -- Auto-save
    timer.Create("QR_AutoSave", QR.Config.SaveInterval, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local id = ply:GetNWInt("QR_CharID", 0)
            if id > 0 then QR.DB_SaveChar(id, ply) end
        end
    end)
end

-----------------------------------------------------------
-- HUD (Client)
-----------------------------------------------------------
if CLIENT then
    hook.Add("HUDPaint", "QR_HUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        if not QR.MyName then return end

        local sw, sh = ScrW(), ScrH()
        local x, y = 20, sh - 170

        -- Background panel
        draw.RoundedBox(8, x, y, 280, 160, Color(12, 12, 20, 220))
        surface.SetDrawColor(0, 180, 255, 50)
        surface.DrawOutlinedRect(x, y, 280, 160, 1)

        -- HP Bar
        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth()
        local hpFrac = math.Clamp(hp / maxHp, 0, 1)
        local hpColor = hpFrac > 0.5 and Color(80, 200, 80) or (hpFrac > 0.25 and Color(255, 180, 50) or Color(255, 50, 50))

        draw.RoundedBox(3, x + 10, y + 10, 260, 18, Color(30, 30, 40))
        draw.RoundedBox(3, x + 10, y + 10, 260 * hpFrac, 18, hpColor)
        draw.SimpleText(hp .. " / " .. maxHp, "DermaDefault", x + 140, y + 19, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Armor
        local ar = ply:Armor()
        if ar > 0 then
            draw.RoundedBox(3, x + 10, y + 32, 260, 12, Color(30, 30, 40))
            draw.RoundedBox(3, x + 10, y + 32, 260 * (ar / 100), 12, Color(100, 150, 255))
        end

        -- Stats row
        local hunger = math.floor(ply:GetNWFloat("QR_Hunger", 100))
        local thirst = math.floor(ply:GetNWFloat("QR_Thirst", 100))
        local inf = math.floor(ply:GetNWFloat("QR_Infection", 0))

        draw.SimpleText("H: " .. hunger, "DermaDefault", x + 10, y + 52, Color(255, 200, 50))
        draw.SimpleText("T: " .. thirst, "DermaDefault", x + 80, y + 52, Color(100, 180, 255))
        if inf > 0 then
            draw.SimpleText("INF: " .. inf .. "%", "DermaDefault", x + 150, y + 52, Color(255, 50, 50))
        end

        -- Name + Faction
        draw.SimpleText(QR.MyName, "DermaDefaultBold", x + 10, y + 75, color_white)
        draw.SimpleText(QR.MyFaction, "DermaDefault", x + 10, y + 92, Color(150, 150, 170))

        -- Money
        draw.SimpleText(QR.FormatMoney(ply:GetNWInt("QR_Money", 0)), "DermaDefaultBold", x + 10, y + 115, Color(255, 200, 50))

        -- Zombie indicator
        if ply:GetNWBool("QR_IsZombie", false) then
            draw.SimpleText("ZOMBIE! Lives: " .. ply:GetNWInt("QR_ZombieLives", 0), "DermaLarge", sw / 2, sh / 2 + 60, Color(255, 50, 50), TEXT_ALIGN_CENTER)
        end

        -- Wanted stars
        local wanted = ply:GetNWInt("QR_Wanted", 0)
        if wanted > 0 then
            local stars = string.rep("* ", wanted) .. string.rep(". ", 5 - wanted)
            draw.SimpleText("WANTED: " .. stars, "DermaDefaultBold", sw - 20, 20, Color(255, 50, 50), TEXT_ALIGN_RIGHT)
        end

        -- Server name
        draw.SimpleText("QUARANTINE RP v" .. QR.Version, "DermaDefault", sw / 2, 15, Color(0, 180, 255, 120), TEXT_ALIGN_CENTER)
    end)

    hook.Add("HUDShouldDraw", "QR_HideHUD", function(name)
        if name == "CHudHealth" or name == "CHudBattery" then return false end
    end)
end

-----------------------------------------------------------
-- GAMEMODE HOOKS
-----------------------------------------------------------
function GM:PlayerInitialSpawn(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            QR.OpenCharMenu(ply)
        end
    end)
end

function GM:PlayerSpawn(ply)
    player_manager.SetPlayerClass(ply, "player_sandbox")
end

function GM:PlayerLoadout(ply)
    return true
end

function GM:PlayerDisconnected(ply)
    if SERVER then
        local id = ply:GetNWInt("QR_CharID", 0)
        if id > 0 then QR.DB_SaveChar(id, ply) end
    end
end

function GM:ShutDown()
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            local id = ply:GetNWInt("QR_CharID", 0)
            if id > 0 then QR.DB_SaveChar(id, ply) end
        end
    end
end

-----------------------------------------------------------
-- CHAT COMMANDS
-----------------------------------------------------------
hook.Add("PlayerSay", "QR_Chat", function(ply, text)
    local lower = string.lower(text)

    if lower == "/help" then
        ply:ChatPrint("=== QUARANTINE RP COMMANDS ===")
        ply:ChatPrint("/help - this menu")
        ply:ChatPrint("/me <action> - roleplay action")
        ply:ChatPrint("// <text> - out of character chat")
        ply:ChatPrint("/stats - character stats")
        ply:ChatPrint("F2 - open inventory")
        return ""
    end

    if lower == "/stats" then
        local name = ply:GetNWString("QR_CharName", "?")
        local faction = ply:GetNWString("QR_Faction", "?")
        local money = ply:GetNWInt("QR_Money", 0)
        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth()
        local hunger = math.floor(ply:GetNWFloat("QR_Hunger", 100))
        local thirst = math.floor(ply:GetNWFloat("QR_Thirst", 100))
        local inf = math.floor(ply:GetNWFloat("QR_Infection", 0))
        local wanted = ply:GetNWInt("QR_Wanted", 0)

        ply:ChatPrint("=== " .. name .. " ===")
        ply:ChatPrint("Faction: " .. faction)
        ply:ChatPrint("Money: " .. QR.FormatMoney(money))
        ply:ChatPrint("HP: " .. hp .. "/" .. maxHp)
        ply:ChatPrint("Hunger: " .. hunger .. " | Thirst: " .. thirst)
        ply:ChatPrint("Infection: " .. inf .. "%")
        ply:ChatPrint("Wanted: " .. wanted .. "/5")
        if ply:GetNWBool("QR_IsZombie", false) then
            ply:ChatPrint("STATUS: ZOMBIE! Lives: " .. ply:GetNWInt("QR_ZombieLives", 0))
        end
        return ""
    end

    if string.sub(lower, 1, 4) == "/me " then
        local action = string.sub(text, 5)
        QR.NotifyAll(ply:GetNWString("QR_CharName", ply:Name()) .. " " .. action)
        return ""
    end

    if string.sub(text, 1, 2) == "//" then
        local msg = string.sub(text, 3)
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("(( OOC " .. ply:Name() .. ": " .. msg .. " ))")
        end
        return ""
    end
end)

-----------------------------------------------------------
-- DONE
-----------------------------------------------------------
print("===========================================")
print("  QUARANTINE RP v" .. QR.Version .. " LOADED!")
print("  Factions: " .. table.Count(QR.Factions))
print("  Items: " .. table.Count(QR.Items))
print("  Systems: characters, inventory, zombie,")
print("  infection, hunger, thirst, wanted, HUD")
print("===========================================")

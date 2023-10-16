-- Themes
-- this file isn't completed at all, this is just temporary so greatchar doesn't bite my head off

local primary = Settings:Register("PrimaryCol", Color(31, 31, 34, 170))
local secondary = Settings:Register("SecondaryCol", Color(32, 32, 36, 170))
local tertiary = Settings:Register("TertiaryCol", Color(34, 34, 38, 170))
local accent = Settings:Register("AccentCol", Color(80, 30, 40, 170))
local outlines = Settings:Register("Outlines", true) and color_black or Color(0, 0, 0, 0)
local text = Settings:Register("TextCol", color_white)
local text2 = Settings:Register("TextCol2", Color(200, 200, 200))

Settings:Register("StartZone", Color( 0, 230, 0, 255 ))
Settings:Register("EndZone", Color( 180, 0, 0, 255 ))
Settings:Register("BonusStart", Color( 127, 140, 141 ))
Settings:Register("BonusEnd", Color( 52, 73, 118 ))

local panel = false
concommand.Add("kawaii_thememanager", function()
	if panel then 
		panel:Remove()
		panel = false
		gui.EnableScreenClicker(false)

		return 
	end 

	local w, h = 500, 400
	gui.EnableScreenClicker(true)

	panel = vgui.Create("DPanel")
	panel:SetSize(w, h)
	panel:Center()
	panel.Paint = function(self, width, height)
		surface.SetDrawColor(primary)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(outlines)
		surface.DrawOutlinedRect(0, 0, width, height)
		surface.DrawLine(0, 28, width, 28)

		-- Title 
		draw.SimpleText("BETA: Theme Editor", "hud.subtitle", 12, 15, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		-- Select theme option
		draw.SimpleText("Select colour to change", "hud.subtitle", 12, 46, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		-- color updates
		primary = Settings:GetValue("PrimaryCol")
		secondary = Settings:GetValue("SecondaryCol")
		outlines = Settings:GetValue("Outlines") and color_black or Color(0, 0, 0, 0)
		text = Settings:GetValue("TextCol")
	end

	local combo = panel:Add("DComboBox")
	combo:SetPos(w - 150, 34)
	combo:SetSize(140, 24)
	combo:SetTextColor(text)
	combo.Paint = function(self, width, height) 
		surface.SetDrawColor(outlines)
		surface.DrawOutlinedRect(0, 0, width, height)
	end

	local colours = {
		["Primary Colour"] = "PrimaryCol",
		["Secondary Colour"] = "SecondaryCol",
		["Tertiary Colour"] = "TertiaryCol",
		["Accent Colour"] = "AccentCol",
		["Text Colour"] = "TextCol",
		["Text Colour 2"] = "TextCol2",
		["Start Zone"] = "StartZone",
		["End Zone"] = "EndZone",
		["Bonus Start"] = "BonusStart",
		["Bonus End"] = "BonusEnd"
	}

	for k, v in pairs(colours) do
		combo:AddChoice(k, v)
	end

	local x, y = combo:GetPos()

	local picker = panel:Add("DColorMixer")
	picker:SetWide(476)
	picker:SetPos(12, y + 40)

	local code_called = false
	function combo:OnSelect(index, text, data)
		code_called = true
		picker:SetColor(Settings:GetValue(data))
	end

	function picker:ValueChanged(col)
		local selected, data = combo:GetSelected()

		if (not selected) or (not data) then return end
		if (code_called) then
			code_called = false 
			return
		end

		Settings:SetValue(data, self:GetColor())
	end

	x, y = picker:GetPos()

	-- Reset
	local reset = panel:Add("DButton")
	reset:SetPos(12, y + picker:GetTall() + 14)
	reset:SetWide(picker:GetWide())
	reset:SetTall(30)
	reset:SetText("Reset value to default")
	reset:SetTextColor(text)
	reset:SetFont("hud.subtitle")
	reset.Paint = function(self, width, height)
		surface.SetDrawColor(secondary)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(outlines)
		surface.DrawOutlinedRect(0, 0, width, height)
	end
	reset.OnMousePressed = function()
		local selected, data = combo:GetSelected()
		if (not selected) or (not data) then return end

		Settings:ResetDefault(data)
		code_called = true 
		picker:SetColor(Settings:GetValue(data))
	end

	-- Close
	local close = panel:Add("DButton")
	close:SetPos(12, y + picker:GetTall() + 52)
	close:SetWide(picker:GetWide())
	close:SetTall(30)
	close:SetText("Close")
	close:SetTextColor(text)
	close:SetFont("hud.subtitle")
	close.Paint = function(self, width, height)
		surface.SetDrawColor(secondary)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(outlines)
		surface.DrawOutlinedRect(0, 0, width, height)
	end
	close.OnMousePressed = function()
		LocalPlayer():ConCommand("kawaii_thememanager")
		return
	end
end)


-- Module
Theme = {}
local themes = {}

-- Register Theme
function Theme:Register(ty, id, name, options)
	themes[id] = {name = name, ty = ty, options = options}

	-- We're just gonna piggyback off cl_settings 
	Settings:Register(id, options)
end

-- HUD themes
Theme:Register("HUD", "hud.flow.redesign", "Flow Network (Re-Design)", {
	["Colours"] = {
		["Primary Colour"] = Color(31, 31, 34, 170),
		["Secondary Colour"] = Color(32, 32, 36, 170),
		["Accent Colour"] = Color(80, 30, 40, 170),
		["Text Colour"] = color_white,
	},

	["Toggles"] = {
		["Outlines"] = true
	}
})

-- UI Themes
Theme:Register("UI", "ui.kawaii", "	", {
	["Colours"] = {
		["Primary Colour"] = Color(31, 31, 34, 170),
		["Secondary Colour"] = Color(32, 32, 36, 170),
		["Accent Colour"] = Color(80, 30, 40, 170),
		["Text Colour"] = color_white,
	},

	["Toggles"] = {
		["Outlines"] = true
	}
})

-- Get theme for id
function Theme:Get(id)
	return themes[id].options
end









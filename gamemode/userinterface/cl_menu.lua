-- F1/!options/!menu 
-- by Justa

-- TODO: Finish Main Menu HUD

-- Theme
--local theme = Theme:GetPreference("UI") 
--local primary = theme["Colours"]["Primary Colour"]
--local outlines = theme["Toggles"]["Outline Colour"]

-- Update colours
--Theme:AddUpdate("UI",)

-- Function to toggle menu
function UI:ToggleMainmenu()
	-- Already exists
	if (self.mainmenu) then
		self.mainmenu:Remove() 
		self.mainmenu = nil
	gui.EnableScreenClicker(false)
		return
	end

	-- Size and positioning 
	local width = ScrW() * 0.52
	local height = ScrH() * 0.65

	-- Create
	self.mainmenu = vgui.Create("DPanel")
	self.mainmenu:SetSize(width, height)
	self.mainmenu:Center()

	-- Painting of base
	function self.mainmenu:Paint(width, height)
		gui.EnableScreenClicker(true)

		-- color updates
		primary = Settings:GetValue("PrimaryCol")
		secondary = Settings:GetValue("SecondaryCol")
		outlines = Settings:GetValue("Outlines") and color_black or Color(0, 0, 0, 0)
		text = Settings:GetValue("TextCol")
		
		surface.SetDrawColor(Color(43, 43, 43))
		surface.DrawRect(0, 0, width, height)

		surface.DrawOutlinedRect(0, 0, width, height, 10)

		surface.SetDrawColor(Color( 35, 35, 35 ))
		surface.DrawRect(0, 0, width, 55)
		
		-- Title 
		draw.SimpleText("BETA: Main Menu", "HUDTimerMedThick", 12, 15, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		draw.SimpleText("Rules", "hud.subtitle", 12, 96, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		draw.SimpleText("HOW TO PLAY", "hud.subtitle", 12, 206, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	end
end

-- Debug concommand
concommand.Add("kawaii_mainmenu", function()
	UI:ToggleMainmenu()
end)
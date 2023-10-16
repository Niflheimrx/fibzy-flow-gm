-- Settings
-- by Justa

-- Module is neat
Settings = {}
local lst = {}

-- Add new setting
function Settings:Register(settingId, default)
	lst[settingId] = {value = default, default = default}  
	return lst[settingId].value
end

-- Load settings
function Settings:Load()
	-- Does file exist
	if file.Exists("kawaii", "DATA") and file.Exists("kawaii/settings.txt", "DATA") then 
		local settings = file.Read("kawaii/settings.txt", "DATA")
		lst = util.JSONToTable(settings)

		return
	end

	file.CreateDir("kawaii")
end
hook.Add("Initialize", "Settings_Load", function()
	Settings:Load()
end)

function Settings:Save()
	local settings = util.TableToJSON(lst)
	file.Write("kawaii/settings.txt", settings)
end

function Settings:GetValue(settingId)
	if (not lst) or (not lst[settingId]) then
		return nil 
	end

	return lst[settingId].value 
end

function Settings:SetValue(settingId, value)
	if (not lst[settingId]) then
		return nil 
	end

	lst[settingId].value = value
	self:Save() 
end

function Settings:ResetDefault(settingId)
	self:SetValue(settingId, lst[settingId].default)
end

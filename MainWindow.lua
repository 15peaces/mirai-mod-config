-- mirai-mod-conf
-- class MainWindow

local class             = require "30log"
local LoadConfigOptions = require "LoadConfigOptions"
local SkillsTab         = require "SkillsTab"
local TacticsTab        = require "TacticsTab"

local MainWindow = class("MainWindow")

MainWindow.IDs = {}


function MainWindow:init(xmlResource)
	assert(xmlResource)
	-- no parent parameter for this function,
	-- since we will only ever have one instance of MainWindow
	
	-- TODO: keep a reference to xmlResource?
	--       we might need it when MainWindow wants to create a child window.
	
	self.dialog = nil
	
	local handlers = {} -- table for all event handler functions
	
	function handlers.OnClose(event)
		DebugLog("MainWindow: OnClose")
		event:Skip()
		-- TODO: check if there are unsaved changes and warn user before quitting.
		self.dialog:Show(false)
		self.dialog:Destroy()
		-- for some reason, the standalone exe process does not always end
		-- when MainWindow is closed (or does it?)
		-- so we force it to end:
		os.exit()
	end
	
	-- manages linking of "Homunculus: Attack and Evade" sliders and spinCtrls (tab "General")
	function handlers.OnAttackAndEvade(event)
		DebugLog("MainWindow: OnAttackAndEvade")
		event:Skip()
		
		local attackChanged = false
		local evadeChanged = false
		
		local src = event:GetId()
		if src == MainWindow.IDs.SL_AttackWhenHP then
			DebugLog("source: SL_AttackWhenHP")
			self.SC_AttackWhenHP:SetValue(event:GetInt())
			attackChanged = true
			
		elseif src == MainWindow.IDs.SC_AttackWhenHP then
			DebugLog("source: SC_AttackWhenHP")
			self.SL_AttackWhenHP:SetValue(event:GetInt())
			attackChanged = true
			
		elseif src == MainWindow.IDs.SL_EvadeWhenHP then
			DebugLog("source: SL_EvadeWhenHP")
			self.SC_EvadeWhenHP:SetValue(event:GetInt())
			evadeChanged = true
			
		elseif src == MainWindow.IDs.SC_EvadeWhenHP then
			DebugLog("source: SC_EvadeWhenHP")
			self.SL_EvadeWhenHP:SetValue(event:GetInt())
			evadeChanged = true
		end
		
		local attack = self.SC_AttackWhenHP:GetValue()
		local evade = self.SC_EvadeWhenHP:GetValue()
		if attackChanged and attack < evade then
			DebugLog("attackChanged and attack < evade")
			self.SC_EvadeWhenHP:SetValue(attack)
			self.SL_EvadeWhenHP:SetValue(attack)
			
		elseif evadeChanged and evade > attack then
			DebugLog("evadeChanged and evade > attack")
			self.SC_AttackWhenHP:SetValue(evade)
			self.SL_AttackWhenHP:SetValue(evade)
		end
	end
	
	
	function handlers.OnButtonEdit(event)
		DebugLog("MainWindow: OnButtonEdit")
		event:Skip()
		TacticsTab.OnEdit(self.LC_Tactics)
	end
	
	
	function handlers.OnButtonAdd(event)
		DebugLog("MainWindow: OnButtonAdd")
		event:Skip()
		TacticsTab.OnAdd(self.LC_Tactics)
	end
	
	
	function handlers.OnButtonRemove(event)
		DebugLog("MainWindow: OnButtonRemove")
		event:Skip()
		TacticsTab.OnRemove(self.LC_Tactics)
	end
	
	
	function handlers.OnButtonUp(event)
		DebugLog("MainWindow: OnButtonUp")
		event:Skip()
		TacticsTab.OnUp(self.LC_Tactics)
	end
	
	
	function handlers.OnButtonDown(event)
		DebugLog("MainWindow: OnButtonDown")
		event:Skip()
		TacticsTab.OnDown(self.LC_Tactics)
	end
	
	
	function handlers.OnSaveConfig(event)
		DebugLog("MainWindow: OnSaveConfig")
		event:Skip()
		
		xpcall(function()
			self:SaveConfig(CONFIG_FILE)
		end, ErrorHandler)
	end
	
	-- TODO: remaining event handler functions, eg: "function handlers.OnSomething(event)"
	
	
	-- get IDs / init wxWindow ID values (yes, before loading the dialog)
	-- TODO: add all the remaining IDs!
	for i, v in ipairs {
		--"TAB_General", -- Tab 'General' ----------------------------------------------------------
		--"SB_HomuAttackAndEvade",
		--"TXT_AttackWhenHP",
		"CB_DontMove",
		"SL_AttackWhenHP",
		"SC_AttackWhenHP",
		--"TXT_EvadeWhenHP",
		"CB_Cautious",
		"SL_EvadeWhenHP",
		"SC_EvadeWhenHP",
		"CB_HelpOwnerFirst",
		"CB_KillEnemiesFirst",
		
		--"SB_KindHomu",
		"CB_NoMovingTargets",
		"CB_AdvMotionCheck",
		
		--"SB_Other",
		--"TXT_MaxEnemyDistance",
		"SC_MaxEnemyDistance",
		--"TXT_SkillTimeout",
		"SC_SkillTimeout",
		--"TXT_OwnerClosedistance",
		"SC_OwnerClosedistance",
		
		"CB_FollowAtOnce",
		"CB_CircleOnIdle",
		--"CB_CanDetectNoPot", -- will be removed/replaced later
		
		
		--"TAB_Tactics", -- Tab 'Tactics' ----------------------------------------------------------
		"BUT_Edit",
		"BUT_Add",
		"BUT_Remove",
		"BUT_Up",
		"BUT_Down",
		"LC_Tactics",
		
		
		--"TAB_Skills", -- Tab 'Skills' ------------------------------------------------------------
		--"SCROLLWIN_Skills", -- we don't need this, SkillsTab.lua manages this by itself.
		
		
		--"TAB_Mod", -- Tab 'Mod' ------------------------------------------------------------------
		-- TODO: TAB_Mod
		
		
		--"TAB_Language", -- Tab 'Language' --------------------------------------------------------
		-- TODO: TAB_Language
		
		
		"BUT_SaveConfig",
	} do
		MainWindow.IDs[v] = xmlResource.GetXRCID(v)
	end
	
	
	-- load the dialog:
	self.dialog = wx.wxDialog()
	assert(xmlResource:LoadDialog(self.dialog, wx.NULL, "MainWindow"), 
		"Error loading dialog 'MainWindow'"
	)
	
	
	-- initialize the reference variables for the input fields:
	self:InitInputs()
	
	
	-- connect events to handler functions:
	
	-- (see wxWidgets docs: class "wxCommandEvent")
	self.dialog:Connect(MainWindow.IDs.SL_AttackWhenHP, wx.wxEVT_COMMAND_SLIDER_UPDATED, handlers.OnAttackAndEvade)
	-- found the wxEVT_* constant via wxLua sample program "controls.wx.lua"
	self.dialog:Connect(MainWindow.IDs.SC_AttackWhenHP, wx.wxEVT_COMMAND_SPINCTRL_UPDATED, handlers.OnAttackAndEvade)
	
	self.dialog:Connect(MainWindow.IDs.SL_EvadeWhenHP, wx.wxEVT_COMMAND_SLIDER_UPDATED, handlers.OnAttackAndEvade)
	self.dialog:Connect(MainWindow.IDs.SC_EvadeWhenHP, wx.wxEVT_COMMAND_SPINCTRL_UPDATED, handlers.OnAttackAndEvade)
	
	self.dialog:Connect(MainWindow.IDs.BUT_Edit, wx.wxEVT_COMMAND_BUTTON_CLICKED, handlers.OnButtonEdit)
	self.dialog:Connect(MainWindow.IDs.BUT_Add, wx.wxEVT_COMMAND_BUTTON_CLICKED, handlers.OnButtonAdd)
	self.dialog:Connect(MainWindow.IDs.BUT_Remove, wx.wxEVT_COMMAND_BUTTON_CLICKED, handlers.OnButtonRemove)
	self.dialog:Connect(MainWindow.IDs.BUT_Up, wx.wxEVT_COMMAND_BUTTON_CLICKED, handlers.OnButtonUp)
	self.dialog:Connect(MainWindow.IDs.BUT_Down, wx.wxEVT_COMMAND_BUTTON_CLICKED, handlers.OnButtonDown)
	
	self.dialog:Connect(MainWindow.IDs.BUT_SaveConfig, wx.wxEVT_COMMAND_BUTTON_CLICKED, handlers.OnSaveConfig)
	-- TODO: connect remaining events to handler functions
	
	-- connect the closeevent to the OnClose function:
	self.dialog:Connect(wx.wxEVT_CLOSE_WINDOW, handlers.OnClose)
	
	
	-- SkillsTab.FillSkillsTab returns a a table containing references to the widgets it creates
	self.skillWidgets = SkillsTab.FillSkillsTab(self.dialog, xmlResource)
	
	-- load the configuration file before showing the window:
	self:LoadConfig(CONFIG_FILE)
	
	
	self:HideLanguageTab(xmlResource) -- TODO: remove this later
	
	self.dialog:Center()
	self.dialog:Show(true)
end


-- initializes the reference variables for the input fields
function MainWindow:InitInputs()
	
	local InitWidget = function(name, widgetType)
		DebugLog('InitWidget("' .. name .. '", "' .. widgetType .. '")')
		local w = assert(self.dialog:FindWindow(MainWindow.IDs[name]))
		w = assert(w:DynamicCast(widgetType))
		self[name] = w
		--return w
	end
	
	
	InitWidget("CB_DontMove", "wxCheckBox")
	
	-- the 4 input references
	-- "SL_AttackWhenHP", "SC_AttackWhenHP", "SL_EvadeWhenHP" and "SC_EvadeWhenHP"
	-- are also used by function 'handlers.OnAttackAndEvade'
	InitWidget("SL_AttackWhenHP", "wxSlider")
	InitWidget("SC_AttackWhenHP", "wxSpinCtrl")
	
	InitWidget("CB_Cautious", "wxCheckBox")
	
	InitWidget("SL_EvadeWhenHP", "wxSlider")
	InitWidget("SC_EvadeWhenHP", "wxSpinCtrl")
	
	
	-- the input references below are only used by MainWindow:SaveConfig and MainWindow:LoadConfig
	InitWidget("CB_HelpOwnerFirst", "wxCheckBox")
	InitWidget("CB_KillEnemiesFirst", "wxCheckBox")
	InitWidget("CB_NoMovingTargets", "wxCheckBox")
	InitWidget("CB_AdvMotionCheck", "wxCheckBox")
	
	-- TODO: more stuff
	InitWidget("SC_MaxEnemyDistance", "wxSpinCtrl")
	InitWidget("SC_SkillTimeout", "wxSpinCtrl")
	InitWidget("SC_OwnerClosedistance", "wxSpinCtrl")
	
	InitWidget("CB_FollowAtOnce", "wxCheckBox")
	InitWidget("CB_CircleOnIdle", "wxCheckBox")
	
	InitWidget("LC_Tactics", "wxListCtrl")
	
	-- TODO: more stuff
	
	-- TODO: initialize the remaining reference variables for all the input fields
end

-- saves the configuration to file 'filename'
function MainWindow:SaveConfig(filename)
	assert(type(filename) == "string")
	DebugLog('MainWindow:SaveConfig("' .. filename .. '")')
	
	-- TODO: add error handler (try/catch block) to all functions that call this one!
	local f = assert(io.open(filename, "w"))
	
	local WriteOpt = function(o) DebugLog(o); f:write(o .. "\n") end
	
	-- write header:
	f:write(
		"--------------------------------------------------\n" ..
		"-- Mir AI configuration file (generated by " .. APP_NAME .. ")\n" ..
		"--------------------------------------------------\n"
	)
	
	-- save regular settings:
	
	-- TAB_General:
	WriteOpt("CIRCLE_ON_IDLE=" .. tostring(self.CB_CircleOnIdle:GetValue() and 1 or 0))
	WriteOpt("FOLLOW_AT_ONCE=" .. tostring(self.CB_FollowAtOnce:GetValue() and 1 or 0))
	WriteOpt("HELP_OWNER_1ST=" .. tostring(self.CB_HelpOwnerFirst:GetValue()))
	WriteOpt("KILL_YOUR_ENEMIES_1ST=" .. tostring(self.CB_KillEnemiesFirst:GetValue()))
	WriteOpt("LONG_RANGE_SHOOTER=" .. tostring(self.CB_DontMove:GetValue()))
	
	-- BOLTS_ON_CHASE_ST is not supported by mirai-mod-config
	WriteOpt(
		"BOLTS_ON_CHASE_ST=false -- part of 'Alchemist Auto Attacks', not supported by " .. APP_NAME
	)
	WriteOpt("HP_PERC_DANGER=" .. tostring(self.SC_EvadeWhenHP:GetValue()))
	WriteOpt("HP_PERC_SAFE2ATK=" .. tostring(self.SC_AttackWhenHP:GetValue()))
	WriteOpt("OWNER_CLOSEDISTANCE=" .. tostring(self.SC_OwnerClosedistance:GetValue()))
	WriteOpt("TOO_FAR_TARGET=" .. tostring(self.SC_MaxEnemyDistance:GetValue()))
	WriteOpt("SKILL_TIME_OUT=" .. tostring(self.SC_SkillTimeout:GetValue()))
	WriteOpt("NO_MOVING_TARGETS=" .. tostring(self.CB_NoMovingTargets:GetValue()))
	
	WriteOpt("ADV_MOTION_CHECK=" .. tostring(self.CB_AdvMotionCheck:GetValue()))
	
	
	-- save the auto attack stuff (with a comment that it is disabled and not configurable)
	f:write(
		"\n" ..
		"--------------------------------------------------\n" ..
		"-- Alchemist automatic skills\n" ..
		"-- (These options are not supported by " .. APP_NAME .. ")\n" ..
		"--------------------------------------------------\n" ..
		"-- Alchemist Auto Attacks (AAA)\n" ..
		"AAA_MinHP=100\n" ..
		"AAA_MaxHP=32000\n" ..
		"-- Auto Cart Revolution (ACR)\n" ..
		"ACR = {}\n" ..
		"ACR.MinEnemies=2\n" ..
		"ACR.MinSP=20\n" ..
		"Auto Single Target (AST)" ..
		"AST = {}\n" ..
		"AST.SkillID=0\n" ..
		"AST.MinSP=20\n" ..
		"AST.Level=5\n" ..
		"-- Auto Aid Potion (AAP)\n" ..
		"CAN_DETECT_NOPOT=true\n" ..
		"AAP = {}\n" ..
		"AAP.Mode=3\n" ..
		"AAP.HP_Perc=65\n" ..
		"AAP.Level=2\n\n"
	)
	
	
	f:write(
		"--------------------------------------------------\n" ..
		"-- Homunculus Skills: minimum SP to activate\n" ..
		"--------------------------------------------------\n"
	)
	-- save skill settings
	SkillsTab.SaveSkills(f, self.skillWidgets)
	
	f:write("\n\n")
	
	f:write(
		"--------------------------------------------------\n" ..
		"-- Tact list: behaviour for each monster\n" ..
		"--------------------------------------------------\n"
	)
	
	WriteOpt("DEFAULT_BEHA = " .. (self.CB_Cautious:GetValue() and "BEHA_react" or "BEHA_attack"))
	
	WriteOpt("DEFAULT_WITH = WITH_slow_power -- not configurable with " .. APP_NAME)
	
	-- TODO: write tact list!
	
	-- TODO: save tactics
	-- TODO: save selected Mod
	-- TODO: Checkbox "Cautious" / Option "DEFAULT_BEHA" and "DEFAULT_WITH" come right before the Tact list!
	
	f:close()
end


-- loads the configuration from file 'filename'
function MainWindow:LoadConfig(filename)
	assert(type(filename) == "string")
	DebugLog('MainWindow:LoadConfig("' .. filename .. '")')
	
	-- TODO: add error handler (try/catch block) to all functions that call this one!
	
	local f = io.open(filename, "r")
	if not f then
		--DebugLog("Configuration file could not be opened, creating new file...")
		--self:SaveConfig(filename)
		DebugLog("Configuration file could not be opened, using default settings.")
		return
	end
	
	local options, tactics = LoadConfigOptions(f)
	
	if DEBUG then -- DEBUG:
		print() -- empty line
		DebugLog("options:")
		for k, v in pairs(options) do
			--DebugLog(k, " = ", v)
			DebugLog('"' .. k .. '"', " = ", '"' .. v .. '"')
		end
		print()
		DebugLog("tactics:")
		for i, v in ipairs(tactics) do
			DebugLog(i, " = ", LoadConfigOptions.TactToString(v))
			--DebugLog('"' .. i .. '"', " = ", '"' .. LoadConfigOptions.TactToString(v) .. '"')
		end
		print()
	end
	
	
	-- load regular settings:
	
	-- helper func ReadOpt:
	-- option      - the option (string)
	-- widget      - the widget that will be set by the option (string)
	-- isOneOrZero - if true, the option will be assumed to be boolean, but saved as either 1 or 0.
	-- isDEFAULT_BEHA - if true, the option will be assumed to be 
	--                     "BEHA_react" for true,
	--                  or "BEHA_attack" (or anything else) for false.
	-- (isOneOrZero is required for options 'CIRCLE_ON_IDLE' and 'FOLLOW_AT_ONCE')
	local ReadOpt = function(option, widget, isOneOrZero, isDEFAULT_BEHA)
		local v = options[option]
		if v then -- if the option exists in Config.lua
			if isOneOrZero then
				if v == "1" then
					v = true
					
				elseif v == "0" then
					v = false
					
				else
					error(
						'Invalid value for option "' .. option ..
						'". expected 1 or 0, got: "' .. v .. '"'
					)
				end
				
			elseif isDEFAULT_BEHA then
				if v == "BEHA_react" then
					v = true
					
				else --if v == "BEHA_attack" then
					v = false
				end
				
			elseif v == "true" then
				v = true
				
			elseif v == "false" then
				v = false
				
			else
				v = tonumber(v)
			end
			DebugLog(
				'ReadOpt("'..option..'", "'..widget..'", '..tostring(isOneOrZero)..', '..
				tostring(isDEFAULT_BEHA)..') = '..
				'"'..tostring(v)..'" type('..type(v)..')'
			)
			self[widget]:SetValue(v)
		end
	end
	
	-- TAB_General:
	ReadOpt("CIRCLE_ON_IDLE", "CB_CircleOnIdle", true)
	ReadOpt("FOLLOW_AT_ONCE", "CB_FollowAtOnce", true)
	ReadOpt("HELP_OWNER_1ST", "CB_HelpOwnerFirst")
	ReadOpt("KILL_YOUR_ENEMIES_1ST", "CB_KillEnemiesFirst")
	ReadOpt("LONG_RANGE_SHOOTER", "CB_DontMove")
	
	--ReadOpt("BOLTS_ON_CHASE_ST", "") not supported by mirai-mod-config
	
	-- read this option into both: SpinCtrl and Slider:
	ReadOpt("HP_PERC_DANGER", "SC_EvadeWhenHP") -- SpinCtrl
	ReadOpt("HP_PERC_DANGER", "SL_EvadeWhenHP") -- Slider
	-- see above:
	ReadOpt("HP_PERC_SAFE2ATK", "SC_AttackWhenHP") -- SpinCtrl
	ReadOpt("HP_PERC_SAFE2ATK", "SL_AttackWhenHP") -- Slider
	
	ReadOpt("OWNER_CLOSEDISTANCE", "SC_OwnerClosedistance")
	ReadOpt("TOO_FAR_TARGET", "SC_MaxEnemyDistance")
	ReadOpt("SKILL_TIME_OUT", "SC_SkillTimeout")
	ReadOpt("NO_MOVING_TARGETS", "CB_NoMovingTargets")
	
	ReadOpt("ADV_MOTION_CHECK", "CB_AdvMotionCheck")
	
	ReadOpt("DEFAULT_BEHA", "CB_Cautious", false, true)
	
	-- load skill settings:
	SkillsTab.LoadSkills(options, self.skillWidgets)
	
	-- use method SetValue()
	
	-- TODO: LoadConfig!
	
	f:close()
end





-- TEMP: hide the tab "Language" / TODO: remove this later
function MainWindow:HideLanguageTab(xmlResource)
	local nb = assert(self.dialog:FindWindow(xmlResource.GetXRCID("m_notebook1")))
	nb = assert(nb:DynamicCast("wxNotebook"))
	nb:DeletePage(4)
end


return MainWindow

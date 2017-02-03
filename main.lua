-- mirai-mod-conf
-- for now, this is just a simple program that loads and displays the mirai-mod-conf MainWindow

package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

DEBUG      = true
USE_STRICT = true

if DEBUG then
	print("### debug mode enabled ###")
	if USE_STRICT then require "strict" end
	function DebugLog(...) print("DEBUG: ", ...) end
else
	function DebugLog(...) --[[ do nothing ]] end
end

class = require "30log"
MainWindow = require "MainWindow"

-- constants:
XRC_FILE        = "config/config.xrc"
APP_NAME        = "MirAI Mod Config"
CONFIG_FILE     = "Config.lua"
MOD_FILE        = "SelectedMod.lua"
MOD_TEMPLATE    = "config/SelectedModTemplate.lua"
SKILL_ICON_PATH = "config"

-- globals:
-- MARK: don't make this global for now, it's probably not needed.
--xmlResource = nil



function ErrorHandler(err)
	DebugLog("ErrorHandler: " .. err)
	wx.wxMessageBox(err, APP_NAME, wx.wxOK + wx.wxICON_EXCLAMATION)
	os.exit()
end


function LoadXmlResource(xrcFile)
	local xmlResource = wx.wxXmlResource()
	xmlResource:InitAllHandlers()
	
	--local logNo = wx.wxLogNull() -- temporarily disable wx error messages
	
	assert(xmlResource:Load(xrcFile), "Error loading File: " .. xrcFile)
	
	--logNo:delete() -- re-enable error messages
	
	return xmlResource
end


xpcall(function() --try
	local xmlResource = LoadXmlResource(XRC_FILE)
	local mainWin = MainWindow(xmlResource)
end, ErrorHandler)


wx.wxGetApp():MainLoop()

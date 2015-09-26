require 'orient'

addPackagePath(script_path()..'?')

local configPath = io.toAbsPath('..\\postproc_getconfigs.lua', io.local_dir())

local config = dofile(configPath)

local waterluaPath = config.assignments['waterlua']

assert(waterluaPath, 'no waterlua path found')

requireDir(io.toAbsPath(waterluaPath, getFolder(configPath)))

require 'waterlua'

require 'wx'

local t={}

for k, v in pairs(wx) do
	--t[#t+1]=tostring(k), '->', tostring(v)
end


--print(table.concat(t, '\n'))
local win = wx.wxFrame(wx.NULL, wx.wxID_ANY, 'hello world', wx.wxDefaultPosition, wx.wxSize(250, 150))

win:Show(true)
win:Centre()

local sizer = wx.wxBoxSizer(wx.wxVERTICAL)

local textCtrl = wx.wxTextCtrl(win, wx.wxID_ANY, '', wx.wxPoint(0, 0), wx.wxSize(350, 20))

local dialogButton = wx.wxButton(win, wx.wxID_ANY, 'select path', wx.wxPoint(0, 0))

local dialog = wx.wxFileDialog(win, 'pick WorldEditor executable', '', '', 'exe files (*.exe)|*.exe')

local function selectPath()
	dialog:ShowModal()

	textCtrl:Clear()
	textCtrl:AppendText(io.getFolder(dialog:GetPath()))
end

dialogButton:Connect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED, selectPath)

local installButton = wx.wxButton(win, wx.wxID_ANY, 'install', wx.wxPoint(0, 0))

local function install()
	local targetPath = textCtrl:GetValue()

	if not io.copyFile(io.local_dir()..'lua51.dll', targetPath, true) then
		wx.wxMessageBox('could not copy lua51.dll')

		return
	end
	if not io.copyFile(io.local_dir()..'lua5.1.dll', targetPath, true) then
		wx.wxMessageBox('could not copy lua5.1.dll')

		return
	end
	if not io.copyFile(io.local_dir()..'5d\\wehack.lua', targetPath, true) then
		wx.wxMessageBox('could not copy wehack.lua')

		return
	end

	wx.wxMessageBox('done')	
end

installButton:Connect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED, install)

sizer:Add(textCtrl)
sizer:Add(dialogButton)
sizer:Add(installButton)

win:SetSizerAndFit(sizer)

wx.wxGetApp():MainLoop()
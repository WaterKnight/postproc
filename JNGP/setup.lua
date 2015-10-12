require 'orient'

addPackagePath(script_path()..'?')

local postprocDir = io.toAbsPath('..\\', io.local_dir())

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
local win = wx.wxFrame(wx.NULL, wx.wxID_ANY, 'postproc JNGP setup', wx.wxDefaultPosition, wx.wxSize(250, 150))

win:Show(true)
win:Centre()

local sizer = wx.wxBoxSizer(wx.wxVERTICAL)

local textCtrl = wx.wxTextCtrl(win, wx.wxID_ANY, '', wx.wxPoint(0, 0), wx.wxSize(350, 20))

local wehackChoices = {'5d', '5e', '207', 'wursteditor'}

local wehackChoicesWx = wx.wxArrayString()

for i = 1, #wehackChoices, 1 do
	wehackChoicesWx:Add(wehackChoices[i])
end

local wehackComboBox = wx.wxComboBox(win, wx.wxID_ANY, '', wx.wxPoint(0, 0), wx.wxSize(350, 20), wehackChoicesWx)

wehackComboBox:SetValue(wehackChoices[1])

local dialogButton = wx.wxButton(win, wx.wxID_ANY, 'select path', wx.wxPoint(0, 0))

local dialog = wx.wxFileDialog(win, 'pick WorldEditor executable', '', '', 'exe files (*.exe)|*.exe')

local function selectPath()
	local ret = dialog:ShowModal()

	if (ret ~= wx.wxID_OK) then
		return
	end

	textCtrl:Clear()

	textCtrl:AppendText(io.getFolder(dialog:GetPath()))
end

dialogButton:Connect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED, selectPath)

local installButton = wx.wxButton(win, wx.wxID_ANY, 'install', wx.wxPoint(0, 0))

local function install()
	local targetPath = io.toFolderPath(textCtrl:GetValue())

	if not io.copyFile(io.local_dir()..'lua51.dll', targetPath, true) then
		wx.wxMessageBox('could not copy lua51.dll')

		return
	end
	if not io.copyFile(io.local_dir()..'lua5.1.dll', targetPath, true) then
		wx.wxMessageBox('could not copy lua5.1.dll')

		return
	end

	local wehackVersion = wehackComboBox:GetValue()

	if not io.copyFile(io.local_dir()..'wehack.lua', targetPath..'wehack_orig.lua', true) then
		wx.wxMessageBox('could not copy original wehack.lua')

		return
	end

	if not io.copyFile(io.local_dir()..'wehack.lua', targetPath, true) then
		wx.wxMessageBox('could not copy wehack.lua')

		return
	end

	local jngpConfigPath = targetPath..'postproc.conf'

	local f = io.open(jngpConfigPath, 'w+')

	assert((f ~= nil), string.format('could not open %s', jngpConfigPath))

	f:write(string.format([[postprocDir="%s"]], postprocDir))
	f:write('\n')
	f:write(string.format([[wehackVersion="%s"]], wehackVersion))

	f:close()

	wx.wxMessageBox('done')
end

installButton:Connect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED, install)

sizer:Add(textCtrl)
sizer:Add(dialogButton)
sizer:Add(wehackComboBox)
sizer:Add(installButton)

win:SetSizerAndFit(sizer)

wx.wxGetApp():MainLoop()
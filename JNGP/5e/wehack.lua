-- This file is executed once on we start up.  The state perseveres
-- through callbacks
--
-- wehack.runprocess:  Wait for exit code, report errors (grimext)
-- wehack.runprocess2:  Wait for exit code, don't report errors (jasshelper)
-- wehack.execprocess:  Don't wait for exit code (War3)
--
grimregpath = "Software\\Grimoire\\"
--warcraftdir = grim.getregpair(grimregpath,"War3InstallPath")
--if warcraftdir == 0 then
--	wehack.messagebox("Error, could not find warcraft install path in wehack.lua")
--end

isstartup = true
grimdir = grim.getcwd()
dofile("wehacklib.lua")
dofile("findpath.lua")
if path==0 or path=="" then
	path = "."
end
mapvalid = true
cmdargs = "" -- used to execute external tools on save

confregpath = "HKEY_CURRENT_USER\\Software\\Grimoire\\"

haveext = grim.exists("grimext\\grimex.dll")
if haveext then
	utils = wehack.addmenu("Extensions")
end
haveumswe = haveext and grim.exists("umswe\\umswecore.lua")
if haveumswe then
	ums =  	wehack.addmenu("UMSWE")
end

whmenu = wehack.addmenu("Grimoire")
wh_window = TogMenuEntry:New(whmenu,"Start War3 with -window",nil,true)
wh_opengl = TogMenuEntry:New(whmenu,"Start War3 with -opengl",nil,false)
if not grim.isnewcompiler(path.."\\war3.exe") then
  wh_grimoire = TogMenuEntry:New(whmenu,"Start War3 with Grimoire",nil,true)
  wh_enablewar3err = TogMenuEntry:New(whmenu,"Enable war3err",nil,true)
  wh_enablejapi = TogMenuEntry:New(whmenu,"Enable japi",nil,false)
end
wehack.addmenuseparator(whmenu)
wh_tesh = TogMenuEntry:New(whmenu,"Enable TESH",nil,true)
if grim.isdotnetinstalled() then
	wh_colorizer = TogMenuEntry:New(whmenu,"Enable Colorizer",nil,true)
end
wh_nolimits = TogMenuEntry:New(whmenu,"Enable no limits",
	function(self) grim.nolimits(self.checked) end,false)
wh_oehack = TogMenuEntry:New(whmenu,"Enable object editor hack",
	function(self) grim.objecteditorhack(self.checked) end,true)
wh_syndisable = TogMenuEntry:New(whmenu,"Disable WE syntax checker",
	function(self) grim.syndisable(self.checked) end,true)
wh_descpopup = TogMenuEntry:New(whmenu,"Disable default description nag",
	function(self) grim.descpopup(self.checked) end,true)
wh_autodisable = TogMenuEntry:New(whmenu,"Don't let WE disable triggers",
	function(self) grim.autodisable(self.checked) end,true)
wh_alwaysenable = TogMenuEntry:New(whmenu,"Always allow trigger enable",
	function(self) grim.alwaysenable(self.checked) end,true)
wh_disablesound = TogMenuEntry:New(whmenu,"Mute editor sounds",nil,true)
wh_firstsavenag = TogMenuEntry:New(whmenu,"Disable first save warning",nil,true)

wehack.addmenuseparator(whmenu)
weukey = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\WE Unlimited_is1"
weuval = "InstallLocation"
weupath = grim.getregpair(weukey,weuval)
haveweu = grim.exists(weupath .. "WE Unlimited.exe")
if haveweu then
	wh_useweu = TogMenuEntry:New(whmenu,"Integrate WEU",nil,false)
end

usetestmapconf = (grim.getregpair(confregpath,"Use custom test map settings") == "on")
function testmapconfig()
	usetestmapconf = wehack.testmapconfig(path,usetestmapconf)
	if usetestmapconf then
		grim.setregstring(confregpath,"Use custom test map settings","on")
	else
		grim.setregstring(confregpath,"Use custom test map settings","off")
	end
end
wh_configtest = MenuEntry:New(whmenu,"Customize test map settings",testmapconfig);

function attachdebugger()
	wehack.execprocess("w3jdebug\\pyw3jdebug.exe")
end
havedebugger = grim.exists("w3jdebug\\pyw3jdebug.exe")
if havedebugger then
    wh_debug = MenuEntry:New(whmenu,"Attach debugger",attachdebugger)
end

function aboutpopup()
	wehack.showaboutdialog("Grimoire 1.5")
end

function grimdoc()
	wehack.execprocess("starter.bat ./grimoiremanual.pdf")
end

wh_docm = MenuEntry:New(whmenu, "Grimoire Documentation ...", grimdoc)

wh_about = MenuEntry:New(whmenu,"About Grimoire ...",aboutpopup)

--Here I'll add the custom menu to jasshelper. moyack
jh_path = ""
havejh = grim.exists("cohadarjasshelper\\jasshelper.exe") or grim.exits("vexorianjasshelper\\jasshelper.exe")
if havejh then
	jhmenu = wehack.addmenu("JassHelper")
	jh_enable = TogMenuEntry:New(jhmenu,"Enable JassHelper",nil,true)
	wehack.addmenuseparator(jhmenu)
	
	jh_iscohadar = TogMenuEntry:New(jhmenu,"Enable Cohadar's JassHelper",nil,true)
	jh_isvexorian = TogMenuEntry:New(jhmenu,"Enable Vexorian's JassHelper",nil,false)
	
	wehack.addmenuseparator(jhmenu)
	jh_debug = TogMenuEntry:New(jhmenu,"Debug Mode",nil,false)
	jh_disable = TogMenuEntry:New(jhmenu,"Disable vJass syntax",nil,false)
    jh_disableopt = TogMenuEntry:New(jhmenu,"Disable script optimization",nil,false)

	wehack.addmenuseparator(jhmenu)
	
	function jhsetpath()
		if jh_isvexorian.checked then
			jh_path = "vexorian"
		else
			jh_path = "cohadar" -- Default
		end
	end
	
	jhsetpath()
	
	function jhshowerr()
	  	wehack.execprocess(jh_path.."jasshelper\\jasshelper.exe --showerrors")
	end
	
	function jhabout()
	  	wehack.execprocess(jh_path.."jasshelper\\jasshelper.exe --about")
	end
	
	jhshowerrm = MenuEntry:New(jhmenu,"Show previous errors",jhshowerr)
	jhaboutm = MenuEntry:New(jhmenu,"About JassHelper ...",jhabout)
	
    function jhsetcohadar()
		jh_iscohadar.checked = true
		jh_iscohadar:redraw(jh_iscohadar)
		jh_isvexorian.checked = false
		jh_isvexorian:redraw(jh_isvexorian)
		jhsetpath()
	end
	
	function jhsetvexorian()
		jh_isvexorian.checked = true
		jh_isvexorian:redraw(jh_isvexorian)
		jh_iscohadar.checked = false
		jh_iscohadar:redraw(jh_iscohadar)
		jhsetpath()
	end
	
	jh_iscohadar.cb = jhsetcohadar
	jh_isvexorian.cb = jhsetvexorian
	
	function jhshowhelp()
		jhsetpath()
		wehack.execprocess("starter.bat ./"..jh_path.."jasshelper\\jasshelpermanual.html")
	end
	
	jhhelp = MenuEntry:New(jhmenu, "JassHelper Documentation...", jhshowhelp)
end

--%POSTPROC_REPLACED_START_MENU
-- # begin postproc #
local function postproc_createConfig()
	local this = {}

	this.assignments = {}
	this.sections = {}

	function this:readFromFile(path, ignoreNotFound)
		assert(path, 'configParser: no path passed')

		local f = io.open(path, 'r')

		if (f == nil) then
			if not ignoreNotFound then
				error(string.format('configParser: cannot open file %s', tostring(path)))
			else
				return false
			end
		end

		local curSection = nil

		for line in f:lines() do
			local sectionName = line:match('%['..'([%w%d%p_]*)'..'%]')

			if (sectionName ~= nil) then
				curSection = this.sections[sectionName]

				if (curSection == nil) then
					curSection = {}

					this.sections[sectionName] = curSection

					curSection.assignments = {}
					curSection.lines = {}
				end
			elseif (curSection ~= nil) then
				curSection.lines[#curSection.lines + 1] = line
			end

			local pos, posEnd = line:find('=')

			if pos then
				local name = line:sub(1, pos - 1)
				local val = line:sub(posEnd + 1, line:len())

				if ((type(val) == 'string')) then
					val = val:match('\"(.*)\"')
				end

				if (curSection ~= nil) then
					curSection.assignments[name] = val
				else
					this.assignments[name] = val
				end
			end
		end

		f:close()

		return true
	end

	function this:merge(other)
		assert(other, 'no other')

		for name, val in pairs(other.assignments) do
			this.assignments[name] = val
		end

		for name, otherSection in pairs(other.sections) do
			local section = this.sections[name]

			if (section == nil) then
				section = {}

				this.sections[name] = section
			end

			for name, val in pairs(otherSection.assignments) do
				section.assignments[name] = val
			end
		end
	end

	return this
end

postproc_jngpConfig = postproc_createConfig()

postproc_jngpConfigPath = 'postproc.conf'

if not postproc_jngpConfig:readFromFile(postproc_jngpConfigPath) then
	wehack.messagebox(string.format('could not read %s'), postproc_jngpConfigPath)
end

postproc_dir = postproc_jngpConfig.assignments['postprocDir']

if (postproc_dir == nil) then
	wehack.messagebox('no postproc dir in jngp config', 'postproc', false)

	postproc = false
else
	postproc = true
end

if not postproc_dir:match('\\$') then
	postproc_dir = postproc_dir..'\\'
end

local postproc_jngpDir = postproc_dir..[[JNGP\]]
local postproc_tempDir = postproc_dir..[[temp\]]

local postproc_config = postproc_createConfig()

local postproc_configPath = postproc_dir..'config.conf'

postproc_config:readFromFile(postproc_configPath)

postproc_config:merge(postproc_jngpConfig)

local postproc_logPath = postproc_config.assignments['logPath']
local postproc_outputPathNoExt = postproc_config.assignments['outputPathNoExt']

local function tryloadfile(path, doShell)
	if doShell then
		if (postproc_dir == nil) then
			wehack.messagebox('no postproc dir', 'postproc', true)

			return nil
		end

		local shellPath = postproc_jngpDir..[[jngp_shell.lua]]

		local f = loadfile(shellPath)

		if (f == nil) then
			return nil
		end

		f()

		return jngp_createShell(path)
	end

	if (path == nil) then
		return nil
	end

	return loadfile(path)
end

local postproc_onStartupPath = postproc_jngpDir..'jngp_onStartup.lua'
local postproc_onSavePath = postproc_jngpDir..'jngp_onSave.lua'
local postproc_onTestmapPath = postproc_jngpDir..'jngp_onTestmap.lua'
local postproc_requestInfo = tryloadfile(postproc_jngpDir..'jngp_requestInfo.lua')

local t = {postproc_onStartupPath, postproc_onSavePath, postproc_onTestmapPath}
local t2 = {}

for i = 1, #t, 1 do
	if (tryloadfile(t[i]) == nil) then
		t2[#t2 + 1] = t[i]
	end
end

if (#t2 > 0) then
	wehack.messagebox('warning: inited postproc but could not load files:\n'..table.concat(t2, '\n'))
end

if (postproc_logPath == nil) then
	postproc_logPath = postproc_tempDir..'log.txt'
end

if (postproc_outputPathNoExt == nil) then
	postproc_outputPathNoExt = postproc_tempDir..'output'
end

local postproc_startup = tryloadfile(postproc_onStartupPath, true)

if (postproc_startup ~= nil) then
	postproc_startup:exec({wc3path = path, configPath = configPath, postprocDir = postproc_dir, logPath = postproc_logPath, outputPathNoExt = postproc_outputPathNoExt})
end

local postproc_forcingSave = false
local postproc_forcingTest = false

do
	postproc_menu = wehack.addmenu('postproc')

	postproc_menu_enable = TogMenuEntry:New(postproc_menu, 'Enable', nil, true)

	wehack.addmenuseparator(postproc_menu)

	postproc_menu_blockTools = TogMenuEntry:New(postproc_menu, 'Block other compiling tools', nil, false)

	postproc_menu_saveMapAuto = TogMenuEntry:New(postproc_menu, 'Use postproc when map is being saved', nil, false)

	postproc_menu_runMapAuto = TogMenuEntry:New(postproc_menu, 'Use last compiled map when testing', nil, false)

	wehack.addmenuseparator(postproc_menu)

	local function editInstructions()
		local mapPath = wehack.findmappath()
		
		if (mapPath == nil) then
			wehack.messagebox([[No map opened.]], 'postproc', true)
			
			return
		end

		if (mapPath == '') then			
			wehack.messagebox([[Cannot edit instructions of an unnamed map. Please save first.]], 'postproc', false)
			
			return
		end
		
		local path = postproc_jngpDir..[[jngp_pullInstructions.lua]]

		local f = tryloadfile(path, true)

		if (f ~= nil) then
			f:exec({mapPath = mapPath, postprocDir = postproc_dir})
		else
			wehack.messagebox('could not load '..tostring(path), 'postproc', true)
		end
	end

	MenuEntry:New(postproc_menu, 'Edit instructions', editInstructions)

	wehack.addmenuseparator(postproc_menu)

	local function showPaths()
		local t = {}

		t[#t + 1] = 'postprocDir='..postproc_dir
		t[#t + 1] = 'logPath='..postproc_logPath
		t[#t + 1] = 'outputPathNoExt='..postproc_outputPathNoExt

		wehack.messagebox(table.concat(t, '\n'), 'postproc paths')
	end

	postprocShowPaths = MenuEntry:New(postproc_menu, 'Show current paths', showPaths)

	local function showConfig()
		os.execute('start \"\" \"'..postproc_dir..'config.conf'..'\"')
	end

	postprocShowConfig = MenuEntry:New(postproc_menu, 'Show config', showConfig)

	local function showConfigTools()
		os.execute('start \"\" \"'..postproc_dir..'configTools.slk'..'\"')
	end

	postproc_menu_showConfigTools = MenuEntry:New(postproc_menu, 'Show tools', showConfigTools)

	local function showJNGPConf()
		os.execute('start \"\" \"'..'postproc.conf'..'\"')
	end

	postproc_menu_showJNGPConf = MenuEntry:New(postproc_menu, 'Show postproc.conf (JNGP)', showJNGPConf)

	local function showLog()
		os.execute('start \"\" \"'..postproc_logPath..'\"')
	end

	postproc_menu_showLog = MenuEntry:New(postproc_menu, 'Show log', showLog)

	wehack.addmenuseparator(postproc_menu)

	local function saveMap()
		local mapPath = wehack.findmappath()
		
		if (mapPath == nil) then
			wehack.messagebox([[No map opened.]], 'postproc', true)
			
			return
		end
		
		postproc_forcingSave = true

		compilemap()

		postproc_forcingSave = false
	end

	postproc_menu_useConsoleLog = TogMenuEntry:New(postproc_menu, 'Use console log', nil, false)

	postproc_menu_saveMap = MenuEntry:New(postproc_menu, 'Save and compile map', saveMap)

	postproc_menu_useLogTracker = TogMenuEntry:New(postproc_menu, 'Start LogTracker when testing', nil, false)

	local function runMap()
		if (postproc_requestInfo == nil) then
			wehack.messagebox('could not open requestInfo')

			return
		end

		local t = postproc_requestInfo()

		local mapPath = t.getLastOutputPath(postproc_dir)

		if (mapPath == nil) then
			wehack.messagebox([[No last compiled map.]], 'postproc', true)

			return
		end

		local cmdline = '\"'..path..'\\War3.exe\"'..' -loadfile \"'..mapPath..'\"'

		postproc_forcingTest = true

		testmap(cmdline)

		postproc_forcingTest = false
	end

	postproc_menu_runMap = MenuEntry:New(postproc_menu, 'Run last compiled map', runMap)

	wehack.addmenuseparator(postproc_menu)

	local function showManual()
		local path = postproc_dir..'manual.html'

		os.execute(string.format('%q', path))
	end

	postproc_menu_manual = MenuEntry:New(postproc_menu, 'Manual', showManual)

	local function update()
		local path = postproc_jngpDir..[[jngp_update.lua]]

		local f = tryloadfile(path, true)

		if (f ~= nil) then
			f:exec({postprocDir = postproc_dir})
		else
			wehack.messagebox('cannot load '..tostring(path), 'postproc', true)
		end
	end

	postproc_menu_update = MenuEntry:New(postproc_menu, 'Update', update)

	local function showAbout()
		if (postproc_requestInfo == nil) then
			wehack.messagebox('could not open requestInfo')

			return
		end

		local t = postproc_requestInfo()

		local version = t.getVersion(postproc_dir)

		local s = 'postproc grants you the ability to build compiler tool chains. It creates a copy of the passed map and applies the instructions of a custom instruction file to the replica.\n\nAuthor:\tWaterKnight\nVersion:\t%s'

		wehack.messagebox(string.format(s, version), 'About postproc', false)
	end

	postproc_menu_about = MenuEntry:New(postproc_menu, 'About postproc', showAbout)
end
-- # end postproc #
--%POSTPROC_REPLACED_END_MENU

function initshellext()
    local first, last = string.find(grim.getregpair("HKEY_CLASSES_ROOT\\WorldEdit.Scenario\\shell\\open\\command\\", ""),"NewGen",1)
    if first then
        wehack.checkmenuentry(shellext.menu,shellext.id,1)
    else
    		local second, third = string.find(grim.getregpair("HKEY_CLASSES_ROOT\\WorldEdit.Scenario\\shell\\open\\command\\", ""),".bat",1)
    		if second then
    			wehack.checkmenuentry(shellext.menu,shellext.id,1)
    		else
        	wehack.checkmenuentry(shellext.menu,shellext.id,0)
        end
    end
end

function fixopencommand(disable,warpath,grimpath,filetype)
    
    local wepath = "\""..grimpath.."\\NewGen WE.exe\""
    if not grim.exists(grimpath.."\\NewGen WE.exe") then
      wepath = "\""..grimpath.."\\we.bat\""
    end
    if disable then
    	grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\open\\command\\","","\""..warpath.."\\World Editor.exe\" -loadfile \"%L\"")
    else
    	grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\open\\command\\","",wepath.." -loadfile \"%L\"")
    end
end

function registerextension(disable,warpath,grimpath,filetype,istft)
    if disable then
        grim.deleteregkey("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\fullscreen\\command\\");
        grim.deleteregkey("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\fullscreen\\");
        grim.deleteregkey("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\windowed\\command\\");
        grim.deleteregkey("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\windowed\\");
        grim.deleteregkey("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\opengl\\command\\");
        grim.deleteregkey("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\opengl\\");
    else
        --if istft then
        --    gamepath = "\""..warpath.."\\Frozen Throne.exe\""
        --else
        --    gamepath = "\""..warpath.."\\Warcraft III.exe\""
        --end
        --grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\fullscreen\\","","Play Fullscreen")
        --grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\fullscreen\\command\\","",gamepath.." -loadfile \"%L\"")
        --grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\windowed\\","","Play Windowed")
        --grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\windowed\\command\\","",gamepath.." -window -loadfile \"%L\"")

        local gamepath = "\""..grimpath.."\\NewGen Warcraft.exe\""
        if not grim.exists(grimpath.."\\NewGen Warcraft.exe") then
	        gamepath = "\""..grimpath.."\\startwar3.bat\""
	      end
        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\fullscreen\\","","Play Fullscreen")
        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\fullscreen\\command\\","",gamepath.." -loadfile \"%L\"")
        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\windowed\\","","Play Windowed")
        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\windowed\\command\\","",gamepath.." -window -loadfile \"%L\"")
        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\opengl\\","","Play With OpenGL")
        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\opengl\\command\\","",gamepath.." -window -opengl -loadfile \"%L\"")
    end
end

function toggleshellext()
    local istft = (grim.getregpair("HKEY_CURRENT_USER\\Software\\Blizzard Entertainment\\Warcraft III\\", "InstallPathX") ~= 0)
    local first, last = string.find(grim.getregpair("HKEY_CLASSES_ROOT\\WorldEdit.Scenario\\shell\\open\\command\\", ""),"NewGen",1)
    local found = false
    if first then
    	found = true
    else
    		local second, third = string.find(grim.getregpair("HKEY_CLASSES_ROOT\\WorldEdit.Scenario\\shell\\open\\command\\", ""),".bat",1)
    		if second then
    			found = true
    		end
    end

    if path ~= 0 and grimdir ~= 0 then
        fixopencommand(found,path,grimdir,"Scenario")
        registerextension(found,path,grimdir,"Scenario",istft)
        fixopencommand(found,path,grimdir,"ScenarioEx")
        registerextension(found,path,grimdir,"ScenarioEx",istft)
        fixopencommand(found,path,grimdir,"Campaign")
        registerextension(found,path,grimdir,"Campaign",istft)
        fixopencommand(found,path,grimdir,"AIData")
        if found then
            wehack.checkmenuentry(shellext.menu,shellext.id,0)
        else
            wehack.checkmenuentry(shellext.menu,shellext.id,1)
        end
    end
end

function initlocalfiles()
    if grim.getregpair("HKEY_CURRENT_USER\\Software\\Blizzard Entertainment\\Warcraft III\\", "Allow Local Files") == 0 then
        wehack.checkmenuentry(localfiles.menu,localfiles.id,0)
    else
        wehack.checkmenuentry(localfiles.menu,localfiles.id,1)
    end
end

function togglelocalfiles()
    if grim.getregpair("HKEY_CURRENT_USER\\Software\\Blizzard Entertainment\\Warcraft III\\", "Allow Local Files") == 0 then
        grim.setregdword("HKEY_CURRENT_USER\\Software\\Blizzard Entertainment\\Warcraft III\\", "Allow Local Files", 1)
        wehack.checkmenuentry(localfiles.menu,localfiles.id,1)
    else
        grim.setregdword("HKEY_CURRENT_USER\\Software\\Blizzard Entertainment\\Warcraft III\\", "Allow Local Files", 0)
        wehack.checkmenuentry(localfiles.menu,localfiles.id,0)
    end
end

function runobjectmerger(mode)
    curmap = wehack.findmappath()
    if curmap ~= "" then
        source = wehack.openfiledialog("Unit files (*.w3u)|*.w3u|Item files (*.w3t)|*w3t|Doodad files (*.w3d)|*.w3d|Destructable files (*.w3b)|*.w3b|Ability files (*.w3a)|*.w3a|Buff files (*.w3h)|*.w3h|Upgrade files (*.w3q)|*.w3q|", "w3a", "Select files to import ...", true)
grim.log("got in lua: " .. source)
        if source ~= "" then
            list = strsplit("|", source);
--            cmdargs = "ObjectMerger \""..curmap.."\" "..wehack.getlookupfolders().." "..mode..fileargsjoin(list)        
            cmdargs = "grimext\\ObjectMerger.exe \""..curmap.."\" "..wehack.getlookupfolders().." "..mode..fileargsjoin(list)
grim.log("assembled cmdline: " .. cmdargs)
--            wehack.messagebox(cmdargs,"Grimoire",false)
            wehack.savemap()
grim.log("called saved map")
        end
    else
    	showfirstsavewarning()
    end
end

function runconstantmerger()
    curmap = wehack.findmappath()
    if curmap ~= "" then
        source = wehack.openfiledialog("Text files (*.txt)|*.txt|", "txt", "Select files to import ...", true)
        if source ~= "" then
            list = strsplit("|", source);
--            cmdargs = "ConstantMerger \""..curmap.."\" "..wehack.getlookupfolders()..fileargsjoin(list)
            cmdargs = "grimext\\ConstantMerger.exe \""..curmap.."\" "..wehack.getlookupfolders()..fileargsjoin(list)
--            wehack.messagebox(cmdargs,"Grimoire",false)
            wehack.savemap()
        end
    else
    	showfirstsavewarning()
    end
end

function runtriggermerger()
    curmap = wehack.findmappath()
    if curmap ~= "" then
        source = wehack.openfiledialog("GUI Trigger files (*.wtg)|*.wtg|Custom Text Trigger files (*.wct)|*wct|", "wtg", "Select trigger data to import ...", true)
        if source ~= "" then
            list = strsplit("|", source);
--            cmdargs = "TriggerMerger \""..curmap.."\" "..wehack.getlookupfolders()..fileargsjoin(list)
            cmdargs = "grimext\\TriggerMerger.exe \""..curmap.."\" "..wehack.getlookupfolders()..fileargsjoin(list)
--            wehack.messagebox(cmdargs,"Grimoire",false)
            wehack.savemap()
        end
    else
    	showfirstsavewarning()
    end
end

function runfileimporterfiles()
    curmap = wehack.findmappath()
    if curmap ~= "" then
        source = wehack.openfiledialog("All files (*.*)|*.*|", "*", "Select files to import ...", true)
        if source ~= "" then
            list = strsplit("|", source);
            inmpqpath = wehack.inputbox("Specify the target path ...","FileImporter","Units\\")
--            cmdargs = "FileImporter \""..curmap.."\" "..wehack.getlookupfolders()..argsjoin(inmpqpath,list)
            cmdargs = "grimext\\FileImporter.exe \""..curmap.."\" "..wehack.getlookupfolders()..argsjoin(inmpqpath,list)
--            wehack.messagebox(cmdargs,"Grimoire",false)
            wehack.savemap()
        end
    else
    	showfirstsavewarning()
    end
end

function runfileimporterdir()
    curmap = wehack.findmappath()
    if curmap ~= "" then
        source = wehack.browseforfolder("Select the source directory ...")
        if source ~= "" then
--            cmdargs = "FileImporter \""..curmap.."\" "..wehack.getlookupfolders().." \""..source.."\""
            cmdargs = "grimext\\FileImporter.exe \""..curmap.."\" "..wehack.getlookupfolders().." \""..source.."\""
--            wehack.messagebox(cmdargs,"Grimoire",false)
            wehack.savemap()
        end
    else
    	showfirstsavewarning()
    end
end

function runfileexporter()
    curmap = wehack.findmappath()
    if curmap ~= "" then
        target = wehack.browseforfolder("Select the target directory ...")
        if target ~= "" then
--        		wehack.rungrimextool("FileExporter", curmap, removequotes(wehack.getlookupfolders()), target)
            wehack.runprocess("grimext\\FileExporter.exe \""..curmap.."\" "..wehack.getlookupfolders().." \""..target.."\"")
        end
    else
    	showfirstsavewarning()
    end
end

function runtilesetter()
    curmap = wehack.findmappath()
    if curmap ~= "" then
        map = wehack.openarchive(curmap,15)
        oldtiles = wehack.getcurrenttiles()
        wehack.closearchive(map)
        if oldtiles ~= "" then
        		newtiles = wehack.tilesetconfig(string.sub(oldtiles,1,1), string.sub(oldtiles,2))
        		if newtiles ~= "" then
        			tileset = string.sub(newtiles,1,1)
        			tiles = string.sub(newtiles,2)
							if tileset ~= "" and tiles ~= "" then
--								cmdargs = "TileSetter \""..curmap.."\" "..wehack.getlookupfolders().." "..tileset.." "..tiles
								cmdargs = "grimext\\TileSetter.exe \""..curmap.."\" "..wehack.getlookupfolders().." "..tileset.." "..tiles
								wehack.savemap()
        			end
        		end
        		
--            tileset = wehack.inputbox("Specify the tileset ...","TileSetter",string.sub(oldtiles,1,1))
--            if tileset ~= "" then
--                tiles = wehack.inputbox("Specify the tile list ...","TileSetter",string.sub(oldtiles,2))
--                if tiles ~= "" then
--                    cmdargs = "grimext\\TileSetter.exe \""..curmap.."\" "..wehack.getlookupfolders().." "..tileset.." "..tiles
--                    wehack.savemap()
--                end
--            end
        end
    else
    	showfirstsavewarning()
    end
end

function showfirstsavewarning()
	if wh_firstsavenag.checked then
		return
	else
		wehack.messagebox("Could not find path to map, please try saving again","Grimoire",false)
	end
end

function testmap(cmdline)
	if wh_opengl.checked then
		cmdline = cmdline .. " -opengl"
	end
	if wh_window.checked then
		cmdline = cmdline .. " -window"
	end

	--%POSTPROC_REPLACED_START_TEST_MAP
	if (postproc and (postproc_forcingTest or (postproc_menu_enable.checked and postproc_menu_runMapAuto.checked))) then
		local postproc_testmap = tryloadfile(postproc_onTestmapPath)

		assert(postproc_testmap, 'could not load '..tostring(postproc_onTestmapPath))

		local success = false

		success, cmdline = postproc_testmap(postproc_jngpConfig, {cmdline = cmdline, wc3path = path, configPath = postproc_jngpConfigPath, postprocDir = postproc_dir, logPath = postproc_logPath, outputPathNoExt = postproc_outputPathNoExt, forcePostproc = postproc_forcingTest, startLogTracker = postproc_menu_useLogTracker.checked})
	end
--%POSTPROC_REPLACED_END_TEST_MAP

	wehack.execprocess(cmdline)
end

function compilemap_path(mappath)
	if mappath == "" then
		showfirstsavewarning()
		return
	end
	map = wehack.openarchive(mappath,15)
	wehack.extractfile(jh_path.."jasshelper\\common.j","scripts\\common.j")
	wehack.extractfile(jh_path.."jasshelper\\Blizzard.j","scripts\\Blizzard.j")
	wehack.extractfile("war3map.j","war3map.j")
	wehack.closearchive(map)
	if cmdargs ~= "" then
		local cmdtable = argsplit(cmdargs)
--		local len = table.getn(cmdtable)
--		for i = 1, len do
--			cmdtable[i] = removequotes(cmdtable[i])
--		end
--		wehack.rungrimextool(cmdtable)
grim.log("running tool on save: "..cmdargs)
		wehack.runprocess(cmdargs)
		cmdargs = ""
	end

	mapvalid = true

	--%POSTPROC_REPLACED_START_COMPILE_MAP_BLOCK
if (not postproc or (not postproc_menu_enable.checked or not postproc_menu_blockTools.checked and not postproc_forcingSave)) then
--%POSTPROC_REPLACED_END_COMPILE_MAP_BLOCK
		-- Here I'll add a new configuration for jasshelper. moyack
		if havejh and jh_enable.checked then
			cmdline = jh_path .. "jasshelper\\jasshelper.exe"
			if jh_debug.checked then
				cmdline = cmdline .. " --debug"
			end
			if jh_disable.checked then
				cmdline = cmdline .. " --nopreprocessor"
			end
			if jh_disableopt.checked then
				cmdline = cmdline .. " --nooptimize"
			end
			cmdline = cmdline .. " "..jh_path.."jasshelper\\common.j "..jh_path.."jasshelper\\blizzard.j \"" .. mappath .."\""

--			if jh_fast ~= nil and jh_fast.checked then
--				toolresult = wehack.runjasshelper(jh_debug.checked, jh_disable.checked, "jasshelper\\common.j", "jasshelper\\blizzard.j", mappath, "")
--			else
				toolresult = wehack.runprocess2(cmdline)
--			end

			mapvalid = mapvalid and (toolresult == 0)
		end

	--%POSTPROC_REPLACED_START_COMPILE_MAP_SAVE
	if (postproc and (postproc_forcingSave or (postproc_menu_enable.checked and postproc_menu_saveMapAuto.checked))) then
		local postproc_save = tryloadfile(postproc_onSavePath)

		assert(postproc_save, 'could not load '..tostring(postproc_onSavePath))

		local success = false

		wehack.setwaitcursor(true)

		success = postproc_save(postproc_jngpConfig, {mapPath = mappath, wc3path = path, configPath = postproc_jngpConfigPath, postprocDir = postproc_dir, logPath = postproc_logPath, outputPathNoExt = postproc_outputPathNoExt, useConsoleLog = postproc_menu_useConsoleLog.checked})

		wehack.setwaitcursor(false)
		
		mapvalid = mapvalid and success
	end
--%POSTPROC_REPLACED_END_COMPILE_MAP_SAVE
end

dofile("ScExp\\ScExp.lua") 
function compilemap() 
	mappath = wehack.findmappath() 
	if mappath == "" then 
		scexpBuildCampaign()
	else compilemap_path(mappath) 
	end 
end
--function compilemap()
--	mappath = wehack.findmappath()
--	compilemap_path(mappath)
--end

--Menu for JNGP. moyack
function JNGPHelp()
	wehack.execprocess("starter.bat ./NewGenReadme.html")
end

function JNGPAbout()
    wehack.messagebox("Jass New Generation Pack\n-----------------------------------------------\n\nNew compilation by Moyack & PurgeandFire.\n\nFor new versions of this tool and other Warcraft III apps please check: http://wc3modding.info/wc3-editing-tools/\n\nCredits:\n\n - PipeDream\n - MindWorX\n - Guessed\n - Vexorian\n - StonedStoopid\n - Zepir \n - ShadowFlare\n - PitzerMike\n - Cohadar '\n - SFilip\n - Risc\n - ScorpioT1000","About Jass New Generation Pack",false)
end

jngpm = wehack.addmenu("JNGP version 1.5e")
jngphelpm = MenuEntry:New(jngpm,"Jass New Generation Pack Information & Help...",JNGPHelp)
wehack.addmenuseparator(jngpm)
jngpaboutm = MenuEntry:New(jngpm,"Jass New Generation Pack About...",JNGPAbout)

--End menu entry

if haveext then
    localfiles = MenuEntry:New(utils,"Enable Local Files",togglelocalfiles)
    shellext = MenuEntry:New(utils,"Register Shell Extensions",toggleshellext)
    initlocalfiles()
    initshellext()
    wehack.addmenuseparator(utils)
end
if haveext and grim.exists("grimext\\tilesetter.exe") then
    tilesetter = MenuEntry:New(utils,"Edit Tileset",runtilesetter)
end
if haveext and grim.exists("grimext\\fileexporter.exe") then
    fileexporter = MenuEntry:New(utils,"Export Files",runfileexporter)
end
if haveext and grim.exists("grimext\\fileimporter.exe") then
    fileimporterdir = MenuEntry:New(utils,"Import Directory",runfileimporterdir)
    fileimporterfiles = MenuEntry:New(utils,"Import Files",runfileimporterfiles)
end
if haveext and grim.exists("grimext\\objectmerger.exe") then
    objectmerger = MenuEntry:New(utils,"Merge Object Editor Data",function(self) runobjectmerger("m") end)
    objectreplacer = MenuEntry:New(utils,"Replace Object Editor Data",function(self) runobjectmerger("r") end)
    objectimporter = MenuEntry:New(utils,"Import Object Editor Data",function(self) runobjectmerger("i") end)
end
if haveext and grim.exists("grimext\\constantmerger.exe") then
    constantmerger = MenuEntry:New(utils,"Merge Constants Data",runconstantmerger)
end
if haveext and grim.exists("grimext\\triggermerger.exe") then
    triggermerger = MenuEntry:New(utils,"Merge Trigger Data",runtriggermerger)
end

function extabout()
    wehack.execprocess("starter.bat ./grimext\\GrimexManual.html")
end
if haveext then
	wehack.addmenuseparator(utils)
	aboutextensions = MenuEntry:New(utils,"About Grimex ...",extabout)
end


if haveumswe then
	ums_enabled = TogMenuEntry:New(ums,"Enable UMSWE",nil,false)
	ums_cat = TogMenuEntry:New(ums,"Custom Editor Categories",nil,false)
	ums_til = TogMenuEntry:New(ums,"Non Tileset Specific Objects",nil,false)
	ums_pat = TogMenuEntry:New(ums,"Custom Tile Pathability",nil,false)
	
	function unloadumswe()
		local umswehandle = wehack.getarchivehandle("umswe\\umswe.mpq")
		if umswehandle ~= 0 then
			wehack.closearchive(umswehandle)
			wehack.setarchivehandle("umswe\\umswe.mpq", 0)
		end
	end
	
	function getumsweargs()
		local umsargs = "";
		if (ums_enabled.checked) then
			umsargs = umsargs .. " umscore=1"
		else
			umsargs = umsargs .. " umscore=0"
		end
		if (ums_cat.checked) then
			umsargs = umsargs .. " umscategories=1"
		else
			umsargs = umsargs .. " umscategories=0"
		end
		if (ums_til.checked) then
			umsargs = umsargs .. " umstiles=1"
		else
			umsargs = umsargs .. " umstiles=0"
		end
		if (ums_pat.checked) then
			umsargs = umsargs .. " umspathing=1"
		else
			umsargs = umsargs .. " umspathing=0"
		end
		return umsargs
	end
	
	function toggleumswe()
		if not isstartup then
			unloadumswe()
			wehack.setwaitcursor(true)
			wehack.runprocess("grimext\\PatchGenerator.exe umswe\\umswecore.lua "..wehack.getlookupfolders().." umswe"..getumsweargs())
			wehack.setwaitcursor(false)
		end
	end
	
	function toggleumswecat()
		if ums_enabled.checked and not isstartup then
			unloadumswe()
			wehack.setwaitcursor(true)
			wehack.runprocess("grimext\\PatchGenerator.exe umswe\\umswecategories.lua "..wehack.getlookupfolders().." umswe"..getumsweargs())
			wehack.setwaitcursor(false)
		end
	end
	
	function toggleumswetil()
		if ums_enabled.checked and not isstartup then
			unloadumswe()
			wehack.setwaitcursor(true)
			wehack.runprocess("grimext\\PatchGenerator.exe umswe\\umswetilesets.lua "..wehack.getlookupfolders().." umswe"..getumsweargs())
			wehack.setwaitcursor(false)
		end
	end
	
	function toggleumswepat(newstate)
		if ums_enabled.checked and not isstartup then
			unloadumswe()
			wehack.setwaitcursor(true)
			wehack.runprocess("grimext\\PatchGenerator.exe umswe\\umswepathing.lua "..wehack.getlookupfolders().." umswe"..getumsweargs())
			wehack.setwaitcursor(false)
		end
	end
	
	ums_enabled.cb = toggleumswe
	ums_cat.cb = toggleumswecat
	ums_til.cb = toggleumswetil
	ums_pat.cb = toggleumswepat
	
	function categoryconfig()
		if wehack.showcategorydialog("umswe\\umswecategories.conf.lua") and ums_enabled.checked then
			if ums_cat.checked then
				unloadumswe()
				wehack.setwaitcursor(true)
				wehack.runprocess("grimext\\PatchGenerator.exe umswe\\umswecategories.lua "..wehack.getlookupfolders().." umswe"..getumsweargs())
				wehack.setwaitcursor(false)
			end
		end
	end
	
	function pathabilityconfig()
		unloadumswe()
		if wehack.showpathdialog("umswe\\umswepathing.conf.lua","umswe\\umswe.mpq") and ums_enabled.checked then
			if ums_pat.checked then
				wehack.setwaitcursor(true)
				wehack.runprocess("grimext\\PatchGenerator.exe umswe\\umswepathing.lua "..wehack.getlookupfolders().." umswe"..getumsweargs())
				wehack.setwaitcursor(false)
			end
		end
	end
	
	function umsweabout()
		wehack.showumsweabout("UMSWE 5.0")
	end
	
	function umswehelp()
		wehack.execprocess("starter.bat ./umswe\\UMSWEManual.html")
	end
	
	wehack.addmenuseparator(ums)
	ums_catconf = MenuEntry:New(ums,"Customize Editor Categories",categoryconfig)
	ums_pathconf = MenuEntry:New(ums,"Customize Tile Pathability",pathabilityconfig)
	ums_about = MenuEntry:New(ums,"About UMSWE ...",umsweabout)
	ums_help = MenuEntry:New(ums,"UMSWE Documentation ...",umswehelp)
end

isstartup = false
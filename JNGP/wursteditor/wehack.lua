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

whmenu = wehack.addmenu("Grimoire")
wh_window = TogMenuEntry:New(whmenu,"Start War3 with -window",nil,true)
wh_opengl = TogMenuEntry:New(whmenu,"Start War3 with -opengl",nil,false)
if not grim.isnewcompiler(path.."\\war3.exe") then
  wh_grimoire = TogMenuEntry:New(whmenu,"Start War3 with Grimoire",nil,true)
  wh_enablewar3err = TogMenuEntry:New(whmenu,"Enable war3err",nil,true)
  wh_enablejapi = TogMenuEntry:New(whmenu,"Enable japi",nil,false)
  --wh_machine = TogMenuEntry:New(whmenu,"Enable warmachine",nil,false)
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
wh_about = MenuEntry:New(whmenu,"About Grimoire ...",aboutpopup)

-- ##WurstScript##
havewurst = grim.exists("wurstscript\\wurstscript.exe")
if havewurst then
	wurstmenu = wehack.addmenu("WurstScript")
	
	function wurst_command()
		if wurst_b_enable.checked then
			return "wurstscript\\wurstscript_b.exe"
		else
			return "wurstscript\\wurstscript.exe"
		end
	end
	
	
	wurst_enable = TogMenuEntry:New(wurstmenu,"Enable WurstScript",nil,true)
	wurst_b_enable = TogMenuEntry:New(wurstmenu,"Use Wurst compilation server",nil,false)
	
	
	function wurst_compilationserver_start()
		wehack.execprocess("wurstscript\\wurstscript.exe -startServer")
	end
	
	function wurst_compilationserver_stop()
		wehack.execprocess("wurstscript\\wurstscript.exe -stopServer")
	end
	
	-- TODO
	--MenuEntry:New(wurstmenu,"Start Wurst compilation server ",wurst_compilationserver_start)
	--MenuEntry:New(wurstmenu,"Stop Wurst compilation server ",wurst_compilationserver_stop)
	
	wehack.addmenuseparator(wurstmenu)
	-- optimizer options
	wurst_optenable = TogMenuEntry:New(wurstmenu,"Enable Froptimizer",nil,false)
	wurst_localoptenable = TogMenuEntry:New(wurstmenu,"Enable (experimental) local optimizations",nil,false)
	wurst_inliner = TogMenuEntry:New(wurstmenu, "Enable Inliner",nil,false)
	
	wehack.addmenuseparator(wurstmenu)
	
	-- debug options
	wurst_stacktraces = TogMenuEntry:New(wurstmenu, "Enable stack-traces",nil,false)
	wurst_nodebug = TogMenuEntry:New(wurstmenu, "Disable debug messages",nil,false)
	wurst_debug = TogMenuEntry:New(wurstmenu,"Debug Mode",nil,false)
	
	wehack.addmenuseparator(wurstmenu)
	
	-- compiletime options
	wurst_compiletimefunctions  = TogMenuEntry:New(wurstmenu, "Run compiletime functions",nil,false)
	wurst_injectObjects  = TogMenuEntry:New(wurstmenu, "Inject compiletime objects",nil,false)
	
	wehack.addmenuseparator(wurstmenu)
	
	-- other tools
	
	
	
	function wurst_runfileexporter()
		curmap = wehack.findmappath()
		if curmap ~= "" then
			wehack.execprocess(wurst_command() .. " --extractImports \"" .. curmap .. "\"")
		else
			wehack.messagebox("No map loaded. Try saving the map first.","Wurst",false)
		end
	end
	
	MenuEntry:New(wurstmenu,"Extract all imported files",wurst_runfileexporter)

	wehack.addmenuseparator(wurstmenu)
	
	function wurstshowerr()
	  	wehack.execprocess(wurst_command() .. " --showerrors")
	end
	
	function wurstabout()
	  	wehack.execprocess(wurst_command() .. " --about")
	end
	
  -- TODO wurstshowerrm = MenuEntry:New(wurstmenu,"Show previous errors",wurstshowerr)
  wurstaboutm = MenuEntry:New(wurstmenu,"About WurstScript ...",wurstabout)
end





-- ##EndWurstScript##

-- ## Jasshelper ##
--Here I'll add the custom menu to jasshelper. moyack
jh_path = "vexorian"
havejh = grim.exists("vexorianjasshelper\\jasshelper.exe")
if havejh then
	jhmenu = wehack.addmenu("JassHelper")
	jh_enable = TogMenuEntry:New(jhmenu,"Enable JassHelper",nil,true)

	
	
	wehack.addmenuseparator(jhmenu)
	jh_debug = TogMenuEntry:New(jhmenu,"Debug Mode",nil,false)
	jh_disable = TogMenuEntry:New(jhmenu,"Disable vJass syntax",nil,false)
    jh_disableopt = TogMenuEntry:New(jhmenu,"Disable script optimization",nil,false)

	wehack.addmenuseparator(jhmenu)
	
	function jhshowerr()
	  	wehack.execprocess(jh_path.."jasshelper\\jasshelper.exe --showerrors")
	end
	
	function jhabout()
	  	wehack.execprocess(jh_path.."jasshelper\\jasshelper.exe --about")
	end
	
	jhshowerrm = MenuEntry:New(jhmenu,"Show previous errors",jhshowerr)
	jhaboutm = MenuEntry:New(jhmenu,"About JassHelper ...",jhabout)
	
	
	function jhshowhelp()
		jhsetpath()
		wehack.execprocess("starter.bat ./"..jh_path.."jasshelper\\jasshelpermanual.html")
	end
	
	jhhelp = MenuEntry:New(jhmenu, "JassHelper Documentation...", jhshowhelp)
end
-- # end jasshelper #

-- # begin sharpcraft #
haveSharpCraft = grim.exists("SharpCraft\\SharpCraft.exe")
if haveSharpCraft then
	sharpCraftMenu = wehack.addmenu("SharpCraft")
	sharpCraftEnable = TogMenuEntry:New(sharpCraftMenu,"Run with ShapCraft",nil,true)
end
-- # end sharpcraft #

-- # begin postproc #
local function postproc_createConfig()
	local this = {}

	this.assignments = {}
	this.sections = {}

	function this:readFromFile(path, ignoreNotFound)
		assert(path, 'configParser: no path passed')

		local f = io.open(path, 'r')

		if not ignoreNotFound then
			assert(f, 'configParser: cannot open file '..tostring(path))
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
					val = val:match("\"(.*)\"")
				end

				if (curSection ~= nil) then
					curSection.assignments[name] = val
				else
					this.assignments[name] = val
				end
			end
		end

		f:close()
	end

	return this
end

local config = postproc_createConfig()

local configPath = 'jasshelper.conf'

config:readFromFile(configPath)

local config_postprocSection = config.sections['postproc']

local postproc_dir
local postproc_logPath
local postproc_outputPathNoExt

local postproc_onStartupPath
local postproc_onSavePath
local postproc_onTestmapPath
local postproc_requestInfo

local function tryloadfile(path)
	if (path == nil) then
		return nil
	end

	return loadfile(path)
end

havePostproc = (config_postprocSection ~= nil)

if (config_postprocSection ~= nil) then
	postproc_dir = config_postprocSection.assignments['postprocDir']
	postproc_logPath = config_postprocSection.assignments['logPath']
	postproc_outputPathNoExt = config_postprocSection.assignments['outputPathNoExt']

	if (postproc_dir ~= nil) then
		if not postproc_dir:match('\\$') then
			postproc_dir = postproc_dir..'\\'
		end

		postproc_onStartupPath = postproc_dir..'JNGP\\jngp_onStartup.lua'
		postproc_onSavePath = postproc_dir..'JNGP\\jngp_onSave.lua'
		postproc_onTestmapPath = postproc_dir..'JNGP\\jngp_onTestmap.lua'
		postproc_requestInfo = tryloadfile(postproc_dir..'JNGP\\jngp_requestInfo.lua')

		local t = {postproc_onStartupPath, postproc_onSavePath, postproc_onTestmapPath}
		local t2 = {}

		for i = 1, #t, 1 do
			if (tryloadfile(t[i]) == nil) then
				t2[#t2 + 1] = t[i]
			end
		end

		if (#t2 > 0) then
			wehack.messagebox('warning: found postproc config section but could not load files:\n'..table.concat(t2, '\n'))
		end
	end
end

local postproc_startup = tryloadfile(postproc_onStartupPath)

if (postproc_startup ~= nil) then
	postproc_startup(config, {wc3path = path, configPath = configPath, postprocDir = postproc_dir, logPath = postproc_logPath, outputPathNoExt = postproc_outputPathNoExt})
end

if havePostproc then
	postprocMenu = wehack.addmenu("postproc")
	postprocEnable = TogMenuEntry:New(postprocMenu, "Enable", nil, true)

	wehack.addmenuseparator(postprocMenu)

	postprocBlockTools = TogMenuEntry:New(postprocMenu, "Block other compiling tools", nil, false)

	postprocRunMapAuto = TogMenuEntry:New(postprocMenu, "Use last compiled map when testing", nil, false)

	wehack.addmenuseparator(postprocMenu)

	local function showPaths()
		local t = {}

		t[#t + 1] = "postprocDir="..postproc_dir
		t[#t + 1] = "logPath="..postproc_logPath
		t[#t + 1] = "outputPathNoExt="..postproc_outputPathNoExt

		wehack.messagebox(table.concat(t, '\n'), 'postproc paths')
	end

	postprocShowPaths = MenuEntry:New(postprocMenu, "Show current paths", showPaths)

	local function showConfig()
		os.execute("start \"\" \""..postproc_dir.."config.conf".."\"")
	end

	postprocShowConfig = MenuEntry:New(postprocMenu, "Show config", showConfig)

	local function showConfigTools()
		os.execute("start \"\" \""..postproc_dir.."configTools.slk".."\"")
	end

	postprocShowConfigTools = MenuEntry:New(postprocMenu, "Show tools", showConfigTools)

	local function showJasshelperConf()
		os.execute("start \"\" \"".."jasshelper.conf".."\"")
	end

	postprocShowJasshelperConf = MenuEntry:New(postprocMenu, "Show jasshelper.conf", showJasshelperConf)

	local function showLog()
		os.execute("start \"\" \""..postproc_logPath.."\"")
	end

	postprocShowLog = MenuEntry:New(postprocMenu, "Show log", showLog)

	local function runMap()
		if (postproc_requestInfo == nil) then
			wehack.messagebox('could not open requestInfo')

			return
		end

		local t = postproc_requestInfo()

		local mapPath = t.getLastOutputPath(postproc_dir)

		local cmdline = "\""..path.."\\War3.exe\"".." -loadfile \""..mapPath.."\""

		testmap(cmdline)
	end

	wehack.addmenuseparator(postprocMenu)

	postprocRunMap = MenuEntry:New(postprocMenu, "Run last compiled map", runMap)
end
-- # end postproc #

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
    --local curval = grim.getregpair("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\open\\command\\","")
    --if curval ~= 0 then
    --    if disable then
    --        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\open\\command\\","",string.gsub(curval, "%%L", "%%1"))
    --    else
    --        grim.setregstring("HKEY_CLASSES_ROOT\\WorldEdit."..filetype.."\\shell\\open\\command\\","",string.gsub(curval, "%%1", "%%L"))
    --    end
    --end
    
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
	--if havewurst and wurst_enable.checked and not mapvalid then
	--	return
	--end
	--wehack.messagebox(cmdline)
	--mappath = strsplit(" ",cmdline)[2]
	--compilemap_path(mappath)
	
	if haveSharpCraft and sharpCraftEnable.checked then
		-- remove default .exe
		local pos = string.find(cmdline, ".exe")
		cmdline = string.sub(cmdline, 4 + pos)
		-- replace with SharpCraft exe
		cmdline = "SharpCraft\\SharpCraft.exe -game " .. cmdline
	end
	
	if wh_opengl.checked then
		cmdline = cmdline .. " -opengl"
	end
	if wh_window.checked then
		cmdline = cmdline .. " -window"
	end

	if (havePostproc and postprocRunMapAuto.checked) then
		local postproc_testmap = tryloadfile(postproc_onTestmapPath)

		if (postproc_testmap ~= nil) then
			local success = false

			success, cmdline = postproc_testmap(config, {cmdline = cmdline, wc3path = path, configPath = configPath, postprocDir = postproc_dir, logPath = postproc_logPath, outputPathNoExt = postproc_outputPathNoExt})
		end
	end

	wehack.execprocess(cmdline)
end

function compilemap_path(mappath)
	if mappath == "" then
		showfirstsavewarning()
		return
	end
	map = wehack.openarchive(mappath,15)
	wehack.extractfile("wurstscript\\common.j","scripts\\common.j")
	wehack.extractfile("wurstscript\\Blizzard.j","scripts\\Blizzard.j")
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

	local postproc_override = false

	if (havePostproc and postprocEnable.checked) then
		local postproc_save = tryloadfile(postproc_onSavePath)

		if (postproc_save ~= nil) then
			local success = false

			success, postproc_override = postproc_save(config, {mapPath = mappath, wc3path = path, configPath = configPath, postprocDir = postproc_dir, logPath = postproc_logPath, outputPathNoExt = postproc_outputPathNoExt})

			mapvalid = mapvalid and success
		end
	end

	if (not postprocBlockTools.checked and not postproc_override) then
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
			toolresult = 0
			toolresult = wehack.runprocess2(cmdline)
			if toolresult == 0 then 
				mapvalid = true
			else
				mapvalid = false
			end
		end
		
		if havewurst and wurst_enable.checked then
			cmdline = wurst_command()
			cmdline = cmdline .. " -gui"
			if wurst_debug.checked then
				--cmdline = cmdline .. " --debug"
			end
			--if wurst_disable.checked then
				--cmdline = cmdline .. " --nopreprocessor"
			--end
			if wurst_optenable.checked then
				cmdline = cmdline .. " -opt"
			end
			if wurst_localoptenable.checked then
				cmdline = cmdline .. " -localOptimizations"
			end
			if wurst_inliner.checked then
				cmdline = cmdline .. " -inline"
			end
			if wurst_stacktraces.checked then
				cmdline = cmdline  .. " -stacktraces"
			end
			if wurst_nodebug.checked then
				cmdline = cmdline  .. " -nodebug"
			end
			if wurst_compiletimefunctions.checked then
				cmdline = cmdline .. " -runcompiletimefunctions"
			end
			if wurst_injectObjects.checked then
				cmdline = cmdline .. " -injectobjects"
			end
			
			-- cmdline = cmdline .. " -lib ./wurstscript/lib/"
			cmdline = cmdline .. " wurstscript\\common.j wurstscript\\Blizzard.j \"" .. mappath .."\""
			
			toolresult = 0
	--		if wurst_fast ~= nil and wurst_fast.checked then
	--			toolresult = wehack.runjasshelper(wurst_debug.checked, wurst_disable.checked, "jasshelper\\common.j", "jasshelper\\blizzard.j", mappath, "")
	--		else
				toolresult = wehack.runprocess2(cmdline)
	--		end
			if toolresult == 0 then 
				mapvalid = true
			else
				wehack.messagebox("Could not run Wurst.","Wurst",false)
				mapvalid = false
			end
		end
	end
end

function compilemap()
	mappath = wehack.findmappath()
	compilemap_path(mappath)
end

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
    grim.openlink("http://www.wc3campaigns.net")
end
if haveext then
	wehack.addmenuseparator(utils)
  aboutextensions = MenuEntry:New(utils,"About Grimex ...",extabout)
end



isstartup = false
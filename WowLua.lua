--[[--------------------------------------------------------------------------
  Copyright (c) 2007, James Whitehead II  
  All rights reserved.
  
  WowLua is an interactive interpreter for World of Warcraft
--------------------------------------------------------------------------]]--

-- TODO:
-- * Make the scroll bars hide/show as necessary
-- * Implement each button as required
-- * Make line numbers line up with soft-wrapped lines
-- * Disable selection of line numbers. Actually, would it be possible to make
--   it select lines a la most other edtiors?
-- * There seems to be a missing background texture in the upper-left 6th or so of the window
-- * Resizing the window should grow the edit box vertically and leave the output window static.
-- * Profit!!!
 
WowLua = {
	VERSION = "WowLua 1.0 Interactive Interpreter",
}

WowLuaDB = {
	pages = { ["Untitled 1"] = "", [1] = "Untitled 1"},
	currentPage = 1,
	untitled = 1,
}

local function wowpad_print(...)
	local out = ""
	for i=1,select("#", ...) do
		-- Comma seperate values
		if i > 1 then
			out = out .. ", "
		end

		out = out .. tostring(select(i, ...))
	end
	WowLuaFrameOutput:AddMessage("|cff999999" .. out .. "|r")
end

if not print then
	print = wowpad_print
end

local function processSpecialCommands(txt)
	if txt == "/reload" then
		ReloadUI()
		return true
	elseif txt == "/reset" then
		WowLuaFrame:ClearAllPoints()
		WowLuaFrame:SetPoint("CENTER")
		WowLuaFrame:SetWidth(640)
		WowLuaFrame:SetHeight(512)
		WowLuaFrameResizeBar:ClearAllPoints()
		WowLuaFrameResizeBar:SetPoint("TOPLEFT", 14, -220)
		WowLuaFrameResizeBar:SetPoint("TOPRIGHT", 0, -220)
		return true
	end
end

function WowLua:ProcessLine(text)
	WowLuaFrameCommandEditBox:SetText("")
	
	if processSpecialCommands(text) then
		return
	end
	
	-- escape any color codes:
	local output = text:gsub("\124", "\124\124")

	WowLuaFrameOutput:AddMessage(WowLuaFrameCommandPrompt:GetText() .. output)

	WowLuaFrameCommandEditBox:AddHistoryLine(output)

	-- If they're using "= value" syntax, just print it
	text = text:gsub("^%s*=%s*(.+)", "print(%1)")

	-- Store this command into self.cmd in case we have multiple lines
	if self.cmd then
		self.cmd = self.cmd .. "\n" .. text
		self.orig = self.orig .. "\n" .. text
	else
		self.cmd = text
		self.orig = text
	end

	-- Trim the command before we run it
	self.cmd = string.trim(self.cmd)

	-- Process the current command
	local func,err = loadstring(self.cmd)

	-- Fail to compile?  Give it a return
	-- Check to see if this just needs a return in front of it
	if not func then
		local newfunc,newerr = loadstring("print(" .. self.cmd .. ")")
		if newfunc then
			func,err = newfunc,newerr
		end
	end

	if not func then
		-- Check to see if this is just an unfinished block
		if err:sub(-7, -1) == "'<eof>'" then
			-- Change the prompt
			WowLuaFrameCommandPrompt:SetText(">> ")
			return
		end

		WowLuaFrameOutput:AddMessage("|cffff0000" .. err .. "|r")
		self.cmd = nil
		WowLuaFrameCommandPrompt:SetText("> ")
	else
		-- Make print a global function
		local old_print = print
		print = wowpad_print

		-- Call the function
		local succ,err = pcall(func)

		-- Restore the value of print
		print = old_print

		if not succ then
			WowLuaFrameOutput:AddMessage("|cffff0000" .. err .. "|r")
		end

		self.cmd = nil
		WowLuaFrameCommandPrompt:SetText("> ")
	end
end

function WowLua.RunScript(text)
	-- escape any color codes:
	local output = text:gsub("\124", "\124\124")

	if text == "/reload" then 
		ReloadUI()
	end

	-- If they're using "= value" syntax, just print it
	text = text:gsub("^%s*=%s*(.+)", "print(%1)")

	-- Trim the command before we run it
	text = string.trim(text)

	-- Process the current command
	local func,err = loadstring(text, "WowLua")

	if not func then
		WowLuaFrameOutput:AddMessage("|cffff0000" .. err .. "|r")
		return false, err
	else
		-- Make print a global function
		local old_print = print
		print = wowpad_print

		-- Call the function
		local succ,err = pcall(func)

		-- Restore the value of print
		print = old_print

		if not succ then
			WowLuaFrameOutput:AddMessage("|cffff0000" .. err .. "|r")
			return false, err
		end
	end

	return true
end

function WowLua.Initialize(self)
	WowLua.OnSizeChanged(self)
	table.insert(UISpecialFrames, "WowLuaFrame")
			PlaySound("igMainMenuOpen");
end

local tooltips = {
	["New"] = "Create a new script page",
	["Open"] = "Open an existing script page",
	["Save As"] = "Save the current page with a name",
	["Undo"] = "Revert to the last saved version",
	["Delete"] = "Delete the current page",
	["Lock"] = "Locks/unlocks the current page from being changed",
	["Previous"] = "Navigate back one page",
	["Next"] = "Navigate forward one page",
	["Run"] = "Run the current script",
}	
	
function WowLua.Button_OnEnter(self)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOM");
	local operation = self:GetName():match("WowLuaButton_(.+)"):gsub("_", " ")
	GameTooltip:SetText(operation)
	if tooltips[operation] then
		GameTooltip:AddLine(tooltips[operation], 1, 1, 1)
	end
	GameTooltip:Show();
end

function WowLua.Button_OnLeave(self)
	GameTooltip:Hide()
end

function WowLua.Button_OnClick(self)
	local operation = self:GetName():match("WowLuaButton_(.+)")
	if operation == "New" then
		WowLua.NewPage()
	elseif operation == "Open" then
		WowLua.OpenPage()
	elseif operation == "Save_As" then
		WowLua.SavePageAs()
	elseif operation == "Undo" then
		WowLua.Undo()
	elseif operation == "Delete" then
		WowLua.DeletePage()
	elseif operation == "Lock" then
		WowLua.LockPage()
	elseif operation == "Previous" then
		WowLua.PreviousPage()
	elseif operation == "Next" then
		WowLua.NextPage()
	elseif operation == "Run" then
		WowLua.RunPage()
	end
end

function WowLua.CommitPage()
	local page = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaDB.pages[page] = WowLuaFrameEditBox:GetText()
end

function WowLua.SetPrevNextStates()
	local tex = WowLuaButton_Previous:GetNormalTexture()
	local cPage = WowLuaDB.currentPage
	if cPage == 1 then
		WowLuaButton_Previous:Disable()
		SetDesaturation(tex, true)
	else
		WowLuaButton_Previous:Enable()
		SetDesaturation(tex, false)
	end
	
	tex = WowLuaButton_Next:GetNormalTexture()
	if cPage == #WowLuaDB.pages then
		WowLuaButton_Next:Disable()
		SetDesaturation(tex, true)
	else
		WowLuaButton_Next:Enable()
		SetDesaturation(tex, false)
	end
end

function WowLua.NewPage()
	WowLua.CommitPage()
	WowLuaFrameEditBox:SetText("")
	WowLuaDB.untitled = WowLuaDB.untitled + 1
	WowLuaDB.pages[#WowLuaDB.pages + 1] = string.format("Untitled %d", WowLuaDB.untitled)
	WowLuaDB.currentPage = #WowLuaDB.pages
	WowLua.SetPrevNextStates()
	WowLua.SetTitle()
end

function WowLua.OpenPage()
end

function WowLua.OpenDropDownOnLoad(self)
	--UIDropDownMenu_Initialize(self, WowLua.
end

function WowLua.SavePageAs()
end

function WowLua.Undo()
	local page = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaFrameEditBox:SetText(WowLuaDB.pages[page])
end

function WowLua.DeletePage()
	if #WowLuaDB.pages == 1 then
		WowLua.NewPage()
		WowLua.PreviousPage()
	end
	local page = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaDB.pages[page] = nil
	table.remove(WowLuaDB.pages, WowLuaDB.currentPage)
	if WowLuaDB.currentPage > 1 then
		WowLuaDB.currentPage = WowLuaDB.currentPage - 1
	end
	local page = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaFrameEditBox:SetText(WowLuaDB.pages[page])
	WowLua.SetPrevNextStates()
	WowLua.SetTitle()
end

function WowLua.LockPage()
end

function WowLua.PreviousPage()
	local cPage = WowLuaDB.pages[WowLuaDB.currentPage]
	local text = WowLuaFrameEditBox:GetText()
	WowLuaDB.pages[cPage] = text
	WowLuaDB.currentPage = WowLuaDB.currentPage - 1
	cPage = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaFrameEditBox:SetText(WowLuaDB.pages[cPage] or "")
	WowLua.SetPrevNextStates()
	WowLua.SetTitle()
end

function WowLua.NextPage()
	local cPage = WowLuaDB.pages[WowLuaDB.currentPage]
	local text = WowLuaFrameEditBox:GetText()
	WowLuaDB.pages[cPage] = text
	WowLuaDB.currentPage = WowLuaDB.currentPage + 1
	cPage = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaFrameEditBox:SetText(WowLuaDB.pages[cPage] or "")
	WowLua.SetPrevNextStates()
	WowLua.SetTitle()
end

function WowLua.RunPage()
	-- Run the script, if there is an error then highlight it
	local text = WowLuaFrameEditBox:GetText()
	if text then
		local succ,err = WowLua.RunScript(text)
		if not succ then
			local chunkName,lineNum = err:match("(%b[]):(%d+):")
			lineNum = tonumber(lineNum)
			WowLua.UpdateLineNums(lineNum)

			-- Highlight the text in the editor by finding the char of the line number we're on
			text = WowLua.indent.coloredGetText(WowLuaFrameEditBox)

			local curLine,start = 1,1
			while curLine < lineNum do
				local s,e = text:find("\n", start)
				start = e + 1
				curLine = curLine + 1
			end

			local nextLine = select(2, text:find("\n", start))
			
			WowLuaFrameEditBox:SetFocus()
			WowLuaFrameEditBox:SetCursorPosition(start - 1)
		end
		local page = WowLuaDB.pages[WowLuaDB.currentPage]
		WowLuaDB.pages[page] = text
	end
end

function WowLua.SetTitle()
	local pageName = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaFrameTitle:SetText(pageName.." - WowLua Editor")
end

local function slashHandler(txt)
	local page = WowLuaDB.pages[WowLuaDB.currentPage]
	WowLuaFrameEditBox:SetText(WowLuaDB.pages[page] or "")
	if WowLuaDB.currentPage == 1 then
		WowLuaButton_Previous:Disable()
		SetDesaturation(WowLuaButton_Previous:GetNormalTexture(),true)
	end
	if WowLuaDB.currentPage == #WowLuaDB.pages then 
		WowLuaButton_Next:Disable() 
		SetDesaturation(WowLuaButton_Next:GetNormalTexture(),true)
	end
	--WowLua:CreateFrame()
	WowLuaFrame:Show()
	WowLua.SetTitle()
	
	if processSpecialCommands(txt) then
		return
	end

	if txt:match("%S") then
		WowLua:ProcessLine(txt)
	end

	WowLuaFrameCommandEditBox:SetFocus()
end

SLASH_WOWLUA1 = "/wowlua"
SLASH_WOWLUA2 = "/lua"
SlashCmdList["WOWLUA"] = slashHandler

function WowLua.OnSizeChanged(self)
	-- The first graphic is offset 13 pixels to the right
	local width = self:GetWidth() - 13
	local bg2w,bg3w,bg4w = 0,0,0

	-- Resize bg2 up to 256 width
	local bg2w = width - 256
	if bg2w > 256 then
		bg3w = bg2w - 256
		bg2w = 256
	end

	if bg3w > 256 then
		bg4w = bg3w - 256
		bg3w = 256
	end

	local bg2 = WowLuaFrameBG2
	local bg3 = WowLuaFrameBG3
	local bg4 = WowLuaFrameBG4

	if bg2w > 0 then
		bg2:SetWidth(bg2w)
		bg2:SetTexCoord(0, (bg2w / 256), 0, 1)
		bg2:Show()
	else
		bg2:Hide()
	end
		
	if bg3w and bg3w > 0 then
		bg3:SetWidth(bg3w)
		bg3:SetTexCoord(0, (bg3w / 256), 0, 1)
		bg3:Show()
	else
		bg3:Hide()
	end

	if bg4w and bg4w > 0 then
		bg4:SetWidth(bg4w)
		bg4:SetTexCoord(0, (bg4w / 256), 0, 1)
		bg4:Show()
	else
		bg4:Hide()
	end

	if WowLuaFrameResizeBar and false then
		local parent = WowLuaFrameResizeBar:GetParent()
		local cursorY = select(2, GetCursorPosition())
		local newPoint = select(5, WowLuaFrameResizeBar:GetPoint())
		local maxPoint = parent:GetHeight() - 175; 

		if newPoint < 100 then
			newPoint = 100
		elseif newPoint > maxPoint then
			newPoint = maxPoint
		end

		WowLuaFrameResizeBar:ClearAllPoints()
		WowLuaFrameResizeBar:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 14, newPoint)
		WowLuaFrameResizeBar:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, newPoint)
	end
end

function WowLua.ResizeBar_OnMouseDown(self, button)
	self.cursorStart = select(2, GetCursorPosition())
	self.anchorStart = select(5, self:GetPoint())
	self:SetScript("OnUpdate", WowLua.ResizeBar_OnUpdate)
end

function WowLua.ResizeBar_OnMouseUp(self, button)
	self:SetScript("OnUpdate", nil)
end

function WowLua.ResizeBar_OnUpdate(self, elapsed)
	local parent = self:GetParent()
	local cursorY = select(2, GetCursorPosition())
	local newPoint = self.anchorStart - (self.cursorStart - cursorY)/self:GetEffectiveScale()
	local maxPoint = parent:GetHeight() - 175; 

	if newPoint < 100 then
		newPoint = 100
	elseif newPoint > maxPoint then
		newPoint = maxPoint
	end

	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 14, newPoint)
	self:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, newPoint)
end

function WowLua.OnVerticalScroll(scrollFrame)
	local offset = scrollFrame:GetVerticalScroll();
	local scrollbar = getglobal(scrollFrame:GetName().."ScrollBar");
	
	scrollbar:SetValue(offset);
	local min, max = scrollbar:GetMinMaxValues();
	local display = false;
	if ( offset == 0 ) then
	    getglobal(scrollbar:GetName().."ScrollUpButton"):Disable();
	else
	    getglobal(scrollbar:GetName().."ScrollUpButton"):Enable();
	    display = true;
	end
	if ((scrollbar:GetValue() - max) == 0) then
	    getglobal(scrollbar:GetName().."ScrollDownButton"):Disable();
	else
	    getglobal(scrollbar:GetName().."ScrollDownButton"):Enable();
	    display = true;
	end
	if ( display ) then
		scrollbar:Show();
	else
		scrollbar:Hide();
	end
end

function WowLua.UpdateLineNums(highlightNum)
	-- highlightNum is the line number indicated by the error message
	if highlightNum then 
		WowLua.highlightNum = highlightNum
	else
		highlightNum = WowLua.highlightNum
	end

	-- Since we know this is FAIAP enabled, we need to pass true in order
	-- to get the raw values
	local editbox = WowLuaFrameEditBox
	local linebox = WowLuaFrameLineNumEditBox
	local linetest = WowLuaFrameEditBoxLineTest
	local linescroll = WowLuaFrameLineNumScrollFrame

	local width = editbox:GetWidth() 
	local text = editbox:GetText(true)

	local linetext = ""
	local count = 1
	for line in text:gmatch("([^\n]*\n?)") do
		if #line > 0 then
			if count == highlightNum then
				linetext = linetext .. "|cFFFF1111" .. count .. "|r" .. "\n"
			else
				linetext = linetext .. count .. "\n"
			end
			count = count + 1

			-- Check to see if the line of text spans more than one actual line
			linetest:SetText(line:gsub("|", "||"))
			local testwidth = linetest:GetWidth()
			if testwidth >= width then
				linetext = linetext .. string.rep("\n", testwidth / width) 
			end
		end
	end

	if text:sub(-1, -1) == "\n" then
		linetext = linetext .. count .. "\n"
		count = count + 1
	end

	-- Make the line number frame wider as necessary
	local offset = tostring(count):len() * 10
	linescroll:ClearAllPoints()
	linescroll:SetPoint("TOPLEFT", WowLuaFrame, "TOPLEFT", 18, -74)
	linescroll:SetPoint("BOTTOMRIGHT", WowLuaFrameResizeBar, "TOPLEFT", 15 + offset, -4)

	linebox:SetText(linetext)
	linetest:SetText(text)
end

local function canScroll(scroll, direction)
	local num, displayed, currScroll = scroll:GetNumMessages(),
					   scroll:GetNumLinesDisplayed(),
					   scroll:GetCurrentScroll();
	if ( direction == "up" and
	     (
		num == displayed or
		num == ( currScroll + displayed )
	      )
	) then
		return false;
	elseif ( direction == "down" and currScroll == 0 ) then
		return false;
	end
	return true;
end

function WowLua.UpdateScrollingMessageFrame(frame)
	local name = frame:GetName();
	local display = false;
	
	if ( canScroll(frame, "up") ) then
		getglobal(name.."UpButton"):Enable();
		display = true;
	else
		getglobal(name.."UpButton"):Disable();
	end
	
	if ( canScroll(frame, "down") ) then
		getglobal(name.."DownButton"):Enable();
		display = true;
	else
		getglobal(name.."DownButton"):Disable();
	end
	
	if ( display ) then
		getglobal(name.."UpButton"):Show();
		getglobal(name.."DownButton"):Show();
	else
		getglobal(name.."UpButton"):Hide();
		getglobal(name.."DownButton"):Hide();
	end
end

local scrollMethods = {
	["line"] = { ["up"] = "ScrollUp", ["down"] = "ScrollDown" },
	["page"] = { ["up"] = "PageUp", ["down"] = "PageDown" },
	["end"] = { ["up"] = "ScrollToTop", ["down"] = "ScrollToBottom" },
};

function WowLua.ScrollingMessageFrameScroll(scroll, direction, type)
	-- Make sure we can scroll first
	if ( not canScroll(scroll, direction) ) then
		return;
	end
	local method = scrollMethods[type][direction];
	scroll[method](scroll);
end

function WowLua.OnTextChanged(self)
	self.highlightNum = nil
end

function WowLua.OnCursorChanged(self)
	WowLua.dirty = true
end


WowLuaLocals = {}
local L = WowLuaLocals

SLASH_WOWLUA1 = "/wowlua"
SLASH_WOWLUA2 = "/lua"

L.NEW_PAGE_TITLE = "Untitled %d"
L.RELOAD_COMMAND = "/reload"
L.RESET_COMMAND  = "/reset"

L.TOOLTIPS = {
	["New"] = { name = "New", text = "Create a new script page" },
	["Open"] = { name = "Open", text = "Open an existing script page" },
	["Save"] = { name = "Save", text = "Save the current page\n\nHint: You can shift-click this button to rename a page" },
	["Undo"] = { name = "Undo", text = "Revert to the last saved version" },
	["Delete"] = { name = "Delete", text = "Delete the current page" },
	["Lock"] = { name = "Lock", text = "This page is unlocked to allow changes. Click to lock." },
	["Unlock"] = { name = "Unlock", text = "This page is locked to prevent changes. Click to unlock." },
	["Previous"] = { name = "Previous", text = "Navigate back one page" },
	["Next"] = { name = "Next", text = "Navigate forward one page" },
	["Run"] = { name = "Run", text = "Run the current script" },
}	
	
L.OPEN_MENU_TITLE = "Select a Script"
L.SAVE_AS_TEXT = "Save %s with the following name:"
L.UNSAVED_TEXT = "You have unsaved changes on this page that will be lost if you navigate away from it.  Continue?"
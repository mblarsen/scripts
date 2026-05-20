use framework "AppKit"
use scripting additions

-- Maximize the current/frontmost window inside the visible screen area,
-- leaving configurable padding on each side.
--
-- Default padding values, in points:
property defaultLeftPadding : 32
property defaultTopPadding : 32
property defaultRightPadding : 32
property defaultBottomPadding : 32

-- Usage:
--   osascript max-current-window-with-padding.applescript
--   osascript max-current-window-with-padding.applescript 32
--   osascript max-current-window-with-padding.applescript 32 32 32 32
--
-- Arguments, if provided:
--   1 number  = same padding for all sides
--   4 numbers = left top right bottom
--
-- The app/tool that runs this script needs Accessibility permission in
-- System Settings → Privacy & Security → Accessibility.

on run argv
	set {leftPadding, topPadding, rightPadding, bottomPadding} to paddingValues(argv)

	set screenInfo to mainVisibleScreenInfo()
	set visibleLeft to item 1 of screenInfo
	set visibleTop to item 2 of screenInfo
	set visibleWidth to item 3 of screenInfo
	set visibleHeight to item 4 of screenInfo

	set targetLeft to visibleLeft + leftPadding
	set targetTop to visibleTop + topPadding
	set targetWidth to visibleWidth - leftPadding - rightPadding
	set targetHeight to visibleHeight - topPadding - bottomPadding

	if targetWidth < 1 or targetHeight < 1 then
		error "Padding is too large for the visible screen area."
	end if

	set targetLeft to round targetLeft rounding down
	set targetTop to round targetTop rounding down
	set targetWidth to round targetWidth rounding down
	set targetHeight to round targetHeight rounding down

	tell application "System Events"
		set frontProcess to first application process whose frontmost is true
		set frontAppName to name of frontProcess

		tell frontProcess
			if not (exists window 1) then error frontAppName & " has no window to resize."

			try
				set frontWindow to first window whose value of attribute "AXMain" is true
			on error
				set frontWindow to window 1
			end try

			set position of frontWindow to {targetLeft, targetTop}
			set size of frontWindow to {targetWidth, targetHeight}
		end tell
	end tell
end run

on paddingValues(argv)
	set argCount to count of argv

	if argCount = 0 then
		return {defaultLeftPadding, defaultTopPadding, defaultRightPadding, defaultBottomPadding}
	else if argCount = 1 then
		set allPadding to parsePadding(item 1 of argv)
		return {allPadding, allPadding, allPadding, allPadding}
	else if argCount = 4 then
		return {parsePadding(item 1 of argv), parsePadding(item 2 of argv), parsePadding(item 3 of argv), parsePadding(item 4 of argv)}
	else
		error "Usage: osascript max-current-window-with-padding.applescript [allPadding | left top right bottom]"
	end if
end paddingValues

on parsePadding(rawValue)
	try
		set padding to rawValue as number
	on error
		error "Padding must be a number: " & rawValue
	end try

	if padding < 0 then error "Padding must be zero or greater: " & rawValue
	return padding
end parsePadding

on mainVisibleScreenInfo()
	set mainScreen to current application's NSScreen's mainScreen()
	set visibleFrame to (mainScreen's visibleFrame()) as list
	set fullFrame to (mainScreen's frame()) as list

	set visibleOrigin to item 1 of visibleFrame
	set visibleSize to item 2 of visibleFrame
	set fullOrigin to item 1 of fullFrame
	set fullSize to item 2 of fullFrame

	set visibleLeft to item 1 of visibleOrigin
	set visibleBottom to item 2 of visibleOrigin
	set visibleWidth to item 1 of visibleSize
	set visibleHeight to item 2 of visibleSize
	set fullBottom to item 2 of fullOrigin
	set fullHeight to item 2 of fullSize

	-- Cocoa screen coordinates start at the bottom-left; accessibility window
	-- positions start at the top-left. Convert the visible frame's top edge.
	set visibleTop to (fullBottom + fullHeight) - (visibleBottom + visibleHeight)

	return {visibleLeft, visibleTop, visibleWidth, visibleHeight}
end mainVisibleScreenInfo

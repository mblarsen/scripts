use framework "AppKit"
use scripting additions

-- Place the current/frontmost window into the left or right split position
-- inside the visible screen area, with explicit outer padding and center gap.
--
-- Usage:
--   osascript split-current-window-with-padding.applescript left top right bottom gap position
--
-- Arguments, all required, in points unless noted:
--   left     outer padding from the visible screen's left edge
--   top      outer padding from the visible screen's top edge
--   right    outer padding from the visible screen's right edge
--   bottom   outer padding from the visible screen's bottom edge
--   gap      total gap between left and right split windows
--   position 1 = left split, 2 = right split
--
-- Example:
--   osascript split-current-window-with-padding.applescript 200 32 32 32 24 1
--   osascript split-current-window-with-padding.applescript 200 32 32 32 24 2
--
-- The split line is the visible screen midpoint. The gap is centered on that
-- midpoint, so a 24pt gap leaves 12pt on each side of the midpoint.
--
-- The app/tool that runs this script needs Accessibility permission in
-- System Settings → Privacy & Security → Accessibility.

on run argv
	set {leftPadding, topPadding, rightPadding, bottomPadding, centerGap, splitPosition} to argumentsFrom(argv)

	set screenInfo to mainVisibleScreenInfo()
	set visibleLeft to item 1 of screenInfo
	set visibleTop to item 2 of screenInfo
	set visibleWidth to item 3 of screenInfo
	set visibleHeight to item 4 of screenInfo

	set halfWidth to visibleWidth / 2
	set halfGap to centerGap / 2

	if splitPosition = 1 then
		set targetLeft to visibleLeft + leftPadding
		set targetWidth to halfWidth - leftPadding - halfGap
	else
		set targetLeft to visibleLeft + halfWidth + halfGap
		set targetWidth to halfWidth - rightPadding - halfGap
	end if

	set targetTop to visibleTop + topPadding
	set targetHeight to visibleHeight - topPadding - bottomPadding

	if targetWidth < 1 or targetHeight < 1 then
		error "Padding/gap values are too large for the visible screen area."
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

on argumentsFrom(argv)
	if (count of argv) is not 6 then
		error "Usage: osascript split-current-window-with-padding.applescript left top right bottom gap position"
	end if

	set leftPadding to parseNonNegativeNumber(item 1 of argv, "left")
	set topPadding to parseNonNegativeNumber(item 2 of argv, "top")
	set rightPadding to parseNonNegativeNumber(item 3 of argv, "right")
	set bottomPadding to parseNonNegativeNumber(item 4 of argv, "bottom")
	set centerGap to parseNonNegativeNumber(item 5 of argv, "gap")
	set splitPosition to parsePosition(item 6 of argv)

	return {leftPadding, topPadding, rightPadding, bottomPadding, centerGap, splitPosition}
end argumentsFrom

on parseNonNegativeNumber(rawValue, label)
	try
		set parsedValue to rawValue as number
	on error
		error label & " must be a number: " & rawValue
	end try

	if parsedValue < 0 then error label & " must be zero or greater: " & rawValue
	return parsedValue
end parseNonNegativeNumber

on parsePosition(rawValue)
	try
		set parsedPosition to rawValue as integer
	on error
		error "position must be 1 or 2: " & rawValue
	end try

	if parsedPosition is not 1 and parsedPosition is not 2 then error "position must be 1 or 2: " & rawValue
	return parsedPosition
end parsePosition

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

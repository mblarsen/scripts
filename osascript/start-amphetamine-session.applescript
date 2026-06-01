use scripting additions

-- Start an Amphetamine session for the provided number of hours.
-- Usage:
--   osascript start-amphetamine-session.applescript 3

on run argv
	if (count of argv) is not 1 then
		error "Usage: osascript start-amphetamine-session.applescript hours"
	end if

	set sessionHours to parsePositiveInteger(item 1 of argv, "hours")

	tell application "Amphetamine"
		start new session with options {duration:sessionHours, interval:hours, displaySleepAllowed:false}
	end tell
end run

on parsePositiveInteger(rawValue, label)
	try
		set parsedNumber to rawValue as number
	on error
		error label & " must be a positive integer: " & rawValue
	end try

	set parsedInteger to parsedNumber as integer
	if parsedNumber is not parsedInteger then error label & " must be a whole number: " & rawValue
	if parsedInteger < 1 then error label & " must be 1 or greater: " & rawValue

	return parsedInteger
end parsePositiveInteger

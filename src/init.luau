--!strict
--[[
	NumberFormat
	Luau port of @rbxts/formatting (https://github.com/R-unic/rbx-formatting)
	Utility functions for formatting numbers/currency/time and parsing strings back into numbers.
]]

local floor = math.floor
local log = math.log

local function trim(s: string, pattern: string?): string
	local p = pattern or "%s*"
	return s:match("^" .. p .. "(.-)" .. p .. "$") or s
end

local function capitalize(s: string): string
	return s:sub(1, 1):upper() .. s:sub(2)
end

local caseInsensitiveRegexCache: { [{ string }]: string } = {}

local function createCaseInsensitiveRegex(strings: { string }): string
	local cached = caseInsensitiveRegexCache[strings]
	if cached then
		return cached
	end

	local escapedStrings = {}
	for _, s in strings do
		local pattern = s:gsub("%a", function(c: string)
			return string.format("(%s%s)", c:upper(), c:lower())
		end)
		table.insert(escapedStrings, pattern)
	end

	local fullRegex = table.concat(escapedStrings, "|")
	caseInsensitiveRegexCache[strings] = fullRegex
	return fullRegex
end

local NumberFormat = {}

--[[
	Places commas between every three decimal points in `n`.
	@param n The number to format
	@param minimum If `n` is less than this number, return `n` as a string
	@param separator The separator to use (default: ",")
	@param decimal The decimal separator to use (default: ".")
	@example NumberFormat.commaFormat(1000000) -- "1,000,000"
]]
function NumberFormat.commaFormat(n: number | string, minimum: number?, separator: string?, decimal: string?): string
	local sep = separator or ","
	local dec = decimal or "."
	local nString = tostring(n)

	if minimum ~= nil then
		local asNumber = tonumber(n)
		if asNumber ~= nil and asNumber < minimum then
			return nString
		end
	end

	local integerPart, decimalPart = nString:match("([^%" .. dec .. "]+)%" .. dec .. "?(.*)")
	integerPart = integerPart or nString

	local reversed = integerPart:reverse()
	local formattedReversed = reversed:gsub("(%d%d%d)", "%1" .. sep)
	local formatted = formattedReversed:reverse()

	if formatted:sub(1, 1) == sep then
		formatted = formatted:sub(2)
	end

	if decimalPart ~= nil and decimalPart ~= "" then
		formatted = formatted .. dec .. decimalPart
	end

	return formatted
end

local defaultSuffixes = {
	"K",
	"M", "B", "T", "Qd", "Qt", "Sx", "Sp", "Oc", "No", "Dc",
	"Udc", "Ddc", "Tdc", "Qdc", "Qnd", "Sxd", "Spd", "Ocd", "Nvd", "Vg",
	"Uvg", "Dvg", "Tvg", "Qvg", "Qnv", "Sxv", "Spv", "Ocv", "Nvv", "Tg",
	"Utg", "G",
}
createCaseInsensitiveRegex(defaultSuffixes) -- cache it so it isn't generated when you call parseAbbreviated()

NumberFormat.defaultSuffixes = defaultSuffixes

--[[
	Abbreviates numbers larger than or equal to `threshold`.
	@example
	NumberFormat.abbreviate(1000000) -- "1M"
	NumberFormat.abbreviate(1000000000000000000) -- "1Qt"
]]
function NumberFormat.abbreviate(n: number, threshold: number?, suffixes: { string }?): string
	local thresh = threshold or 1000
	local suf = suffixes or defaultSuffixes

	if n < thresh then
		return NumberFormat.commaFormat(n)
	end

	local index = floor(log(n, 1000)) - 1
	local divisor = 10 ^ ((index + 1) * 3)
	local baseNumber = string.format("%.3f", n / divisor):gsub("%.?0+$", "")
	return baseNumber .. (index < 0 and "" or suf[index + 1])
end

--[[
	Parses a number formatted by `abbreviate()` back into a number type.
	@example NumberFormat.parseAbbreviated("1B") -- 1000000000
]]
function NumberFormat.parseAbbreviated(suffixed: string, suffixes: { string }?): number
	local suf = suffixes or defaultSuffixes
	local regex = createCaseInsensitiveRegex(suf)
	local stripped = (suffixed:gsub(",", ""))
	local numberPart, suffix = trim(stripped):match("^([0-9,.]+)([(" .. regex .. ")]?)$")

	if numberPart == nil then
		error("[NumberFormat]: Invalid suffixed number format")
	end

	local result = tonumber(numberPart)
	if result == nil then
		error("[NumberFormat]: Invalid suffixed number format")
	end

	if suffix ~= nil and suffix ~= "" then
		local index = table.find(suf, capitalize(suffix:lower()))
		if index ~= nil then
			local multiplier = 10 ^ (index * 3)
			result *= multiplier
		end
	end

	return result
end

local SECOND = 1
local MINUTE = 60
local HOUR = 3600
local DAY = 86400
local WEEK = 604800

local timePatterns: { [string]: number } = {
	s = SECOND, second = SECOND, seconds = SECOND,
	m = MINUTE, minute = MINUTE, minutes = MINUTE,
	h = HOUR, hour = HOUR, hours = HOUR,
	d = DAY, day = DAY, days = DAY,
	w = WEEK, week = WEEK, weeks = WEEK,
}

--[[
	Takes a remaining time string and converts it to the amount of time it represents in seconds.
	@example NumberFormat.toSeconds("10m 20s") -- 620
]]
function NumberFormat.toSeconds(time: string): number
	local timeNumber = tonumber(time)
	if timeNumber ~= nil then
		return timeNumber
	end

	local seconds = 0
	local stripped = (time:gsub(" ", ""))
	for value, unit in stripped:gmatch("(%d+)(%a)") do
		local multiplier = timePatterns[unit]
		if multiplier ~= nil then
			seconds += tonumber(value)! * multiplier
		end
	end

	return seconds
end

--[[
	Takes a time in seconds and converts it to a remaining time string.
	@example NumberFormat.toRemainingTime(310) -- "5m 10s"
]]
function NumberFormat.toRemainingTime(
	seconds: number,
	secondsFormat: string?,
	minutesFormat: string?,
	hoursFormat: string?,
	daysFormat: string?
): string
	local secondsFmt = secondsFormat or "%ds"
	local minutesFmt = minutesFormat or "%dm"
	local hoursFmt = hoursFormat or "%dh"
	local daysFmt = daysFormat or "%dd"

	local remaining = seconds
	local days = floor(remaining / DAY)
	remaining %= DAY

	local hours = floor(remaining / HOUR)
	remaining %= HOUR

	local minutes = floor(remaining / MINUTE)
	remaining %= MINUTE

	local remainingTime = ""
	if days > 0 then
		remainingTime ..= string.format(daysFmt .. " ", days)
	end
	if hours > 0 then
		remainingTime ..= string.format(hoursFmt .. " ", hours)
	end
	if minutes > 0 then
		remainingTime ..= string.format(minutesFmt .. " ", minutes)
	end
	if remaining > 0 then
		remainingTime ..= string.format(secondsFmt .. " ", remaining)
	end

	return trim(remainingTime)
end

--[[
	Takes a time in seconds and converts it to a long remaining time string (HH:MM:SS).
	@example NumberFormat.toLongRemainingTime(3690) -- "01:01:30"
]]
function NumberFormat.toLongRemainingTime(seconds: number): string
	local hours = floor(seconds / HOUR)
	local minutes = floor((seconds % HOUR) / MINUTE)
	local remainingSeconds = seconds % MINUTE

	return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

return NumberFormat

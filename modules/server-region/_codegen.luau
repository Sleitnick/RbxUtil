const HttpService = game:GetService("HttpService")
const ScriptEditorService = game:GetService("ScriptEditorService")

const response = HttpService:RequestAsync({
	Url = "https://raw.githubusercontent.com/davidmegginson/ourairports-data/refs/heads/main/airports.csv",
})

if not response.Success then
	error(`request failed: [{response.StatusCode}] {response.StatusMessage}`)
end

const startElt = os.clock()

const data = string.split(response.Body, "\n")

const B_MINUS = string.byte("-")
const B_DOT = string.byte(".")

const REMAP_KEYS = {
	["latitude_deg"] = "Lat",
	["longitude_deg"] = "Lon",
	["continent"] = "Continent",
	["iso_country"] = "Country",
	["iata_code"] = "IATA",
}

@native
const function parseLine(csvLine: string): { string | number }
	const parts: { string | number } = {}

	local i = 1

	const function isQuote(at: number)
		return string.sub(csvLine, at, at) == '"'
	end

	const function charIs(at: number, c: string)
		return string.sub(csvLine, at, at) == c
	end

	const function parseString()
		const str: { string } = {}

		const findEndQuote = (isQuote(i) and not isQuote(i + 1)) or (isQuote(i) and isQuote(i + 1) and isQuote(i + 2))
		if findEndQuote then
			i += 1
		end

		while i <= #csvLine do
			const c = string.sub(csvLine, i, i)
			if findEndQuote then
				if c == '"' and charIs(i + 1, ",") then
					i += 2
					break
				end
			else
				if c == "," then
					break
				end
			end
			if c == '"' and isQuote(i + 1) then
				table.insert(str, '\\"')
				i += 2
			else
				table.insert(str, c)
				i += 1
			end
		end

		table.insert(parts, table.concat(str, ""))
	end

	const function tryParseNumber(): boolean
		const nextSep = string.find(csvLine, ",", i, true)
		const str = string.sub(csvLine, i, if nextSep then nextSep - 1 else #csvLine)
		const num = tonumber(str)
		if num ~= nil then
			table.insert(parts, num)
			i = if nextSep then nextSep + 1 else #csvLine + 1
			return true
		end
		return false
	end

	const function parseAny(c: string)
		const b = string.byte(c)
		if c == "," then
			table.insert(parts, "")
			i += 1
		elseif (b >= 48 and b <= 57) or b == B_MINUS or b == B_DOT then
			const start = i
			const success = tryParseNumber()
			if not success then
				i = start
				parseString()
			end
		else
			parseString()
		end
	end

	while i <= #csvLine do
		const c = string.sub(csvLine, i, i)
		parseAny(c)
	end

	return parts
end

const header = parseLine(data[1])

-- Find IATA index so we can skip early when looping thru airport data
local iataIdx = 0
for i, v in header do
	if v == "iata_code" then
		iataIdx = i
		break
	end
end
assert(iataIdx ~= 0)

const airports = {}

for i = 2, #data do
	const rawDataLine = data[i]
	if rawDataLine == "" then
		continue
	end

	const airportRaw = parseLine(rawDataLine)

	const iata = airportRaw[iataIdx]
	if iata == "" or iata == "no" then
		continue
	end

	const airport = {}
	for j, key in header do
		const remappedKey = REMAP_KEYS[key]
		if remappedKey == nil then
			continue
		end
		const value = airportRaw[j]
		if value ~= "" then
			airport[remappedKey] = airportRaw[j]
		end
	end

	table.insert(airports, airport)
end

const elapsedElt = os.clock() - startElt
const startCodegen = os.clock()

const sourceBuf = {
	"--!strict",
	"-- stylua: ignore",
	"",
	"-- This code was auto-generated. Do not modify.",
	"",
	"--[=[",
	"\t@class ServerRegion",
	"\t@server",
	"",
	"\tExtra information about a game server's region, referenced by `game.ServerRegion`, such as geographic coordinates",
	"\tand country.",
	"",
	"\tSince this is a server-only module, ensure to list the package under `[server-dependencies]` within your",
	"\t`wally.toml` file.",
	"",
	"\t:::warning Memory Usage",
	"\tDue to how Luau works, this module uses upwards of 7MB of heap memory. Therefore, it is recommended to use the",
	"\t`getAndDestroy()` function, which will destroy the ModuleScript after fetching the region information. This will",
	"\tfree up the heap memory used. Call this function once and cache the result.",
	"\t```lua",
	"\t-- Custom ServerRegion ModuleScript which proxies the one-time call to getAndDestroy",
	"\treturn require(ServerStorage.ServerPackages.ServerRegion).getAndDestroy()",
	"\t```",
	"\t:::",
	"]=]",
	"",
	"--[=[",
	"\t@within ServerRegion",
	"\t@interface Region",
	"\t.Lat number -- Latitude",
	"\t.Lon number -- Longitude",
	"\t.Continent string",
	"\t.Country string",
	"\t.IATA string -- Three-letter location identifier",
	"]=]",
	"",
	'const RunService = game:GetService("RunService")',
	"",
	"export type Region = {",
	"\tread Lat: number,",
	"\tread Lon: number,",
	"\tread Continent: string,",
	"\tread Country: string,",
	"\tread IATA: string,",
	"}",
	"",
	"const regions: { [string]: Region } = {",
}

for i, airport in airports do
	table.insert(
		sourceBuf,
		`\t["{airport.IATA}"] = table.freeze(\{ Lat = {airport.Lat}, Lon = {airport.Lon}, Continent = "{airport.Continent}", Country = "{airport.Country}", IATA = "{airport.IATA}" }),`
	)
end

table.insert(sourceBuf, "}")
table.insert(sourceBuf, "table.freeze(regions)")
table.insert(sourceBuf, "")
table.insert(sourceBuf, "const ServerRegion = {}")
table.insert(sourceBuf, "")
table.insert(sourceBuf, "--[=[")
table.insert(sourceBuf, "\t@within ServerRegion")
table.insert(sourceBuf, "")
table.insert(sourceBuf, "\tGets the server region.")
table.insert(sourceBuf, "]=]")
table.insert(sourceBuf, "function ServerRegion.get(): Region")
table.insert(sourceBuf, "\tconst region = game.ServerRegion")
table.insert(sourceBuf, '\tassert(RunService:IsServer(), "ServerRegion.get() can only be called from the server")')
table.insert(sourceBuf, "\treturn regions[region]")
table.insert(sourceBuf, "end")
table.insert(sourceBuf, "")
table.insert(sourceBuf, "--[=[")
table.insert(sourceBuf, "\t@within ServerRegion")
table.insert(sourceBuf, "")
table.insert(sourceBuf, "\tGets the server region, and then destroys the source ModuleScript to free up heap memory.")
table.insert(sourceBuf, "]=]")
table.insert(sourceBuf, "function ServerRegion.getAndDestroy(): Region")
table.insert(sourceBuf, "\tconst region = ServerRegion.get()")
table.insert(sourceBuf, "\ttask.defer(function() script:Destroy() end)")
table.insert(sourceBuf, "\treturn region")
table.insert(sourceBuf, "end")
table.insert(sourceBuf, "")
table.insert(sourceBuf, "return table.freeze(ServerRegion)")
table.insert(sourceBuf, "")

const source = table.concat(sourceBuf, "\n")

const elapsedCodegen = os.clock() - startCodegen

print(string.format("Elapsed ELT: %.3fms", elapsedElt * 1000))
print(string.format("Elapsed Codegen: %.3fms", elapsedCodegen * 1000))

local genScript: ModuleScript = game:GetService("ServerStorage"):FindFirstChild("ServerRegionAutoGen")
if not genScript then
	genScript = Instance.new("ModuleScript")
	genScript.Name = "ServerRegionAutoGen"
	genScript.Parent = game:GetService("ServerStorage")
end
ScriptEditorService:UpdateSourceAsync(genScript, function()
	return source
end)

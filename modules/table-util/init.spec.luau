local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local TableUtil = require(script.Parent)

	ctx:Describe("Copy (Deep)", function()
		ctx:Test("should create a deep table copy", function()
			local tbl = { a = { b = { c = { d = 32 } } } }
			local tblCopy = TableUtil.Copy(tbl, true)
			ctx:Expect(tbl):Not():ToBe(tblCopy)
			ctx:Expect(tbl.a):Not():ToBe(tblCopy.a)
			ctx:Expect(tblCopy.a.b.c.d):ToBe(tbl.a.b.c.d)
		end)
	end)

	ctx:Describe("Copy (Shallow)", function()
		ctx:Test("should create a shallow dictionary copy", function()
			local tbl = { a = { b = { c = { d = 32 } } } }
			local tblCopy = TableUtil.Copy(tbl)
			ctx:Expect(tblCopy):Not():ToBe(tbl)
			ctx:Expect(tblCopy.a):ToBe(tbl.a)
			ctx:Expect(tblCopy.a.b.c.d):ToBe(tbl.a.b.c.d)
		end)

		ctx:Test("should create a shallow array copy", function()
			local tbl = { 10, 20, 30, 40 }
			local tblCopy = TableUtil.Copy(tbl)
			ctx:Expect(tblCopy):Not():ToBe(tbl)
			for i, v in ipairs(tbl) do
				ctx:Expect(tblCopy[i]):ToBe(v)
			end
		end)
	end)

	ctx:Describe("Sync", function()
		ctx:Test("should sync tables", function()
			local template = { a = 32, b = 64, c = 128, e = { h = 1 } }
			local tblSrc = { a = 32, b = 10, d = 1, e = { h = 2, n = 2 }, f = { x = 10 } }
			local tbl = TableUtil.Sync(tblSrc, template)
			ctx:Expect(tbl.a):ToBe(template.a)
			ctx:Expect(tbl.b):ToBe(10)
			ctx:Expect(tbl.c):ToBe(template.c)
			ctx:Expect(tbl.d):ToBeNil()
			ctx:Expect(tbl.e.h):ToBe(2)
			ctx:Expect(tbl.e.n):ToBeNil()
			ctx:Expect(tbl.f):ToBeNil()
		end)
	end)

	ctx:Describe("Reconcile", function()
		ctx:Test("should reconcile table", function()
			local template = { kills = 0, deaths = 0, xp = 10, stuff = {}, stuff2 = "abc", stuff3 = { "data" } }
			local data =
				{ kills = 10, deaths = 4, stuff = { "abc", "xyz" }, extra = 5, stuff2 = { abc = 10 }, stuff3 = true }
			local reconciled = TableUtil.Reconcile(data, template)
			ctx:Expect(reconciled):Not():ToBe(data)
			ctx:Expect(reconciled):Not():ToBe(template)
			ctx:Expect(reconciled.kills):ToBe(10)
			ctx:Expect(reconciled.deaths):ToBe(4)
			ctx:Expect(reconciled.xp):ToBe(10)
			ctx:Expect(reconciled.stuff[1]):ToBe("abc")
			ctx:Expect(reconciled.stuff[2]):ToBe("xyz")
			ctx:Expect(reconciled.extra):ToBe(5)
			ctx:Expect(type(reconciled.stuff2)):ToBe("table")
			ctx:Expect(reconciled.stuff2):Not():ToBe(data.stuff2)
			ctx:Expect(reconciled.stuff2.abc):ToBe(10)
			ctx:Expect(type(reconciled.stuff3)):ToBe("boolean")
			ctx:Expect(reconciled.stuff3):ToBe(true)
		end)
	end)

	ctx:Describe("SwapRemove", function()
		ctx:Test("should swap remove index", function()
			local tbl = { 1, 2, 3, 4, 5 }
			TableUtil.SwapRemove(tbl, 3)
			ctx:Expect(#tbl):ToBe(4)
			ctx:Expect(tbl[3]):ToBe(5)
		end)
	end)

	ctx:Describe("SwapRemoveFirstValue", function()
		ctx:Test("should swap remove first value given", function()
			local tbl = { "hello", "world", "goodbye", "planet" }
			TableUtil.SwapRemoveFirstValue(tbl, "world")
			ctx:Expect(#tbl):ToBe(3)
			ctx:Expect(tbl[2]):ToBe("planet")
		end)
	end)

	ctx:Describe("Map", function()
		ctx:Test("should map table", function()
			local tbl = {
				{ FirstName = "John", LastName = "Doe" },
				{ FirstName = "Jane", LastName = "Smith" },
			}
			local tblMapped = TableUtil.Map(tbl, function(person)
				return person.FirstName .. " " .. person.LastName
			end)
			ctx:Expect(tblMapped[1]):ToBe("John Doe")
			ctx:Expect(tblMapped[2]):ToBe("Jane Smith")
		end)
	end)

	ctx:Describe("Filter", function()
		ctx:Test("should filter table", function()
			local tbl = { 10, 20, 30, 40, 50, 60, 70, 80, 90 }
			local tblFiltered = TableUtil.Filter(tbl, function(n)
				return (n >= 30 and n <= 60)
			end)
			ctx:Expect(#tblFiltered):ToBe(4)
			ctx:Expect(tblFiltered[1]):ToBe(30)
			ctx:Expect(tblFiltered[#tblFiltered]):ToBe(60)
		end)
	end)

	ctx:Describe("Reduce", function()
		ctx:Test("should reduce table with numbers", function()
			local tbl = { 1, 2, 3, 4, 5 }
			local reduced = TableUtil.Reduce(tbl, function(accum, value)
				return accum + value
			end)
			ctx:Expect(reduced):ToBe(15)
		end)

		ctx:Test("should reduce table", function()
			local tbl = { { Score = 10 }, { Score = 20 }, { Score = 30 } }
			local reduced = TableUtil.Reduce(tbl, function(accum, value)
				return accum + value.Score
			end, 0)
			ctx:Expect(reduced):ToBe(60)
		end)

		ctx:Test("should reduce table with initial value", function()
			local tbl = { { Score = 10 }, { Score = 20 }, { Score = 30 } }
			local reduced = TableUtil.Reduce(tbl, function(accum, value)
				return accum + value.Score
			end, 40)
			ctx:Expect(reduced):ToBe(100)
		end)

		ctx:Test("should reduce functions", function()
			local function Square(x)
				return x * x
			end
			local function Double(x)
				return x * 2
			end
			local Func = TableUtil.Reduce({ Square, Double }, function(a, b)
				return function(x)
					return a(b(x))
				end
			end)
			local result = Func(10)
			ctx:Expect(result):ToBe(400)
		end)
	end)

	ctx:Describe("Assign", function()
		ctx:Test("should assign tables", function()
			local target = { a = 32, x = 100 }
			local t1 = { b = 64, c = 128 }
			local t2 = { a = 10, c = 100, d = 200 }
			local tbl = TableUtil.Assign(target, t1, t2)
			ctx:Expect(tbl.a):ToBe(10)
			ctx:Expect(tbl.b):ToBe(64)
			ctx:Expect(tbl.c):ToBe(100)
			ctx:Expect(tbl.d):ToBe(200)
			ctx:Expect(tbl.x):ToBe(100)
		end)
	end)

	ctx:Describe("Extend", function()
		ctx:Test("should extend tables", function()
			local tbl = { "a", "b", "c" }
			local extension = { "d", "e", "f" }
			local extended = TableUtil.Extend(tbl, extension)
			ctx:Expect(table.concat(extended)):ToBe("abcdef")
		end)
	end)

	ctx:Describe("Reverse", function()
		ctx:Test("should create a table in reverse", function()
			local tbl = { 1, 2, 3 }
			local tblRev = TableUtil.Reverse(tbl)
			ctx:Expect(table.concat(tblRev)):ToBe("321")
		end)
	end)

	ctx:Describe("Shuffle", function()
		ctx:Test("should shuffle a table", function()
			local tbl = { 1, 2, 3, 4, 5 }
			ctx:Expect(function()
				TableUtil.Shuffle(tbl)
			end)
				:Not()
				:ToThrow()
		end)
	end)

	ctx:Describe("Sample", function()
		ctx:Test("should sample a table", function()
			local tbl = { 1, 2, 3, 4, 5 }
			local sample = TableUtil.Sample(tbl, 3)
			ctx:Expect(#sample):ToBe(3)
		end)
	end)

	ctx:Describe("Flat", function()
		ctx:Test("should flatten table", function()
			local tbl = { 1, 2, 3, { 4, 5, { 6, 7 } } }
			local tblFlat = TableUtil.Flat(tbl, 3)
			ctx:Expect(table.concat(tblFlat)):ToBe("1234567")
		end)
	end)

	ctx:Describe("FlatMap", function()
		ctx:Test("should map and flatten table", function()
			local tbl = { 1, 2, 3, 4, 5, 6, 7 }
			local tblFlat = TableUtil.FlatMap(tbl, function(n)
				return { n, n * 2 }
			end)
			ctx:Expect(table.concat(tblFlat)):ToBe("12243648510612714")
		end)
	end)

	ctx:Describe("Keys", function()
		ctx:Test("should give all keys of table", function()
			local tbl = { a = 1, b = 2, c = 3 }
			local keys = TableUtil.Keys(tbl)
			ctx:Expect(#keys):ToBe(3)
			ctx:Expect(table.find(keys, "a")):ToBeOk()
			ctx:Expect(table.find(keys, "b")):ToBeOk()
			ctx:Expect(table.find(keys, "c")):ToBeOk()
		end)
	end)

	ctx:Describe("Values", function()
		ctx:Test("should give all values of table", function()
			local tbl = { a = 1, b = 2, c = 3 }
			local values = TableUtil.Values(tbl)
			ctx:Expect(#values):ToBe(3)
			ctx:Expect(table.find(values, 1)):ToBeOk()
			ctx:Expect(table.find(values, 2)):ToBeOk()
			ctx:Expect(table.find(values, 3)):ToBeOk()
		end)
	end)

	ctx:Describe("Find", function()
		ctx:Test("should find item in array", function()
			local tbl = { 10, 20, 30 }
			local item, index = TableUtil.Find(tbl, function(value)
				return (value == 20)
			end)
			ctx:Expect(item):ToBeOk()
			ctx:Expect(index):ToBe(2)
			ctx:Expect(item):ToBe(20)
		end)

		ctx:Test("should find item in dictionary", function()
			local tbl = { { Score = 10 }, { Score = 20 }, { Score = 30 } }
			local item, index = TableUtil.Find(tbl, function(value)
				return (value.Score == 20)
			end)
			ctx:Expect(item):ToBeOk()
			ctx:Expect(index):ToBe(2)
			ctx:Expect(item.Score):ToBe(20)
		end)
	end)

	ctx:Describe("Every", function()
		ctx:Test("should see every value is above 20", function()
			local tbl = { 21, 40, 200 }
			local every = TableUtil.Every(tbl, function(n)
				return (n > 20)
			end)
			ctx:Expect(every):ToBe(true)
		end)

		ctx:Test("should see every value is not above 20", function()
			local tbl = { 20, 40, 200 }
			local every = TableUtil.Every(tbl, function(n)
				return (n > 20)
			end)
			ctx:Expect(every):Not():ToBe(true)
		end)
	end)

	ctx:Describe("Some", function()
		ctx:Test("should see some value is above 20", function()
			local tbl = { 5, 40, 1 }
			local every = TableUtil.Some(tbl, function(n)
				return (n > 20)
			end)
			ctx:Expect(every):ToBe(true)
		end)

		ctx:Test("should see some value is not above 20", function()
			local tbl = { 5, 15, 1 }
			local every = TableUtil.Some(tbl, function(n)
				return (n > 20)
			end)
			ctx:Expect(every):Not():ToBe(true)
		end)
	end)

	ctx:Describe("Truncate", function()
		ctx:Test("should truncate an array", function()
			local t1 = { 1, 2, 3, 4, 5 }
			local t2 = TableUtil.Truncate(t1, 3)
			ctx:Expect(#t2):ToBe(3)
			ctx:Expect(t2[1]):ToBe(t1[1])
			ctx:Expect(t2[2]):ToBe(t1[2])
			ctx:Expect(t2[3]):ToBe(t1[3])
		end)

		ctx:Test("should truncate an array with out of bounds sizes", function()
			local t1 = { 1, 2, 3, 4, 5 }
			ctx:Expect(function()
				TableUtil.Truncate(t1, -1)
			end)
				:Not()
				:ToThrow()
			ctx:Expect(function()
				TableUtil.Truncate(t1, #t1 + 1)
			end)
				:Not()
				:ToThrow()
			local t2 = TableUtil.Truncate(t1, #t1 + 10)
			ctx:Expect(#t2):ToBe(#t1)
			ctx:Expect(t2):Not():ToBe(t1)
		end)
	end)

	ctx:Describe("Lock", function()
		ctx:Test("should lock a table", function()
			local t = { abc = { xyz = { num = 32 } } }
			ctx:Expect(function()
				t.abc.xyz.num = 64
			end)
				:Not()
				:ToThrow()
			local t2 = TableUtil.Lock(t)
			ctx:Expect(t.abc.xyz.num):ToBe(64)
			ctx:Expect(t):ToBe(t2)
			ctx:Expect(function()
				t.abc.xyz.num = 10
			end):ToThrow()
		end)
	end)

	ctx:Describe("Zip", function()
		ctx:Test("should zip arrays together", function()
			local t1 = { 1, 2, 3, 4, 5 }
			local t2 = { 9, 8, 7, 6, 5 }
			local t3 = { 1, 1, 1, 1, 1 }
			local lastIndex = 0
			for i, v in TableUtil.Zip(t1, t2, t3) do
				lastIndex = i
				ctx:Expect(v[1]):ToBe(t1[i])
				ctx:Expect(v[2]):ToBe(t2[i])
				ctx:Expect(v[3]):ToBe(t3[i])
			end
			ctx:Expect(lastIndex):ToBe(math.min(#t1, #t2, #t3))
		end)

		ctx:Test("should zip arrays of different lengths together", function()
			local t1 = { 1, 2, 3, 4, 5 }
			local t2 = { 9, 8, 7, 6 }
			local t3 = { 1, 1, 1 }
			local lastIndex = 0
			for i, v in TableUtil.Zip(t1, t2, t3) do
				lastIndex = i
				ctx:Expect(v[1]):ToBe(t1[i])
				ctx:Expect(v[2]):ToBe(t2[i])
				ctx:Expect(v[3]):ToBe(t3[i])
			end
			ctx:Expect(lastIndex):ToBe(math.min(#t1, #t2, #t3))
		end)

		ctx:Test("should zip maps together", function()
			local t1 = { a = 10, b = 20, c = 30 }
			local t2 = { a = 100, b = 200, c = 300 }
			local t3 = { a = 3000, b = 2000, c = 3000 }
			for k, v in TableUtil.Zip(t1, t2, t3) do
				ctx:Expect(v[1]):ToBe(t1[k])
				ctx:Expect(v[2]):ToBe(t2[k])
				ctx:Expect(v[3]):ToBe(t3[k])
			end
		end)

		ctx:Test("should zip maps of different keys together", function()
			local t1 = { a = 10, b = 20, c = 30, d = 40 }
			local t2 = { a = 100, b = 200, c = 300, z = 10 }
			local t3 = { a = 3000, b = 2000, c = 3000, x = 0 }
			for k, v in TableUtil.Zip(t1, t2, t3) do
				ctx:Expect(v[1]):ToBe(t1[k])
				ctx:Expect(v[2]):ToBe(t2[k])
				ctx:Expect(v[3]):ToBe(t3[k])
			end
		end)
	end)

	ctx:Describe("IsEmpty", function()
		ctx:Test("should detect that table is empty", function()
			local tbl = {}
			local isEmpty = TableUtil.IsEmpty(tbl)
			ctx:Expect(isEmpty):ToBe(true)
		end)

		ctx:Test("should detect that array is not empty", function()
			local tbl = { 10, 20, 30 }
			local isEmpty = TableUtil.IsEmpty(tbl)
			ctx:Expect(isEmpty):ToBe(false)
		end)

		ctx:Test("should detect that dictionary is not empty", function()
			local tbl = { a = 10, b = 20, c = 30 }
			local isEmpty = TableUtil.IsEmpty(tbl)
			ctx:Expect(isEmpty):ToBe(false)
		end)
	end)

	ctx:Describe("JSON", function()
		ctx:Test("should encode json", function()
			local tbl = { hello = "world" }
			local json = TableUtil.EncodeJSON(tbl)
			ctx:Expect(json):ToBe('{"hello":"world"}')
		end)

		ctx:Test("should decode json", function()
			local json = '{"hello":"world"}'
			local tbl = TableUtil.DecodeJSON(json)
			ctx:Expect(tbl):ToBeA("table")
			ctx:Expect(tbl.hello):ToBe("world")
		end)
	end)
end

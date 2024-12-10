local ServerScriptService = game:GetService("ServerScriptService")

local Test = require(ServerScriptService.TestRunner.Test)

return function(ctx: Test.TestContext)
	local Silo = require(script.Parent)

	local silo1, silo2, rootSilo

	ctx:BeforeEach(function()
		silo1 = Silo.new({
			Kills = 0,
			Deaths = 0,
		}, {
			SetKills = function(state, kills)
				state.Kills = kills
			end,
			IncrementDeaths = function(state, deaths)
				state.Deaths += deaths
			end,
		})
		silo2 = Silo.new({
			Money = 0,
		}, {
			AddMoney = function(state, money)
				state.Money += money
			end,
		})
		rootSilo = Silo.combine({
			Stats = silo1,
			Econ = silo2,
		})
	end)

	ctx:Describe("State", function()
		ctx:Test("should get state properly", function()
			local silo = Silo.new({
				ABC = 10,
			})
			local state = silo:GetState()
			ctx:Expect(state):ToBeA("table")
			ctx:Expect(state.ABC):ToBe(10)
		end)

		ctx:Test("should get state from combined silos", function()
			local state = rootSilo:GetState()
			ctx:Expect(state):ToBeA("table")
			ctx:Expect(state.Stats):ToBeA("table")
			ctx:Expect(state.Econ):ToBeA("table")
			ctx:Expect(state.Stats.Kills):ToBeA("number")
			ctx:Expect(state.Stats.Deaths):ToBeA("number")
			ctx:Expect(state.Econ.Money):ToBeA("number")
		end)

		ctx:Test("should not allow getting state from sub-silo", function()
			ctx:Expect(function()
				silo1:GetState()
			end):ToThrow()
			ctx:Expect(function()
				silo2:GetState()
			end):ToThrow()
		end)

		ctx:Test("should throw error if attempting to modify state directly", function()
			ctx:Expect(function()
				rootSilo:GetState().Stats.Kills = 10
			end):ToThrow()
			ctx:Expect(function()
				rootSilo:GetState().Stats.SomethingNew = 100
			end):ToThrow()
			ctx:Expect(function()
				rootSilo:GetState().Stats = {}
			end):ToThrow()
			ctx:Expect(function()
				rootSilo:GetState().SomethingElse = {}
			end):ToThrow()
		end)
	end)

	ctx:Describe("Dispatch", function()
		ctx:Test("should dispatch", function()
			ctx:Expect(rootSilo:GetState().Stats.Kills):ToBe(0)
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			ctx:Expect(rootSilo:GetState().Stats.Kills):ToBe(10)
			rootSilo:Dispatch(silo2.Actions.AddMoney(10))
			rootSilo:Dispatch(silo2.Actions.AddMoney(20))
			ctx:Expect(rootSilo:GetState().Econ.Money):ToBe(30)
		end)

		ctx:Test("should not allow dispatching from a sub-silo", function()
			ctx:Expect(function()
				silo1:Dispatch(silo1.Action.SetKills(0))
			end):ToThrow()
			ctx:Expect(function()
				silo2:Dispatch(silo2.Action.AddMoney(0))
			end):ToThrow()
		end)

		ctx:Test("should not allow dispatching from within a modifier", function()
			ctx:Expect(function()
				local silo
				silo = Silo.new({
					Data = 0,
				}, {
					SetData = function(state, newData)
						state.Data = newData
						silo:Dispatch({ Name = "", Payload = 0 })
					end,
				})
				silo:Dispatch(silo.Actions.SetData(0))
			end):ToThrow()
		end)
	end)

	ctx:Describe("Subscribe", function()
		ctx:Test("should subscribe to a silo", function()
			local new, old
			local n = 0
			local unsubscribe = rootSilo:Subscribe(function(newState, oldState)
				n += 1
				new, old = newState, oldState
			end)
			ctx:Expect(n):ToBe(0)
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			ctx:Expect(n):ToBe(1)
			ctx:Expect(new):ToBeA("table")
			ctx:Expect(old):ToBeA("table")
			ctx:Expect(new.Stats.Kills):ToBe(10)
			ctx:Expect(old.Stats.Kills):ToBe(0)
			rootSilo:Dispatch(silo1.Actions.SetKills(20))
			ctx:Expect(n):ToBe(2)
			ctx:Expect(new.Stats.Kills):ToBe(20)
			ctx:Expect(old.Stats.Kills):ToBe(10)
			unsubscribe()
			rootSilo:Dispatch(silo1.Actions.SetKills(30))
			ctx:Expect(n):ToBe(2)
		end)

		ctx:Test("should not allow subscribing same function more than once", function()
			local function sub() end
			ctx:Expect(function()
				rootSilo:Subscribe(sub)
			end)
				:Not()
				:ToThrow()
			ctx:Expect(function()
				rootSilo:Subscribe(sub)
			end):ToThrow()
		end)

		ctx:Test("should not allow subscribing to a sub-silo", function()
			ctx:Expect(function()
				silo1:Subscribe(function() end)
			end):ToThrow()
		end)

		ctx:Test("should not allow subscribing from within a modifier", function()
			ctx:Expect(function()
				local silo
				silo = Silo.new({
					Data = 0,
				}, {
					SetData = function(state, newData)
						state.Data = newData
						silo:Subscribe(function() end)
					end,
				})
				silo:Dispatch(silo.Actions.SetData(0))
			end):ToThrow()
		end)
	end)

	ctx:Describe("Watch", function()
		ctx:Test("should watch value changes", function()
			local function SelectMoney(state)
				return state.Econ.Money
			end
			local changes = 0
			local currentMoney = 0
			local unsubscribeWatch = rootSilo:Watch(SelectMoney, function(money)
				changes += 1
				currentMoney = money
			end)
			ctx:Expect(changes):ToBe(1)
			rootSilo:Dispatch(silo2.Actions.AddMoney(10))
			ctx:Expect(changes):ToBe(2)
			ctx:Expect(currentMoney):ToBe(10)
			rootSilo:Dispatch(silo2.Actions.AddMoney(20))
			ctx:Expect(changes):ToBe(3)
			ctx:Expect(currentMoney):ToBe(30)
			rootSilo:Dispatch(silo2.Actions.AddMoney(0))
			ctx:Expect(changes):ToBe(3)
			ctx:Expect(currentMoney):ToBe(30)
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			ctx:Expect(changes):ToBe(3)
			ctx:Expect(currentMoney):ToBe(30)
			unsubscribeWatch()
			rootSilo:Dispatch(silo2.Actions.AddMoney(10))
			ctx:Expect(changes):ToBe(3)
			ctx:Expect(currentMoney):ToBe(30)
		end)
	end)

	ctx:Describe("ResetToDefaultState", function()
		ctx:Test("should reset the silo to it's default state", function()
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			rootSilo:Dispatch(silo2.Actions.AddMoney(30))
			ctx:Expect(rootSilo:GetState().Stats.Kills):ToBe(10)
			ctx:Expect(rootSilo:GetState().Econ.Money):ToBe(30)
			rootSilo:ResetToDefaultState()
			ctx:Expect(rootSilo:GetState().Stats.Kills):ToBe(0)
			ctx:Expect(rootSilo:GetState().Econ.Money):ToBe(0)
		end)
	end)
end

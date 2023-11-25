return function()
	local Silo = require(script.Parent)

	local silo1, silo2, rootSilo

	beforeEach(function()
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

	describe("State", function()
		it("should get state properly", function()
			local silo = Silo.new({
				ABC = 10,
			})
			local state = silo:GetState()
			expect(state).to.be.a("table")
			expect(state.ABC).to.equal(10)
		end)

		it("should get state from combined silos", function()
			local state = rootSilo:GetState()
			expect(state).to.be.a("table")
			expect(state.Stats).to.be.a("table")
			expect(state.Econ).to.be.a("table")
			expect(state.Stats.Kills).to.be.a("number")
			expect(state.Stats.Deaths).to.be.a("number")
			expect(state.Econ.Money).to.be.a("number")
		end)

		it("should not allow getting state from sub-silo", function()
			expect(function()
				silo1:GetState()
			end).to.throw()
			expect(function()
				silo2:GetState()
			end).to.throw()
		end)

		it("should throw error if attempting to modify state directly", function()
			expect(function()
				rootSilo:GetState().Stats.Kills = 10
			end).to.throw()
			expect(function()
				rootSilo:GetState().Stats.SomethingNew = 100
			end).to.throw()
			expect(function()
				rootSilo:GetState().Stats = {}
			end).to.throw()
			expect(function()
				rootSilo:GetState().SomethingElse = {}
			end).to.throw()
		end)
	end)

	describe("Dispatch", function()
		it("should dispatch", function()
			expect(rootSilo:GetState().Stats.Kills).to.equal(0)
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			expect(rootSilo:GetState().Stats.Kills).to.equal(10)
			rootSilo:Dispatch(silo2.Actions.AddMoney(10))
			rootSilo:Dispatch(silo2.Actions.AddMoney(20))
			expect(rootSilo:GetState().Econ.Money).to.equal(30)
		end)

		it("should not allow dispatching from a sub-silo", function()
			expect(function()
				silo1:Dispatch(silo1.Action.SetKills(0))
			end).to.throw()
			expect(function()
				silo2:Dispatch(silo2.Action.AddMoney(0))
			end).to.throw()
		end)

		it("should not allow dispatching from within a modifier", function()
			expect(function()
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
			end).to.throw()
		end)
	end)

	describe("Subscribe", function()
		it("should subscribe to a silo", function()
			local new, old
			local n = 0
			local unsubscribe = rootSilo:Subscribe(function(newState, oldState)
				n += 1
				new, old = newState, oldState
			end)
			expect(n).to.equal(0)
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			expect(n).to.equal(1)
			expect(new).to.be.a("table")
			expect(old).to.be.a("table")
			expect(new.Stats.Kills).to.equal(10)
			expect(old.Stats.Kills).to.equal(0)
			rootSilo:Dispatch(silo1.Actions.SetKills(20))
			expect(n).to.equal(2)
			expect(new.Stats.Kills).to.equal(20)
			expect(old.Stats.Kills).to.equal(10)
			unsubscribe()
			rootSilo:Dispatch(silo1.Actions.SetKills(30))
			expect(n).to.equal(2)
		end)

		it("should not allow subscribing same function more than once", function()
			local function sub() end
			expect(function()
				rootSilo:Subscribe(sub)
			end).never.to.throw()
			expect(function()
				rootSilo:Subscribe(sub)
			end).to.throw()
		end)

		it("should not allow subscribing to a sub-silo", function()
			expect(function()
				silo1:Subscribe(function() end)
			end).to.throw()
		end)

		it("should not allow subscribing from within a modifier", function()
			expect(function()
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
			end).to.throw()
		end)
	end)

	describe("Watch", function()
		it("should watch value changes", function()
			local function SelectMoney(state)
				return state.Econ.Money
			end
			local changes = 0
			local currentMoney = 0
			local unsubscribeWatch = rootSilo:Watch(SelectMoney, function(money)
				changes += 1
				currentMoney = money
			end)
			expect(changes).to.equal(1)
			rootSilo:Dispatch(silo2.Actions.AddMoney(10))
			expect(changes).to.equal(2)
			expect(currentMoney).to.equal(10)
			rootSilo:Dispatch(silo2.Actions.AddMoney(20))
			expect(changes).to.equal(3)
			expect(currentMoney).to.equal(30)
			rootSilo:Dispatch(silo2.Actions.AddMoney(0))
			expect(changes).to.equal(3)
			expect(currentMoney).to.equal(30)
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			expect(changes).to.equal(3)
			expect(currentMoney).to.equal(30)
			unsubscribeWatch()
			rootSilo:Dispatch(silo2.Actions.AddMoney(10))
			expect(changes).to.equal(3)
			expect(currentMoney).to.equal(30)
		end)
	end)

	describe("ResetToDefaultState", function()
		it("should reset the silo to it's default state", function()
			rootSilo:Dispatch(silo1.Actions.SetKills(10))
			rootSilo:Dispatch(silo2.Actions.AddMoney(30))
			expect(rootSilo:GetState().Stats.Kills).to.equal(10)
			expect(rootSilo:GetState().Econ.Money).to.equal(30)
			rootSilo:ResetToDefaultState()
			expect(rootSilo:GetState().Stats.Kills).to.equal(0)
			expect(rootSilo:GetState().Econ.Money).to.equal(0)
		end)
	end)
end

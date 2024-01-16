"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[6813],{78763:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Constructs a new PID.\\n\\n```lua\\nlocal pid = PID.new(0, 1, 0.1, 0, 0)\\n```","params":[{"name":"min","desc":"Minimum value the PID can output","lua_type":"number"},{"name":"max","desc":"Maximum value the PID can output","lua_type":"number"},{"name":"kp","desc":"Proportional coefficient","lua_type":"number"},{"name":"ki","desc":"Integral coefficient","lua_type":"number"},{"name":"kd","desc":"Derivative coefficient","lua_type":"number"}],"returns":[{"desc":"","lua_type":"PID"}],"function_type":"static","source":{"line":61,"path":"modules/pid/init.lua"}},{"name":"Reset","desc":"Resets the PID to a zero start state.","params":[],"returns":[],"function_type":"method","source":{"line":82,"path":"modules/pid/init.lua"}},{"name":"Calculate","desc":"Calculates the new output based on the setpoint and input. For example,\\nif the PID was being used for a car\'s throttle control where the throttle\\ncan be in the range of [0, 1], then the PID calculation might look like\\nthe following:\\n```lua\\nlocal cruisePID = PID.new(0, 1, ...)\\nlocal desiredSpeed = 50\\n\\nRunService.Heartbeat:Connect(function()\\n\\tlocal throttle = cruisePID:Calculate(desiredSpeed, car.CurrentSpeed)\\n\\tcar:SetThrottle(throttle)\\nend)\\n```","params":[{"name":"setpoint","desc":"The desired point to reach","lua_type":"number"},{"name":"input","desc":"The current inputted value","lua_type":"number"},{"name":"deltaTime","desc":"Delta time","lua_type":"number"}],"returns":[{"desc":"","lua_type":"output: number"}],"function_type":"method","source":{"line":107,"path":"modules/pid/init.lua"}},{"name":"Debug","desc":"Creates a folder that contains attributes that can be used to\\ntune the PID during runtime within the explorer.\\n\\n:::info Studio Only\\nThis will only create the folder in Studio. In a real game server,\\nthis function will do nothing.","params":[{"name":"name","desc":"Folder name","lua_type":"string"},{"name":"parent","desc":"Folder parent","lua_type":"Instance?"}],"returns":[],"function_type":"method","source":{"line":145,"path":"modules/pid/init.lua"}},{"name":"Destroy","desc":"Destroys the PID. This is only necessary if calling `PID:Debug`.","params":[],"returns":[],"function_type":"method","source":{"line":194,"path":"modules/pid/init.lua"}}],"properties":[{"name":"POnE","desc":"POnE stands for \\"Proportional on Error\\".\\n\\nSet to `true` by default.\\n\\n- `true`: The PID applies the proportional calculation on the _error_.\\n- `false`: The PID applies the proportional calculation on the _measurement_.\\n\\nSetting this value to `false` may help the PID move smoother and help\\neliminate overshoot.\\n\\n```lua\\nlocal pid = PID.new(...)\\npid.POnE = true|false\\n```","lua_type":"boolean","source":{"line":46,"path":"modules/pid/init.lua"}}],"types":[],"name":"PID","desc":"The PID class simulates a [PID controller](https://en.wikipedia.org/wiki/PID_controller). PID is an acronym\\nfor _proportional, integral, derivative_. PIDs are input feedback loops that try to reach a specific\\ngoal by measuring the difference between the input and the desired value, and then returning a new\\ndesired input.\\n\\nA common example is a car\'s cruise control, which would give a PID the current speed\\nand the desired speed, and the PID controller would return the desired throttle input to reach the\\ndesired speed.\\n\\nOriginal code based upon the [Arduino PID Library](https://github.com/br3ttb/Arduino-PID-Library).","source":{"line":24,"path":"modules/pid/init.lua"}}')}}]);
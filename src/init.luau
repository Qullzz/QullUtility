--!native

--[[
@MADE BY 'Drop'

@DOCUMENTATION
- For Roblox Instances and yielding
- Provides a helpful set of functions to use when working
- Functions include: deep copy, deep search, Vector3s, async functions, etc...
]]

-- // TYPES // --

export type ConnectionLike =
	| RBXScriptConnection
	| {
		Connected : boolean,
		Disconnect : ( self : ConnectionLike ) -> ()
	}

export type SignalLike<T...> =
	| RBXScriptSignal
	| {
		Fire : ( self: SignalLike<T...>, T... ) -> (),
		Connect : ( self : SignalLike<T...>, callback : ( T... ) -> () ) -> ConnectionLike
	}

-- // MAIN // --

local Utility = {}

-- // FUNCTIONS // --

local function depthIterator(state)
	while true do
		local tab = state.tab
		local stack = state.stack
		local k = state.k
		
		local K, V = next(tab, k)
		
		while K == nil do
			if #stack == 0 then
				return nil
			end
			
			local last = table.remove(stack)
			tab, k = last[1], last[2]
			state.tab = tab
			state.k = k
			K, V = next(tab, k)
		end
		
		if typeof(V) == "table" then
			table.insert(stack, { tab, K })
			state.tab = V
			state.k = nil
			-- Iterate through the table
		else
			state.k = K
			return V
		end
	end
end

-- // MAIN // --

--[[
<strong>deepCopy</strong> – Copies a table deeply.

<strong>Parameters:</strong><br>
- <code>desiredTable</code> (`table`) – The table that'll be deeply copied.<br>

<strong>Returns:</strong><br>
- <code>table</code> – A copy of the passed table.

<em>i'm u.</em>.
]]
function Utility.deepCopy<T>( desiredTable: T ): T
	local copy = {} :: T
	
	--for key, value in pairs(desiredTable) do
	for key, value in desiredTable do
		copy[key] = typeof(value) == "table" and Utility.deepCopy(value :: T) or value
	end
	
	return copy
end

--[[
<strong>deepSearch</strong> – Searches a table, and any table inside of it. (Should be used like 'pairs / ipairs')

<strong>Parameters:</strong><br>
- <code>tab</code> (`table`) – The table that'll be deeply searched.<br>

<strong>Returns:</strong><br>
- <code>?҉༙྇ o҉༙྇ ʜ҉༙྇ w҉༙྇ </code> – ....

<em>....</em>.
]]
function Utility.deepSearch<T>( tab: T )
	local state = {
		tab = tab,
		stack = {},
		k = nil,
	}
	
	return depthIterator, state, nil
end

function Utility.observeTable<T>( tab: T, callback: ( key: any, value: any ) -> () )
	local mt = {}
	mt.__newindex = function( self, k: any, v: any )
		if self[k] == v then return end
		
		callback( k, v )
		rawset( self, k, v )
	end
	
	for key, value in tab do
		print(key, value)
		if typeof(value) ~= "table" then continue end
		
		setmetatable( value, mt )
	end
	
	setmetatable( tab, mt )
end

--[[
<strong>assetFormat</strong> – Turn an asset id to a valid asset format.

<strong>Parameters:</strong><br>
- <code>id</code> (`number`) – The asset's id to be turned into an asset format.<br>

<strong>Returns:</strong><br>
- <code>string</code> – A string of the asset in a valid asset format.

<em>dunno why'd i actually explain that.</em>.
]]
function Utility.assetFormat(id: number): string
	return typeof(id) == "number" and string.format("rbxassetid://%d", id) or nil
end

--[[
<strong>randomPickFrom</strong> – Picks up a random value of type T inside the passed holder with an optional seed.

<strong>Parameters:</strong><br>
- <code>holder</code> (`array<T> | Instance`) – The table to pick from.<br>
- <code>deep</code> (`boolean`) – Whether to include the descendants if the passed holder was an instance.<br>
- <code>seed</code> (`number?`) – The seed to be used when determining the output. (chosen randomly if not included)<br>

<strong>Returns:</strong><br>
- <code>T</code> – A value type from the holder.

<em>now generate a world.</em>
]]
function Utility.randomPickFrom<T>( value: { T } | Instance, deep: boolean?, seed: number? ): T
	
	if typeof(seed) == "number" then math.randomseed( seed ) end
	
	if typeof(value) == "table" then
		return #value > 0 and value[math.random(1, #value)] or nil
	elseif typeof(value) == "Instance" then
		local childs = deep == true and value:GetDescendants() or value:GetChildren()
		
		return #childs > 0 and childs[math.random(1, #childs)] or nil
	end
	
	return nil
end

--[[
<strong>WaitForDescendant</strong> – Yields until the descendant exists within the ancestor.

<strong>Parameters:</strong><br>
- <code>ancestor</code> (`Instance`) – The Instance that hold the children.<br>
- <code>name</code> (`string`) – The name of the wanted descendant.<br>
- <code>timeout</code> (`number`) – The amount of seconds to timeout.<br>

<strong>Returns:</strong><br>
- <code>Instance</code> – The descendant.

<em>took u some while?.</em>.
]]
function Utility.WaitForDescendant(ancestor: Instance, name: string, timeout: number?): Instance?
	-- // Checking // --
	do
		if typeof(ancestor) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(ancestor)} was passed instead`); return nil
		end
		
		if typeof(name) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(name)} was passed instead`); return nil
		end
		
		if timeout ~= nil and typeof(timeout) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(timeout)} was passed instead`)
			timeout = nil
		end
	end
	
	local child = ancestor:FindFirstChild(name, true)
	
	if child then return child end -- Return the child if found already --
	
	local connection: RBXScriptConnection?
	local destroyedConnection: RBXScriptConnection?
	local timeThread: thread?
	local thread: thread = coroutine.running()
	
	local function DisconnectAll()
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
			connection = nil
		end
		
		if typeof(destroyedConnection) == "RBXScriptConnection" then
			destroyedConnection:Disconnect()
			destroyedConnection = nil
		end
		
		if timeThread and timeThread ~= coroutine.running() then
			task.cancel(timeThread)
			timeThread = nil
		end
	end
	
	connection = ancestor.DescendantAdded:Connect(function(descendant: Instance)
		if descendant.Name ~= name then return end
		
		DisconnectAll()
		
		task.spawn(thread, descendant)
	end)
	
	destroyedConnection = ancestor.Destroying:Once(function()
		DisconnectAll()
		
		task.spawn(thread)
	end)
	
	if timeout then
		timeThread = task.delay(timeout, function()
			DisconnectAll()
			
			task.spawn(thread)
		end)
	end
	
	return coroutine.yield(thread)
end

--[[
<strong>WaitForChildOfType</strong> – Yields until a child of a certain type exists exists within the ancestor.

<strong>Parameters:</strong><br>
- <code>ancestor</code> (`Instance`) – The Instance that hold the children.<br>
- <code>instanceType</code> (`string`) – The type of the child to wait for.<br>
- <code>timeout</code> (`number`) – The amount of seconds to timeout.<br>
- <code>recursive</code> (`boolean`) – Determines if the search is recursive.<br>

<strong>Returns:</strong><br>
- <code>Instance</code> – The child.

<em>i'm special.</em>.
]]
function Utility.WaitForChildOfType(ancestor: Instance, instanceType: string, timeout: number?, recursive: boolean?): Instance?
	-- // Checking // --
	do
		if typeof(ancestor) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(ancestor)} was passed instead`); return nil
		end
		
		if timeout ~= nil and typeof(timeout) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(timeout)} was passed instead`)
			timeout = nil
		end
		
		if recursive ~= nil and typeof(recursive) ~= "boolean" then
			warn(`A type of 'boolean' must be passed, type {typeof(recursive)} was passed instead`)
			recursive = false
		end
	end
	
	local child = ancestor:FindFirstChildWhichIsA(instanceType, recursive == true)
	
	if child then return child end -- Return the child if found already --
	
	local connection: RBXScriptConnection?
	local destroyedConnection: RBXScriptConnection?
	local timeThread: thread?
	local thread: thread = coroutine.running()
	
	local function DisconnectAll()
		print(typeof(connection), typeof(destroyedConnection), typeof(timeThread))
		
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
			connection = nil
		end
		
		if typeof(destroyedConnection) == "RBXScriptConnection" then
			destroyedConnection:Disconnect()
			destroyedConnection = nil
		end
		
		if timeThread and timeThread ~= coroutine.running() then
			task.cancel(timeThread)
			timeThread = nil
		end
	end
	
	connection = ( recursive == true and ancestor.DescendantAdded or ancestor.ChildAdded ):Connect(function(obj: Instance)
		if not obj:IsA(instanceType) then return end
		
		DisconnectAll()
		
		task.spawn(thread, obj)
	end)
	
	destroyedConnection = ancestor.Destroying:Once(function()
		DisconnectAll()
		
		task.spawn(thread)
	end)
	
	if timeout then
		timeThread = task.delay(timeout, function()
			DisconnectAll()
			task.spawn(thread)
		end)
	end
	
	return coroutine.yield(thread)
end

--[[
<strong>WaitForChildFirst</strong> – Yields until one of the named childs exists within the ancestor.

<strong>Parameters:</strong><br>
- <code>ancestor</code> (`Instance`) – The Instance that hold the children.<br>
- <code>names</code> (`table{string}`) – A table the holds the name of the desired children.<br>
- <code>timeout</code> (`number`) – The amount of seconds to timeout.<br>
- <code>recursive</code> (`boolean`) – Determines if the search is recursive.<br>

<strong>Returns:</strong><br>
- <code>Instance</code> – One of the named children.

<em>YOOO RACE.</em>.
]]
function Utility.WaitForChildFirst(ancestor: Instance, names: {string}, timeout: number?, recursive: boolean?): Instance?
	-- // CHECKING // --
	do
		if typeof(ancestor) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(ancestor)} was passed instead`); return nil
		end
		
		if typeof(names) ~= "table" then
			warn(`A type of 'table' must be passed, type {typeof(names)} was passed instead`); return nil
		end
		
		if timeout ~= nil and typeof(timeout) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(timeout)} was passed instead`)
			timeout = nil
		end
		
		if recursive ~= nil and typeof(recursive) ~= "boolean" then
			warn(`A type of 'boolean' must be passed, type {typeof(recursive)} was passed instead`)
			recursive = false
		end
	end
	
	for _, childName in pairs(names) do
		local child = ancestor:FindFirstChild(childName)
		
		if child then return child end
	end
	
	local addedConnection: RBXScriptConnection?
	local destroyedConnection: RBXScriptConnection?
	local timeThread: thread?
	local thread: thread = coroutine.running()
	
	local function DisconnectAll()
		if ( typeof(addedConnection) == "RBXScriptConnection" and addedConnection.Connected ) then
			addedConnection:Disconnect()
			addedConnection = nil
		end
		
		if ( typeof(destroyedConnection) == "RBXScriptConnection" and destroyedConnection.Connected ) then
			destroyedConnection:Disconnect()
			destroyedConnection = nil
		end
		
		if timeThread and timeThread ~= coroutine.running() then
			task.cancel(timeThread)
			timeThread = nil
		end
	end
	
	addedConnection = ( recursive and ancestor.DescendantAdded or ancestor.ChildAdded ):Connect(function(child: Instance)
		if table.find(names, child.Name) then
			DisconnectAll()
			task.spawn(thread, child)
		end
	end)
	
	destroyedConnection = ancestor.Destroying:Once(function()
		DisconnectAll()
		task.spawn(thread)
	end)
	
	if timeout then
		timeThread = task.delay(timeout, function()
			task.spawn(thread)
			DisconnectAll()
		end)
	end
	
	return coroutine.yield(thread)
end

--[[
<strong>WaitForProperty</strong> – Yields until a Instance's property exists.

<strong>Parameters:</strong><br>
- <code>instance</code> (`Instance`) – The Instance that hold the property.<br>
- <code>property</code> (`string`) – The property to look for.<br>

<strong>Returns:</strong><br>
- <code>Property-Value</code> – Could be anything dude.

<em>wait for me.</em>.
]]
function Utility.WaitForProperty(instance: Instance, property: string): any?
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(property) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(property)} was passed instead`); return nil
		end
	end
	
	do
		local exists, _ = pcall(function(ins: Instance, prop: string)
			return ins[prop]
		end, instance, property)
		
		if not exists then
			warn(`The property '{property}' does not exist in the instance '{instance}'`)
			return
		end
	end
	
	if instance[property] ~= nil then return instance[property] end
	
	local changedConnection: RBXScriptConnection?
	local destroyedConnection: RBXScriptConnection?
	local thread = coroutine.running()
	
	local function DisconnectAll()
		if ( typeof(changedConnection) == "RBXScriptConnection" and changedConnection.Connected ) then
			changedConnection:Disconnect()
			changedConnection = nil
		end
		
		if ( typeof(destroyedConnection) == "RBXScriptConnection" and destroyedConnection.Connected ) then
			destroyedConnection:Disconnect()
			destroyedConnection = nil
		end
	end
	
	changedConnection = instance:GetPropertyChangedSignal(property):Connect(function()
		local value = instance[property]
		
		if value == nil then return end
		
		DisconnectAll()
		
		task.spawn(thread, value)
	end)
	
	destroyedConnection = instance.Destroying:Once(function()
		DisconnectAll()
		
		task.spawn(thread)
	end)
	
	return coroutine.yield(thread)
end

--[[
<strong>WaitForAttribute</strong> – Yields until a Instance's attribute exists (also the value mustn't be nil ).

<strong>Parameters:</strong><br>
- <code>instance</code> (`Instance`) – The Instance that hold the attribute.<br>
- <code>attribute</code> (`string`) – The attribute to look for.<br>

<strong>Returns:</strong><br>
- <code>Property-Value</code> – Could be anything dude.

<em>wait for me.</em>.
]]
function Utility.WaitForAttribute(instance: Instance, attribute: string): any?
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(attribute) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(attribute)} was passed instead`); return nil
		end
	end
	
	local value = instance:GetAttribute( attribute )
	
	if value then return value end
	
	local changedConnection: RBXScriptConnection?
	local destroyedConnection: RBXScriptConnection?
	local thread = coroutine.running()
	
	local function DisconnectAll()
		if ( typeof(changedConnection) == "RBXScriptConnection" and changedConnection.Connected ) then
			changedConnection:Disconnect()
			changedConnection = nil
		end
		
		if ( typeof(destroyedConnection) == "RBXScriptConnection" and destroyedConnection.Connected ) then
			destroyedConnection:Disconnect()
			destroyedConnection = nil
		end
	end
	
	changedConnection = instance:GetAttributeChangedSignal( attribute ):Connect(function()
		local value = instance:GetAttribute( attribute )
		
		if value == nil then return end
		
		DisconnectAll()
		
		task.spawn(thread, value)
	end)
	
	destroyedConnection = instance.Destroying:Once(function()
		DisconnectAll()
		
		task.spawn(thread)
	end)
	
	return coroutine.yield(thread)
end

--[[Destroy's an Instance inside 'instance' that has the same name as 'instanceName', whether it already exists or added later.]]
function Utility.PopItem( instance: Instance, instanceName: string, timeout: number?, recursive: boolean? ): ()
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return
		end
		
		if typeof(instanceName) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(instanceName)} was passed instead`); return
		end
		
		if timeout ~= nil and typeof(timeout) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(timeout)} was passed instead`)
			
			timeout = nil
		end
		
		if recursive ~= nil and typeof(recursive) ~= "boolean" then
			warn(`A type of 'boolean' must be passed, type {typeof(recursive)} was passed instead`)
			recursive = false
		end
	end
	
	if recursive then
		local item = Utility.WaitForDescendant( instance, instanceName, timeout )
		
		if not item then return end
		
		item:Destroy()
	else
		local item = instance:WaitForChild( instanceName, timeout )
		
		if not item then return end
		
		item:Destroy()
	end
	
	--local item = instance:FindFirstChild( instanceName, recursive )
	
	--if item then item:Destroy(); return end
	
	--local connection: RBXScriptConnection = nil
	--local destroyingConnection: RBXScriptConnection = nil
	--local timeThread: thread = nil
	
	--local function DisconnectAll()
	--	if typeof(connection) == "RBXScriptConnection" and connection.Connected then
	--		connection:Disconnect()
	--		connection = nil
	--	end
		
	--	if typeof(destroyingConnection) == "RBXScriptConnection" and connection.Connected then
	--		destroyingConnection:Disconnect()
	--		destroyingConnection = nil
	--	end
		
	--	if typeof(timeThread) == "thread" then
	--		task.cancel(timeThread)
	--		timeThread = nil
	--	end
	--end
	
	--connection = ( recursive and instance.DescendantAdded or instance.ChildAdded ):Connect(function(child)
		
	--	if child.Name ~= instanceName then return end
		
	--	child:Destroy()
		
	--	DisconnectAll()
	--end)
	
	--destroyingConnection = instance.Destroying:Once(function()
	--	DisconnectAll()
	--end)
	
	--if timeout then
	--	timeThread = task.delay(timeout, function()
	--		DisconnectAll()
	--	end)
	--end
end

--[[Destroy's an Instance inside 'instance' that has the same type as 'instanceType', whether it already exists or added later.]]
function Utility.PopItemOfType( instance: Instance, instanceType: string, timeout: number?, recursive: boolean? ): ()
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return
		end
		
		if typeof(instanceType) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(instanceType)} was passed instead`); return
		end
		
		if timeout ~= nil and typeof(timeout) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(timeout)} was passed instead`)
			
			timeout = nil
		end
		
		if recursive ~= nil and typeof(recursive) ~= "boolean" then
			warn(`A type of 'boolean' must be passed, type {typeof(recursive)} was passed instead`)
			recursive = false
		end
	end
	
	local item = Utility.WaitForChildOfType( instance, instanceType, timeout, recursive )
	
	if not item then return end
	
	item:Destroy()
end

--[[This one is useless, but too late already.]]
function Utility.GetAncestorBefore( instance: Instance, before: ( Instance | string )? ): Instance?
	if not ( typeof(before) == "Instance" or typeof(before) == "string" ) then
		warn("You didn't pass the ancestor or the name for it."); return nil
	end
	
	local name = typeof(before) == "string" and before or before.Name
	
	if instance.Parent == before then return instance end
	
	local fullName = instance:GetFullName()
	
	if not fullName:find(name) then
		warn(`{instance} is not under {before}`); return nil
	end
	
	local parent = instance
	local found = false
	
	while ( found == false and parent ~= game ) do
		local newParent = parent.Parent
		
		if newParent.Parent.Name == name then
			break
		else
			parent = newParent
		end
	end
	
	return parent
end

--[[This gets the furthest ancestor of certian type relative to an instance.]]
function Utility.GetFarAncestorOfType( instance: Instance, ancestorType: string, exclude: { Instance }? ): Instance?
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(ancestorType) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(ancestorType)} was passed instead`); return nil
		end
	end
	
	local parent = instance
	
	while parent do
		local ins = parent
		parent = parent.Parent
		
		if not ins or ins == game or ( exclude and table.find( exclude, ins ) ) then break end
		
		if not ins:IsA( ancestorType ) then continue end
		
		return ins
	end
	
	return nil
end

--[[This is used to alter the anchor state of an instance, especially if it's a Model.]]
function Utility.SetAnchor( instance: Instance, state: boolean ): ()
	
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(state) ~= "boolean" then
			if state ~= nil then
				warn(`A type of 'boolean' must be passed, type {typeof(state)} was passed instead`)
			end
			
			state = false
		end
	end
	
	if instance:IsA("BasePart") then
		instance.Anchored = state
	elseif instance:IsA("Model") then
		for _, subPart in ipairs(instance:GetDescendants() :: { BasePart }) do
			
			if not subPart:IsA("BasePart") then continue end
			
			subPart.Anchored = state
		end
	end
end

--[[This is used to alter the collisions of an instance, especially if it's a Model.]]
function Utility.SetCollisions( instance: Instance, state: boolean ): ()
	
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(state) ~= "boolean" then
			if state ~= nil then
				warn(`A type of 'boolean' must be passed, type {typeof(state)} was passed instead`)
			end
			
			state = false
		end
	end
	
	if instance:IsA("BasePart") then
		instance.CanCollide = state
	elseif instance:IsA("Model") then
		for _, subPart in ipairs(instance:GetDescendants() :: { BasePart }) do
			
			if not subPart:IsA("BasePart") then continue end
			
			subPart.CanCollide = state
		end
	end
end

--[[This is used to alter the query of an instance, especially if it's a Model.]]
function Utility.SetQuery( instance: Instance, state: boolean ): ()
	
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(state) ~= "boolean" then
			if state ~= nil then
				warn(`A type of 'boolean' must be passed, type {typeof(state)} was passed instead`)
			end
			
			state = false
		end
	end
	
	if instance:IsA("BasePart") then
		instance.CanQuery = state
	elseif instance:IsA("Model") then
		for _, subPart in ipairs(instance:GetDescendants() :: { BasePart }) do
			
			if not subPart:IsA("BasePart") then continue end
			
			subPart.CanQuery = state
		end
	end
end

--[[This is used to alter the transparency of an instance, especially if it's a Model.]]
function Utility.SetTransparency( instance: Instance, transparency: number, localTransparency: boolean? ): ()
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(transparency) ~= "number" then
			if transparency ~= nil then
				warn(`A type of 'number' must be passed, type {typeof(transparency)} was passed instead`)
			end
			
			transparency = 1
		end
		
		if localTransparency ~= nil and typeof(localTransparency) ~= "boolean" then
			warn(`A type of 'boolean' must be passed, type {typeof(localTransparency)} was passed instead`)
			localTransparency = false
		end
	end
	
	if instance:IsA("BasePart") then
		instance[ localTransparency and "LocalTransparencyModifier" or "Transparency" ] = transparency
	else
		for _, subPart in ipairs(instance:GetDescendants() :: { BasePart }) do
			
			if not subPart:IsA("BasePart") then continue end
			
			subPart[ localTransparency and "LocalTransparencyModifier" or "Transparency" ] = transparency
		end
	end
end

--[[Checks whether an instance has a neighbor of a certian type]]
function Utility.HasNeighbor( instance: Instance, neighborType: string ): (boolean, Instance?)
	-- // CHECKING // --
	do
		if typeof(instance) ~= "Instance" then
			warn(`A type of 'Instance' must be passed, type {typeof(instance)} was passed instead`); return nil
		end
		
		if typeof(neighborType) ~= "string" then
			warn(`A type of 'string' must be passed, type {typeof(neighborType)} was passed instead`); return nil
		end
	end
	
	local current: Instance = instance
	
	while true do
		current = current.Parent
		
		if not current or current == game then break end
		
		local target = current:FindFirstChildOfClass( neighborType )
		
		if not target then continue end
		
		return true, target
	end
	
	return false, nil
end

--[[
<strong>Connect</strong> – Connects to a signal and provides a function to disconnect from it

<strong>Parameters:</strong><br>
- <code>signal</code> (`SignalLike`) – The signal to connect to.<br>
- <code>callback</code> (`(disconnect: () -> (), T...) -> ()`) – The callback that'll be called when the signal is fired.
The disconnect function will be passed as the first argument, followed by the signal's arguments.<br><br>

<strong>Returns:</strong><br>
- <code>nil</code>

<em>Some weird message.</em>.
]]
function Utility.Connect<T...>( signal: SignalLike<T...>, callback: ( disconnect: () -> (), T... ) -> () ): ()
	local connection: ConnectionLike?
	
	local function disconnect(): ()
		
		if not connection or not connection.Connected then return end
		
		connection:Disconnect()
		connection = nil
	end
	
	connection = signal:Connect(function( ... )
		callback( disconnect, ... )
	end)
end

--[[
<strong>MaxVector</strong> – Clamps the vector so that the magnitude doesn't exceed the defined maximum.

<strong>Parameters:</strong><br>
- <code>vec</code> (`Vector3 / Vector2`) – The vector to clamp.<br>
- <code>max</code> (`number`) – The maximum allowed value for each component.<br>

<strong>Returns:</strong><br>
- <code>Vector3 / Vector2</code> – A vector with all components ≤ the given maximum.

<em>i'm the original medjed</em>.
]]
function Utility.MaxVector<T>(vec: T, maximumMagnitude: number): T
	-- // CHECKING // --
	do
		if typeof(vec) ~= "Vector3" and typeof(vec) ~= "Vector2" then
			warn(`A type of 'Vector3 / Vector2' must be passed, type {typeof(vec)} was passed instead`); return nil
		end
		
		if typeof(maximumMagnitude) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(maximumMagnitude)} was passed instead`); return nil
		end
	end
	
	if vec.Magnitude == 0 then
		return typeof(vec) == "Vector3" and Vector3.zero or Vector2.zero
	end
	
	if vec.Magnitude > maximumMagnitude then
		return vec.Unit * maximumMagnitude
	else
		return vec
	end
end

--[[
Sets a minimum magnitude for the vector, ensuring it can't be smaller than the defined magnitude.

<strong>Parameters:</strong><br>
<strong>vec</strong> (<code>Vector3 / Vector2</code>) – The vector to enforce the minimum magnitude on.<br>
<strong>minMag</strong> (<code>number</code>) – The minimum allowed magnitude.<br>

<strong>Returns:</strong><br>
<code>Vector3 / Vector2</code> – A vector with at least the specified magnitude.
]]

--[[
<strong>MinVector</strong> – Clamps the vector so that the magnitude doesn't fall behind the defined minimum.

<strong>Parameters:</strong><br>
- <code>vec</code> (`Vector3 / Vector2`) – The vector to clamp.<br>
- <code>max</code> (`number`) – The maximum allowed value for each component.<br>

<strong>Returns:</strong><br>
- <code>Vector3 / Vector2</code> – A vector with all components ≤ the given maximum.

<em>i'm the original medjed</em>.
]]
function Utility.MinVector<T>(vec: T, minimumMagnitude: number): T
	-- // CHECKING // --
	do
		if typeof(vec) ~= "Vector3" and typeof(vec) ~= "Vector2" then
			warn(`A type of 'Vector3 / Vector2' must be passed, type {typeof(vec)} was passed instead`); return nil
		end
		
		if typeof(minimumMagnitude) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(minimumMagnitude)} was passed instead`); return nil
		end
	end
	
	if vec.Magnitude == 0 then
		return typeof(vec) == "Vector3" and Vector3.zero or Vector2.zero
	end
	
	if vec.Magnitude < minimumMagnitude then
		return vec.Unit * minimumMagnitude
	else
		return vec
	end
end

--[[
Clamps a vector between 2 magnitudes

<strong>'vec' (Vector3 / Vector2) :</strong> The vector to clamp
<strong>'minMag' (number) :</strong> The minimum magnitude
<strong>'maxMag' (number) :</strong> -- The maximum magnitude
<code>Returns the clamped vector</code>
]]
function Utility.ClampVector<T>(vec: T, minMag: number, maxMag: number): T
	-- // CHECKING // --
	do
		if typeof(vec) ~= "Vector3" and typeof(vec) ~= "Vector2" then
			warn(`A type of 'Vector3 / Vector2' must be passed, type {typeof(vec)} was passed instead`); return nil
		end
		
		if typeof(minMag) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(minMag)} was passed instead`); return nil
		end
		
		if typeof(maxMag) ~= "number" then
			warn(`A type of 'number' must be passed, type {typeof(maxMag)} was passed instead`); return nil
		end
	end
	
	return Utility.MaxVector(Utility.MinVector(vec, minMag), maxMag)
end

--[[
Sets the vector's magnitude to 1 (used for getting the direction only)

<strong>'vec' (Vector3 / Vector2) :</strong> The vector to unitize
<code>Returns a unit vector with the same direction as the given vector</code>
]]
function Utility.UnitVector<T>(vec: T): T
	-- // CHECKING // --
	if typeof(vec) ~= "Vector3" and typeof(vec) ~= "Vector2" then
		warn(`A type of 'Vector3 / Vector2' must be passed, type {typeof(vec)} was passed instead`); return nil
	end
	
	return Utility.ClampVector( vec, 1, 1 )
end

--[[
Wraps the angle (in radians) between -pi and +pi

<strong>'angle' (number) :</strong> the angle to wrap
<code>Returns an angle wrapped between -pi and +pi</code>
]]
function Utility.WrapAngle(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

return Utility
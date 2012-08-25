--[[ 
		luaunit.lua

Description: A unit testing framework
Homepage: https://github.com/bluebird75/luaunit
Initial author: Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
Lot of improvements by Philippe Fremy <phil@freehackers.org>
License: BSD License, see LICENSE.txt
]]--

argv = arg

--[[ Some people like assertEquals( actual, expected ) and some people prefer 
assertEquals( expected, actual ).
]]--
USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS = true

function assertError(f, ...)
	-- assert that calling f with the arguments will raise an error
	-- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
	local has_error, error_msg = not pcall( f, ... )
	if has_error then return end 
	error( "Expected an error but no error generated", 2 )
end

function assertEquals(actual, expected)
	-- assert that two values are equal and calls error else
	if  actual ~= expected  then
		local function wrapValue( v )
			if type(v) == 'string' then return "'"..v.."'" end
			return tostring(v)
		end
		if not USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS then
			expected, actual = actual, expected
		end

		local errorMsg
		if type(expected) == 'string' then
			errorMsg = "\nexpected: "..wrapValue(expected).."\n"..
                             "actual  : "..wrapValue(actual).."\n"
		else
			errorMsg = "expected: "..wrapValue(expected)..", actual: "..wrapValue(actual)
		end
		error( errorMsg, 2 )
	end
end

assert_equals = assertEquals
assert_error = assertError

function wrapFunctions(...)
	-- Use me to wrap a set of functions into a Runnable test class:
	-- TestToto = wrapFunctions( f1, f2, f3, f3, f5 )
	-- Now, TestToto will be picked up by LuaUnit:run()
	local testClass, testFunction
	testClass = {}
	for i,testName in ipairs({...}) do
		testFunction = _G[testName]
		testClass[testName] = testFunction
	end
	return testClass
end

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key,_ in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
	-- Equivalent of the next() function of table iteration, but returns the
	-- keys in the alphabetic order. We use a temporary ordered key table that
	-- is stored in the table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    local key
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = nil
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,#t.__orderedIndex do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

function strsplit(delimiter, text)
-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
	local list = {}
	local pos = 1
	if string.find("", delimiter, 1) then -- this would result in endless loops
		error("delimiter matches empty string!")
	end
	while 1 do
		local first, last = string.find(text, delimiter, pos)
		if first then -- found?
			table.insert(list, string.sub(text, pos, first-1))
			pos = last+1
		else
			table.insert(list, string.sub(text, pos))
			break
		end
	end
	return list
end


function prefixString( prefix, s )
	local t, s2
	t = strsplit('\n', s)
	s2 = prefix..table.concat(t, '\n'..prefix)
	return s2
end


----------------------------------------------------------------
--					   class TapOutput
----------------------------------------------------------------

TapOutput = { -- class
	runner = nil,
	result = nil,
}
TapOutput_MT = { __index = TapOutput }

	function TapOutput:new()
		local t = {}
		t.verbosity = 0
		setmetatable( t, TapOutput_MT )
		return t
	end
	function TapOutput:startSuite() end
	function TapOutput:startClass(className) end
	function TapOutput:startTest(testName) end

	function TapOutput:addFailure( errorMsg )
	   print(string.format("not ok %d\t%s", self.result.testCount, self.result.currentTestName ))
	   if self.verbosity > 0 then
		   print( prefixString( '    ', errorMsg ) )
		end
	end

	function TapOutput:endTest(testHasFailure)
	   if not self.result.currentTestHasFailure then
	      print(string.format("ok     %d\t%s", self.result.testCount, self.result.currentTestName ))
	   end
	end

	function TapOutput:endClass() end

	function TapOutput:endSuite()
	   print("1.."..self.result.testCount)
	   return self.result.failureCount
	end


-- class TapOutput end


----------------------------------------------------------------
--					   class TextOutput
----------------------------------------------------------------

TextOutput = {}
TextOutput_MT = { -- class
	__index = TextOutput
}

	function TextOutput:new()
		local t = {}
		t.runner = nil
		t.result = nil
		t.errorList ={}
		t.verbosity = 1
		setmetatable( t, TextOutput_MT )
		return t
	end

	function TextOutput:startSuite()
	end

	function TextOutput:startClass(className)
		print( '>>>>>>>>> '.. self.result.currentClassName )
	end

	function TextOutput:startTest(testName)
		if self.verbosity > 0 then
			print( ">>> ".. self.result.currentTestName )
		end
	end

	function TextOutput:addFailure( errorMsg )
		table.insert( self.errorList, { self.currentTestName, errorMsg } )
		if self.verbosity == 0 then
			io.stdout:write("F")
		else
			print( errorMsg )
			print( 'Failed' )
		end
	end

	function TextOutput:endTest(testHasFailure)
		if not testHasFailure then
			if self.verbosity > 0 then
				--print ("Ok" )
			else 
				io.stdout:write(".")
			end
		end
	end

	function TextOutput:endClass()
	   print()
	end

	function TextOutput:displayOneFailedTest( failure )
		testName, errorMsg = unpack( failure )
		print(">>> "..testName.." failed")
		print( errorMsg )
	end

	function TextOutput:displayFailedTests()
		if #self.errorList == 0 then return end
		print("Failed tests:")
		print("-------------")
		for i,v in ipairs(self.errorList) do
			self:displayOneFailedTest( v )
		end
		print()
	end

	function TextOutput:endSuite()
		print("=========================================================")
		self:displayFailedTests()
		local failurePercent, successCount
		if self.result.testCount == 0 then
			failurePercent = 0
		else
			failurePercent = 100 * self.result.failureCount / self.result.testCount
		end
		successCount = self.result.testCount - self.result.failureCount
		print( string.format("Success : %d%% - %d / %d",
			100-math.ceil(failurePercent), successCount, self.result.testCount) )
    end


-- class TextOutput end


----------------------------------------------------------------
--					   class LuaUnit
----------------------------------------------------------------

LuaUnit = {
	outputType = TextOutput
}
LuaUnit_MT = { __index = LuaUnit }

	function LuaUnit:new()
		local t = {}
		setmetatable( t, LuaUnit_MT )
		return t
	end

	-----------------[[ Utility methods ]]---------------------

	function LuaUnit.isFunction(aObject) 
		return 'function' == type(aObject)
	end

	function LuaUnit.strip_luaunit_stack(stack_trace)
		stack_list = strsplit( "\n", stack_trace )
		strip_end = nil
		for i = #stack_list,1,-1 do
			-- a bit rude but it works !
			if string.find(stack_list[i],"[C]: in function `xpcall'",0,true)
				then
				strip_end = i - 2
			end
		end
		if strip_end then
			table.setn( stack_list, strip_end )
		end
		stack_trace = table.concat( stack_list, "\n" )
		return stack_trace
	end


	--------------[[ Output methods ]]-------------------------

	function LuaUnit:startSuite()
		self.result = {}
		self.result.failureCount = 0
		self.result.testCount = 0
		self.result.currentTestName = ""
		self.result.currentClassName = ""
		self.result.currentTestHasFailure = false
		self.outputType = self.outputType or TextOutput
		self.output = self.outputType:new()
		self.output.runner = self
		self.output.result = self.result
		self.output:startSuite()
	end

	function LuaUnit:startClass( aClassName )
		self.result.currentClassName = aClassName
		self.output:startClass( aClassName )
	end

	function LuaUnit:startTest( aTestName  )
		self.result.currentTestName = aTestName
  		self.result.testCount = self.result.testCount + 1
  		self.result.currentTestHasFailure = false
		self.output:startTest( aTestName )
	end

	function LuaUnit:addFailure( errorMsg )
		self.result.failureCount = self.result.failureCount + 1
		self.result.currentTestHasFailure = true
		self.output:addFailure( errorMsg )
    end

    function LuaUnit:endTest()
		self.output:endTest( self.currentTestHasFailure )
		self.result.currentTestName = ""
		self.result.currentTestHasFailure = false
    end

    function LuaUnit:endClass()
    	self.output:endClass()
    end

    function LuaUnit:endSuite()
		self.output:endSuite()
	end

   	function LuaUnit:setOutputType(outputType)
      	-- default to text
      	-- tap produces results according to TAP format
      	if outputType:upper() == "TAP" then
        	self.outputType = TapOutput
    	else 
    		if outputType:upper() == "TEXT" then
      			self.outputType = TextOutput
    		else 
    			error( 'No such format: '..outputType)
    		end 
    	end
	end

	--------------[[ Runner ]]-----------------

    function LuaUnit:runTestMethod(aName, aClassInstance, aMethod)
		local ok, errorMsg
		-- example: runTestMethod( 'TestToto:test1', TestToto, TestToto.testToto(self) )
		self:startTest(aName)

		-- run setUp first(if any)
		if self.isFunction( aClassInstance.setUp ) then
				aClassInstance:setUp()
		end

		local function err_handler(e)
			return e..'\n'..debug.traceback()
		end

		-- run testMethod()
        ok, errorMsg = xpcall( aMethod, err_handler )
		if not ok then
			errorMsg  = self.strip_luaunit_stack(errorMsg)
			self:addFailure( errorMsg )
        end

		-- lastly, run tearDown(if any)
		if self.isFunction(aClassInstance.tearDown) then
			 aClassInstance:tearDown()
		end

		self:endTest()
    end

	function LuaUnit:runTestMethodName( methodName, classInstance )
		-- example: runTestMethodName( 'TestToto:testToto', TestToto )
		local methodInstance = loadstring(methodName .. '()')
		self:runTestMethod(methodName, classInstance, methodInstance)
	end

    function LuaUnit:runTestClassByName( aClassName )
		-- example: runTestClassByName( 'TestToto' )
		local hasMethod, methodName, classInstance
		hasMethod = string.find(aClassName, ':' )
		if hasMethod then
			methodName = string.sub(aClassName, hasMethod+1)
			aClassName = string.sub(aClassName,1,hasMethod-1)
		end
        classInstance = _G[aClassName]
		if not classInstance then
			error( "No such class: "..aClassName )
		end
		self:startClass( aClassName )

		if hasMethod then
			if not classInstance[ methodName ] then
				error( "No such method: "..methodName )
			end
			self:runTestMethodName( aClassName..':'.. methodName, classInstance )
		else
			-- run all test methods of the class
			for methodName, method in orderedPairs(classInstance) do
			--for methodName, method in classInstance do
				if LuaUnit.isFunction(method) and string.sub(methodName, 1, 4) == "test" then
					--print(methodName)
					self:runTestMethodName( aClassName..':'.. methodName, classInstance )
				end
			end
		end

		self:endClass()
   	end

	function LuaUnit:run(...)
		-- Run some specific test classes.
		-- If no arguments are passed, run the class names specified on the
		-- command line. If no class name is specified on the command line
		-- run all classes whose name starts with 'Test'
		--
		-- If arguments are passed, they must be strings of the class names 
		-- that you want to run
		local runner = self:new()
		return runner:runSuite(...)
	end

	function LuaUnit:runSuite(...)
		self:startSuite()

        args={...};
		if #args == 0 then
			args = argv
		end

		if #args == 0 then
			-- create the list if classes to run now ! If not, you can
			-- not iterate over _G while modifying it.
			args = {}
			for key, val in pairs(_G) do 
				if string.sub(key,1,4) == 'Test' then 
					table.insert( args, key )
				end
			end
			table.sort( args )
		end

		for i,fname in ipairs( args ) do
			self:runTestClassByName( fname )
		end

		self:endSuite()
		return self.result.failureCount
	end
-- class LuaUnit

Classes.Application.ThreadsManager = Class(Object, function(this)
	Object.init(this, 'ThreadsManager');

	------------------------------------------------------------------------------------------------------------------
	----- Fields -----------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------

	local threads;
	local threadsToDelete;

	local events;
	local tFilters;

	------------------------------------------------------------------------------------------------------------------
	----- Methods ----------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------

	local function contains(_id)
		for i = 1, #threads do
			if (threads[i]:GetId() == _id) then
				return true;
			end
		end

		return false;
	end

	local function getThread(_id)
		for i = 1, #threads do
			if (threads[i]:GetId() == _id) then
				return threads[i], i;
			end
		end

		return nil, nil;
	end

	function this:AddThread(_thread)
		if (type(_thread) ~= 'table' or _thread.GetClassName == nil or _thread:GetClassName() ~= 'Thread') then
			error('ThreadsManager.AddThread [thread]: Thread expected, got '..type(_thread)..'.');
		end
		if (_thread:GetId() ~= nil) then
			error('ThreadsManager.AddThread [thread]: Thread is allready initialized.');
		end

		_thread:Initialize(System:GenerateId());
		table.insert(threads, _thread);
	end

	function this:RemoveThread(_id)
		if (type(_id) ~= 'string') then
			error('ThreadsManager.RemoveThread [id]: String expected, got '..type(_id)..'.');
		end

		if (contains(_id)) then
			table.insert(threadsToDelete, _id);
		end
	end

	function this:GetThreadsCount()
		return #threads;
	end

	function this:Clear()
		threads = {};
		threadsToDelete = {};
		tFilters = {};
	end

	function this:Update()
		if (#events == 0) then
			this:ProcessTimerEvent(0);
		end

		while (#events > 0) do
			local event = events[1];
			table.remove(events, 1);
			
			for i = 1, #threads do
				local thread = threads[i];
				local id = thread:GetId();
				if (tFilters[id] == nil or tFilters[id] == event[1] or event[1] == 'terminate') then
					local ok, params = thread:Resume(event);
					if (not ok) then
						error(params);
					else
						tFilters[id] = params;
					end
					if (thread:GetStatus() == 'dead') then
						this:RemoveThread(id);
					end
				end
			end

			for i = 1, #threadsToDelete do
				local _, index = getThread(threadsToDelete[i]);
				if (index ~= nil) then
					table.remove(threads, index);
				end
			end

			threadsToDelete = {};
		end
	end

	-- Events

	function this:ProcessLeftClickEvent(_cursorX, _cursorY)
		local event = { 'mouse_click', 1, _cursorX, _cursorY };
		table.insert(events, event);
	end

	function this:ProcessRightClickEvent(_cursorX, _cursorY)
		local event = { 'mouse_click', 2, _cursorX, _cursorY };
		table.insert(events, event);
	end

	function this:ProcessKeyEvent(_key)
		local event = { 'key', _key };
		table.insert(events, event);
	end

	function this:ProcessCharEvent(_symbol)
		local event = { 'char', _symbol };
		table.insert(events, event);
	end

	function this:ProcessRednetEvent(_id, _message, _distance, _side, _channel)
		local event = { 'modem_message', _side, _channel, _id, _message, _distance };
		table.insert(events, event);
		local event2 = { 'rednet_message', _id, _message, _distance };
		table.insert(events, event2);
	end

	function this:ProcessLeftMouseDragEvent(_newCursorX, _newCursorY)
		local event = { 'mouse_drag', 1, _newCursorX, _newCursorY };
		table.insert(events, event);
	end

	function this:ProcessRightMouseDragEvent(_newCursorX, _newCursorY)
		local event = { 'mouse_drag', 2, _newCursorX, _newCursorY };
		table.insert(events, event);
	end

	function this:ProcessTimerEvent(_timerId)
		local event = { 'timer', _timerId };
		table.insert(events, event);
	end

	function this:ProcessRedstoneEvent()
		local event = { 'redstone' };
		table.insert(events, event);
	end

	function this:ProcessMouseScrollEvent(_direction, _cursorX, _cursorY)
		local event = { 'mouse_scroll', _direction, _cursorX, _cursorY };
		table.insert(events, event);
	end

	function this:ProcessHttpEvent(_status, _url, _handler)
		local event;
		if (_status) then
			event = { 'http_success', _url, _handler };
		else
			event = { 'http_failure', _url, _handler };
		end
		table.insert(events, event);
	end

	function this:ProcessTerminateEvent()
		event = { 'terminate' };
		table.insert(events, event);
	end

	------------------------------------------------------------------------------------------------------------------
	----- Constructors -----------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------

	local function constructor()
		threads = {};
		threadsToDelete = {};
		events = {};
		tFilters = {};
	end

	constructor();
end)
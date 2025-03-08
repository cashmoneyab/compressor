local cca = {}

cca.spaceChar = "\0";
cca.collapseChar = "!"

function cca:setup(dictionary)
	self.list = dictionary;
	self.index = {};
	self.dictionary = table.clone(self.list);

	for i,v in next, dictionary do self.index[v] = i; end
end

function cca.convertNum(number)
	return string.char(number) --string.format("%x", number)
end

function cca:compile(content)
	assert(self.list and self.dictionary, "No dictionary found! Please setup cca before using it!")
	
	local result = {};
	local lastCharacter;
	local dictionary = table.clone(self.dictionary);

	local count = 0;
	for i,v in next, dictionary do
		count = count +1;
	end
	
	content:gsub(".", function(character)
		if dictionary[character] then
			if lastCharacter and dictionary[lastCharacter .. character] then

				table.remove(result, #result);
				table.insert(result, dictionary[lastCharacter .. character]);

				lastCharacter = nil;
				return character;
			elseif lastCharacter then
				count = count + 1;

				dictionary[lastCharacter .. character] = self.convertNum(count);

				table.insert(result, dictionary[character]);
				lastCharacter = nil;
				return character;
			end
			lastCharacter = character;
			table.insert(result, dictionary[character]);
			return character;
		else
			error("Invalid character, not found in dictionary!")
		end
	end)
	return result
end

function cca:decompile(result)
	assert(self.list and self.dictionary, "No dictionary found! Please setup cca before using it!")
	
	local decoded = {};
	local lastCharacter;
	local count = 0;
	local index = table.clone(self.index); for i,v in next, index do count = count + 1; end
	
	for i,v in next, result do
		if index[v] or index[tonumber(v)] then
			local char = index[v] or index[tonumber(v)] 
			table.insert(decoded, char)

			if lastCharacter then
				count = count + 1;
				index[self.convertNum(count)] = lastCharacter .. char;

				lastCharacter = nil;
			elseif #char == 1 then
				lastCharacter = char;
			end
		elseif decoded[#decoded] and decoded[#decoded - 1] then
			local val = decoded[#decoded - 1] .. decoded[#decoded];
			index[v] = val;
			lastCharacter = nil;
			
			table.insert(decoded, val);
		end
	end

	return table.concat(decoded);
end

function cca:serializeContent(content)
	local content = self.spaceChar .. content:gsub("["..self.spaceChar.."]+", self.spaceChar..self.spaceChar)  .. self.spaceChar;
	local tokens = {};

	local function seperateTok(text)
		local seq = {};

		for c in text:sub(1,-2):gmatch(".") do
			seq[#seq+1] = c;
		end
		return seq
	end

	for tok in content:gmatch("["..self.spaceChar.."](.-)["..self.spaceChar.."]") do
		if #tok == 0 then continue end;
		if tok:sub(-1,-1) == self.collapseChar then
			for _, v in next, seperateTok(tok) do
				table.insert(tokens, v);
			end
		else
			table.insert(tokens, tok);
		end
	end

	return (tokens)
end

function cca:pack(list : {string | number}) : string
	local array = {};
	local content = "";
	local index = 0;

	for i,v in next, list do
		table.insert(array, v);
	end
	
	while true do
		index = index + 1;
		local v = array[index];
		local nextChar = array[index+1]
		if v == nil then break end;

		if #tostring(v) == 1 and (nextChar) and #tostring(nextChar) == 1 then -- can collapse
			local skip = 1;
			local newContent = v .. nextChar;

			for i = index+2, #array do
				local k = array[i];
				if k and #tostring(k) == 1 then
					skip = skip + 1;
					newContent = newContent .. k;
					continue;
				end
				break;
			end

			newContent = newContent .. self.collapseChar;
			index = index + skip;
			content = content .. newContent .. self.spaceChar;
			continue;
		end

		content = content .. v .. self.spaceChar;
	end
	return content:sub(1,-2);
end

function cca.encode(content)
	local complied = cca:compile(content);
	local packed = cca.pack(cca, complied);
	return packed;
end

function cca.decode(compliedContent)
	local unwrapped = cca.serializeContent(cca, compliedContent);
	local decomplied = cca:decompile(unwrapped);
	return decomplied;
end

function cca.gatherBytecodeList()
	local list = {};
	for i = 0, 127 do
		list[string.char(i)] = string.char(i) --string.format("%x", i);
	end
	return list;
end

return cca;
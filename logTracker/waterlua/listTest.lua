require 'waterlua'

local list = module_dataStructures.createList()

list:add('A')
list:add('B')
list:add('C')
list:add('D')
list:add('E')

list:print()

list:removeByKey('C')

list:removeByKey('A')

list:addAt('Z', 4)

list:removeByIndex(1)

list:print()

osLib.pause()
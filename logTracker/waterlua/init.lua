local packagePath = package.path

package.path = debug.getinfo(1, 'S').source:sub(2):match('(.*'..'\\'..')')..'?.lua'
--..'waterlua\\?.lua'

require 'bit'
require 'rings'

require 'localio'

require 'configParser'
require 'mathLib'
require 'osLib'
require 'stringLib'
require 'tableLib'

package.path = packagePath
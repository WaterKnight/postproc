require 'waterlua'

local params = {...}

require 'socket.http'

local resp, stat, hdr = socket.http.request{
  url     = "http://www.moonlightflower.net"
}



error(tostring(hdr["content-length"]))
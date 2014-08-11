local bin = require "bin"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"
local ipOps = require "ipOps"

description = [[
This Nmap Script will enumerate the BBMD (BACnet Broadcast Management Device).
This allows a device on one network to communicate with a device on another 
network by using the BBMD to forward and route the messages. Also the NSE will 
attempt to pull the FDT (Foreign-Device-Table), as well as the (TTL) Time To 
Live, and timeout until the device will be removed from the foreign device table. 

This process was submitted via Jeff Meden via the original 
BACnet-discover-enumerate.nse script on github, it was determined to create a 
new script with the submitted methods. 

Note: Requests and responses are via UDP 47808, ensure scanner will receive UDP
47808 source and destination responses.

http://digitalbond.com

]]

---
-- @usage
-- nmap --script BACnet-discover-enumerate.nse -sU  -p 47808 <host>
--
-- @args aggressive - boolean value defines find all or just first sid
--
-- @output
--47808/udp open  BACNet -- Building Automation and Control Networks
--| bacnet-enum:
--|   BBMD: 
--|		192.168.0.100:47808
--|   FDT: 
--|_	192.168.1.101:47809:ttl=60:timeout=37
--
-- @xmloutput
--<elem key="BBMD">192.168.0.100:47808</elem>
--<elem key="FDT">192.168.1.101:47808:ttl=60:timeout=37</elem>

author = "Stephen Hilt (Digital Bond)"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"discovery", "intrusive"}


--
-- Function to define the portrule as per nmap standards
--
--
--

portrule = shortport.port_or_service(47808, "bacnet", "udp")

---
-- Function to determine if a string starts with the parameter that is passed in
--
-- First argument is the string to be evaluated, the second argument is
-- the character(s) to be tested if the string starts with this argument. Uses Lua
-- <code>string.sub</code> and <code>string.len</code>
-- @param String String to be passed in.
-- @param Start The char you want to test to see the string starts with.
function string.starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

---
--  Function to set the Nmap output for the host, if a valid BACNet packet
--  is received then the output will show that the port is open instead of
--  <code>open|filtered</code>
--
-- @param host Host that was passed in via nmap
-- @param port port that BACNet is running on (Default UDP/47808)
function set_nmap(host, port)

  --set port Open
  port.state = "open"
  -- set version name to BACNet
  port.version.name = "BACNet -- Building Automation and Control Networks"
  nmap.set_port_version(host, port)
  nmap.set_port_state(host, port, "open")

end

---
--  Function to send a request for BVLC info to the discovered BACNet devices. 
--  This includes the BBMD and the FDT queries. These are read only and do not
--  attempt to join the router as a Foreign Device. 
--
-- @param socket The socket that was created in the action function
-- @param type Type is the type of packet to send, this can be bbmd or fdt
function bvlc_query(socket, type)

  -- set the BVLC query data for sending
  -- BBMD = 0x02
  local bbmd_query = bin.pack("H","81020004")
  -- FDT = 0x06
  local fdt_query = bin.pack("H","81060004")
  -- initialize query var 
  local query

  -- Based on type parameter passed in from Action
  if (type == "bbmd") then
    query = bbmd_query
  elseif (type == "fdt") then
    query = fdt_query
  end

  -- Send the query that was set by the type
  local status, result = socket:send(query)
  if(status == false) then
    stdnse.print_debug(1, "BVLC-" .. type .. ": Socket error sending query: %s", result)
    return nil
  end
  -- Recive response from the query
  local rcvstatus, response = socket:receive()
  if(rcvstatus == false) then
    stdnse.print_debug(1, "BVLC-" .. type .. ": Socket error receiving: %s", response)
    return nil
  end
  
  -- Validate that packet is BACNet, if it is then we will start parsing more response
  if( string.starts(response, "\x81")) then
  
    -- init up vars 
    local info = ""
    local ips = {}
    local length
    local mask
    local resptype
    
    -- unpack response type, this will be used to determine BBMD vs FDT
    local pos, resptype = bin.unpack("C", response, 2)
    
    -- unpack length, this will be the length of the information to be parsed
    pos, length = bin.unpack(">S", response, 3)
	-- add one to length since Lua starts at 1 not 0
    length = length + 1
    stdnse.print_debug(1, "BVLC-" .. type .. ": starting on bacnet bytes: " .. length)
	-- if length is 7(packet size 6), then we will test to see if it was NAK response
    if length == 7 then
	  -- response type will be BVLC-Result
	  if resptype == 0 then
	    -- unpack two bytes of interest 
	    pos, byte1 = bin.unpack("C", response, 4)
	    pos, byte2 = bin.unpack("C", response, 6) 
	    if byte1 == 0x06 and byte2 == 0x40 then
		  return "Non-Acknowledgement (NAK)"
	    elseif byte1 == 0x06 and byte2 == 0x20 then
		  return "Non-Acknowledgement (NAK)"
		end
	  end
	-- if the packet length is 5(packet size 4) then check to see if a Empty response
	elseif length == 5 then
	  -- validate the response is for the FDT query 
	  if resptype == 7 then
	    return "Empty Table"
	  end
	-- if packet is not long enough then we will exit
	elseif length < 15 then
      stdnse.print_debug(1, 
          "BVLC-" .. type .. ": stopping, this response had not enough bytes: " .. length .. " < 15")
      return nil
	end
    -- While loop for the length of the packet as determined from above.
    while pos < length do
      local ipaddr = ""
      --Unpack and the IP Address from the response
      pos, info = bin.unpack("<I", response, pos)
      ipaddr = ipOps.fromdword(info)
      -- if BBMD type
      if resptype == 3 then
        --Unpack port number used by host in BBMD
        pos, info = bin.unpack(">S", response, pos)
	-- Make string to be stored in output table to be returned to Nmap
        ipaddr = ipaddr .. ":" .. info
        -- shift by 4 bytes
	pos = pos + 4 
		
      -- else if the type is FDT
      elseif resptype == 7 then
        --Unpack port number
        pos, info = bin.unpack(">S", response, pos)
        ipaddr = ipaddr .. ":" .. info
        --Unpack TTL field
        pos, info = bin.unpack(">S", response, pos)
        ipaddr = ipaddr .. ":ttl=" .. info
        --Unpack the timeout field
        pos, info = bin.unpack(">S", response, pos)
        ipaddr = ipaddr .. ":timeout=" .. info
        stdnse.print_debug(1, "BVLC-" .. type .. ": found this: " .. ipaddr)
      -- else the type was not something we were asking for
      --we don't know what response type this is!
      else
	stdnse.print_debug(1, "BVLC-" .. type .. ": unknown response type encountered!")
        return nil
      end
      -- insert to the ips table for output to Nmap
      table.insert(ips, ipaddr)

      -- consider if its time to quit based on the last pos from the last 
      -- unpack was the end of the packet
      if pos == length then
        stdnse.print_debug(1, "BVLC-" .. type .. ": bailing because we are at the end: " .. pos)
        return ips
      end
      stdnse.print_debug(1, "BVLC-" .. type .. ": done with loop")
  end
  -- else ERROR
  else
    stdnse.print_debug(1, "Invalid BACNet packet in response to: " .. type)
    return nil
  end

end

---
--  Action Function that is used to run the NSE. This function will send the 
--  initial query to the host and port that were passed in via nmap. The 
--  initial response is parsed to determine if host is a BACNet device. If it 
--  is then more actions are taken to gather extra information.
--
-- @param host Host that was scanned via nmap
-- @param port port that was scanned via nmap
action = function(host, port)
  --set the first query data for sending
  local orig_query = bin.pack( "H","810a001101040005010c0c023FFFFF194b" )
  local to_return = nil

  -- create new socket
  local sock = nmap.new_socket()
  -- Bind to port for niceness with BACNet this may need to be commented out if
  -- scanning more than one host at a time, may fix some issues seen on Windows
  --
  local status, err = sock:bind(nil, 47808)
  if(status == false) then
    stdnse.print_debug(1,
      "Couldn't bind to 47808/udp. Continuing anyway, results may vary")
  end
  -- connect to the remote host
  local constatus, conerr = sock:connect(host, port)
  if not constatus then
    stdnse.print_debug(1,
      'Error establishing a UDP connection for %s - %s', host, conerr
      )
    return nil
  end
  -- send the original query to see if it is a valid BACNet Device
  local sendstatus, senderr = sock:send(orig_query)
  if not sendstatus then
    stdnse.print_debug(1,
      'Error sending BACNet request to %s:%d - %s',
      host.ip, port.number,  senderr
      )
    return nil
  end

  -- receive response
  local rcvstatus, response = sock:receive()
  if(rcvstatus == false) then
    stdnse.print_debug(1, "Receive error: %s", response)
    return nil
  end

  -- if the response starts with 0x81 then its BACNet
  if( string.starts(response, "\x81")) then
    local pos, value = bin.unpack("C", response, 7)
    --if the first query resulted in an error
    --
    if( value == 0x50) then
      -- set the nmap output for the port and version
      set_nmap(host, port)
      -- return that BACNet Error was received
      to_return = "\nBACNet ADPU Type: Error (5) \n\t" .. stdnse.tohex(response)
      --else pull the InstanceNumber and move onto the pulling more information
      --
    else
      to_return = stdnse.output_table()
      -- set the nmap output for the port and version
      set_nmap(host, port)

      -- BBMD
      to_return["BBMD"] = bvlc_query(sock, "bbmd")
      
      -- FDT
      to_return["FDT"] = bvlc_query(sock, "fdt")

    end
  else
    -- return nothing, no BACNet was detected
    -- close socket
    sock:close()
    return nil
  end
  -- close socket
  sock:close()
  -- return all information that was found
  return to_return

end

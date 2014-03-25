Redpoint
========

Digital Bond's ICS Enumeration Tools


========
BACnet-discover-enumerate.nse

--------
Authors
--------

Stephen Hilt and Michael Toecker
Digital Bond, Inc

--------
Purpose and Description
--------

The purpose of BACnet-discover-enumerate.nse is to first identify if an IP connected devices is running BACnet. This works by querying the device with a pregenerated BACnet message. Newer versions of the BACnet protocol will respond with an acknowledgement, older versions will return a BACnet error message. Presence of either the acknowledgement or the error is sufficient to prove a BACnet capable device is at the target IP Address.

Second, if an acknowledgement is received, this script will also attempt to enumerate several BACnet properties on a responsive BACnet device. Again, the device is queried with a pregenerated BACnet message. Successful enumeration uses specially crafted requests, and will not be successful if the BACnet device does not support the property. 

BACnet properties queried by this script are:
1. Vendor ID - A number that corresponds to a registered BACnet Vendor. The script returns the associated vendor name as well.
2. Object Identifier - A number that uniquely identifies the device, and can be used to initiate other BACnet operations against the device. This is a required property for all BACnet devices.
3. Firmware Revision - The revision number of the firmware on the BACnet device.
4. Application Software Revision - The revision number of the software being used for BACnet communication.
5. Object Name - A user defined string that assigns a name to the BACnet device, commonly entered by technicians on commissioning. This is a required property for all BACnet devices.
6. Model Name - The model of the BACnet device
7. Description - A user defined string for describing the device, commonly entered by technicians on commissioning
8. Location - A user defined string for recording the physical location of the device, commonly entered by technicians on commissioning

The Object Identifier is the unique BACnet address of the device. Using the Object-Identifier, it is possible to send a larger number of commands with BACnet client software, including those that change values, programs, schedules, and other operational information on BACnet devices. 

This script uses a feature added in 2004 to the BACnet specification in order to retrieve the Object Identifier of a device with a single request, and without joining the BACnet network as a foreign device.  (See ANSI/ASHRAE Addendum a to ANSI/ASHRAE Standard 135-2001 for details)

--------
History and Background
--------

From Wikipedia article on BACnet http://en.wikipedia.org/wiki/BACnet:

	BACnet is a communications protocol for building automation and control networks. It is an ASHRAE, ANSI, and ISO standard[1] protocol. The default port for BACnet traffic is UDP/47808.

	BACnet is used in building automation and control systems for applications such as heating, ventilating, and air-conditioning control, lighting control, access control, and fire detection systems and their associated equipment. The BACnet protocol provides mechanisms for computerized building automation devices to exchange information, regardless of the particular building service they perform. 
	
--------
Change Log
--------

3/25/2012 - Initial Version 

-------
INSTALL
-------
This script requires NMAP to run. If you do not have nmap download and Install Nmap based off the nmap instructions. 
	http://nmap.org/download.html

 1) Windows
	a) After downloading bacnet-discover.nse you'll need to move it into the NSE Scripts directory, this will have to be done as an administrator.  Go to Start -> Programs -> Accessories, and right click on 'Command Prompt'.  Select "Run as Administrator.
		move BACnet-discover-enumerate.nse C:\Program Files (x86)\Nmap\scripts
 2) Linux
	a) After Downloading BACnet-discover-enumerate.nse you'll need to move it into the NSE Scripts directory, this will have to be done as sudo/root
		sudo mv BACnet-discover-enumerate.nse /usr/share/nmap/scripts
		
------------
USAGE
------------

  1) Inside a Termanial Window/Command Prompt use one of the following commands where <hosts> is the target you wish you scan for BACNet
	a) Windows: nmap -sU -p 47808 --script BACnet-discover-enumerate <host>
	b) Linux: sudo nmap -sU -p 47808 --script BACnet-discover-enumerate <host> 
  2) To speed up results by not performing DNS lookups during the scan use the -n option, also disable pings to determineif the device is up by doing a -Pn option for full results 
	a)  nmap -sU -Pn -p 47807 -n --script BACnet-discover-enumerate <host>

		
--------
Notes
--------

The official version of this script is maintained at: https://github.com/digitalbond/Redpoint/blob/master/BACnet-discover-enumerate.nse 

This script uses the standard BACnet source and destination port of UDP 47808. 

Newer (after February 25, 2004) BACnet devices are required by spec to respond to specific requests that use a 'catchall' object-identifier with their own valid instance number (see ANSI/ASHRAE Addendum a to ANSI/ASHRAE Standard 135-2001).  Older versions of BACnet devices may not respond to this catchall, and will respond with a BACnet error packet instead.

This script does not attempt to join a BACnet network as a foreign device, it simply sends BACnet requests directly to an IP addressable device.

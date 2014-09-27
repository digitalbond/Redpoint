#Redpoint


###Digital Bond's ICS Enumeration Tools

Redpoint is a Digital Bond research project to enumerate ICS applications and devices. 

We use our Redpoint tools in assessments to discover ICS devices and pull information that would be helpful in secondary testing. A portion of those tools will be made available as Nmap NSE scripts to the public in this repository.

The Redpoint tools use legitimate protocol or application commands to discover and enumerate devices and applications. There is no effort to exploit or crash anything. However many ICS devices and applications are fragile and can crash or respond in an unexpected way to any unexpected traffic so use with care.

Each script is documented below and available in a .nse file in this repository. 

* [BACnet-discover-enumerate.nse](https://github.com/digitalbond/Redpoint#bacnet-discover-enumeratense) - Identify and enumerate BACnet devices

* [enip-enumerate.nse](https://github.com/digitalbond/Redpoint#enip-enumeratense) - Identify and enumerate EtherNet/IP devices from Rockwell Automation and other vendors

* [s7-enumerate.nse](https://github.com/digitalbond/Redpoint#s7-enumeratense) - Identify and enumerate Siemens SIMATIC S7 PLCs

==

###BACnet-discover-enumerate.nse

![BACnet-discover-enumerate Sample Output] (http://digibond.wpengine.netdna-cdn.com/wp-content/uploads/2014/03/BACnet-nse.png)

####Authors

Stephen Hilt and Michael Toecker  
[Digital Bond, Inc](http://www.digitalbond.com)

####Purpose and Description

The purpose of BACnet-discover-enumerate.nse is to first identify if an IP connected devices is running BACnet. This works by querying the device with a pre-generated BACnet message. Newer versions of the BACnet protocol will respond with an acknowledgement, older versions will return a BACnet error message. Presence of either the acknowledgement or the error is sufficient to prove a BACnet capable device is at the target IP Address.

Second, if an acknowledgement is received, this script will also attempt to enumerate several BACnet properties on a responsive BACnet device. Again, the device is queried with a pregenerated BACnet message. Successful enumeration uses specially crafted requests, and will not be successful if the BACnet device does not support the property. 

BACnet properties queried by this script are:

1. Vendor ID - A number that corresponds to a registered BACnet Vendor. The script returns the associated vendor name as well.

2. Object Identifier - A number that uniquely identifies the device. If the Object-Identifier is known, it is possible to send commands with BACnet client software, including those that change values, programs, schedules, and other operational information on BACnet devices. This is a required property for all BACnet devices.

3. Firmware Revision - The revision number of the firmware on the BACnet device.

4. Application Software Revision - The revision number of the software being used for BACnet communication.

5. Object Name - A user defined string that assigns a name to the BACnet device, commonly entered by technicians on commissioning. This is a required property for all BACnet devices.

6. Model Name - The model of the BACnet device

7. Description - A user defined string for describing the device, commonly entered by technicians on commissioning

8. Location - A user defined string for recording the physical location of the device, commonly entered by technicians on commissioning

9. Broadcast Distribution Table (BDT) - A list of the BACnet Broadcast Management Devices (BBMD) in the BACnet network. This will identify all of the subnets that are part of the BACnet network. 

10. Foreign Device Table (FDT) - A list of foreign devices registered with the BACnet device. A foreign device is any device that is not on a subnet that is part of the BACnet network, not in the BDT. Foreign devices often are located on external networks and could be an attacker's IP address.  

The BDT and FDT can be large lists and may be not desired in a large Nmap scan. The basic script will not pull down the BDT and FDT. Run the command with the --script-args full=yes to pull the BDT and FDT, see the Usage section.

![BACnet-discover-enumerate Sample Output with BDT and FDT]
(http://digibond.wpengine.netdna-cdn.com/wp-content/uploads/2014/08/screenshot_bacnet-1.png)

This script uses a feature added in 2004 to the BACnet specification in order to retrieve the Object Identifier of a device with a single request, and without joining the BACnet network as a foreign device.  (See ANSI/ASHRAE Addendum a to ANSI/ASHRAE Standard 135-2001 for details)


####History and Background

From Wikipedia article on BACnet http://en.wikipedia.org/wiki/BACnet:

> BACnet is a communications protocol for building automation and control networks. It is an ASHRAE, ANSI, and ISO standard[1] protocol. The default port for BACnet traffic is UDP/47808.

> BACnet is used in building automation and control systems for applications such as heating, ventilating, and air-conditioning control, lighting control, access control, and fire detection systems and their associated equipment. The BACnet protocol provides mechanisms for computerized building automation devices to exchange information, regardless of the particular building service they perform. 
	

####Installation

This script requires nmap to run. If you do not have Nmap download and Install Nmap based off the Nmap instructions. 
	http://nmap.org/download.html

#####Windows

After downloading bacnet-discover.nse you'll need to move it into the NSE Scripts directory, this will have to be done as an administrator.  Go to Start -> Programs -> Accessories, and right click on 'Command Prompt'.  Select 'Run as Administrator'.

	move BACnet-discover-enumerate.nse C:\Program Files (x86)\Nmap\scripts

#####Linux

After Downloading BACnet-discover-enumerate.nse you'll need to move it into the NSE Scripts directory, this will have to be done as sudo/root.
		
	sudo mv BACnet-discover-enumerate.nse /usr/share/nmap/scripts
		

####Usage

Inside a Terminal Window/Command Prompt use one of the following commands where host is the target you wish you scan for BACNet. Use --script-args full=yes if you want the output to included the BDT and FDT.

	Windows: nmap -sU -p 47808 --script BACnet-discover-enumerate <host>
	Windows: nmap -sU -p 47808 --script BACnet-discover-enumerate --script-args full=yes <host>
	
	Linux: sudo nmap -sU -p 47808 --script BACnet-discover-enumerate <host> 
	Linux: sudo nmap -sU -p 47808 --script BACnet-discover-enumerate --script-args full=yes <host>

To speed up results by not performing DNS lookups during the scan use the -n option, also disable pings to determine if the device is up by doing a -Pn option for full results. 

	nmap -sU -Pn -p 47808 -n --script BACnet-discover-enumerate <host>

		
####Notes

The official version of this script is maintained at: https://github.com/digitalbond/Redpoint/blob/master/BACnet-discover-enumerate.nse 

This script uses the standard BACnet source and destination port of UDP 47808. 

Newer (after February 25, 2004) BACnet devices are required by spec to respond to specific requests that use a 'catchall' object-identifier with their own valid instance number (see ANSI/ASHRAE Addendum a to ANSI/ASHRAE Standard 135-2001).  Older versions of BACnet devices may not respond to this catchall, and will respond with a BACnet error packet instead.

This script does not attempt to join a BACnet network as a foreign device, it simply sends BACnet requests directly to an IP addressable device.

==
###enip-enumerate.nse
![enip-enumerate Sample Output] (http://digibond.wpengine.netdna-cdn.com/wp-content/uploads/2014/04/enip.png)

####Author

Stephen Hilt  
[Digital Bond, Inc](http://www.digitalbond.com)


####Purpose and Description

The purpose of enip-enumerate.nse is to identify and enumerate EtherNet/IP devices. Rockwell Automation / Allen Bradley developed the protocol and is the primary maker of these devices, e.g. ControlLogix and MicroLogix, but it is an open standard and a number of vendors offer an EtherNet/IP interface card or solution. 

An EtherNet/IP device is positively identified by querying TCP/44818 with a list Identities Message (0x63). The response messages will determine if it is a EtherNet/IP device and parse the information to enumerate the device. 

The EtherNet/IP Request List Identities pulls basic information about the device known as the Device's "electronic key". Information includes Vendor, Product Name, Serial Number, Device Type, Product Code and Revision Number. Also the script parses the devices configured IP address from the Socket Address Field within the EtherNet/IP frame of the packet.

EtherNet/IP properties parsed by this script are:

1. Vendor - A two Byte integer that is used to look up Vendor Name

2. Product Name - A string that represents a short description of the product/product family, maximum length is 32 chars

3. Serial Number - A six Byte Hexadecimal Number that is stored little Endian 

4. Device Type - Two byte integer that is used to look up Device type. This field is often not used and set to 0.

5. Product Code - The vendor assigned Product Code identifies a particular product within a device type. The script does not have access to the vendor product code tables so the number is displayed.

6. Revision - Two one-byte integers that lists the major and minor revision number of the device 

7. Device IP - Four one-byte integers that represent the device's configured IP address. This address often differs from the IP address scanned by the script.

####History and Background

From Wikipedia article on EtherNet/IP http://en.wikipedia.org/wiki/EtherNet/IP

> EtherNet/IP was developed in the late 1990s by Rockwell Automation as part of Rockwell's industrial Ethernet networking solutions. Rockwell gave EtherNet/IP its moniker and handed it over to ODVA, which now manages the protocol and assures multi-vendor system interoperability by requiring adherence to established standards whenever new products that utilize the protocol are developed today.

>EtherNet/IP is most commonly used in industrial automation control systems, such as for water processing plants, manufacturing facilities and utilities. Several control system vendors have developed programmable automation controllers and I/O capable of communicating via EtherNet/IP.
	

####Installation

This script requires Nmap to run. If you do not have Nmap download and Install Nmap based off the Nmap instructions. 
	http://nmap.org/download.html

#####Windows

After downloading enip-enumerate.nse you'll need to move it into the NSE Scripts directory, this will have to be done as an administrator.  Go to Start -> Programs -> Accessories, and right click on 'Command Prompt'.  Select 'Run as Administrator'.

	move enip-enumerate.nse C:\Program Files (x86)\Nmap\scripts

#####Linux

After Downloading enip-enumerate.nse you'll need to move it into the NSE Scripts directory, this will have to be done as sudo/root.
		
	sudo mv enip-enumerate.nse /usr/share/nmap/scripts
		

####Usage

Inside a Terminal Window/Command Prompt use one of the following commands where <host> is the target you wish you scan for EtherNet/IP.

	Windows: nmap -p 44818 --script enip-enumerate <host>
	
	Linux: sudo nmap -p 44818 --script enip-enumerate <host> 

		
####Notes

The official version of this script is maintained at:https://github.com/digitalbond/Redpoint/enip-enumerate.nse

This script uses the standard Ethernet/IP destination port of TCP 44818. 

==

###modicon-info.nse


####Author

Stephen Hilt  
[Digital Bond, Inc](http://www.digitalbond.com)

####Purpose and Description

The purpose of modicon-info.nse is to first identify if an IP connected devices is running Modbus. This works by querying the device with a pre-generated function code 43 Modbus message. Presence of either the acknowledgement or the error is sufficient to prove a Modbus capable device is at the target IP Address.

Second, if the vendor name contains the string Schneider, this script will also attempt to enumerate several Modbus Function code 90 properties on a positively identified Schneider Electric Device. This information will include information about the device, as well as information about who and what programmed the PLC.

Modbus Function Code 43, and Function Code 90 properties queried by this script are:

1) Vendor Name - A String within a Function Code 43 response to identify the device as a Schneider Electric Device. Once Identified it will continue to pull information via Function Code 90

2) Network Module - A String that is returned as well with the Function Code 43 Response

3) CPU Module - A String that is queried via Function Code 90, This will represent the CPU module within the Chassis 

4) Firmware - A string that represents the firmware version running on the Modicon, this information is also found within the Function Code 43 response.

5) Memory Card - The model number of the Memory card that is located within the CPU Module, This information is beneficial for a asset inventory stance. 

6) Project Information - Miscellaneous information about the project, such as the project name, the version of Unity Pro that was used to configure it, as well as the workstation name that programmed the PLC. Some Devices will provide the location of the .stu file on the workstation that configured the device.

7) Project Revision - The revision of the project running on the PLC, the project revision number increments by 1 each time a the project is built, and transferred to the PLC.

8) Project Last Modified Date - A time stamp that is stored for when the last time the PLC was modified by a technician.  

####History and Background

From Wikipedia article on Programmable Logic Controllers http://en.wikipedia.org/wiki/Programmable_logic_controller#History:

> In 1968 GM Hydra-Matic (the automatic transmission division of General Motors) issued a request for proposals for an electronic replacement for hard-wired relay systems based on a white paper written by engineer Edward R. Clark. The winning proposal came from Bedford Associates of Bedford, Massachusetts. The first PLC, designated the 084 because it was Bedford Associates' eighty-fourth project, was the result.[2] Bedford Associates started a new company dedicated to developing, manufacturing, selling, and servicing this new product: Modicon, which stood for MOdular DIgital CONtroller. One of the people who worked on that project was Dick Morley, who is considered to be the "father" of the PLC.[3] The Modicon brand was sold in 1977 to Gould Electronics, and later acquired by German Company AEG and then by French Schneider Electric, the current owner.

####Installation

This script requires Nmap to run. If you do not have Nmap download and Install Nmap based off the Nmap instructions. 
	http://nmap.org/download.html

#####Windows

After downloading modicon-info.nse you'll need to move it into the NSE Scripts directory, this will have to be done as an administrator.  Go to Start -> Programs -> Accessories, and right click on 'Command Prompt'.  Select 'Run as Administrator'.

	move modicon-info.nse C:\Program Files (x86)\Nmap\scripts

#####Linux

After Downloading modicon-info.nse you'll need to move it into the NSE Scripts directory, this will have to be done as sudo/root.
		
	sudo mv modicon-info.nse /usr/share/nmap/scripts
		

####Usage

Inside a Terminal Window/Command Prompt use one of the following commands where <host> is the target you wish you scan for Modicon PLCs.

	Windows: nmap -p 502 --script modicon-info.nse -sV <host>
	
	Linux: sudo nmap -p 502 --script modicon-info.nse -sV <host> 

		
####Notes

The official version of this script is maintained at:https://github.com/digitalbond/Redpoint/modicon-info.nse

This script uses the standard Modbus destination port of TCP 502. 

###s7-enumerate.nse
![s7-enumerate Sample Output] (http://digibond.wpengine.netdna-cdn.com/wp-content/uploads/2014/04/S7screenshot.png)

####Author

Stephen Hilt  
[Digital Bond, Inc](http://www.digitalbond.com)

Note: This script is meant to provide the same functionality as PLCScan inside of Nmap. Some of the information that is 
collected by PLCScan was not ported over to this NSE, this information can be parsed out of the packets that are received.

Thanks to Positive Research, and Dmitry Efanov for creating PLCScan

####Purpose and Description

The purpose of s7-enumerate.nse is to identify and enumerate Siemens SIMATIC S7 PLCs. A S7 is positively identified by querying TCP/102 with a pre-generated COTP and S7COMM messages. The response messages will determine if it is a S7 PLC and lead to additional enumeration. Note: TCP/102 is used by multiple applications, one being S7COMM.

Two S7 requests are sent after successful S7 communication has been established.

These requests pull basic hardware, firmware information, and some descriptive information such as plant identification and system name. This information is then returned to Nmap and presented in standard output formats supported by Nmap.  

S7 properties parsed by this script are:

1. Module - A string that represents the identification of the module that is being queried. This identifies the S7 model, e.g. 315, 412, 1200, ...

2. Basic Hardware -  A string that represents the identification of basic hardware that is being queried.

3. Version - A string that represents the identification of the basic hardware version.

4. System Name - A string that represents the system name that was given to the device. This can provide some useful intelligence if the asset owner had implemented a structured naming convention.

5. Module Type - A string that is the module type name of the inserted module.

6. Serial Number - A string that is the serial number of module. This is primarily of interest for inventory purposes.

7. Copyright - A string that is the copyright information. This usually reads "Original Siemens Equipment", but it is possible a third party implementation of the S7 protocol stack could provide additional information. 

8. Plant Identification - A string that represents the plant identification that is configured on the device. This string has rarely been seen in our scanning, but it could provide useful intelligence.


####History and Background

From Wikipedia article on SIMATIC http://simple.wikipedia.org/wiki/SIMATIC:

> SIMATIC is the name of an automation system which was developed by the German company Siemens. The automation system controls machines used for industrial production. This system makes it possible for machines to run automatically.
	

####Installation

This script requires Nmap to run. If you do not have Nmap download and Install Nmap based off the Nmap instructions. 
	http://nmap.org/download.html

#####Windows

After downloading s7-enumerate.nse you'll need to move it into the NSE Scripts directory, this will have to be done as an administrator.  Go to Start -> Programs -> Accessories, and right click on 'Command Prompt'.  Select 'Run as Administrator'.

	move s7-enumerate.nse C:\Program Files (x86)\Nmap\scripts

#####Linux

After Downloading s7-enumerate.nse you'll need to move it into the NSE Scripts directory, this will have to be done as sudo/root.
		
	sudo mv s7-enumerate.nse /usr/share/nmap/scripts
		

####Usage

Inside a Terminal Window/Command Prompt use one of the following commands where <host> is the target you wish you scan for S7 PLCs.

	Windows: nmap -p 102 --script s7-enumerate -sV <host>
	
	Linux: sudo nmap -p 102 --script s7-enumerate -sV <host> 

		
####Notes

The official version of this script is maintained at:https://github.com/digitalbond/Redpoint/s7-enumerate.nse

This script uses the standard S7COMMS destination port of TCP 102. 



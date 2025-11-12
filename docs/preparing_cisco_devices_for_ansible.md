# How to Prepare Cisco Devices for Ansible Automation  
**Version 1.0 • Authored by Alfredo Jo ® • 2024**

This guide outlines the process I use to configure Cisco switches and routers for smooth integration with Ansible. These are the methods that have consistently worked for me over the years, covering preparation, setup, and configuration practices proven in real-world enterprise environments  

---

## Prerequisites

Before you begin, ensure you have the following ready:

- An **allocated IP address** for the switch or stack.  
- If using internal DNS, **create an A record** for the new stack.  
- The **username and password** for your automation account.  
- An **8GB or 16GB FAT32-formatted USB thumb drive** to store the latest IOS image.  
- A **Cisco serial console cable** and basic understanding of how to access the console using `screen` on macOS.  
  - Optional: use the paid [Serial App](https://apps.apple.com/us/app/serial/id877615577?mt=12) from the Mac App Store for easier serial access.

---

## Example Use Case

In this example, we’ll prepare a four-switch Cisco stack located in the **13th-floor IDF** at HQ.  

Allocated details:  
```
IP Address: 10.10.10.50
FQDN: hq_nyc-sw13a.hq_nyc_internal_domain.com
```
Keep these details handy, as we’ll reference them throughout the setup.

---

## DNS Setup

If your organization uses internal DNS, now is a good time to create the A record for your new stack.  
This ensures Ansible can resolve the device hostname without relying on IP addresses.

---

## Cisco Switch Initial Setup

1. **Unbox and connect** all necessary power supplies and stack cables. Designate one switch as the **Master** (connect the stack cable to the *left* stack port).  
2. **Power on** the switch and connect via serial console.  
3. When prompted during the boot sequence, respond as follows:

```
--- System Configuration Dialog ---

Would you like to enter the initial configuration dialog? [yes/no]: no
Would you like to terminate autoinstall? [yes]: yes
```

You should then see the standard prompt:
```
switch>
```

---

### Cisco CLI Prompt Reference

| Prompt | Mode | Description |
|--------|------|-------------|
| `switch>` | User EXEC | Basic monitoring and diagnostics |
| `switch#` | Privileged EXEC | Access to system configuration commands |
| `switch(config)#` | Global Configuration | Device-wide configuration |
| `switch(config-if)#` | Interface Configuration | Interface-specific settings |
| `switch(config-line)#` | Line Configuration | VTY, console, or async lines |

For more details, see [Cisco IOS Command Hierarchy](https://www.geeksforgeeks.org/cisco-ios-command-hierarchy/).

---

### Disable Console Logging

Console logging can clutter your session during setup. Disable it with:

```
switch>enable
switch#config t
switch(config)#no logging console
switch(config)#end
switch#wr
```

---

## Software Upgrade

Download the latest **Cisco IOS XE Universal** image (marked with a gold star) from the [Cisco Software Download Portal](https://software.cisco.com/).

Once downloaded, you can transfer the image using either **USB** or **TFTP**.

---

### USB Method

1. Copy the IOS image to your USB drive.  
2. Insert the USB drive into the switch and copy the image to flash:  
   ```
   switch#copy usbflash0:cat9k_iosxe.17.09.05.SPA.bin flash:
   ```
3. Verify the file copied successfully:
   ```
   switch#dir flash:
   ```

*Note: Update the filename if your image version differs.*

---

### TFTP Method

1. Confirm access to your TFTP server (example: `10.10.10.20`).  
2. Copy the IOS image to the switch flash:  
   ```
   switch#copy tftp://10.10.10.20/cat9k_iosxe.17.09.05.SPA.bin flash:
   ```
3. Once complete, install and activate the new image:
   ```
   switch#install add file flash:cat9k_iosxe.17.09.05.SPA.bin activate commit
   ```
4. Update the boot configuration:
   ```
   switch#conf t
   switch(config)#no boot system switch all
   switch(config)#boot system flash:packages.conf
   switch(config)#no boot manual
   switch(config)#end
   switch#wr
   switch#reload
   ```
5. After the reboot, clean up inactive files:
   ```
   install remove inactive
   ```

---

## Setting Switch Priority

Stack priority determines which switch becomes the **Master**.  
By default, all switches start with `priority 1`.  
Set the Master switch to the highest priority (`15`) before stacking:

```
switch#switch 1 priority 15
switch#wr
```

![Switch Priority Diagram](/img/preparing_cisco_devices_for_ansible/switch_priority_diagram.png)

*Repeat the software upgrade and priority configuration steps on all switches in the stack.*

---

## Initial Configuration

The following commands prepare the Master switch for production and Ansible access.

---

### Configure Routing and Default Gateway

```
switch#conf t
switch(config)#ip routing
switch(config)#ip route 0.0.0.0 0.0.0.0 10.10.10.1
switch(config)#end
switch#wr
```

---

### Configure VTP Mode

```
switch#conf t
switch(config)#vtp mode transparent
switch(config)#end
switch#wr
```

---

### Create Management VLAN

```
switch#conf t
switch(config)#vlan 10
switch(config-vlan)#name Net_MGMT
switch(config-vlan)#end
switch#wr
```

---

### Assign SVI for Management VLAN

```
switch#conf t
switch(config)#interface Vlan10
switch(config-if)#ip address 10.10.10.50 255.255.255.0
switch(config-if)#no ip route-cache
switch(config-if)#end
switch#wr
```

---

### Configure PortChannel Trunk

```
switch#conf t
switch(config)#interface Port-channel1
switch(config-if)#description vPC to hq_nyc-cores
switch(config-if)#switchport mode trunk
switch(config-if)#end
switch#wr
```

Add interfaces to the PortChannel:
```
switch#conf t
switch(config)#interface TenGigabitEthernet1/1/1
switch(config-if)#description hq_nyc-core01
switch(config-if)#switchport mode trunk
switch(config-if)#channel-group 1 mode active
switch(config-if)#end

switch(config)#interface TenGigabitEthernet4/1/1
switch(config-if)#description hq_nyc-core02
switch(config-if)#switchport mode trunk
switch(config-if)#channel-group 1 mode active
switch(config-if)#end
switch#wr
```

---

### Set Hostname, Domain, and SSH Access

```
switch#conf t
switch(config)#hostname hq_nyc-sw13
switch(config)#ip domain-name hq_nyc_internal_domain.com
switch(config)#crypto key generate rsa modulus 4096
switch(config)#ip ssh version 2
switch(config)#end
switch#wr
```

---

### Create Local User for Ansible Automation

```
switch#conf t
switch(config)#username ansible privilege 15 secret your_password_here
switch(config)#end
switch#wr
```

---

### Configure VTY Lines for Remote Access

```
switch#conf t
switch(config)#line vty 0 30
switch(config-line)#login local
switch(config-line)#transport input ssh
switch(config-line)#end
switch#wr
```

---

## Verification Steps

Run the following commands to confirm your setup:

```
show ip interface brief
show version
show switch
show run | include hostname
```

Ensure SSH works using your Ansible control node:
```
ssh ansible@hq_nyc-sw13a.hq_nyc_internal_domain.com
```

---

## Troubleshooting
**Coming Soon...**

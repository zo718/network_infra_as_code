# Network Automation with Ansible for Cisco & Juniper
**Version 1.2 • Authored by Alfredo Jo ® • 2024**

***This project is a work in progress — I’ll continue adding context and additional files as time allows.***

This repository provides a complete **Ansible-based automation framework** for managing and deploying Cisco IOS and Juniper Junos devices in a typical **enterprise or office network environment**.  
It demonstrates how to use **host variables**, **group variables**, and **modular playbooks** to perform configuration, monitoring, and validation tasks efficiently and consistently.

---

## Overview

Modern network operations rely on automation for consistency, scalability, and efficiency.  
This project showcases a **real-world implementation** of network automation using **Ansible** — a lightweight, agentless automation platform.

The goal of this repository is to:
- Reduce manual network tasks (configuration, validation, backup, etc.)
- Increase deployment speed and accuracy
- Provide a reusable framework that can be adapted to any office or enterprise network

---

## Features

- ✅ **Multi-Vendor Support:** Cisco IOS (Catalyst, ISR, Meraki) and Juniper (Junos)
- ⚙️ **Dynamic Host & Group Variables:** Organized under `host_vars/` and `group_vars/`
- 🧱 **Modular Playbook Design:** Separate playbooks for deployment, validation, and backup tasks
- 📊 **Configuration Validation:** Compare live configs vs templates for drift detection
- 🔁 **Backup & Rollback Automation:** Automatically save device states and configs
- 🔐 **Secure Credential Management:** Supports encrypted Ansible Vault files
- 🕵️ **Pre-Deployment Checks:** Validate device reachability and credentials before execution
- 🌍 **Office Network Focus:** Ideal for internal LAN/WAN, IDF, and branch environments

---

## Repository Structure
```
├── group_vars/
│   ├── hq_nyc_borders.yml                                        # Juniper border switch variables
│   ├── hq_nyc_cores_9k.yml                                        # Cisco 9K cores switch variables
│   └── hq_nyc_idf_stacks.yml                                     # Cisco IOS switch stack variables          
│
├── host_vars/
│   ├── hq_nyc-border01.hq_nyc_hq_nyc_internal_domain.com.yml     #HQ Junipers Border01 switch
│   ├── hq_nyc-border02.hq_nyc_hq_nyc_internal_domain.com.yml     #HQ Junipers Border02 switch
│   ├── hq_nyc-sw01.hq_nyc_internal_domain.com.yml                #HQ First Floor IDF Cisco Stacks
│   ├── hq_nyc-sw02.hq_nyc_internal_domain.com.yml                #HQ Second Floor IDF Cisco Stacks
│   ├── hq_nyc-sw03.hq_nyc_internal_domain.com.yml                #HQ Third Floor IDF Cisco Stacks
│   ├── hq_nyc-sw04.hq_nyc_internal_domain.com.yml                #HQ Fourth Floor IDF Cisco Stacks
│   ├── hq_nyc-sw05.hq_nyc_internal_domain.com.yml                #HQ Fifth Floor IDF Cisco Stacks
│
├── playbooks/
│   ├── cisco_stacks_setup.yml         # Deploy configs to cisco IDF stacks
│   ├── get_cisco_stacks_serials.yml   # Gathers all the Cisco stacks serial numbers and display them on screen.
│
├── templates/
│   ├── access_ports_loop.j2         # Cisco IOS access ports set up loop
│   └── cisco_login_banner.j2        # Example login banner template
│
├── support_files
├── hosts         #Defines devices and groups
├── ansible.cfg   #Defines the settings and tweaks for our anisble server
├── README.md     #Detailed documention about this repository
```
---


## How It Works

1. **Define your network inventory** under `hosts` file..  
   Devices are grouped by role or location (e.g., border, IDF, branch).

2. **Assign variables** using:
   - `group_vars/` for settings shared across multiple devices (like SNMP, NTP, syslog)
   - `host_vars/` for device-specific configurations (like hostname, VLANs, interfaces)

3. **Run the appropriate playbook** depending on the task:
   ```bash
   ansible-playbook playbooks/get_cisco_stacks_serial.yml -e var_host=hq_nyc-sw01.hq_nyc_internal_domain.com.yml

## ⚠️ Disclaimer

Please make sure to thoroughly test this in a lab environment before using it in production.  
It is important that you fully understand what each playbook and task is doing before running them against live devices.

While I have tested these workflows extensively in my own environment, it is impossible to account for every network design, topology, or edge case.  
I cannot be held responsible for any outages, misconfigurations, or damage caused by the use of this code.

Although these playbooks are written with idempotence and safety in mind, **always test and validate in your own environment first**.

# This script scans any production IDF Cisco IOS switch and builds a YAML file
# ready to drop straight into your host_vars directory.
# Version 1.2 – Originally written by a former teammate. Credit pending owner approval. © 2024

import logging
import getpass
from netmiko import ConnectHandler
from io import StringIO
from cisco_objects import CiscoInterface
import argparse


def get_interfaces_config(switch_name: str, user: str, password: str) -> list[str]:
    switch_obj = {
        'device_type': 'cisco_ios',
        'ip': switch_name,
        'username': user,
        'password': password
    }

    # Connect to the switch
    logger.info("Connecting to '%s'." % switch_name)
    net_connect = ConnectHandler(**switch_obj)

    # Run the command to retrieve interface information
    logger.info("Getting interfaces configuration from '%s'." % switch_name)
    interfaces_output = net_connect.send_command("show run | section interface", use_textfsm=True)

    return interfaces_output.splitlines()


def export_config_to_yaml(interfaces: list[str], switch_name: str):
    ulbuffer = StringIO(newline="\n")
    ifbuffer = StringIO(newline="\n")
    cif = None

    ulbuffer.write("uplinks:\n")
    ifbuffer.write("interfaces:\n")

    logger.info("Processing %i configuration lines from '%s'." % (len(interfaces), switch_name))
    for i, line in enumerate(interfaces):
        values = line.split(' ')

        # There are apparently empty lines in the config
        if values[0] == "" and len(values) <= 2:
            continue

        if values[0] == "interface" \
                and (values[1][0:15] == "GigabitEthernet" or values[1][0:18] == "TenGigabitEthernet"):
                #and i + 1 < len(interfaces) and interfaces[i + 1][0] == " ":
            # Write the previous object to the buffer.
            if cif is not None and cif.port[0:15] == "GigabitEthernet":
                logger.debug("Writing port config to buffer: %s", repr(cif))
                ifbuffer.write(str(cif))
            elif cif is not None and cif.port[0:18] == "TenGigabitEthernet":
                # We don't want empty uplink configs
                if cif.vlan == "trunk":
                    logger.debug("Writing port config to buffer: %s", repr(cif))
                    ulbuffer.write(str(cif))

            # Create a new object for storing the config
            logger.debug("Processing port '%s'." % values[1])
            cif = CiscoInterface(values[1])
        elif cif and values[1] == "description":
            tempname = (" ".join(values[2:])).strip()
            cif.name = tempname if tempname != "\"\"" else CiscoInterface.DEFAULT_NAME
        elif cif and values[1] == "switchport" and values[2] == "access":
            cif.vlan = values[4]
        elif cif and values[1] == "switchport" and values[2] == "mode" and values[3] == "trunk":
            cif.vlan = values[3]

    # Write the text buffer to file
    fname = switch_name + ".yml"
    logger.info("Writing YAML config of '%s' to file '%s'." % (switch_name, fname))
    with open(fname, mode="w") as f:
        print("--- # This is the stack %s\n" % switch_name, file=f)
        print(ulbuffer.getvalue(), file=f, end="")
        print(ifbuffer.getvalue()[:-1], file=f, end="")


LOG_FORMAT = "%(asctime)s %(levelname)s %(message)s"
logging.basicConfig(format=LOG_FORMAT)
logger = logging.getLogger(__name__)
logger.setLevel("DEBUG")

parser = argparse.ArgumentParser()
parser.add_argument("--switch", "-s", required=False, help="Switch name or IP address to connect to.")
args = parser.parse_args()

hostnames = ["hq_nyc-sw01.hq_nyc_internal_domain.com", "hq_nyc-sw02.hq_nyc_internal_domain.com", "hq_nyc-sw03.hq_nyc_internal_domain.com" ]

if args.switch:
    hostnames = [args.switch]

ldap_user = input("LDAP name of user who can read switches: ")
ldap_password = getpass.getpass("Password for that user: ")

logger.info("Processing %i switch stacks." % len(hostnames))
for switch_name in hostnames:
    ifconfig = get_interfaces_config(switch_name, ldap_user, ldap_password)
    export_config_to_yaml(ifconfig, switch_name)

logger.info("Export of %i switch stack configurations completed." % len(hostnames))

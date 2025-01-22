import os
import sys
import ctypes
import getpass
import subprocess
import requests
import socket
import argparse

# Create the parser
parser = argparse.ArgumentParser(description="Downloads and runs a PowerShell script that removes uncessesary UWP apps, along with some other misc tweaks.")

# Add the arguments
parser.add_argument('--debug', action='store_true', help='Enable debug mode')
parser.add_argument('--first_run', type=str, help='Signifies the first automatic re-run of the script. Used autonomously')
parser.add_argument('--azure', action='store_true', help='Specify if computer is Entra joined (will not uninstall OneDrive)')

# Parse the arguments
args, unknown = parser.parse_known_args()

if args.debug:
    print("Debug mode enabled")

if args.debug:
    for i in range(1, len(sys.argv)):
        print(f"Argument {i}: {sys.argv[i]}")

original_stdout = sys.stdout 


def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def add_to_admin_group(username, domain):
    try:
        subprocess.run(['net', 'localgroup', 'Administrators', f"{domain}\\{username}", '/add'])
    except subprocess.CalledProcessError:
        print(f"User {username} is already in the Administrators group.")

def remove_from_admin_group(username, domain):
    subprocess.run(['net', 'localgroup', 'Administrators', f"{domain}\\{username}", '/delete'])

def download_and_run_script(url, username, domain):
    password = getpass.getpass(f"Enter the password for {username}: ")
    if args.debug:
        ps_command = f'Start-Process powershell -Credential (New-Object System.Management.Automation.PSCredential("{domain}\\{username}", (ConvertTo-SecureString "{password}" -AsPlainText -Force))) -ArgumentList "-ExecutionPolicy Unrestricted ./script.ps1 --debug"'
    else:
        ps_command = f'Start-Process powershell -Credential (New-Object System.Management.Automation.PSCredential("{domain}\\{username}", (ConvertTo-SecureString "{password}" -AsPlainText -Force))) -ArgumentList "-ExecutionPolicy Unrestricted ./script.ps1"'
    print("Downloading script")
    response = requests.get(url)
    with open('script.ps1', 'w') as file:
        file.write(response.text)
    if args.debug:
        input("Running script, Press Enter to continue...")
    else:
        print("Running script")
    print(f"User that powershell will open as: {username}")
    try:
        subprocess.run(["powershell", "-Command", ps_command], shell=True)
    except subprocess.CalledProcessError as error:
        input("Error opening PowerShell, Press Enter to continue...")

def main():
    if args.debug:
        input("Getting current user name, Press Enter to continue...")
    if args.first_run:
        username = args.first_run
        print(f"Passed username: {username}")
    else:
        username = getpass.getuser()
        print(f"Current username: {username}")
    if args.debug:
        input("Getting Domain name, Press Enter to continue...")
    domain = socket.getfqdn().split('.', 1)[-1]
    print(f"Current domain: {domain}")

    if is_admin() and args.first_run is not None:
        if args.debug:
            input("Elevated restart, elevating current user step, Press Enter to continue...")
        else:
            print("Elevated restart, elevating current user step.")
        if args.debug:
            input(f"Adding {username} to local Administrators group, Press Enter to continue...")
        else:
            print(f"Adding {username} to local Administrators group")
        add_to_admin_group(username, domain)
        if args.debug:
            input(f"Added {username} to local Administrators group, Press Enter to continue...")
        else:
            print(f"Added {username} to local Administrators group")
        if args.debug:
            input("Running script routine, Press Enter to continue...")
        else:
            print("Running script routine")
        download_and_run_script("https://raw.githubusercontent.com/legoj15/domainRemoveUWP/main/removeUWP.ps1", username, domain)
        if args.debug:
            input(f"Removing {username} from local Administrators group, Press Enter to continue...")
        else:
            print(f"Removing {username} from local Administrators group")
        remove_from_admin_group(username, domain)
        if args.debug:
            input(f"Removed {username} from local Administrators group, Press Enter to continue...")
        else:
            print(f"Removed {username} from local Administrators group")
    elif is_admin():
        print("Downloading script")
        response = requests.get("https://raw.githubusercontent.com/legoj15/domainRemoveUWP/main/removeUWP.ps1")
        with open('script.ps1', 'w') as file:
            file.write(response.text)
        if args.debug:
            input("Running script, Press Enter to continue...")
        else:
            print("Running script")
        print(f"User that powershell will open as: {username}")
        try:
            if args.debug:
                subprocess.run(["powershell", "-ExecutionPolicy", "Unrestricted", "./script.ps1", "--debug"], shell=True)
            elif args.azure:
                subprocess.run(["powershell", "-ExecutionPolicy", "Unrestricted", "./script.ps1", "--azure"], shell=True)
            else:
                subprocess.run(["powershell", "-ExecutionPolicy", "Unrestricted", "./script.ps1"], shell=True)
        except subprocess.CalledProcessError as error:
            input("Error opening PowerShell, Press Enter to continue...")
    else:
        # Prompt for elevation and restart the script
        if args.debug:
            input("Not an admin, restarting as one, Press Enter to continue...")
            ctypes.windll.shell32.ShellExecuteW(None, 'runas', sys.executable, ' '.join([sys.argv[0], '--debug', '--first_run', f'"{username}"']), None, 1)
        else:
            print("Not an admin, restarting as one")
            ctypes.windll.shell32.ShellExecuteW(None, 'runas', sys.executable, ' '.join([sys.argv[0], '--first_run', f'"{username}"']), None, 1)

if __name__ == '__main__':
    main()

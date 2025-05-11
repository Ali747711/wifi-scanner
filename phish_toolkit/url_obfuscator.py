#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
URL Obfuscator - Educational Purposes Only
This tool provides various methods to obfuscate URLs for phishing simulations.
"""

import re
import sys
import random
import argparse
from urllib.parse import urlparse

# ANSI colors for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def display_banner():
    """Display the tool banner"""
    banner = f"""
{Colors.BLUE}╔═══════════════════════════════════════════════════════════════╗{Colors.ENDC}
{Colors.BLUE}║                                                               ║{Colors.ENDC}
{Colors.BLUE}║{Colors.GREEN}  URL Obfuscator - Educational Security Testing Tool       {Colors.BLUE}║{Colors.ENDC}
{Colors.BLUE}║{Colors.YELLOW}  For controlled environments and authorized testing only   {Colors.BLUE}║{Colors.ENDC}
{Colors.BLUE}║                                                               ║{Colors.ENDC}
{Colors.BLUE}╚═══════════════════════════════════════════════════════════════╝{Colors.ENDC}
"""
    print(banner)

def validate_url(url):
    """Validate if the input is a proper URL"""
    if not url.startswith(('http://', 'https://')):
        return False
    
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except:
        return False

def hex_encode_url(url):
    """Convert URL to hexadecimal representation"""
    parts = url.split('://')
    if len(parts) < 2:
        print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
        return url
    
    protocol = parts[0] + '://'
    domain = parts[1]
    
    # Convert domain to hex
    hex_domain = ""
    for char in domain:
        hex_domain += f"\\x{ord(char):02x}"
    
    obfuscated = f"{protocol}{hex_domain}"
    return obfuscated

def decimal_encode_url(url):
    """Convert URL to decimal IP representation"""
    parts = url.split('://')
    if len(parts) < 2:
        print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
        return url
    
    protocol = parts[0] + '://'
    domain = parts[1]
    
    # Split domain and path
    if '/' in domain:
        domain_part, path_part = domain.split('/', 1)
        path_part = '/' + path_part
    else:
        domain_part = domain
        path_part = ''
    
    # Try to convert domain to IP decimal
    try:
        import socket
        ip = socket.gethostbyname(domain_part)
        ip_parts = ip.split('.')
        decimal_ip = int(ip_parts[0]) * 16777216 + int(ip_parts[1]) * 65536 + int(ip_parts[2]) * 256 + int(ip_parts[3])
        
        obfuscated = f"{protocol}{decimal_ip}{path_part}"
        return obfuscated
    except:
        print(f"{Colors.YELLOW}Could not resolve domain to IP. Using original domain.{Colors.ENDC}")
        return url

def add_fake_subdomain(url):
    """Add a fake subdomain to the URL"""
    parts = url.split('://')
    if len(parts) < 2:
        print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
        return url
    
    protocol = parts[0] + '://'
    domain = parts[1]
    
    # Split domain and path
    if '/' in domain:
        domain_part, path_part = domain.split('/', 1)
        path_part = '/' + path_part
    else:
        domain_part = domain
        path_part = ''
    
    # Generate fake subdomain
    fake_domains = [
        "secure-login",
        "account-verify",
        "signin-secure",
        "auth-portal",
        "login-confirm",
        "security-check",
        "verify-account",
        "user-validate",
        "access-portal",
        "secure-gateway"
    ]
    
    fake = random.choice(fake_domains)
    
    # Check if domain already has subdomains
    if domain_part.count('.') > 1:
        # Domain already has subdomain, replace it
        parts = domain_part.split('.', 1)
        domain_part = f"{fake}.{parts[1]}"
    else:
        # Add new subdomain
        domain_part = f"{fake}.{domain_part}"
    
    obfuscated = f"{protocol}{domain_part}{path_part}"
    return obfuscated

def add_fake_path(url):
    """Add a fake path to the URL that looks legitimate"""
    parts = url.split('://')
    if len(parts) < 2:
        print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
        return url
    
    protocol = parts[0] + '://'
    domain = parts[1]
    
    # Split domain and path
    if '/' in domain:
        domain_part, path_part = domain.split('/', 1)
    else:
        domain_part = domain
        path_part = ''
    
    # Generate fake path
    fake_paths = [
        "login",
        "signin",
        "account/verify",
        "security/checkpoint",
        "auth/login",
        "session/validate",
        "user/profile",
        "account/password-reset",
        "secure/login",
        "validate/identity"
    ]
    
    fake = random.choice(fake_paths)
    
    # Combine with existing path if any
    if path_part:
        new_path = f"{fake}/{path_part}"
    else:
        new_path = fake
    
    obfuscated = f"{protocol}{domain_part}/{new_path}"
    return obfuscated

def unicode_encode_url(url):
    """Use unicode characters that look similar to ASCII"""
    # Map of ASCII characters to similar-looking Unicode characters
    unicode_map = {
        'a': 'а',  # Cyrillic 'a'
        'e': 'е',  # Cyrillic 'e'
        'o': 'о',  # Cyrillic 'o'
        'p': 'р',  # Cyrillic 'p'
        'c': 'с',  # Cyrillic 'c'
        'x': 'х',  # Cyrillic 'x'
        'y': 'у',  # Cyrillic 'y'
        'i': 'і',  # Cyrillic 'i'
    }
    
    parts = url.split('://')
    if len(parts) < 2:
        print(f"{Colors.RED}Invalid URL format.{Colors.ENDC}")
        return url
    
    protocol = parts[0] + '://'
    domain = parts[1]
    
    # Replace characters in domain with Unicode lookalikes
    obfuscated_domain = ''
    for char in domain:
        if char.lower() in unicode_map:
            # 50% chance to replace with Unicode
            if random.random() > 0.5:
                obfuscated_domain += unicode_map[char.lower()]
            else:
                obfuscated_domain += char
        else:
            obfuscated_domain += char
    
    obfuscated = f"{protocol}{obfuscated_domain}"
    return obfuscated

def interactive_mode():
    """Run the tool in interactive mode"""
    display_banner()
    
    while True:
        print(f"\n{Colors.GREEN}URL Obfuscation Options:{Colors.ENDC}")
        print(f"{Colors.YELLOW}1. Convert to hexadecimal format{Colors.ENDC}")
        print(f"{Colors.YELLOW}2. Convert to decimal IP format{Colors.ENDC}")
        print(f"{Colors.YELLOW}3. Add fake subdomain{Colors.ENDC}")
        print(f"{Colors.YELLOW}4. Add fake path{Colors.ENDC}")
        print(f"{Colors.YELLOW}5. Use Unicode lookalike characters{Colors.ENDC}")
        print(f"{Colors.YELLOW}6. Apply all obfuscation methods{Colors.ENDC}")
        print(f"{Colors.RED}7. Exit{Colors.ENDC}")
        
        choice = input(f"\n{Colors.GREEN}Select an option [1-7]: {Colors.ENDC}")
        
        if choice == '7':
            print(f"\n{Colors.GREEN}Exiting URL Obfuscator. Goodbye!{Colors.ENDC}")
            sys.exit(0)
        
        url = input(f"\n{Colors.GREEN}Enter URL to obfuscate: {Colors.ENDC}")
        
        if not validate_url(url):
            print(f"{Colors.RED}Invalid URL. Please enter a valid URL (e.g., http://example.com).{Colors.ENDC}")
            continue
        
        if choice == '1':
            result = hex_encode_url(url)
            print(f"\n{Colors.GREEN}Hexadecimal URL:{Colors.ENDC}")
            print(f"{Colors.BLUE}{result}{Colors.ENDC}")
        
        elif choice == '2':
            result = decimal_encode_url(url)
            print(f"\n{Colors.GREEN}Decimal IP URL:{Colors.ENDC}")
            print(f"{Colors.BLUE}{result}{Colors.ENDC}")
        
        elif choice == '3':
            result = add_fake_subdomain(url)
            print(f"\n{Colors.GREEN}URL with fake subdomain:{Colors.ENDC}")
            print(f"{Colors.BLUE}{result}{Colors.ENDC}")
        
        elif choice == '4':
            result = add_fake_path(url)
            print(f"\n{Colors.GREEN}URL with fake path:{Colors.ENDC}")
            print(f"{Colors.BLUE}{result}{Colors.ENDC}")
        
        elif choice == '5':
            result = unicode_encode_url(url)
            print(f"\n{Colors.GREEN}URL with Unicode lookalikes:{Colors.ENDC}")
            print(f"{Colors.BLUE}{result}{Colors.ENDC}")
        
        elif choice == '6':
            # Apply all methods in sequence
            result = url
            result = add_fake_subdomain(result)
            result = add_fake_path(result)
            result = unicode_encode_url(result)
            
            print(f"\n{Colors.GREEN}Fully obfuscated URL:{Colors.ENDC}")
            print(f"{Colors.BLUE}{result}{Colors.ENDC}")
            
            # Show hex version as well
            hex_result = hex_encode_url(url)
            print(f"\n{Colors.GREEN}Alternative (hexadecimal):{Colors.ENDC}")
            print(f"{Colors.BLUE}{hex_result}{Colors.ENDC}")
        
        else:
            print(f"{Colors.RED}Invalid choice. Please try again.{Colors.ENDC}")
        
        input(f"\n{Colors.BLUE}Press Enter to continue...{Colors.ENDC}")

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='URL Obfuscator - Educational Purposes Only')
    parser.add_argument('--url', type=str, help='URL to obfuscate')
    parser.add_argument('--hex', action='store_true', help='Convert to hexadecimal')
    parser.add_argument('--decimal', action='store_true', help='Convert to decimal IP')
    parser.add_argument('--subdomain', action='store_true', help='Add fake subdomain')
    parser.add_argument('--path', action='store_true', help='Add fake path')
    parser.add_argument('--unicode', action='store_true', help='Use Unicode lookalikes')
    parser.add_argument('--all', action='store_true', help='Apply all obfuscation methods')
    
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    
    if args.url:
        # Command line mode
        url = args.url
        
        if not validate_url(url):
            print(f"{Colors.RED}Invalid URL. Please enter a valid URL (e.g., http://example.com).{Colors.ENDC}")
            sys.exit(1)
        
        if args.hex:
            result = hex_encode_url(url)
            print(result)
        
        elif args.decimal:
            result = decimal_encode_url(url)
            print(result)
        
        elif args.subdomain:
            result = add_fake_subdomain(url)
            print(result)
        
        elif args.path:
            result = add_fake_path(url)
            print(result)
        
        elif args.unicode:
            result = unicode_encode_url(url)
            print(result)
        
        elif args.all:
            result = url
            result = add_fake_subdomain(result)
            result = add_fake_path(result)
            result = unicode_encode_url(result)
            print(result)
        
        else:
            # No specific method chosen, show all
            print(f"{Colors.GREEN}Original URL:{Colors.ENDC} {url}")
            print(f"{Colors.GREEN}Hex:{Colors.ENDC} {hex_encode_url(url)}")
            print(f"{Colors.GREEN}Decimal IP:{Colors.ENDC} {decimal_encode_url(url)}")
            print(f"{Colors.GREEN}Fake Subdomain:{Colors.ENDC} {add_fake_subdomain(url)}")
            print(f"{Colors.GREEN}Fake Path:{Colors.ENDC} {add_fake_path(url)}")
            print(f"{Colors.GREEN}Unicode:{Colors.ENDC} {unicode_encode_url(url)}")
    
    else:
        # Interactive mode
        interactive_mode()

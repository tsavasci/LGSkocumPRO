#!/bin/bash

# Set RPi IP and user
RPI_IP="192.168.1.119"
RPI_USER="pi"

# Create website directory on RPi
ssh $RPI_USER@$RPI_IP "mkdir -p ~/website"

# Copy website files to RPi
scp -r /Users/tamersavasci/Documents/LGS\ Kocum\ PRO/Website/* $RPI_USER@$RPI_IP:~/website/

# Create server script on RPi
ssh $RPI_USER@$RPI_IP "cat > ~/website/server.py" << 'EOL'
#!/usr/bin/env python3
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        return super().end_headers()

    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
        return SimpleHTTPRequestHandler.do_GET(self)

def run(port=8081):
    server_address = ('', port)
    httpd = HTTPServer(server_address, CORSRequestHandler)
    print(f'Starting server on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    run()
EOL

# Make server script executable
ssh $RPI_USER@$RPI_IP "chmod +x ~/website/server.py"

# Install Python if not installed
ssh $RPI_USER@$RPI_IP "command -v python3 || sudo apt update && sudo apt install -y python3"

echo "Setup complete! To start the server, run:"
echo "ssh $RPI_USER@$RPI_IP 'cd ~/website && python3 server.py'"
echo "Then access your website at: http://$RPI_IP:8081"

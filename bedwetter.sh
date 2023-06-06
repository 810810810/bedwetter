#!/bin/bash

# Function to check if a port is available
function is_port_available() {
  nc -z -w1 "$1" "$2" >/dev/null 2>&1
  return $?
}

# Find an available port
PORT=8000
while ! is_port_available "localhost" "$PORT"; do
  ((PORT++))
done

# Get the IP address of the machine
IP_ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')

SERVER_IP="$IP_ADDRESS"
OUTPUT_FILE="$SERVER_IP.sh"

# Create a new shell script file with the IP address as the filename
echo "#!/bin/bash" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "# Connect to the server as a client" >> "$OUTPUT_FILE"
echo "socat TCP:$SERVER_IP:$PORT openssl-connect:$SERVER_IP:$PORT,verify=0 &" >> "$OUTPUT_FILE"

# Make the shell script file executable
chmod +x "$OUTPUT_FILE"

# Start the server with encryption and tunneling using socat
socat SSL_version=TLSv1.2 TCP:$SERVER_IP:$PORT openssl-connect:$SERVER_IP:$PORT,verify=0 &

# Sleep for a moment to allow the server to start
sleep 1

# Execute the generated shell script to activate the connection
./"$OUTPUT_FILE"

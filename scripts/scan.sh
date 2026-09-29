#!/bin/bash

# Configuration
SUBNET="192.168.178"
SERVER_USER="benni"
LUKS_KEY_TITLE="[Ubuntu Server] LUKS encryption passphrase"

# 1. Verify and Retrieve LUKS Passphrase
if ! command -v secret-tool &> /dev/null; then
    echo "Error: secret-tool is not installed. Run: sudo pacman -S libsecret" >&2
    exit 1
fi

LUKS_PASS=$(secret-tool lookup Title "$LUKS_KEY_TITLE")
if [ -z "$LUKS_PASS" ]; then
    echo "Error: LUKS passphrase not found in keyring." >&2
    echo "Store it first using:" >&2
    echo "secret-tool store --label=\"$LUKS_KEY_TITLE\" Title \"$LUKS_KEY_TITLE\"" >&2
    exit 1
fi

# 2. Fast Parallel Scan for Dropbear (Port 2222)
echo "Scanning $SUBNET.0/24 for Dropbear (port 2222)..."
SERVER_IP=""
TMP_FILE=$(mktemp)

for i in {1..254}; do
    # 'timeout 0.2' prevents the script from hanging for 120s on dropped packets
    (
        timeout 0.2 bash -c "</dev/tcp/$SUBNET.$i/2222" 2>/dev/null && echo "$SUBNET.$i" > "$TMP_FILE"
    ) &
done
wait

if [ -s "$TMP_FILE" ]; then
    SERVER_IP=$(cat "$TMP_FILE" | head -n 1)
fi
rm -f "$TMP_FILE"

if [ -z "$SERVER_IP" ]; then
    echo "Dropbear not found on the network. Is the server booting?" >&2
    exit 1
fi

echo "Dropbear found at: $SERVER_IP"

# 3. Verify Key & Execute Unlock
echo "Transmitting LUKS passphrase..."
# -T: Disables pseudo-tty allocation, ensuring stdin pipes cleanly to the remote command.
# UserKnownHostsFile=/dev/null & StrictHostKeyChecking=no: Bypasses the Dropbear vs OpenSSH key collision.
# echo -n "$LUKS_PASS" | ssh -p 2222 -T \
#     -o UserKnownHostsFile=/dev/null \
#     -o StrictHostKeyChecking=no \
#     -o BatchMode=yes \
#     "root@$SERVER_IP" "cryptroot-unlock" >/dev/null 2>&1
echo -n "$LUKS_PASS" | ssh -T -o BatchMode=yes amps-unlock "cryptroot-unlock" >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Warning: SSH command returned a non-zero exit code. This usually happens because Dropbear kills the connection the moment decryption succeeds."
fi

# 4. Handover Wait Loop (Port 22)
echo "Unlock command dispatched. Waiting for OpenSSH handover on port 22..."
while ! timeout 0.5 bash -c "</dev/tcp/$SERVER_IP/22" 2>/dev/null; do
    sleep 2
done

echo "Handover complete. OpenSSH is active."

# 5. Connect to Main OS
echo "Connecting to main OS..."
# ssh -o StrictHostKeyChecking=accept-new "${SERVER_USER}@${SERVER_IP}"
exec ssh amps-main

#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if FreeSWITCH is installed
is_freeswitch_installed() {
    if command -v freeswitch >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check if SignalWire TOKEN is already set
is_token_set() {
    if [ -f /etc/apt/auth.conf ]; then
        if grep -q "freeswitch.signalwire.com" /etc/apt/auth.conf; then
            return 0
        fi
    fi
    return 1
}

# Function to check if systemd is available
is_systemd() {
    if pidof systemd >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if the SignalWire TOKEN is already set
if is_token_set; then
    echo "SignalWire TOKEN is already set. Skipping TOKEN setup."
else
    # Prompt the user for their SignalWire TOKEN
	echo "You can get a Community FreeSWITCH ~Personal Access Token~ from your SignalWire dashboard https://id.signalwire.com/login/session/new"
    read -p "Please enter your SignalWire TOKEN: " TOKEN

    # Create the APT authentication configuration
    echo "Creating APT authentication configuration..."
    echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" | sudo tee /etc/apt/auth.conf > /dev/null
    sudo chmod 600 /etc/apt/auth.conf

    # Download and install the SignalWire FreeSWITCH repository GPG key
    echo "Downloading the SignalWire FreeSWITCH repository GPG key..."
    sudo wget --http-user=signalwire --http-password="$TOKEN" -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg "https://freeswitch.signalwire.com/repo/deb/debian-unstable/signalwire-freeswitch-repo.gpg"

    # Add the FreeSWITCH repository to the APT sources list
    echo "Adding the FreeSWITCH repository to APT sources..."
    sudo bash -c 'echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-unstable/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/freeswitch.list'
    sudo bash -c 'echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-unstable/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/freeswitch.list'

    # Update package lists
    echo "Updating package lists..."
    sudo apt-get update
fi

# Check if FreeSWITCH is already installed
if is_freeswitch_installed; then
    echo "FreeSWITCH is already installed. Skipping installation."
else
    # Update package lists and install prerequisites
    echo "Updating package lists and installing prerequisites..."
    sudo apt-get update && sudo apt-get install -y gnupg2 wget lsb-release

    # Install FreeSWITCH dependencies and FreeSWITCH
    echo "Installing FreeSWITCH..."
    sudo apt-get install -y freeswitch-meta-all
fi

# Create 'freeswitch' user and group if they don't exist
echo "Creating 'freeswitch' user and group..."
if ! id -u freeswitch >/dev/null 2>&1; then
    sudo adduser --quiet --system --home /var/lib/freeswitch --shell /bin/false --group freeswitch
fi

# Set ownership of FreeSWITCH directories
echo "Setting ownership of FreeSWITCH directories..."
sudo chown -R freeswitch:freeswitch /etc/freeswitch
sudo chown -R freeswitch:freeswitch /var/lib/freeswitch
sudo chown -R freeswitch:freeswitch /usr/share/freeswitch
sudo chown -R freeswitch:freeswitch /var/log/freeswitch
sudo sed -i 's/<param name="listen-ip" value="::"\/>/<param name="listen-ip" value="127.0.0.1"\/>/g' /etc/freeswitch/autoload_configs/event_socket.conf.xml

# Optionally populate /etc/freeswitch at this point
# if [ ! -d "/etc/freeswitch" ]; then
#     echo "/etc/freeswitch does not exist. Deploying custom configuration..."
#     # Add commands here to populate /etc/freeswitch
#     # For example:
#     # sudo cp -r /path/to/your/config/* /etc/freeswitch/
#     # sudo chown -R freeswitch:freeswitch /etc/freeswitch
# fi

# Ask the user to choose between systemd and init scripts
echo "Please choose the service management method for FreeSWITCH:"
echo "1) systemd"
echo "2) SysVinit (init scripts with 'service' command)"
read -p "Enter the number of your choice [1 or 2]: " SERVICE_CHOICE

if [ "$SERVICE_CHOICE" == "1" ]; then
    # Use systemd
    if is_systemd; then
        echo "Configuring FreeSWITCH to use systemd..."

        # Create systemd service file for FreeSWITCH
        echo "Creating systemd service file for FreeSWITCH..."
        sudo tee /etc/systemd/system/freeswitch.service > /dev/null <<EOL
[Unit]
Description=FreeSWITCH
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/freeswitch/freeswitch.pid
Environment="DAEMON_OPTS=-ncwait -nonat"
ExecStartPre=/bin/mkdir -p /run/freeswitch
ExecStartPre=/bin/chown freeswitch:freeswitch /run/freeswitch
ExecStart=/usr/bin/freeswitch -u freeswitch -g freeswitch -ncwait -nonat
TimeoutSec=45s
Restart=always
RestartSec=90

[Install]
WantedBy=multi-user.target
EOL

        # Reload systemd daemon to recognize the new service
        echo "Reloading systemd daemon..."
        sudo systemctl daemon-reload

        # Enable FreeSWITCH service to start at boot
        echo "Enabling FreeSWITCH service to start at boot..."
        sudo systemctl enable freeswitch

        # Optionally start FreeSWITCH now
        read -p "Do you want to start FreeSWITCH now? (y/n): " START_CHOICE
        if [ "$START_CHOICE" == "y" ] || [ "$START_CHOICE" == "Y" ]; then
            sudo systemctl start freeswitch
            echo "FreeSWITCH started."
        else
            echo "You can start FreeSWITCH later using: sudo systemctl start freeswitch"
        fi
    else
        echo "Systemd is not available on this system. Falling back to SysVinit."
        SERVICE_CHOICE="2"
    fi
fi

if [ "$SERVICE_CHOICE" == "2" ]; then
    # Use SysVinit
    echo "Configuring FreeSWITCH to use SysVinit (init scripts)..."

    # Create init script for FreeSWITCH
    echo "Creating init script for FreeSWITCH..."
    sudo tee /etc/init.d/freeswitch > /dev/null <<'EOL'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          freeswitch
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: FreeSWITCH
### END INIT INFO

DAEMON=/usr/bin/freeswitch
DAEMON_OPTS="-ncwait -nonat -u freeswitch -g freeswitch"
NAME=freeswitch
DESC="FreeSWITCH"

PIDFILE=/var/run/$NAME.pid

case "$1" in
  start)
    echo "Starting $DESC..."
    start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS
    ;;
  stop)
    echo "Stopping $DESC..."
    start-stop-daemon --stop --quiet --pidfile $PIDFILE --retry 5
    ;;
  restart)
    echo "Restarting $DESC..."
    $0 stop
    sleep 2
    $0 start
    ;;
  status)
    if [ -e $PIDFILE ]; then
      echo "$DESC is running with PID $(cat $PIDFILE)."
    else
      echo "$DESC is not running."
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0
EOL

    # Make the init script executable
    sudo chmod +x /etc/init.d/freeswitch

    # Update the rc.d to include FreeSWITCH
    echo "Updating rc.d to include FreeSWITCH..."
    sudo update-rc.d freeswitch defaults

    # Optionally start FreeSWITCH now
    read -p "Do you want to start FreeSWITCH now? (y/n): " START_CHOICE
    if [ "$START_CHOICE" == "y" ] || [ "$START_CHOICE" == "Y" ]; then
        sudo service freeswitch start
        echo "FreeSWITCH started."
    else
        echo "You can start FreeSWITCH later using: sudo service freeswitch start"
    fi
fi

echo "FreeSWITCH setup complete."

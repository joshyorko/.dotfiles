set -eu

status() { echo ">>> $*" >&2; }

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null; then
        echo "This script requires superuser permissions. Please re-run as root."
        exit 1
    fi
    SUDO="sudo"
fi

status "Stopping and disabling ollama service..."
$SUDO systemctl stop ollama || true
$SUDO systemctl disable ollama || true
$SUDO rm -f /etc/systemd/system/ollama.service
$SUDO systemctl daemon-reload

status "Removing ollama user and group..."
$SUDO userdel -r ollama || true
$SUDO delgroup ollama || true

status "Uninstalling ollama binary..."
for BINDIR in /usr/local/bin /usr/bin /bin; do
    if [ -f "$BINDIR/ollama" ]; then
        $SUDO rm -f "$BINDIR/ollama"
    fi
done

# Replace this with the appropriate command to remove the NVIDIA CUDA drivers
# for your specific Linux distribution and package manager
# E.g., `$SUDO apt-get remove --purge nvidia-*` for Ubuntu systems using apt
# Or, `$SUDO yum remove nvidia-*` for CentOS/RHEL systems using yum

status "Ollama and related components have been uninstalled."


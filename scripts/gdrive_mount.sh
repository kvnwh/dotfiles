#!/bin/bash

# =============================================================
# Google Drive Setup Script via rclone (macOS)
# =============================================================
# Usage:
#   chmod +x setup_gdrive.sh
#   ./setup_gdrive.sh
# =============================================================

# REMOVED: set -e
# Reason: set -e causes the terminal tab to close on any error
# when this script is sourced from .zshrc. Using return 1 instead.

REMOTE_NAME="gdrive"
MOUNT_DIR="$HOME/gdrive"
LOG_DIR="$HOME/.rclone/logs"
LOG_FILE="$LOG_DIR/gdrive.log"
RCLONE_INSTALL_DIR="/usr/local/bin"

# -------------------------------------------------------------
# Helpers
# -------------------------------------------------------------
info()    { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m    $*"; }
warn()    { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error()   { echo -e "\033[1;31m[ERROR]\033[0m $*"; return 1; }
# NOTE: uses "return 1" instead of "exit 1" so sourcing from .zshrc
# doesn't close the terminal tab on error

# -------------------------------------------------------------
# Detect architecture
# -------------------------------------------------------------
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  RCLONE_ARCH="osx-arm64"
else
  RCLONE_ARCH="osx-amd64"
fi

info "google drive auto mounting..."
# -------------------------------------------------------------
# 1. Check for Homebrew
# -------------------------------------------------------------
# info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  warn "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    error "Homebrew installation failed. Please install manually from https://brew.sh"
    return 1
  }
# else
#   success "Homebrew is installed."
fi

# -------------------------------------------------------------
# 2. Install rclone from official binary (NOT Homebrew)
#    Homebrew's rclone does not support FUSE mounting on macOS
# -------------------------------------------------------------
# info "Checking for rclone (official binary)..."
# RCLONE_IS_HOMEBREW=false
# if command -v rclone &>/dev/null; then
#   if brew list rclone &>/dev/null 2>&1; then
#     RCLONE_IS_HOMEBREW=true
#   fi
# fi

# if [ "$RCLONE_IS_HOMEBREW" = true ]; then
#   warn "Homebrew rclone detected — it does not support FUSE mounting."
#   warn "Uninstalling Homebrew rclone and replacing with the official binary..."
#   brew uninstall rclone
# fi

if ! command -v rclone &>/dev/null; then
  info "Installing official rclone binary for $RCLONE_ARCH..."
  TMP_DIR="$(mktemp -d)"
  cd "$TMP_DIR" || return 1
  curl -fsSL "https://downloads.rclone.org/rclone-current-${RCLONE_ARCH}.zip" -o rclone.zip || {
    error "Failed to download rclone."
    return 1
  }
  unzip -q rclone.zip
  cd rclone-*-osx-*/
  sudo cp rclone "$RCLONE_INSTALL_DIR/rclone"
  sudo chown root:wheel "$RCLONE_INSTALL_DIR/rclone"
  sudo chmod 755 "$RCLONE_INSTALL_DIR/rclone"
  cd ~
  rm -rf "$TMP_DIR"
  success "Official rclone installed at $RCLONE_INSTALL_DIR/rclone."
# else
#   success "rclone is already installed ($(rclone --version | head -1))."
fi

# -------------------------------------------------------------
# 3. Install macFUSE (needed for mounting)
# -------------------------------------------------------------
# info "Checking for macFUSE..."
if ! brew list --cask macfuse &>/dev/null 2>&1; then
  info "Installing macFUSE (may require your password)..."
  brew install --cask macfuse || { error "macFUSE install failed."; return 1; }
  echo ""
  warn "============================================="
  warn "ACTION REQUIRED: Approve macFUSE kernel extension"
  warn "============================================="
  warn "1. Open: System Settings → Privacy & Security"
  warn "2. Scroll to the Security section"
  warn "3. Click 'Allow' next to the macFUSE/Benjamin Fleischer message"
  warn "4. Enter your Mac password"
  warn "5. RESTART your Mac, then re-run this script"
  warn "============================================="
  echo ""
  error "Please approve macFUSE and restart your Mac before continuing."
  return 1
# else
#   success "macFUSE is already installed."
fi

# Verify macFUSE kernel extension is loaded
if ! ls /Library/Filesystems/ 2>/dev/null | grep -q "fuse\|macfuse"; then
  echo ""
  warn "macFUSE is installed but the kernel extension is not loaded."
  warn "Make sure you have:"
  warn "  1. Allowed it in System Settings → Privacy & Security"
  warn "  2. Restarted your Mac"
  echo ""
  error "Please approve macFUSE in System Settings and restart your Mac, then re-run."
  return 1
fi
# success "macFUSE kernel extension is active."

# -------------------------------------------------------------
# 4. Configure rclone remote for Google Drive
# -------------------------------------------------------------
# info "Checking for existing rclone remote '$REMOTE_NAME'..."
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
#   warn "Remote '$REMOTE_NAME' already exists. Skipping configuration."
#   warn "To reconfigure, run: rclone config"
# else
  info "Launching interactive rclone config to connect Google Drive..."
  echo ""
  echo "  Follow these steps in the rclone config wizard:"
  echo "  1. Choose 'n' for New remote"
  echo "  2. Name it: $REMOTE_NAME"
  echo "  3. Choose 'Google Drive' from the list"
  echo "  4. Leave client_id and client_secret blank (press Enter)"
  echo "  5. Choose scope '1' (full access)"
  echo "  6. Leave root_folder_id blank (press Enter)"
  echo "  7. Leave service_account_file blank (press Enter)"
  echo "  8. Choose 'n' for advanced config"
  echo "  9. Choose 'y' to use auto config (browser will open)"
  echo "  10. Choose 'n' for team drive (unless you use one)"
  echo "  11. Confirm with 'y', then 'q' to quit config"
  echo ""
  read -rp "Press Enter to open rclone config..."
  rclone config
fi

# Verify remote was created
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  error "Remote '$REMOTE_NAME' not found after config. Please re-run and complete setup."
  return 1
fi
# success "Remote '$REMOTE_NAME' is configured."

# -------------------------------------------------------------
# 5. Create mount directory and log directory
# -------------------------------------------------------------
# info "Setting up mount directory at $MOUNT_DIR..."
mkdir -p "$MOUNT_DIR"
# mkdir -p "$LOG_DIR"
# success "Mount directory ready."

# -------------------------------------------------------------
# 6. Test the connection
# -------------------------------------------------------------
# info "Testing connection to Google Drive..."
if ! rclone lsd "${REMOTE_NAME}:" --max-depth 1 &>/dev/null; then
#   success "Successfully connected to Google Drive!"
# else
  error "Could not connect to Google Drive. Check your credentials with: rclone config"
  return 1
fi

# -------------------------------------------------------------
# 7. Mount now
# -------------------------------------------------------------
# info "Mounting Google Drive at $MOUNT_DIR..."

# Unmount if already mounted - original
# if not mount, try mounting it
if ! mount | grep -q "$MOUNT_DIR"; then
#   warn "Something is already mounted at $MOUNT_DIR. Unmounting first..."
#   umount "$MOUNT_DIR" 2>/dev/null || diskutil unmount force "$MOUNT_DIR" 2>/dev/null || true
#   sleep 2

  rclone mount "${REMOTE_NAME}:" "$MOUNT_DIR" \
  --vfs-cache-mode full \
  --dir-cache-time 5m \
  --vfs-cache-max-age 5m \
  --poll-interval 30s \
  --daemon

  sleep 3
fi

if mount | grep -q "$MOUNT_DIR"; then
  success "Google Drive mounted at $MOUNT_DIR"
else
  error "Mount failed. Check logs: $LOG_FILE"
  return 1
fi

# # -------------------------------------------------------------
# # 8. Create the mount script
# # -------------------------------------------------------------
# MOUNT_SCRIPT="$HOME/.rclone/mount_gdrive.sh"
# info "Creating mount script at $MOUNT_SCRIPT..."

# cat > "$MOUNT_SCRIPT" << 'MOUNTSCRIPT'
# #!/bin/bash

# MOUNT_DIR="$HOME/gdrive"
# LOG_FILE="$HOME/.rclone/logs/gdrive.log"
# REMOTE_NAME="gdrive"

# # Only mount if not already mounted
# if mount | grep -q "$MOUNT_DIR"; then
#   echo "✅ Google Drive already mounted at $MOUNT_DIR"
#   exit 0
# fi

# # Ensure mount directory exists
# mkdir -p "$MOUNT_DIR"
# mkdir -p "$(dirname "$LOG_FILE")"

# # Mount Google Drive
# rclone mount "${REMOTE_NAME}:" "$MOUNT_DIR" \
#   --vfs-cache-mode full \
#   --dir-cache-time 5m \
#   --vfs-cache-max-age 5m \
#   --poll-interval 30s \
#   --daemon

# sleep 2

# if mount | grep -q "$MOUNT_DIR"; then
#   echo "✅ Google Drive mounted at $MOUNT_DIR"
# else
#   echo "❌ Failed to mount Google Drive. Check logs: $LOG_FILE"
# fi
# MOUNTSCRIPT

# chmod +x "$MOUNT_SCRIPT"
# success "Mount script created at $MOUNT_SCRIPT"

# # -------------------------------------------------------------
# # 9. Add mount script call to ~/.zshrc
# # -------------------------------------------------------------
# info "Adding mount script to ~/.zshrc..."

# ZSHRC="$HOME/.zshrc"
# ZSHRC_MARKER="# rclone gdrive mount"

# if grep -q "$ZSHRC_MARKER" "$ZSHRC" 2>/dev/null; then
#   warn "Mount script already referenced in ~/.zshrc. Skipping."
# else
#   printf "\n%s\nsource \"%s\"\n" "$ZSHRC_MARKER" "$MOUNT_SCRIPT" >> "$ZSHRC"
#   success "Added mount script to ~/.zshrc"
# fi

# # -------------------------------------------------------------
# # Done!
# # -------------------------------------------------------------
# echo ""
# echo "============================================="
# success "Setup complete!"
# echo "============================================="
# echo ""
# echo "  📁 Mount path  : $MOUNT_DIR"
# echo "  🔧 Remote name : $REMOTE_NAME"
# echo "  📜 Mount script: $HOME/.rclone/mount_gdrive.sh"
# echo "  📋 Logs        : $LOG_FILE"
# echo ""
# echo "  Useful commands:"
# echo "    ls ~/gdrive                      — browse your Drive"
# echo "    rclone lsd gdrive:               — list top-level folders"
# echo "    umount ~/gdrive                  — unmount"
# echo "    rclone config                    — manage remotes"
# echo "    cat ~/.rclone/logs/gdrive.log    — view logs"
# echo ""
# echo "  Open a new terminal to auto-mount, or run now:"
# echo "    source ~/.zshrc"
# echo ""
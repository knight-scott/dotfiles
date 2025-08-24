# Shared functions for setup.sh and install.sh

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # reset

# Pretty echo
color_echo() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# Check if directory exists, create if not
checkdir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        color_echo "$CYAN" "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

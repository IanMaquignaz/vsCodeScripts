#!/bin/bash 

# Shortcut
# Add vscode to .bashrc

# Constants
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
THIS_SCRIPT="$LOCAL_DIR/$(basename "$0")"
HOST='shoe'
BOOL_INSTALL_REMOTE=false
BOOL_INSTALL_LOCAL=false

# Get command line arguments
OPTIONS=hiI   # -h help
OPTIND=1 # Holds the number of options parsed by the last call to getopts. Reset in case getopts has been used previously in the shell
while getopts $OPTIONS opt; do
    case "${opt}" in
        I) # Install (local)
            echo "Will add alias to .bashrc on local machine $(hostname)"
            BOOL_INSTALL_LOCAL=true
            ;;
        i) # Install (remote)
            echo "Will install start_vscode.sh on remote"
            BOOL_INSTALL_REMOTE=true
            ;;
        \?) # Invalid option
            echo "Invalid option: -$opt" >&2
            exit 1
            ;;
        h) # Help
            echo "Need help? There is no help. Read the code."
            exit 0 
            ;;
    esac
done
shift $((OPTIND-1)) # remove options that have already been handled from $@

# Check if running in tmux, Screen, or vscode
if [ "$TERM" = "screen" ] && [ -n "$TMUX" ] || [ -n "$TERM_PROGRAM" ]; then 
    echo "<!> Running this script in Screen, Tmux or vscode will cause issues."
    echo "<!> Please run this script in a normal terminal."
fi

# Install Local
if [ "$BOOL_INSTALL_LOCAL" = true ]; then
    BASHRC="$HOME/.bashrc"
    source $BASHRC
    echo "[$(hostname)] Adding Alias to $BASHRC"
    if alias vscode >/dev/null 2>&1; then 
        echo "--> --> Alias \"vscode\" already in $BASHRC"
    else 
        echo "--> --> Installing alias \"vscode\" to $BASHRC"
        echo "alias vscode=\"$THIS_SCRIPT\"" >> $BASHRC
        echo "--> --> Done!"
    fi 
    source $BASHRC
    exit 0
fi

# Get Host
if [ -z "$1" ]; then
    echo "[$(hostname)] Will connect to default host: $HOST"
else
    HOST=$1
    echo "[$(hostname)] Will connect to $HOST"
fi

# Install Remote
if [ "$BOOL_INSTALL_REMOTE" = true ]; then
    echo "[$(hostname)] Installing vscode on host $HOST"
    ssh $HOST -tt <<-'ENDSSH'
START_SCRIPT="$HOME/start_vscode.sh"
echo "[$(hostname)] Creating $START_SCRIPT"
cat <<-'EOF' > $START_SCRIPT
#!/bin/bash

# Downloads & runs VScode
# See: https://code.visualstudio.com/docs/remote/tunnels

SESSION_NAME="VSCODE_TUNNEL"
FP_VSCODE_CLI="$HOME/vscode_cli_alpine_x64_cli.tar.gz"
URL_VSCODE_CLI='https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64'

# Kill Old vscode server(s)
tmux kill-session -t $SESSION_NAME

# Delete old version
rm -f $HOME/code

# Download
wget --no-verbose -NS --content-disposition $URL_VSCODE_CLI -P $HOME

if [ -f "$FP_VSCODE_CLI" ]; then
    	echo "Extracting..."
        # Extract
        tar -xvf $FP_VSCODE_CLI --directory $HOME
else
	echo "Failed to download File. Skipping extraction."
fi

# Run
echo "Starting vsCode tunnel..."
tmux new-session -s $SESSION_NAME "$HOME/code tunnel"
tmux ls
EOF
chmod 700 $START_SCRIPT
echo "[$(hostname)] --> Done."


BASHRC="$HOME/.bashrc"
source $BASHRC
echo "[$(hostname)] Adding Alias to $BASHRC"
if alias code >/dev/null 2>&1;; then 
    echo "--> --> Alias \"code\" already in $BASHRC"
else 
    echo "--> --> Installing alias \"code\" to $BASHRC"
    echo "alias code='\$HOME/start_vscode.sh'">> $BASHRC
    echo "--> --> Done."
fi 

BASH_PROFILE="$HOME/.bash_profile"
echo "[$(hostname)]  Updating $BASH_PROFILE to source $BASHRC"
CMD_BASH_PROFILE="# Source .bashrc if running bash"
if [ -f $BASH_PROFILE ] && $(grep -q "$CMD_BASH_PROFILE" $BASH_PROFILE); then 
    echo "--> --> $BASH_PROFILE sourcing of $BASHRC already implemented."
else 
    echo "--> --> Installing $BASH_PROFILE sourcing of $BASHRC"
    cat <<-'EOF' >> $BASH_PROFILE
# Source .bashrc if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi
EOF
    echo "--> --> Done."
fi

source $BASHRC
echo "[$(hostname)] Installation complete."
./start_vscode.sh
ENDSSH

else
    # Check if file exists and launch
    ssh $HOST -tt <<-'ENDSSH'
if [ -f $HOME/start_vscode.sh ]; then
    echo "[$(hostname)]  Starting vscode server..."
    ./start_vscode.sh
else 
    echo "[$(hostname)] File not found: $(whoami)@$HOSTNAME:$HOME/start_vscode.sh"
fi
ENDSSH
fi

# Cleanup
clear

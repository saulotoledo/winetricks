# Function to protect wine-specific sections of code.
# Outputs a message to console explaining what's being skipped.
# Usage:
#   if w_skip_windows name-of-operation
#   then
#      return
#   fi
#   ... do something that doesn't make sense on windows ...

w_skip_windows()
{
    case "$OS" in
    "Windows_NT")
        echo "Skipping operation '$1' on Windows"
        return 0
        ;;
    esac
    return 1
}


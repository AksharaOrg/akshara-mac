#!/bin/bash

# Setup colors
GREEN='\033[32m'
CYAN='\033[36m'
RED='\033[31m'
YELLOW='\033[33m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

spin() {
    local pid=$1
    local msg="$2"
    local delay=0.08
    local spin_frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    tput civis # Hide cursor
    while kill -0 $pid 2>/dev/null; do
        for frame in "${spin_frames[@]}"; do
            printf "\r \e[36m%s\e[0m %s" "$frame" "$msg"
            sleep $delay
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    local status=$?
    printf "\r\033[K" # Clear line
    if [ $status -eq 0 ]; then
        echo -e "\033[32m✔\033[0m $msg"
    else
        echo -e "\033[31m✖\033[0m $msg"
    fi
    tput cnorm # Show cursor
    return $status
}

print_header() {
    clear
    echo -e "${GREEN}"
    echo "    _    _        _                   "
    echo "   / \  | | _____| |__   __ _ _ __ __ _ "
    echo "  / _ \ | |/ / __| '_ \ / _\` | '__/ _\` |"
    echo " / ___ \|   <\__ \ | | | (_| | | | (_| |"
    echo "/_/   \_\_|\_\___/_| |_|\__,_|_|  \__,_|"
    echo -e "${RESET}"
    echo -e "${CYAN}අක්ෂර (Akshara) Mac Release Manager${RESET}"
    echo "----------------------------------------"
    echo ""
}

# Menu state
SELECTED=0
OPTIONS=("Create Release" "Find Abandoned Tags" "Delete Tag" "Quit")
DESCRIPTIONS=(
    "Create a new local tag and push to upstream"
    "Find tags that do not have a .pkg release asset attached"
    "Delete a tag locally and remotely"
    "Exit this tool"
)

draw_menu() {
    for i in "${!OPTIONS[@]}"; do
        if [ $i -eq $SELECTED ]; then
            printf "${CYAN}> %d. %-20s${RESET} ${DIM}%s${RESET}\n" "$((i+1))" "${OPTIONS[$i]}" "${DESCRIPTIONS[$i]}"
        else
            printf "  %d. %-20s ${DIM}%s${RESET}\n" "$((i+1))" "${OPTIONS[$i]}" "${DESCRIPTIONS[$i]}"
        fi
    done
    echo ""
    echo -e "${DIM}↑/↓ to navigate | Enter to select | Q to quit${RESET}"
}

fetch_github_api() {
    local endpoint="$1"
    if command -v gh >/dev/null 2>&1; then
        gh api "$endpoint" 2>/dev/null
    else
        curl -s "https://api.github.com/repos/AksharaOrg/akshara-mac/$endpoint"
    fi
}

handle_create() {
    echo ""
    local TEMP_LATEST=$(mktemp)
    
    ( fetch_github_api "releases/latest" | jq -r '.tag_name // empty' > "$TEMP_LATEST" ) &
    spin $! "Fetching latest GitHub release..."
    
    local LATEST_GH=$(cat "$TEMP_LATEST")
    rm -f "$TEMP_LATEST"
    
    if [ -z "$LATEST_GH" ]; then
        LATEST_GH="None"
    fi
    
    local LATEST_LOCAL=$(git describe --tags --abbrev=0 2>/dev/null || echo "None")
    
    echo -e "${DIM}Latest GitHub release: ${LATEST_GH}${RESET}"
    echo -e "${DIM}Latest local tag:      ${LATEST_LOCAL}${RESET}"
    echo ""
    
    read -p "Enter the new release version (e.g. v0.1.14): " VERSION
    if [ -z "$VERSION" ]; then
        echo -e "${RED}✖${RESET} Version cannot be empty."
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    # Check if tag already exists
    git show-ref --tags --verify --quiet "refs/tags/$VERSION"
    if [ $? -eq 0 ]; then
        echo -e "${RED}✖${RESET} Tag '$VERSION' already exists."
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    VERSION_NUM=${VERSION#v}
    
    ( git tag -a "$VERSION" -m "Akshara $VERSION_NUM" ) &
    spin $! "Creating local tag $VERSION"
    if [ $? -ne 0 ]; then
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    ( git push upstream "$VERSION" >/dev/null 2>&1 ) &
    spin $! "Pushing tag $VERSION to upstream"
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Failed to push tag. Please check your git configuration and try again.${RESET}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    echo -e "\n${GREEN}🎉 Release process initiated for $VERSION!${RESET}"
    read -n 1 -s -r -p "Press any key to continue..."
}

handle_abandoned() {
    echo ""
    local TEMP_RELEASES=$(mktemp)
    local TEMP_TAGS=$(mktemp)
    
    ( fetch_github_api "releases" | jq -r 'if type == "array" then .[] | select(any(.assets[]; .name | endswith(".pkg"))) | .tag_name else empty end' > "$TEMP_RELEASES" ) &
    spin $! "Fetching tags with .pkg releases..."
    
    ( git ls-remote --tags upstream | awk '{print $2}' | grep -v '\^{}' | sed 's/refs\/tags\///' > "$TEMP_TAGS" ) &
    spin $! "Fetching all remote tags..."
    
    echo -e "\n${YELLOW}Abandoned Tags (No .pkg release attached):${RESET}"
    local count=0
    while read -r tag; do
        if ! grep -q "^$tag$" "$TEMP_RELEASES"; then
            echo "  - $tag"
            count=$((count + 1))
        fi
    done < "$TEMP_TAGS"
    
    if [ $count -eq 0 ]; then
        echo "  None found. All remote tags have valid releases."
    fi
    
    rm -f "$TEMP_RELEASES" "$TEMP_TAGS"
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

handle_delete() {
    local TEMP_LATEST=$(mktemp)
    ( fetch_github_api "releases/latest" | jq -r '.tag_name // empty' > "$TEMP_LATEST" ) &
    spin $! "Fetching latest GitHub release..."
    local LATEST_GH=$(cat "$TEMP_LATEST")
    rm -f "$TEMP_LATEST"
    if [ -z "$LATEST_GH" ]; then LATEST_GH="None"; fi
    local LATEST_LOCAL=$(git describe --tags --abbrev=0 2>/dev/null || echo "None")

    local TEMP_TAGS=$(mktemp)
    ( git fetch upstream --tags >/dev/null 2>&1 || true; git tag -l --sort=-v:refname > "$TEMP_TAGS" ) &
    spin $! "Fetching all local and remote tags..."
    
    local TAGS=()
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            TAGS+=("$line")
        fi
    done < "$TEMP_TAGS"
    rm -f "$TEMP_TAGS"
    
    if [ ${#TAGS[@]} -eq 0 ]; then
        echo -e "\n${RED}No local tags found.${RESET}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    local SELECTED_IDX=0
    local PAGE_SIZE=10
    
    while true; do
        clear
        print_header
        echo -e "${DIM}Latest GitHub release: ${LATEST_GH}${RESET}"
        echo -e "${DIM}Latest local tag:      ${LATEST_LOCAL}${RESET}"
        echo ""
        echo -e "${YELLOW}Select a tag to delete:${RESET}"
        
        local TOTAL_TAGS=${#TAGS[@]}
        local CURRENT_PAGE=$(( SELECTED_IDX / PAGE_SIZE ))
        local START_IDX=$(( CURRENT_PAGE * PAGE_SIZE ))
        local END_IDX=$(( START_IDX + PAGE_SIZE ))
        if [ $END_IDX -gt $TOTAL_TAGS ]; then
            END_IDX=$TOTAL_TAGS
        fi
        
        local TOTAL_PAGES=$(( (TOTAL_TAGS + PAGE_SIZE - 1) / PAGE_SIZE ))
        
        for (( i=START_IDX; i<END_IDX; i++ )); do
            if [ $i -eq $SELECTED_IDX ]; then
                printf "${CYAN}> %-20s${RESET}\n" "${TAGS[$i]}"
            else
                printf "  %-20s\n" "${TAGS[$i]}"
            fi
        done
        
        echo ""
        echo -e "${DIM}Page $((CURRENT_PAGE + 1)) of $TOTAL_PAGES | ↑/↓ to navigate | Enter to select | Q to cancel${RESET}"
        
        read -rsn1 key
        case "$key" in
            $'\e')
                read -rsn2 key2
                case "$key2" in
                    '[A')
                        if [ $SELECTED_IDX -gt 0 ]; then
                            SELECTED_IDX=$((SELECTED_IDX - 1))
                        fi
                        ;;
                    '[B')
                        if [ $SELECTED_IDX -lt $((TOTAL_TAGS - 1)) ]; then
                            SELECTED_IDX=$((SELECTED_IDX + 1))
                        fi
                        ;;
                esac
                ;;
            "") # Enter
                local TAG="${TAGS[$SELECTED_IDX]}"
                tput cnorm
                echo -e "\n${RED}WARNING: You are about to delete tag '$TAG'.${RESET}"
                read -p "Are you sure? [y/N]: " confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo "Aborted."
                    tput civis
                    read -n 1 -s -r -p "Press any key to continue..."
                    return
                fi
                
                echo ""
                # Local delete
                if git show-ref --tags --verify --quiet "refs/tags/$TAG"; then
                    ( git tag -d "$TAG" >/dev/null ) &
                    spin $! "Deleting local tag $TAG"
                else
                    echo -e "${DIM}Local tag not found, skipping.${RESET}"
                fi
                
                # Remote delete
                git ls-remote --exit-code --tags upstream "refs/tags/$TAG" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    ( git push upstream --delete "$TAG" >/dev/null 2>&1 ) &
                    spin $! "Deleting upstream tag $TAG"
                else
                    echo -e "${DIM}Remote tag not found, skipping.${RESET}"
                fi
                
                echo -e "\n${GREEN}✔ Deletion complete.${RESET}"
                tput civis
                read -n 1 -s -r -p "Press any key to continue..."
                return
                ;;
            q|Q)
                return
                ;;
        esac
    done
}

# Ensure upstream is added
git remote add upstream https://github.com/AksharaOrg/akshara-mac.git 2>/dev/null || true

# Hide cursor initially
tput civis
# Ensure cursor is visible on exit
trap "tput cnorm" EXIT

# Main loop
while true; do
    print_header
    draw_menu
    
    # Read a single character or escape sequence
    read -rsn1 key
    case "$key" in
        $'\e') # Handle escape sequences for arrows
            read -rsn2 key2
            case "$key2" in
                '[A') # Up arrow
                    if [ $SELECTED -gt 0 ]; then
                        SELECTED=$((SELECTED - 1))
                    fi
                    ;;
                '[B') # Down arrow
                    if [ $SELECTED -lt $((${#OPTIONS[@]} - 1)) ]; then
                        SELECTED=$((SELECTED + 1))
                    fi
                    ;;
            esac
            ;;
        "") # Enter key
            tput cnorm # Show cursor during interactions
            case $SELECTED in
                0) handle_create ;;
                1) handle_abandoned ;;
                2) handle_delete ;;
                3) echo -e "\nGoodbye!"; exit 0 ;;
            esac
            tput civis # Hide cursor again
            ;;
        q|Q) # Quit key
            echo -e "\nGoodbye!"; exit 0 ;;
    esac
done

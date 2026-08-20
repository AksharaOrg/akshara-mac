#!/bin/bash

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

echo ""

# Step 1: Upstream remote
( git remote add upstream https://github.com/AksharaOrg/akshara-mac.git 2>/dev/null || true ) &
spin $! "Checking upstream remote configuration"

# Step 2: Fetching releases
TEMP_FILE=$(mktemp)
( curl -s https://api.github.com/repos/AksharaOrg/akshara-mac/releases | jq -r '.[] | select(any(.assets[]; .name | endswith(".pkg"))) | .tag_name' > "$TEMP_FILE" ) &
spin $! "Fetching existing release tags"

if [ -s "$TEMP_FILE" ]; then
    head -n 5 "$TEMP_FILE" | while read -r line; do
        printf "    \033[2m- %s\033[0m\n" "$line"
    done
fi
rm -f "$TEMP_FILE"
echo ""

while true; do
    read -p "Enter the new release version (e.g. v0.1.14): " VERSION
    
    if [ -z "$VERSION" ]; then
        echo -e "\033[31m✖\033[0m Version cannot be empty."
        continue
    fi

    # Check if tag already exists in the background
    git show-ref --tags --verify --quiet "refs/tags/$VERSION"
    if [ $? -eq 0 ]; then
        echo -e "\033[31m✖\033[0m Tag '$VERSION' already exists. Please enter a different version."
    else
        echo -e "\033[32m✔\033[0m Version '$VERSION' is available"
        break
    fi
done

echo ""
VERSION_NUM=${VERSION#v}

# Step 3: Create tag
( git tag -a "$VERSION" -m "Akshara $VERSION_NUM" ) &
spin $! "Creating local tag $VERSION"
if [ $? -ne 0 ]; then
    exit 1
fi

# Step 4: Push tag
( git push upstream "$VERSION" >/dev/null 2>&1 ) &
spin $! "Pushing tag $VERSION to upstream"
if [ $? -ne 0 ]; then
    echo -e "\n\033[31mFailed to push tag. Please check your git configuration and try again.\033[0m"
    exit 1
fi

echo ""
echo -e "\033[32m🎉 Release process initiated for $VERSION!\033[0m"
echo ""

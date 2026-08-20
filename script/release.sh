#!/bin/bash

# Add upstream remote, ignore if it already exists
git remote add upstream https://github.com/AksharaOrg/akshara-mac.git 2>/dev/null || true

echo ""
echo "Release tags currently containing a .pkg file:"
curl -s https://api.github.com/repos/AksharaOrg/akshara-mac/releases | jq -r '.[] | select(any(.assets[]; .name | endswith(".pkg"))) | .tag_name'
echo "----------------------------------------"
echo ""

while true; do
    # Prompt for version
    read -p "Enter the release version (e.g. v0.1.14): " VERSION
    
    # Check if input is empty
    if [ -z "$VERSION" ]; then
        echo "Version cannot be empty."
        continue
    fi

    # Check if tag already exists
    if git show-ref --tags --verify --quiet "refs/tags/$VERSION"; then
        echo "Tag '$VERSION' already exists. Please enter a different version."
    else
        break
    fi
done

# Remove 'v' prefix for the commit message (e.g. v0.1.14 -> 0.1.14)
VERSION_NUM=${VERSION#v}

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
    printf "\r\033[K" # Clear line
    tput cnorm # Show cursor
}

# Run tag creation and push in the background
(
    git tag -a "$VERSION" -m "Akshara $VERSION_NUM" && \
    git push upstream "$VERSION"
) >/dev/null 2>&1 &

# Show spinner while background task is running
spin $! "Creating and pushing tag $VERSION..."

wait $!
if [ $? -eq 0 ]; then
    echo -e "\r \033[32m✔\033[0m Successfully created and pushed tag \033[1m$VERSION\033[0m"
else
    echo -e "\r \033[31m✖\033[0m Failed to create or push tag \033[1m$VERSION\033[0m. Please check your git configuration."
fi

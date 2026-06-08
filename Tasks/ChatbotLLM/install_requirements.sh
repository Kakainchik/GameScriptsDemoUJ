#!/usr/bin/env bash
# Usage:
# chmod +x install_requirements.sh
# ./install_requirements.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0

echo "============================================================"
echo "  ChatbotLLM — Environment Check"
echo "============================================================"
echo ""

# Check Python
echo -n "[1/4] Python interpreter ... "
if command -v python3 &>/dev/null; then
    PY=python3
elif command -v python &>/dev/null; then
    PY=python
else
    echo -e "${RED}NOT FOUND${NC}"
    echo "       Please install Python 3.10+ and make sure it is in your PATH."
    exit 1
fi

PY_VERSION=$($PY --version 2>&1 | awk '{print $2}')
PY_MAJOR=$($PY -c "import sys; print(sys.version_info.major)")
PY_MINOR=$($PY -c "import sys; print(sys.version_info.minor)")

if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
    echo -e "${GREEN}OK${NC} ($PY -> $PY_VERSION)"
else
    echo -e "${YELLOW}WARNING${NC} ($PY -> $PY_VERSION)"
    echo "       Python 3.10+ is recommended. Some features may not work."
    errors=$((errors + 1))
fi

# Check pip
echo -n "[2/4] pip ................. "
if $PY -m pip --version &>/dev/null; then
    PIP_VERSION=$($PY -m pip --version | awk '{print $2}')
    echo -e "${GREEN}OK${NC} ($PIP_VERSION)"
else
    echo -e "${RED}NOT FOUND${NC}"
    echo "       Install pip: $PY -m ensurepip --upgrade"
    errors=$((errors + 1))
fi

# Check Python packages from requirements.txt
echo -n "[3/4] Python packages ..... "
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}MISSING${NC} (requirements.txt not found at $REQUIREMENTS_FILE)"
    errors=$((errors + 1))
else
    missing_packages=()
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        [ -z "$line" ] && continue

        # Extract package name (strip version specifiers like >=, ==, etc.)
        pkg_name=$(echo "$line" | sed 's/[><=!].*//' | xargs)

        # pip uses dashes but Python imports use underscores - normalize for import check
        import_name=$(echo "$pkg_name" | sed 's/-/_/g')

        # Special mapping: pyyaml imports as 'yaml', llama-cpp-python imports as 'llama_cpp'
        case "$pkg_name" in
            pyyaml|PyYAML)  import_name="yaml" ;;
            llama-cpp-python) import_name="llama_cpp" ;;
        esac

        if ! $PY -c "import $import_name" &>/dev/null; then
            missing_packages+=("$pkg_name")
        fi
    done < "$REQUIREMENTS_FILE"

    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo -e "${GREEN}OK${NC} (all packages installed)"
    else
        echo -e "${YELLOW}MISSING${NC} - installing..."
        for pkg in "${missing_packages[@]}"; do
            echo -n "       Installing $pkg ... "
            if $PY -m pip install "$pkg" &>/dev/null; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}FAILED${NC}"
                errors=$((errors + 1))
            fi
        done
    fi
fi

# Check required project files
echo -n "[4/4] Project files ....... "
missing_files=()
for fname in "main.py" "config.yaml" "chat_completion_schema.json" "system_prompt.txt"; do
    if [ ! -f "$SCRIPT_DIR/$fname" ]; then
        missing_files+=("$fname")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}MISSING${NC}"
    for f in "${missing_files[@]}"; do
        echo "       - $f"
    done
    errors=$((errors + 1))
fi

# Summary
echo ""
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}All checks passed.${NC} You can run the chatbot:"
    echo "  $PY $SCRIPT_DIR/main.py"
else
    echo -e "${YELLOW}$errors check(s) failed.${NC} Please fix the issues above before running main.py."
    exit 1
fi

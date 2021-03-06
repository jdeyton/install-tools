# This script installs the latest 3.x Python interpreter.

$python_dir = "$env:dev_bin\python"

# 3.x
$3x = choco search python3 --exact
$matches = [regex]::Match("$3x", 'python3\s+(3\.\d+\.\d+)')
if (-Not $matches.Success) {
    echo "ERROR: Could not determine latest Python 3 version available."
    exit 1
}
$3x = $matches.Groups[1].Value
echo "INFO: The latest Python 3 version available is $3x"

echo ""

# ---- (Re-)Install Python 3.x. ---- #
choco uninstall -y python3
choco install -y python3 --params "/InstallDir:$python_dir\$3x"
refreshenv

# ---- Point ROOT_PYTHON to the 3.x install ---- #
$root_python = "$python_dir\$3x"
echo "INFO: Setting ROOT_PYTHON to $root_python"
$env:root_python = "$root_python"
setx ROOT_PYTHON "$root_python" /m

# ---- Upgrade package management. ---- #
# Advised per https://packaging.python.org/tutorials/installing-packages/
# pipenv installed for virtual environment goodness
$cmd = "$env:root_python\python.exe -m pip install --upgrade pip setuptools wheel pipenv"
Invoke-Expression $cmd

exit 0

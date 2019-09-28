# This script installs the latest 2.x and 3.x Python interpreters.
# The 2.x version is not added to the system path.

$python_dir = "$env:dev_bin\python"

# Determine the 2.x and 3.x versions that will be installed.
# 2.x
$2x = choco search python2 --exact
$matches = [regex]::Match("$2x", 'python2\s+(2\.\d+\.\d+)')
if (-Not $matches.Success) {
    echo "ERROR: Could not determine latest Python 2 version available."
    exit 1
}
$2x = $matches.Groups[1].Value
echo "INFO: The latest Python 2 version available is $2x"
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

# ---- (Re-)Install Python 2.x ---- #
choco uninstall -y python2
choco install -y python2 --params "/InstallDir:$python_dir\$2x"
refreshenv
# Remove Python 2.x from the path.
$new_path = ($env:Path.Split(';') | Where-Object { $_ -NotMatch '.*[Pp]ython.*' }) -Join ';'
$env:Path = "$new_path"
setx Path "$new_path" /m

# ---- (Re-)Install Python 3.x. ---- #
choco uninstall -y python3
choco install -y python3 --params "/InstallDir:$python_dir\$3x"
#choco install -y python3 --install-arguments="'quiet TargetDir=$python_dir\3.6.0 InstallAllUsers=1 PrependPath=1'" --override-arguments
refreshenv

# ---- Point ROOT_PYTHON to the 3.x install ---- #
$root_python = "$python_dir\$3x"
echo "INFO: Setting ROOT_PYTHON to $root_python"
$env:root_python = "$root_python"
setx ROOT_PYTHON "$root_python" /m

exit 0
# This script performs the following installation steps for Eclipse:
# 1 - Check for a JVM (using environment variable ROOT_JAVA).
# 2 - Download/Install the latest Eclipse JEE via Chocolatey.
# 3 - Remove the unnecessary eclipse directory in the install dir.
# 4 - Put the JVM in the eclipse.ini file.

$eclipse_dir = "$env:dev_bin\eclipse"

$jvm = Get-ChildItem -Path $env:root_java -Recurse -Include 'java.exe'
if (Test-Path $jvm) {
    echo "INFO: JVM successfully found."
} else {
    echo "ERROR: No JVM found! Cannot install Eclipse!"
    exit 1
}

# Install through Chocolatey under .../eclipse/#.#
choco install -y eclipse --params "'/InstallationPath=$eclipse_dir\$packageVersion /Multi-User'"
$exit_code = $LASTEXITCODE

# Quit early if there was a bad exit code.
$valid_exit_codes = @(0, 1605, 1614, 1641, 3010)
if (-Not ($valid_exit_codes -contains $exit_code)) {
    echo "ERROR: During install of Eclipse, exit code $exit_code was returned!"
    Exit 1
}

# The install effectively extracts a zip file, so the final directory tree will
# be like: C:\...\eclipse\<version>\eclipse\eclipse.exe
# Move the contents from the nested "eclipse" folder up one dir.
$version = gci $eclipse_dir | sort LastWriteTime | select -last 1
$src = "$eclipse_dir\$version\eclipse"
$dest = "$eclipse_dir\$version"
if (Test-Path -Path "$src") {
    Move-Item -Path $src\* -Destination $dest
    Remove-Item -Path $src
    echo "INFO: Removed unnecessary eclipse folder."
}

# Make sure the .ini file has the JVM listed correctly, otherwise Eclipse might
# not start.
$ini = Get-ChildItem -Path $dest -Recurse -Include 'eclipse.ini'
[IO.File]::ReadAllText($ini) -replace '-vmargs',"-vm`n$jvm`n-vmargs" | Set-Content -Path $ini
echo "INFO: Updated $ini to point to the JVM $jvm"

echo ""
echo "INFO: Eclipse $version has been installed successfully."

exit 0
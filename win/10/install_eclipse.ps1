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
$version = Get-ChildItem $eclipse_dir | sort LastWriteTime | select -last 1
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

# ---- Install plugins. ---- #
# To find more plugins:
# 1 - Look them up in the Marketplace website
# 2 - Go to the "External Install Button" tab
# 3 - Get the "node ID", e.g.,
#     <a href="http://marketplace.ec...../mpc_install=<NODE_ID>"...
# 4 - Go to this URL: https://marketplace.eclipse.org/node/<NODE_ID>/api/p
# 5 - Get the update site from the <updateurl> element
# 6 - Get the feature IDs from the <iu> elements.
# 
# For some plugins, like Vrapper and EPIC, the actual feature IDs are different;
# they have ".feature.group" appended to the end.
#
$exe = Get-ChildItem -Path $dest -Recurse -Include 'eclipse.exe'
$plugins = "PyDev (Python)|https://www.pydev.org/updates|org.python.pydev.feature.group",
           "EPIC (Perl)|http://www.epic-ide.org/updates/testing|org.epic.feature.main.feature.group",
           "Vrapper|http://vrapper.sourceforge.net/update-site/stable|net.sourceforge.vrapper.feature.group",
           "Vrapper (JDT)|http://vrapper.sourceforge.net/update-site/stable|net.sourceforge.vrapper.eclipse.jdt.feature.feature.group",
           "Vrapper (PyDev)|http://vrapper.sourceforge.net/update-site/stable|net.sourceforge.vrapper.eclipse.pydev.feature.feature.group",
           "Bash Editor|https://dl.bintray.com/de-jcup/basheditor|de.jcup.basheditor",
           "SQL Editor|https://dl.bintray.com/de-jcup/sqleditor|de.jcup.sqleditor"
ForEach ($element in $plugins) {
    $parts = $element.Split('|')
    $plugin = $parts[0]
    $update_site = $parts[1]
    $feature_id = $parts[2]
    echo "INFO: Installing Eclipse plugin $plugin"
    $command = "$exe -application org.eclipse.equinox.p2.director -repository $update_site -installIU $feature_id"
    Write-Host "$command" -ForegroundColor DarkYellow
    $command | Invoke-Expression
    Read-Host -Prompt "foobar"
    # Eclipse forks off another process, so we have to wait for it to complete.
    # The logic below will wait up to 300 seconds before quitting and moving on.
    # Source: https://techblog.jere.ch/2019/04/09/install-eclipse-plugins-from-command-line/
    Start-Sleep 5
    [int]$counter = 0
    do {
        $eclipse_running = Get-Process -Name *eclipse*
        if (($eclipse_running) -and ($counter -le "30")) {
            Start-Sleep 10
            $counter++
            Write-Host "Still running: $($eclipse_running) $counter"
        } else {
            if ($counter -gt "30") {
                Write-Host "Try to kill running process while process is taking more than 5 Minutes" -ForegroundColor DarkYellow -BackgroundColor Black
            } else {
                Write-Host "Process ended by installer" -ForegroundColor Green
            }
            Get-Process *eclipse* | Stop-Process -Force
        }
    } until (!$eclipse_running)
    Start-Sleep 2
}

exit 0
# I have not figured out a reliable way to automate the latest JDK install.
# Unfortunately, Chocolatey does not seem to have a reliable latest-JDK package,
# so the process here is to wait for an installation to occur, then check for
# the most recently installed version to set the environment variable ROOT_JAVA.

$java_dir = "$env:dev_bin\java"

echo "INFO: Chocolatey does not provide the latest JDK."
echo "INFO: Please download the latest JDK from https://www.oracle.com/technetwork/java/javase/downloads/index.html"
echo "INFO: Install to $java_dir"

echo ""
Read-Host -Prompt "Press the Enter/return key after the installation has completed"
echo ""

$version = Get-ChildItem $java_dir | sort LastWriteTime | select -last 1
if ($version -eq $null) {
    echo "ERROR: Java installation not found under $java_dir!"
    exit 1
}

$root_java = "$java_dir\$version"
echo "INFO: Setting ROOT_JAVA to $root_java"
$env:root_java = "$root_java"
setx ROOT_JAVA "$root_java" /m

exit 0
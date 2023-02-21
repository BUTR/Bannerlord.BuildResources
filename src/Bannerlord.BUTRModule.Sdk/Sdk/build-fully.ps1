param (
    [Parameter()]
    [System.String]
    $BasePath,

    [Parameter()]
    [System.String]
    $OutputPath,

    [Parameter()]
    [System.String]
    $ModuleId,

    [Parameter()]
    [System.String]
    $ProjectPath,

    [Parameter()]
    [System.String]
    $Configuration
)

function GetPathIfFileExist($pathtosearch, $filename)
{
    if($pathtosearch -eq "")
    {
        throw "The file '$filename' was not found in '$pathtosearch'!";
    }
    $path = Join-Path $pathtosearch $filename
    if (Test-Path $path)
    {
        return $path
    }
    else
    {
        return GetPathIfFileExist (Split-Path $pathtosearch) $filename
    }
}

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath();
  do {
    $name = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName());
    $item = New-Item -Path $parent -Name $name -ItemType "directory" -ErrorAction SilentlyContinue;
  } while (-not $item)
  return $item.FullName;
}

if (-not $BasePath -or -not (Test-Path -LiteralPath $BasePath)) {
    throw "The folder '$BasePath' does not exist!";
}
if (-not $OutputPath -or -not (Test-Path -LiteralPath $OutputPath)) {
    $OutputPath = [IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath "output")); # Normalize path
} else {
    $OutputPath = [IO.Path]::GetFullPath(($OutputPath)); # Normalize path
}
if (-not $Configuration) {
    throw "The Configuration was not set!";
}

$tempWindows = New-TemporaryDirectory;
$tempWindowsStore = New-TemporaryDirectory;

$proj = [IO.Path]::GetFullPath($ProjectPath); # Normalize path
$binWindows =  [IO.Path]::GetFullPath((Join-Path -Path $OutputPath -ChildPath ("Modules/$ModuleId/bin/Win64_Shipping_Client"))); # Normalize path
$binWindowsStore =  [IO.Path]::GetFullPath((Join-Path -Path $OutputPath -ChildPath ("Modules/$ModuleId/bin/Gaming.Desktop.x64_Shipping_Client"))); # Normalize path
$pdllWindows = Join-Path -Path $binWindows -ChildPath ("$ModuleId*.dll");
$pdllWindowsStore = Join-Path -Path $binWindowsStore -ChildPath ("$ModuleId*.dll");
$ppdbWindows = Join-Path -Path $binWindows -ChildPath ("$ModuleId*.pdb");
$ppdbWindowsStore = Join-Path -Path $binWindowsStore -ChildPath ("$ModuleId*.pdb");
$gameversionspath = GetPathIfFileExist $BasePath "supported-game-versions.txt";
$gameversions = [IO.File]::ReadAllLines($gameversionspath);

# The folders are required to be created before executing the script
if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::group::Create folders"; }
New-Item -ItemType directory -Force -Path $binWindows;
New-Item -ItemType directory -Force -Path $binWindowsStore;
if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::endgroup::"; }

# Process all implementations
if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::group::Processing implementations"; }
For ($i = 0; $i -le $gameversions.Length - 1; $i++)
{
    if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::group::Build for $gameversion"; }
    $gameversion = $gameversions[$i];
    dotnet clean $proj --configuration $Configuration;
    dotnet build $proj --configuration $Configuration -p:OverrideGameVersion=$gameversion -p:GameFolder="$OutputPath" -p:ExtendedBuild=false;
    # Copy Implementations to the temp Windows folder
    Copy-Item $pdllWindows $tempWindows;
    Copy-Item $ppdbWindows $tempWindows;
    # Copy Implementations to the temp Windows folder
    Copy-Item $pdllWindowsStore $tempWindowsStore;
    Copy-Item $ppdbWindowsStore $tempWindowsStore;
    if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::endgroup::"; }
}
if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::endgroup::"; }

if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::group::Copy implementations folder to final folder and delete it"; }
# Copy Implementations and Loader to the Module
Copy-Item $tempWindows/* $binWindows;
Copy-Item $tempWindowsStore/* $binWindowsStore;
# Delete Implementations folder
Remove-Item -Recurse $tempWindows;
Remove-Item -Recurse $tempWindowsStore;
if ($env:GITHUB_ACTIONS -eq "true") { Write-Output "::endgroup::"; }
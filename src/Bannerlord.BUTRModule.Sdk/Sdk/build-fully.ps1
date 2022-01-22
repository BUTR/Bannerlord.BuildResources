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
    $ProjectPath
)

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath();
  do {
    $name = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName());
    $item = New-Item -Path $parent -Name $name -ItemType "directory" -ErrorAction SilentlyContinue;
  } while (-not $item)
  return $item.FullName;
}

if (-not $BasePath || -not (Test-Path -LiteralPath $BasePath)) {
    throw "The folder '$BasePath' does not exist!";
}
if (-not $OutputPath || -not (Test-Path -LiteralPath $OutputPath)) {
    $OutputPath = [IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath "output")); # Normalize path
} else {
    $OutputPath = [IO.Path]::GetFullPath(($OutputPath)); # Normalize path
}

$temp = New-TemporaryDirectory;

$proj = [IO.Path]::GetFullPath($ProjectPath); # Normalize path
$bin =  [IO.Path]::GetFullPath((Join-Path -Path $OutputPath -ChildPath ("Modules/$ModuleId/bin/Win64_Shipping_Client"))); # Normalize path
$pdll = Join-Path -Path $bin -ChildPath ("$ModuleId*.dll");
$ppdb = Join-Path -Path $bin -ChildPath ("$ModuleId*.pdb");
$gameversionspath = [IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath "supported-game-versions.txt"));
$gameversions = Get-Content -LiteralPath $gameversionspath;

# The folders are required to be created before executing the script
if ($env:GITHUB_ACTIONS -eq "true") { echo "::group::Create folders"; }
New-Item -ItemType directory -Force -Path $bin;
if ($env:GITHUB_ACTIONS -eq "true") { echo "::endgroup::"; }

# Process all implementations
if ($env:GITHUB_ACTIONS -eq "true") { echo "::group::Processing implementations"; }
For ($i = 0; $i -le $gameversions.Length - 1; $i++)
{
    if ($env:GITHUB_ACTIONS -eq "true") { echo "::group::Build for $gameversion"; }
    $gameversion = $gameversions[$i];
    dotnet clean $proj --configuration Release;
    dotnet build $proj --configuration Release -p:OverrideGameVersion=$gameversion -p:GameFolder="$OutputPath" -p:ExtendedBuild=false;
    # Copy Implementations to the temp folder
    Copy-Item $pdll $temp;
    Copy-Item $ppdb $temp;
    if ($env:GITHUB_ACTIONS -eq "true") { echo "::endgroup::"; }
}
if ($env:GITHUB_ACTIONS -eq "true") { echo "::endgroup::"; }

if ($env:GITHUB_ACTIONS -eq "true") { echo "::group::Copy implementations folder to final folder and delete it"; }
# Copy Implementations and Loader to the Module
Copy-Item $temp/* $bin;
# Delete Implementations folder
Remove-Item -Recurse $temp;
if ($env:GITHUB_ACTIONS -eq "true") { echo "::endgroup::"; }
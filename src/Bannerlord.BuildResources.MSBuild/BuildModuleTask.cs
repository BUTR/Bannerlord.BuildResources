using System;
using System.IO;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

public class BuildModuleTask : Task
{
    [Required]
    public required string BasePath { get; set; }

    [Required]
    public required string OutputPath { get; set; }

    [Required]
    public required string ModuleId { get; set; }

    [Required]
    public required string ProjectPath { get; set; }

    [Required]
    public required string Configuration { get; set; }

    public override bool Execute()
    {
        try
        {
            // Normalize paths
            BasePath = Path.GetFullPath(BasePath);
            OutputPath = Path.GetFullPath(OutputPath);
            ProjectPath = Path.GetFullPath(ProjectPath);

            // Validate paths
            if (!Directory.Exists(BasePath))
                throw new DirectoryNotFoundException($"The folder '{BasePath}' does not exist!");

            if (!Directory.Exists(OutputPath))
                Directory.CreateDirectory(OutputPath);

            // Read game versions
            var gameVersionsPath = GetPathIfFileExist(BasePath, "supported-game-versions.txt");
            var gameVersions = File.ReadAllLines(gameVersionsPath);

            // Create temporary directories
            var tempWindows = CreateTemporaryDirectory();
            var tempWindowsStore = CreateTemporaryDirectory();

            // Define output directories
            var binWindows = Path.Combine(OutputPath, $"Modules/{ModuleId}/bin/Win64_Shipping_Client");
            var binWindowsStore = Path.Combine(OutputPath, $"Modules/{ModuleId}/bin/Gaming.Desktop.x64_Shipping_Client");

            // Ensure output directories exist
            Directory.CreateDirectory(binWindows);
            Directory.CreateDirectory(binWindowsStore);

            // Process each game version
            foreach (var gameVersion in gameVersions)
            {
                Log.LogMessage(MessageImportance.High, $"Building for {gameVersion}");

                // Clean and build the project
                RunDotNetCommand($"clean \"{ProjectPath}\" --configuration {Configuration}");
                RunDotNetCommand($"build \"{ProjectPath}\" --configuration {Configuration} -p:OverrideGameVersion={gameVersion} -p:GameFolder=\"{OutputPath}\" -p:ExtendedBuild=false");

                // Copy files to temporary directories
                CopyFiles(Path.Combine(binWindows, $"{ModuleId}*.dll"), tempWindows);
                CopyFiles(Path.Combine(binWindows, $"{ModuleId}*.pdb"), tempWindows);
                CopyFiles(Path.Combine(binWindowsStore, $"{ModuleId}*.dll"), tempWindowsStore);
                CopyFiles(Path.Combine(binWindowsStore, $"{ModuleId}*.pdb"), tempWindowsStore);
            }

            // Copy files from temporary directories to final directories
            CopyFiles(Path.Combine(tempWindows, "*"), binWindows);
            CopyFiles(Path.Combine(tempWindowsStore, "*"), binWindowsStore);

            // Clean up temporary directories
            Directory.Delete(tempWindows, true);
            Directory.Delete(tempWindowsStore, true);

            return true;
        }
        catch (Exception ex)
        {
            Log.LogErrorFromException(ex);
            return false;
        }
    }

    private static string GetPathIfFileExist(string? pathToSearch, string fileName)
    {
        while (true)
        {
            if (string.IsNullOrEmpty(pathToSearch)) throw new FileNotFoundException($"The file '{fileName}' was not found in '{pathToSearch}'!");

            var path = Path.Combine(pathToSearch, fileName);
            if (File.Exists(path)) return path;

            pathToSearch = Directory.GetParent(pathToSearch)?.FullName;
        }
    }

    private static string CreateTemporaryDirectory()
    {
        string tempPath;
        do
        {
            tempPath = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        } while (Directory.Exists(tempPath));

        Directory.CreateDirectory(tempPath);
        return tempPath;
    }

    private static void RunDotNetCommand(string arguments)
    {
        var processStartInfo = new System.Diagnostics.ProcessStartInfo
        {
            FileName = "dotnet",
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        using var process = System.Diagnostics.Process.Start(processStartInfo);
        if (process == null)
            throw new Exception("Failed to start dotnet command");
        process.WaitForExit();
        if (process.ExitCode != 0)
            throw new Exception($"dotnet command failed: {process.StandardError.ReadToEnd()}");
    }

    private static void CopyFiles(string sourcePattern, string destinationDirectory)
    {
        foreach (var file in Directory.GetFiles(Path.GetDirectoryName(sourcePattern)!, Path.GetFileName(sourcePattern)))
        {
            File.Copy(file, Path.Combine(destinationDirectory, Path.GetFileName(file)), true);
        }
    }
}
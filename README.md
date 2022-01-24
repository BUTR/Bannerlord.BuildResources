# Bannerlord.BuildResources

<p align="center">
  <a href="https://www.nuget.org/packages/Bannerlord.BuildResources" alt="NuGet Bannerlord.BuildResources">
    <img src="https://img.shields.io/nuget/v/Bannerlord.BuildResources.svg?label=NuGet%20Bannerlord.BuildResources&colorB=blue" />
  </a>
  <a href="https://www.nuget.org/packages/Bannerlord.BUTRModule.Sdk" alt="NuGet Bannerlord.BUTRModule.Sdk">
    <img src="https://img.shields.io/nuget/v/Bannerlord.BUTRModule.Sdk.svg?label=NuGet%20Bannerlord.BUTRModule.Sdk&colorB=blue" />
  </a>
  <a href="https://www.nuget.org/packages/Bannerlord.DataModule.Sdk" alt="NuGet Bannerlord.DataModule.Sdk">
    <img src="https://img.shields.io/nuget/v/Bannerlord.DataModule.Sdk.svg?label=NuGet%20Bannerlord.DataModule.Sdk&colorB=blue" />
  </a>
  <a href="https://www.nuget.org/packages/Bannerlord.Module.Sdk" alt="NuGet Bannerlord.Module.Sdk">
    <img src="https://img.shields.io/nuget/v/Bannerlord.Module.Sdk.svg?label=NuGet%20Bannerlord.Module.Sdk&colorB=blue" />
  </a>
</p>

BUTR internal MSBuild extensions. Injects data in SubModule.xml. Creates the final module folder for export.  

## Requirements
Requires the `ModuleName` MSBuild property widely used in our BUTR stack. Should be the same as the mod's Module Id.  
Requires the `GameVersion` MSBuild property for assembly injections, see [usage](#usage).  
Requires the `GameFolder` MSBuild property for outputting the final module folder in the game's `/Modules` folder. Should be the base folder path of the game.  

## Installation
Install the [Bannerlord.BuildResources](https://github.com/BUTR/Bannerlord.BuildResources) package.  

## Usage
* Adds `IsStable`, `IsBeta`, `IsDebug` and `IsRelease` based on the current Configuration string. Also adds `STABLE/BETA` constants.  
* If the `GameVersion` MSBuild property is declared, will inject it into the final assembly as `AssemblyMetadata("GameVersion", GameVersion)`.  
* If there are `ItemGroup` enties `InternalsVisibleTo`, will inject it into the final assembly as `InternalsVisibleTo(TEXT)`.  
* If the `GameFolder` MSBuild property is declared, will create the module's folder in the game's `/Modules` folder.  

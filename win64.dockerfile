# escape=`

# Use the Windows Server Core Long Term Servicing Channel image
# NOTE: Updating this to e.g. ltsc2028 requires Windows Server 2028 to run it
FROM mcr.microsoft.com/windows/servercore:ltsc2025 AS builder

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Download the Build Tools bootstrapper.
ADD https://aka.ms/vs/stable/vs_buildtools.exe C:\TEMP\vs_buildtools.exe

# Install Build Tools
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.VC.ATL `
    --add Microsoft.VisualStudio.Component.VC.ATLMFC `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project `
    --add Microsoft.VisualStudio.Component.VC.Llvm.Clang `
    --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Fetch latest python
ADD https://www.python.org/ftp/python/3.14.4/python-3.14.4-amd64.exe C:\TEMP\python_inst.exe

# Install python headlessly to the buildtools folder
RUN C:\TEMP\python_inst.exe /passive TargetDir=C:\BuildTools\python `
    Shortcuts=0 `
    Include_doc=0 `
    Include_launcher=1 `
    InstallLauncherAllUsers=0 `
    Include_tcltk=0 `
    Include_test=0 `
    AssociateFiles=1

# Install git min
ADD https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.3/MinGit-2.53.0.3-64-bit.zip C:\TEMP\MinGit.zip

SHELL ["powershell"]

RUN Expand-Archive c:\TEMP\MinGit.zip -DestinationPath c:\BuildTools\git

# Install git-lfs
ADD https://github.com/git-lfs/git-lfs/releases/download/v3.7.1/git-lfs-windows-amd64-v3.7.1.zip C:\TEMP\git_lfs.zip

RUN Expand-Archive c:\TEMP\git_lfs.zip -DestinationPath c:\BuildTools\git\cmd

# Thanks, git-lfs maintainers, very cool redundant artifact packaging
RUN $item = Get-ChildItem -Path c:\BuildTools\git\cmd -Recurse -Filter "git-lfs.exe";Move-Item -Path $item.Fullname -Destination c:\BuildTools\git\cmd

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Make sure our shell can find everything
RUN setx PATH "%PATH%";c:\BuildTools\python;c:\BuildTools\python\scripts\;c:\BuildTools\git\cmd /M

# This might make git for windows run faster idk
RUN setx HOME c:\BuildTools\ /M

# Thanks, git maintainers, very cool security features
RUN git config --system safe.directory *

# Install any python packages needed
RUN python -m pip install vpk

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

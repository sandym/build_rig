FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

SHELL ["cmd", "/S", "/C"]

ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\\TEMP\\vs_buildtools.exe
ADD https://github.com/git-for-windows/git/releases/download/v2.27.0.windows.1/PortableGit-2.27.0-64-bit.7z.exe C:\\TEMP\\PortableGit-2.27.0-64-bit.7z.exe

RUN C:\\TEMP\\vs_buildtools.exe --quiet --wait --norestart --nocache \
    --installPath C:\BuildTools \
    --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended \
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

ENTRYPOINT ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

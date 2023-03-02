$dependencies = @("nodejs.install", "python3", "git")

ForEach ($dependency in $dependencies) {
    if (!(Get-Command $dependency -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $dependency..."
        Install-Package $dependency -Force
    }
}

npm install -g codeql
codeql database create --language=cpp, csharp, javascript .\codeql-database
codeql analyze .\codeql-database --format=sarif-latest --output=results.sarif

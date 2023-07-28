Write-Host "Begin publish tests" -ForegroundColor Cyan;
Push-Location .\ReactEsProjStaticWebAssets\ReactEsProjStaticWebAssets.client;
npm install;
Pop-Location;
Push-Location .\ReactEsProjStaticWebAssets\ReactEsProjStaticWebAssets.Server;
dotnet publish -c Release;
$publishPath = Resolve-Path ".\bin\Release\net8.0\publish\";
$exePath = Resolve-Path ".\bin\Release\net8.0\publish\ReactEsProjStaticWebAssets.Server.exe";
Push-Location $publishPath;
Get-Process ReactEsProjStaticWebAssets.Server -ErrorAction SilentlyContinue | Stop-Process -ErrorAction Continue;
$server = Start-Process $exePath -NoNewWindow -PassThru -RedirectStandardOutput log.txt;
Start-Sleep -Seconds 3;
Write-Host "Fetch the index page" -ForegroundColor Yellow;
$response = Invoke-WebRequest -Uri "http://localhost:5000" -UseBasicParsing;
if ($response.StatusCode -ne 200) {
  Write-Error "Failed to fetch index page";
}
else {
  Write-Host "`u{2713} Index page fetched successfully" -ForegroundColor Green;
}
if ($response.Headers["Content-Type"] -ne "text/html") {
  Write-Error "Incorrect content type $($response.Headers["Content-Type"])";
}
else {
  Write-Host "`u{2713} Content type is correct" -ForegroundColor Green;
}
if ($response.Headers["Content-Encoding"] -ne "br") {
  Write-Error "Incorrect content encoding $($response.Headers["Content-Encoding"])";
}
else {
  Write-Host "`u{2713} Content encoding is correct" -ForegroundColor Green;
}
Write-Host "Fetch a js file" -ForegroundColor Yellow;
Push-Location wwwroot;
$fileName = Resolve-Path "$publishPath\wwwroot\assets\*.js" -Relative;
Pop-Location;
[Uri]$url = "http://localhost:5000/" + $fileName;
Write-Host $url;
$response = Invoke-WebRequest -Uri $url -UseBasicParsing;
if ($response.StatusCode -ne 200) {
  Write-Error "Failed to fetch $fileName";
}
else {
  Write-Host "`u{2713} $fileName fetched successfully" -ForegroundColor Green;
}
if ($response.Headers["Content-Type"] -ne "text/javascript") {
  Write-Error "Incorrect content type $($response.Headers["Content-Type"])";
}
else {
  Write-Host "`u{2713} Content type is correct" -ForegroundColor Green;
}
if ($response.Headers["Content-Encoding"] -ne "br") {
  Write-Error "Incorrect content encoding $($response.Headers["Content-Encoding"])";
}
else {
  Write-Host "`u{2713} Content encoding is correct" -ForegroundColor Green;
}

Pop-Location;
Pop-Location;

Get-Content $publishPath\log.txt;
Stop-Process $server.Id;
Write-Host "End publish tests" -ForegroundColor Cyan;

Write-Host "Begin dev tests" -ForegroundColor Cyan;

Push-Location .\ReactEsProjStaticWebAssets\ReactEsProjStaticWebAssets.Server;
$server = Start-Process dotnet.exe -ArgumentList "run", "-lp", "https" -NoNewWindow -PassThru -RedirectStandardOutput obj\log.txt;
Pop-Location;

Push-Location .\ReactEsProjStaticWebAssets\ReactEsProjStaticWebAssets.client;
npm install;
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -ErrorAction Continue;
$client = Start-Process npm.cmd -ArgumentList "run dev" -NoNewWindow -PassThru -RedirectStandardOutput obj\log.txt;
Pop-Location;
Start-Sleep -Seconds 3;
Write-Host "Fetch the index page" -ForegroundColor Yellow;
if (-not (Test-Path .\obj)) {
  mkdir obj;  
}

if(Test-Path .\obj\curl.dev.txt) {
  Remove-Item .\obj\curl.dev.txt;
}

$curlProcess = Start-Process curl.exe -ArgumentList "https://localhost:5173" -NoNewWindow -PassThru -RedirectStandardOutput obj\curl.dev.txt;
$curlProcess.WaitForExit();
$curlLog = Resolve-Path .\obj\curl.dev.txt;
if (-not (Test-Path $curlLog)) {
  Write-Error "Curl output not found";
}elseif((Get-Content $curlLog).Length -eq 0)
{
  Write-Error "Curl output is empty";
}
else {
  Write-Host "`u{2713} Index page fetched successfully" -ForegroundColor Green;
}
Write-Host "End dev tests" -ForegroundColor Cyan;
Stop-Process $client.Id;
Stop-Process $server.Id;

Write-Host "Begin library run tests"

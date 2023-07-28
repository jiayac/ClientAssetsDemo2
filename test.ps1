$errors = @();
$successes = @();
Write-Host "Begin publish tests" -ForegroundColor Cyan;
$successes += "Publish app with esproj";
$errors += "Publish app with esproj";
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
  $errors += "Failed to fetch index page";
  Write-Error "Failed to fetch index page";
}
else {
  $successes += "`u{2713} Index page fetched successfully";
  Write-Host "`u{2713} Index page fetched successfully" -ForegroundColor Green;
}
if ($response.Headers["Content-Type"] -ne "text/html") {
  $errors += "Incorrect content type $($response.Headers["Content-Type"])";
  Write-Error "Incorrect content type $($response.Headers["Content-Type"])";
}
else {
  $successes += "Content type is correct";
  Write-Host "`u{2713} Content type is correct" -ForegroundColor Green;
}
if ($response.Headers["Content-Encoding"] -ne "br") {
  $errors += "Incorrect content encoding $($response.Headers["Content-Encoding"])";
  Write-Error "Incorrect content encoding $($response.Headers["Content-Encoding"])";
}
else {
  $successes += "Content encoding is correct";
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
  $errors += "Failed to fetch $fileName";
  Write-Error "Failed to fetch $fileName";
}
else {
  $successes += "$fileName fetched successfully";
  Write-Host "`u{2713} $fileName fetched successfully" -ForegroundColor Green;
}
if ($response.Headers["Content-Type"] -ne "text/javascript") {
  $errors += "Incorrect content type $($response.Headers["Content-Type"])";
  Write-Error "Incorrect content type $($response.Headers["Content-Type"])";
}
else {
  $successes += "Content type is correct";
  Write-Host "`u{2713} Content type is correct" -ForegroundColor Green;
}
if ($response.Headers["Content-Encoding"] -ne "br") {
  $errors += "Incorrect content encoding $($response.Headers["Content-Encoding"])";
  Write-Error "Incorrect content encoding $($response.Headers["Content-Encoding"])";
}
else {
  $successes += "Content encoding is correct";
  Write-Host "`u{2713} Content encoding is correct" -ForegroundColor Green;
}

Pop-Location;
Pop-Location;

Get-Content $publishPath\log.txt;
Stop-Process $server.Id;
Write-Host "End publish tests" -ForegroundColor Cyan;

Write-Host "Begin dev tests" -ForegroundColor Cyan;
$successes += "Dev workflow with esproj";
$errors += "Dev workflow with esproj";

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
  $errors += "Curl output not found";
  Write-Error "Curl output not found";
}elseif((Get-Content $curlLog).Length -eq 0)
{
  $errors += "Curl output is empty";
  Write-Error "Curl output is empty";
}
else {
  $successes += "`u{2713} Index page fetched successfully";
  Write-Host "`u{2713} Index page fetched successfully" -ForegroundColor Green;
}
Write-Host "End dev tests" -ForegroundColor Cyan;
Stop-Process $client.Id;
Stop-Process $server.Id;

Write-Host "Begin library pack tests" -ForegroundColor Cyan;
$successes += "Razor Class Library + esproj pack assets";
$errors += "Razor Class Library + esproj pack assets";

Push-Location .\RazorPagesWithRazorClassLibraryAndEsproj\RazorClassLibAssets\
npm install;
Pop-Location;

Push-Location .\RazorPagesWithRazorClassLibraryAndEsproj\RazorClassLib\
if (Test-Path .\bin\Release\) {
  Remove-Item .\bin\Release\ -Recurse -Force;
}
dotnet pack -c Release
Expand-Archive .\bin\Release\RazorClassLib.1.0.0.nupkg -DestinationPath .\bin\Release\RazorClassLib.1.0.0\
if(Test-Path .\bin\Release\RazorClassLib.1.0.0\staticwebassets\app.min.js) {
  $successes += "`u{2713} app.min.js found in package";
  Write-Host "`u{2713} app.js found in package" -ForegroundColor Green;
}
else {
  $errors += "app.min.js not found in package";
  Write-Error "app.js not found";
}

Pop-Location

Write-Host "End library pack tests" -ForegroundColor Cyan;

Write-Host "Begin library run tests" -ForegroundColor Cyan;

$successes += "Web app + Razor Class Library + esproj dev workflow";
$errors += "Web app + Razor Class Library + esproj dev workflow";

Push-Location .\RazorPagesWithRazorClassLibraryAndEsproj\RazorPagesWithRazorClassLibraryAndEsproj
$razorProcess = Start-Process dotnet.exe -ArgumentList "run" -NoNewWindow -PassThru -RedirectStandardOutput obj\log.txt;
Pop-Location;

[Uri]$url = "http://localhost:5297/_content/RazorClassLib/app.js";
Start-Sleep -Seconds 10;
$response = Invoke-WebRequest -Uri $url -UseBasicParsing -MaximumRetryCount 5 -RetryIntervalSec 3;
if ($response.StatusCode -ne 200) {
  $errors += "Failed to fetch _content/RazorClassLib/app.js";
  Write-Error "Failed to fetch _content/RazorClassLib/app.js";
}
else {
  $successes += "`u{2713} _content/RazorClassLib/app.js fetched successfully";
  Write-Host "`u{2713} _content/RazorClassLib/app.js fetched successfully" -ForegroundColor Green;
}
if ($response.Headers["Content-Type"] -ne "text/javascript") {
  $errors += "Incorrect content type $($response.Headers["Content-Type"])";
  Write-Error "Incorrect content type $($response.Headers["Content-Type"])";
}
else {
  $successes += "Content type is correct";
  Write-Host "`u{2713} Content type is correct" -ForegroundColor Green;
}

Stop-Process $razorProcess;

Write-Host "End library run tests" -ForegroundColor Cyan;

Write-Host "Begin library publish tests" -ForegroundColor Cyan;

$successes += "Web app + Razor Class Library + esproj publish";
$errors += "Web app + Razor Class Library + esproj publish";

Push-Location .\RazorPagesWithRazorClassLibraryAndEsproj\RazorPagesWithRazorClassLibraryAndEsproj
dotnet publish -c Release
Push-Location .\bin\Release\net8.0\publish
if(-not (Test-Path wwwroot\_content\RazorClassLib\app.min.js)) {
  $errors += "app.min.js not found in publish output";
  Write-Error "app.min.js not found in publish output";
}
else {
  $successes += "`u{2713} app.min.js found in publish output";
  Write-Host "`u{2713} app.min.js found in publish output" -ForegroundColor Green;
}
$publishProcess = Start-Process .\RazorPagesWithRazorClassLibraryAndEsproj.exe -NoNewWindow -PassThru -RedirectStandardOutput log.txt;
Pop-Location;
Pop-Location;

[Uri]$url = "http://localhost:5000/_content/RazorClassLib/app.min.js";
Start-Sleep -Seconds 5;
$response = Invoke-WebRequest -Uri $url -UseBasicParsing -MaximumRetryCount 5 -RetryIntervalSec 3;
if ($response.StatusCode -ne 200) {
  Write-Error "Failed to fetch _content/RazorClassLib/app.min.js";
}
else {
  $successes += "`u{2713} _content/RazorClassLib/app.min.js fetched successfully";
  Write-Host "`u{2713} _content/RazorClassLib/app.min.js fetched successfully" -ForegroundColor Green;
}
if ($response.Headers["Content-Type"] -ne "text/javascript") {
  $errors += "Incorrect content type $($response.Headers["Content-Type"])";
  Write-Error "Incorrect content type $($response.Headers["Content-Type"])";
}
else {
  $successes += "`u{2713} Content type is correct";
  Write-Host "`u{2713} Content type is correct" -ForegroundColor Green;
}

Stop-Process $publishProcess;

Write-Host "End library publish tests" -ForegroundColor Cyan;

Write-Host "Success summary:" -ForegroundColor Green;
foreach($success in $successes) {
  Write-Host $success -ForegroundColor Green;
}

Write-Host "Error summary:" -ForegroundColor Red;
foreach($error in $errors) {
  Write-Host $error -ForegroundColor Red;
}

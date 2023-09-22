# Scenarios for esproj + ASP.NET Core

This repo demonstrates different integration scenarios with esproj and ASP.NET Core.
* React app + asp.net core backend
  * Run both in development.
  * Publish the backend and include the frontend files.
    * Demonstrates the integration with static web assets by compressing the resulting files and   making sure the compressed content is served.
* Razor class library + companion esproj
  * Pack assets from the esproj into the nuget package.
  * Use the assets in a web app.
  * Publish the web app and include the assets.

The script test.ps1 runs all the scenarios and verifies that they work as expected, producing a summary like the one below. It might need to be adapted to your environment, but it should be easy to do so.

The `SDK.targets` file contains the changes that were needed to address bugs and integrate properly with static web assets.

```console
Success summary:
Publish app with esproj
✓ Index page fetched successfully
Content type is correct
Content encoding is correct
.\assets\index-082c4086.js fetched successfully
Content type is correct
Content encoding is correct
Dev workflow with esproj
✓ Index page fetched successfully
Razor Class Library + esproj pack assets
✓ app.min.js found in package
Web app + Razor Class Library + esproj dev workflow
✓ _content/RazorClassLib/app.js fetched successfully
Content type is correct
Web app + Razor Class Library + esproj publish
✓ app.min.js found in publish output
✓ _content/RazorClassLib/app.min.js fetched successfully
✓ Content type is correct
Error summary:
Publish app with esproj
Dev workflow with esproj
Razor Class Library + esproj pack assets
Web app + Razor Class Library + esproj dev workflow
Web app + Razor Class Library + esproj publish
```
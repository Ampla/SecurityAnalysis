# Ampla Security Analysis #

Provides a HTML report detailing the roles, security scopes and role assignments configured in an Ampla project.

## Getting Started ##

Follow the instructions below to generate your HTML report:

1. Export a copy of your project naming the file `AmplaProject.xml` and place it in the same folder as `AnalyseSecurity.cmd`.

2. Take a copy of `AuthStore.xml` and place it alongside `AmplaProject.xml`. This file will be located in the `%ProgramData%\Citect\Ampla\Projects\[YourProjectName]` folder.

3. Run `AnalyseSecurity.cmd` and wait for it to finish.

4. View the output by opening `Project.Security.html` located in the `Output` folder.

5. Run `Clean.cmd` to remove the existing output before running another security analysis.

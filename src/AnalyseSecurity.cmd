rem @echo off
set project=AmplaProject.xml
set authstore=AuthStore.xml

xcopy External\css Output\css /E /Y /I 
xcopy External\*.exe Working\*.exe /Y /I 

set nxslt=Working\nxslt.exe

%nxslt% %project% StyleSheets\Project.Normalize.xslt -o Working\project.xml 

%nxslt% Working\project.xml StyleSheets\Project.Security.xslt -o Working\project.security.xml
%nxslt% %authstore% StyleSheets\Authstore.Normalize.xslt -o Working\authstore.xml projectSecurity=..\Working\project.security.xml

%nxslt% Working\authstore.xml StyleSheets\Document.Security.xslt -o Output\Project.Security.html
%nxslt% Working\authstore.xml StyleSheets\Document.Security.Text.xslt -o Output\Project.Security.Roles.txt mode=roles
%nxslt% Working\authstore.xml StyleSheets\Document.Security.Text.xslt -o Output\Project.Security.Assignments.txt mode=assignments

rem pause

git archive -o .git_tmp.zip %1
rd "%TEMP%\gitdiff" /q /s
mkdir "%TEMP%\gitdiff"
c:\meld\unzip .git_tmp.zip -d "%TEMP%\gitdiff"
start c:\meld\meld .\ "%TEMP%\gitdiff"
del .git_tmp.zip


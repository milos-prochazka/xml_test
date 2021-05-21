if .%1.==.. goto syntax
dart-prep --enable-all .\
git add --all
git commit --all -m %1
git push --all --force
pause
rem git gc
rem git gc --aggressive
rem git prune
goto end
:syntax
@echo Syntax: git-push "message"
:end

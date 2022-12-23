# Toolkit

## Common errors

### Windows CLFR/Modes

To show this one, you are in a new banch, you want to `git merge`/`git rebase`, but you can't, you check the status with `git status` and you notice some files. Still there after a `git checkout <file>`, you do a `git diff <file>`, but the only difference are LF->CLFR, or old mode xxx new mode xxx. 

These errors are linked with a Linux/Macos repository, file modes on windows don't make any sense and the CLFR end line is the default one, to disable this error, run these:

```powershell
git config --global core.autocrlf false
git config core.autocrlf false

git config --global core.filemode false
git config core.filemode false
```

- `core.autocrlf false` will disable the switch from crlf
- `core.filemode false` will disable add of a new mode on the files

*It might be useful to add these configs again.*

To apply these options, you simply need to commit the changes you want to keep and run a

```powershell
git reset --hard
```

to reset your branch to the latest changes

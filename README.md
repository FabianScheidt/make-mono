# Make Mono

Make Mono is a bash script to combine multiple git repositories into a monorepo while preserving all branches and tags.

## Usage

Configure the repositories you want to merge in `repositories.txt`. Each repository should have a name and a url separated by a whitespace. The name will be used as the subfolder in the monorepo as well as a prefix for its branches and tags.

Example:
```
repo-1 ../example-repo-1
repo-2 https://github.com/example/example-repo.git
```

You can configure which branches will be merged by modifying `merge-branches.txt`. Branches with the same name can be merged by specifying just the name of the branch. Branches with different names can be merged by specifying the name of the target branch and the additonal branches prefixed with the previously configured prefix.

Example:
```
dev
master
different-branches repo-1/master repo-2/test-branch
```

Be sure to end both configuration files with a blank line to avoid unintended beahvior.

Run `make-mono.sh` to start the conversion. The monorepo will be located in the `res` folder.
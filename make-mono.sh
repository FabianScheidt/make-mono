#!/bin/bash

# Copy list of merge branches
cp merge-branches.txt merged-branches.txt

# Create a repository and perform an initial commit
mkdir res
cd res
git init
git checkout -b 'make-mono'
echo "Monorepo" > README.md
git add README.md
git commit -m 'Inital commit of the monorepo'

# Prepare each repository independently
while IFS=$' ' read -r name url
do
	echo
	echo
	echo "Fetching $url as $name..."
	echo
	git remote add $name "$url"
	git fetch $name --no-tags

	echo "Fetching and prefixing tags..."
	git ls-remote --tags $name | while read -r commit ref
	do
		git tag "$name/${ref##*/}" $commit
	done

	echo "Rewriting files to subfolders..."
	tab="$(printf '\t')"
	index_filter_cmd="git ls-files -s | sed \"s/${tab}/${tab}$name\//\" | GIT_INDEX_FILE=\${GIT_INDEX_FILE}.new git update-index --index-info && mv \${GIT_INDEX_FILE}.new \${GIT_INDEX_FILE}"
	git filter-branch -f --index-filter "$index_filter_cmd" --tag-name-filter "cat" -- --remotes="$name"

	echo "Tracking and prefixing branches..."
	for branch in $(git branch --remote --list "$name/*"); do
    	git branch --track "$name/${branch##*/}" "$branch"
		cat ../merged-branches.txt | sed -e "s/^\(${branch##*/}.*\)/\1 $name\/${branch##*/}/" > ../.merged-branches.txt
		mv ../.merged-branches.txt ../merged-branches.txt
	done

	echo "Removing remote..."
	git remote rm $name

	master_branches="$master_branches $name/master"
done < ../repositories.txt

# Merge branches
while IFS= read -r line
do
	new_branch=$(echo $line | cut -f 1 -d " ")
	existing_branches=$(echo $line | cut -f 2- -d " ")
	existing_branch_names=${existing_branches// /, }
	echo
	echo
	echo "Merging branches $existing_branch_names into $new_branch"
	echo
	git checkout -f make-mono
	git checkout -f -b $new_branch
	git merge $line --no-commit --no-ff --allow-unrelated-histories

	# Fix merge commit: https://stackoverflow.com/questions/10874149/git-octopus-merge-with-unrelated-repositories
	tree_head=HEAD
	for merging in $line; do
	    git read-tree "$tree_head" "$merging"
	    tree_head=$(git write-tree)
	done
	git commit --no-edit
	git reset --hard
done < ../merged-branches.txt

# We probably want to check out master
git checkout -f master

echo
echo
echo "Done!"
echo

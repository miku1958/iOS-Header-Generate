shellFolder=`pwd`

replaceCore() {
	for privateFrameworkPath in $1/PrivateFrameworks/*Core.framework; do
		frameworkName=$(basename $privateFrameworkPath)
		frameworkPath=$1/Frameworks/${frameworkName/Core.framework/.framework}
		if [[ ! -d "$frameworkPath" ]]; then
			continue
		fi
		# if [ ! "$frameworkName" = "UIKitCore.framework" ]; then
		# 	continue
		# fi
		for file in $privateFrameworkPath/*; do
			echo "moving $file"
			rsync -av "$file" "$frameworkPath/"
		done
		rm -rf "$privateFrameworkPath"
	done
}

renameFrame() {
	if [[ ! -d "$1" ]]; then
		return
	fi
	# 递归把文件夹下带有 .framework 的改成 ._framework
	for path in $1/*; do
		if [[ $path =~ ".framework" ]];then
			mv "$path" "${path/.framework/._framework}"
			path=${path/.framework/._framework}
		fi
		renameFrame $path
	done
}
cd "iOS-Header"
if [ ! -d ".git" ]; then
	git init
	git add -A
	git commit -m "init project"
fi
lastTag=$(git describe --tags `git rev-list --tags --max-count=1`)
if [ -z "$lastTag" ]; then
	lastTag=0
fi
echo "lastTag: $lastTag"
for path in $shellFolder/Framework-Header/*; do
	version=$(basename $path)

	if [ `echo "$version < $lastTag"|bc` -eq 1 ] ; then
		continue
	fi

	targetPath="$shellFolder/iOS-Header/Framework-Headers"

	echo "version: $version"
	echo "path: $path"
	echo "targetPath: $targetPath"

	rm -rf $targetPath
	cp -r "$path" "$targetPath"

	replaceCore $targetPath
	renameFrame $targetPath

	git add -A
	git commit -m "$version"
	git tag "$version"
done

git branch -d "Foundation"
git branch -d "UIKit"
git branch -d "SwiftUI"
git branch -d "Combine"

git subtree split -P "Framework-Headers/Frameworks/Foundation._framework" -b "Foundation"
git subtree split -P "Framework-Headers/Frameworks/UIKit._framework" -b "UIKit"
git subtree split -P "Framework-Headers/Frameworks/SwiftUI._framework" -b "SwiftUI"
git subtree split -P "Framework-Headers/Frameworks/Combine._framework" -b "Combine"

git push master refs/heads/master --tags --set-upstream --verbose --progress
git push master refs/heads/Foundation --tags --set-upstream --verbose --progress
git push master refs/heads/UIKit --tags --set-upstream --verbose --progress
git push master refs/heads/SwiftUI --tags --set-upstream --verbose --progress
git push master refs/heads/Combine --tags --set-upstream --verbose --progress

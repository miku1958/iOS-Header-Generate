#!/bin/zsh

runtimesPath=/Library/Developer/CoreSimulator/Profiles/Runtimes
shellFolder=`pwd`
tempFolder="$shellFolder/iOS_temp/"

visitFrameworkOrApp() {
	FRAMEWORK="$1"
	ARCH="$2"
	BASEPATH="$3"

	if [[ -f "$FRAMEWORK" ]]; then
		FRAMEWORK_BASENAME="${${$(basename "$FRAMEWORK")%.*}##lib}"
	else
		FRAMEWORK_BASENAME="$(basename "$FRAMEWORK")"
	fi

	FRAMEWORK_EXCUTEABLE="$(basename "$FRAMEWORK" ".framework")"
	FRAMEWORK_EXCUTEABLE="$FRAMEWORK/$FRAMEWORK_EXCUTEABLE"
	# if [ $FRAMEWORK_BASENAME != "SwiftUI.framework" ]; then 
	# 	return
	# fi
	echo "FRAMEWORK: $FRAMEWORK"
	echo "FRAMEWORK_BASENAME: $FRAMEWORK_BASENAME"
	echo "ARCH: $ARCH"
	echo "BASEPATH: $BASEPATH"
	echo "FRAMEWORK_EXCUTEABLE: $FRAMEWORK_EXCUTEABLE"

	echo -e "\033[1;34mProcessing $FRAMEWORK\033[0m"

	mkdir -p "$BASEPATH"

	echo "using class dump"
	$shellFolder/class-dump --arch "$ARCH" -H  -S -I -o "$BASEPATH/$FRAMEWORK_BASENAME/Objc" "$FRAMEWORK"

	if [[ -f "$FRAMEWORK_EXCUTEABLE" ]]; then

		echo "using dsdump"
		swiftDump=`$shellFolder/dsdump -a $ARCH --swift -vvvvv -U  "$FRAMEWORK_EXCUTEABLE"`
		if [ -n "$swiftDump" ]; then 
			if [[ $(echo $swiftDump | grep "Couldn't resolve") == "" ]]; then
				savePath="$BASEPATH/$FRAMEWORK_BASENAME/Swift/"
				mkdir -p "$savePath" 
				echo "dsdump something to $savePath/dsdump.swift"
				echo $swiftDump > "$savePath/dsdump.swift"
			fi
		fi
	fi

	if [ ! -d "$FRAMEWORK/Frameworks" ]; then
		return
	fi
	if [ -z "$(ls "${FRAMEWORK}/Frameworks")" ]; then
		return
	fi

	for INNER_FRAMEWORK in "${FRAMEWORK}"/Frameworks/* ; do
		visitFrameworkOrApp "$INNER_FRAMEWORK" "$ARCH" "$BASEPATH/$FRAMEWORK_BASENAME"/Frameworks
	done
}

iOS() {
	# iOS
	rm -rf "$tempFolder"
	rm -rf "$shellFolder/$IOS_VER"

	for FRAMEWORK in "$1"/Contents/Resources/RuntimeRoot/System/Library/Frameworks/*.framework ; do
		visitFrameworkOrApp "$FRAMEWORK" x86_64 $tempFolder/Frameworks/
	done

	if [ ! -d "$tempFolder/Frameworks/UIKit.framework" ]; then
		mkdir -p "$tempFolder/Frameworks/UIKit.framework"
	fi

	for FRAMEWORK in "$1"/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/*.framework ; do
		visitFrameworkOrApp "$FRAMEWORK" x86_64 $tempFolder/PrivateFrameworks/
	done

	for FRAMEWORK in "$1"/Contents/Resources/RuntimeRoot/usr/lib/*.dylib ; do
		visitFrameworkOrApp "$FRAMEWORK" x86_64 $tempFolder/usr/lib/
	done

	for FRAMEWORK in "$1"/Contents/Resources/RuntimeRoot/usr/lib/system/*.dylib ; do
		visitFrameworkOrApp "$FRAMEWORK" x86_64 $tempFolder/usr/lib/
	done

	for FRAMEWORK in "$1"/Contents/Resources/RuntimeRoot/System/Library/AccessibilityBundles/*.axbundle ; do
		visitFrameworkOrApp "$FRAMEWORK" x86_64 $tempFolder/AccessibilityBundles
	done
}

checkFile() {
	file=$1
	echo "file: $file"

	IOS_VER=${file/iOS /}
	IOS_VER=${IOS_VER/.simruntime/}
	IOS_VER=${IOS_VER##*/}
	if [ -n "$2" ]; then
		IOS_VER=$2
	fi

	echo "IOS_VER: $IOS_VER"

	# if (($IOS_VER < 14.0))
	# then
	# 	continue
	# fi

	iOS $file

	mv "$tempFolder" "$shellFolder/Framework-Header/$IOS_VER"

	# zipFile=/Volumes/Game/模拟器/$(basename $file).zip
	# if [ ! -f $zipFile ]; then
	# 	cd $runtimesPath
	# 	echo "ziping"
	# 	sudo zip -q -r -m "$zipFile" "$(basename $file)"
	# fi

	# git add -A
	# git commit -m "$IOS_VER"
}



if [ -n "$1" ]; then
	echo "has input $1"
	checkFile $1 $2
else
	for file in $runtimesPath/*; do
		checkFile $file
	done
fi


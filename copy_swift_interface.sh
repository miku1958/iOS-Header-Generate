checkFramework() {
	frameworksPath=$1
	saveBasePath=$2

	for framework in $frameworksPath/*; do
		frameworkName=$(basename $framework)
		for swiftmodule in $framework/Modules/*; do
			if [[ ! $swiftmodule =~ ".swiftmodule" ]];then
				continue
			fi
			interface=`ls $swiftmodule/*.swiftinterface | sed -n 1p`
			savePath=$saveBasePath/$frameworkName/Swift/
			if [[ ! -d "$savePath" ]]; then
				mkdir -p "$savePath"
			fi
			# rm -rf "$savePath/swift.swiftinterface"
			echo "cp \"$interface\" \"$savePath\""
			cp "$interface" "$savePath/sdk.swiftinterface"
		done
	done
}
checkLib() {
	libPath=$1
	saveBasePath=$2
	if [[ ! -d "$libPath" ]]; then
		return
	fi
	for lib in $libPath/*; do
		libName=$(basename $lib ".swiftmodule")
		frameworkPath=$saveBasePath/${libName}.framework
		echo "lib: $lib"
		echo "libName: $libName"
		echo "frameworkPath: $frameworkPath"
		if [[ ! -d "$frameworkPath" ]]; then
			continue
		fi
		savePath=$frameworkPath/Swift/
		echo "savePath: $savePath"
		if [[ ! -d "$savePath" ]]; then
			mkdir -p "$savePath"
		fi

		interface=`ls $lib/*.swiftinterface | sed -n 1p`

		# rm -rf "$savePath/swift.swiftinterface"
		echo "cp \"$interface\" \"$savePath\""
		cp "$interface" "$savePath/sdk.swiftinterface"
	done
}

for version in Framework-Header/*; do
	sdk="SDK/iPhoneOS$(basename $version).sdk"
	if [[ ! -d "$sdk" ]]; then
		continue
	fi
	checkFramework "$sdk/System/Library/Frameworks" "$version/Frameworks"

	checkLib "$sdk/usr/lib/swift/" "$version/Frameworks"
done
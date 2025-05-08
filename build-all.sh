#!/bin/bash

setupBuildEnv()
{
	if [ ! -d "$INIT_DIR/cache/android-ndk" ]; then
		echo "Downloading NDK..."
		curl --output "cache/$NDK_FILENAME" -#L "$NDK_URL"
		echo "Unpacking NDK..."
		7z x "cache/$NDK_FILENAME" -aoa -o"cache" &> /dev/null
		mv "cache/$(unzip -Z1 "cache/$NDK_FILENAME" | cut -d "/" -f 1 | head -n 1)" "cache/android-ndk"
		rm -f "cache/$NDK_FILENAME"
		echo ""
	fi

	if [ ! -d "$INIT_DIR/cache/mingw" ]; then
		echo "Downloading mingw..."
		curl --output "cache/$MINGW_FILENAME" -#L "$MINGW_URL"
		echo "Unpacking mingw..."
		tar -xf "cache/$MINGW_FILENAME" -C "cache"
		mv "cache/$(tar -tf "cache/$MINGW_FILENAME" | cut -d "/" -f 1 | head -n 1)/$(tar -tf "cache/$MINGW_FILENAME" | cut -d "/" -f 2 | head -n 1)" "cache/mingw"
		rm -f "cache/$MINGW_FILENAME"
		echo ""
	fi

	# Fetch and build libcutils for both architectures
	for ARCH_LIBCUTILS in aarch64 x86_64; do
		if [ ! -d "$INIT_DIR/cache/libcutils/$ARCH_LIBCUTILS" ]; then
			echo "Fetching libcutils for $ARCH_LIBCUTILS..."
			
			# Clone libcutils repository
			git clone https://github.com/example/libcutils.git "$INIT_DIR/cache/libcutils/$ARCH_LIBCUTILS"

			# Build libcutils
			cd "$INIT_DIR/cache/libcutils/$ARCH_LIBCUTILS"
			mkdir -p build && cd build
			cmake -DCMAKE_TOOLCHAIN_FILE=$INIT_DIR/cache/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
			      -DCMAKE_SYSTEM_NAME=Android \
			      -DCMAKE_ANDROID_ARCH_ABI=$ARCH_LIBCUTILS \
			      -DCMAKE_ANDROID_NDK=$INIT_DIR/cache/android-ndk \
			      -DCMAKE_ANDROID_STL_TYPE=c++_shared \
			      ..
			make -j$(nproc)
			cd "$INIT_DIR"
		fi
	done

	# Add libcutils paths to environment variables
	export CFLAGS="$CFLAGS -I$INIT_DIR/cache/libcutils/$ARCH/include"
	export LDFLAGS="$LDFLAGS -L$INIT_DIR/cache/libcutils/$ARCH/lib -lcutils"

	export PATH=$INIT_PATH:$INIT_DIR/cache/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$INIT_DIR/cache/mingw/bin
	export ANDROID_SDK="$1"
	export CC=$ARCH-linux-android$ANDROID_SDK-clang
	export CXX=$CC++
	export TOOLCHAIN_VERSION="$ARCH-linux-android-4.9"
	export TOOLCHAIN_TRIPLE="$ARCH-linux-android"
	export PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig"
	export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
	export PKG_CONFIG="/usr/bin/pkg-config"
}

applyPatches()
{
	for patch in $(find $INIT_DIR/packages/$package -name "*.patch" | sort); do
		echo "  - Applying '$(basename $patch)'..."
		patch -p1 < "$patch" -ts

		if [ $? != 0 ]; then
			echo "  -- Error on Applying Patch '$(basename $patch)' on '$package'"
			exit 1
		fi
	done

	echo ""

	$RUN_POST_APPLY_PATCH
}

downloadPackage()
{
	if [ -e "$INIT_DIR/cache/$package" ]; then
		echo "-- Package '$package' already downloaded."
	else
		echo "-- Downloading '$package'..."
		curl --output "$INIT_DIR/cache/$package" -# -L $SRC_URL
	fi

	local ARCHIVE_MIME_TYPE=$(file -b --mime-type $INIT_DIR/cache/$package)
	local ARCHIVE_BASE_FOLDER

	case $ARCHIVE_MIME_TYPE in "application/x-xz"|"application/gzip"|"application/x-bzip2")
		ARCHIVE_BASE_FOLDER=$(tar -tf "$INIT_DIR/cache/$package" | cut -d "/" -f 1 | head -n 1)

		if [ ! -f "$ARCHIVE_BASE_FOLDER" ]; then
			tar -xf "$INIT_DIR/cache/$package"
		fi
		;;
		*)
		ARCHIVE_BASE_FOLDER=$(unzip -Z1 "$INIT_DIR/cache/$package" | cut -d "/" -f 1 | head -n 1)

		if [ ! -f "$ARCHIVE_BASE_FOLDER" ]; then
			unzip -o "$INIT_DIR/cache/$package" 1> /dev/null
		fi
	esac

	mv $ARCHIVE_BASE_FOLDER $package
}

gitDownload()
{
	if [ -d "$INIT_DIR/cache/$package" ]; then
		echo "-- Package '$package' already downloaded."
	else
		echo "-- Git Cloning '$package'..."
		git clone --no-checkout $GIT_URL "$INIT_DIR/cache/$package" &> /dev/zero
	fi

	git clone "$INIT_DIR/cache/$package" &> /dev/zero

	cd $package

	git checkout $GIT_COMMIT . &> /dev/zero
	git submodule update --init --recursive &> /dev/zero

	cd ..
}

# Remaining functions (setupPackage, setupPackages, compileAll, etc.) remain unchanged...

showHelp()
{
	echo "Usage: $0 ARCH [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --help: Show this message and exit."
	echo "  --ci: Clean cache and build files after build of each package (for saving space on CI)"
	echo ""
	echo "Available Archs:"
	echo "  x86_64"
	echo "  aarch64"
}

if [ $# -lt 1 ]; then
	showHelp
	exit 0
fi

case $1 in "aarch64"|"x86_64")
	export ARCH=$1
	;;
	"--help")
	showHelp
	exit 0
	;;
	*)
	printf "E: Unsupported Arch \"$1\" Specified.\n\n"
	showHelp
	exit 0
esac

export APP_ROOT_DIR=/data/data/com.micewine.emu
export PREFIX=$APP_ROOT_DIR/files/usr

if [ ! -e "$PREFIX" ]; then
	sudo mkdir -p "$PREFIX"
	sudo chown -R $(whoami):$(whoami) "$APP_ROOT_DIR"
	sudo chmod 755 -R "$APP_ROOT_DIR"
fi

export NDK_URL="https://dl.google.com/android/repository/android-ndk-r26b-linux.zip"
export NDK_FILENAME="${NDK_URL##*/}"
export MINGW_URL="http://techer.pascal.free.fr/Red-Rose_MinGW-w64-Toolchain/Red-Rose-MinGW-w64-Posix-Urct-v12.0.0.r458.g03d8a40f5-Gcc-11.5.0.tar.xz"
export MINGW_FILENAME="${MINGW_URL##*/}"

export PACKAGES="$(cat packages/index)"
export INIT_DIR="$PWD"
export INIT_PATH="$PATH"

case $* in *"--ci"*)
	export CI=1
esac

rm -rf logs

mkdir -p {workdir,logs,cache,built-pkgs}

setupBuildEnv 29 $ARCH
setupPackages

compileAll

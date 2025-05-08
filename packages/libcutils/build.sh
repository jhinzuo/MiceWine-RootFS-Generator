PKG_VER=1.0.0
PKG_CATEGORY=Utils
PKG_PRETTY_NAME=libcutils
SRC_URL=https://android.googlesource.com/platform/system/core/+archive/refs/tags/android-15.0.0_r36/libcutils.tar.gz
BUILD_IN_SRC=1

# Architecture-specific options
if [ "$ARCH" == "aarch64" ]; then
    CFLAGS="-fPIC -std=c99 -D_GNU_SOURCE -I. -DANDROID -DHAVE_PTHREADS"
    LDFLAGS="-L$PREFIX/lib"
elif [ "$ARCH" == "x86_64" ]; then
    CFLAGS="-fPIC -std=c99 -D_GNU_SOURCE -I. -DANDROID -DHAVE_PTHREADS"
    LDFLAGS="-L$PREFIX/lib"
fi

# Download and extract libcutils
echo "Downloading libcutils..."
curl -o libcutils.tar.gz "$SRC_URL" || { echo "Failed to download libcutils"; exit 1; }

echo "Extracting libcutils..."
mkdir -p libcutils
tar -xzf libcutils.tar.gz -C libcutils || { echo "Failed to extract libcutils"; exit 1; }

# Verify libcutils directory exists
if [ ! -d "libcutils" ]; then
    echo "libcutils directory not found!"
    exit 1
fi

# Change into the libcutils directory
cd libcutils

# Verify header files exist
if ! ls *.h >/dev/null 2>&1; then
    echo "Header files are missing in libcutils"
    exit 1
fi

# Create a custom Makefile since libcutils doesn't come with one
cat > Makefile << EOF
CC ?= $CC
AR ?= ar
RANLIB ?= ranlib
CFLAGS += $CFLAGS
LDFLAGS += $LDFLAGS

# Get all C source files
SRCS = \$(shell ls *.c 2>/dev/null)
OBJS = \$(SRCS:.c=.o)

all: libcutils.a libcutils.so

%.o: %.c
	\$(CC) \$(CFLAGS) -c \$< -o \$@

libcutils.a: \$(OBJS)
	\$(AR) rcs \$@ \$(OBJS)
	\$(RANLIB) \$@

libcutils.so: \$(OBJS)
	\$(CC) -shared \$(LDFLAGS) -o \$@ \$(OBJS)

install:
	mkdir -p \$(DESTDIR)$PREFIX/lib \$(DESTDIR)$PREFIX/include/cutils
	cp *.h \$(DESTDIR)$PREFIX/include/cutils/
	cp libcutils.a libcutils.so \$(DESTDIR)$PREFIX/lib/

clean:
	rm -f *.o libcutils.a libcutils.so
EOF

# Create a pkg-config file for libcutils
mkdir -p \$(DESTDIR)$PREFIX/lib/pkgconfig
cat > \$(DESTDIR)$PREFIX/lib/pkgconfig/libcutils.pc << EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: libcutils
Description: Android libcutils utility library
Version: $PKG_VER
Libs: -L\${libdir} -lcutils
Cflags: -I\${includedir}/cutils
EOF

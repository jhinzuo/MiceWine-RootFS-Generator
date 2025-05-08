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

# Create a custom Makefile since libcutils doesn't come with one
RUN_POST_APPLY_PATCH='
# Exclude architecture-specific source files
if [ "$ARCH" == "x86_64" ]; then
    EXCLUSIONS=".*arm.*\\.c"
elif [ "$ARCH" == "aarch64" ]; then
    EXCLUSIONS=".*x86.*\\.c"
else
    EXCLUSIONS=""
fi

cat > Makefile << EOF
CC ?= $CC
AR ?= ar
RANLIB ?= ranlib
CFLAGS += $CFLAGS
LDFLAGS += $LDFLAGS

# Get all C source files excluding architecture-specific ones
SRCS = \$(shell ls *.c 2>/dev/null | grep -Ev "$EXCLUSIONS")
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
'
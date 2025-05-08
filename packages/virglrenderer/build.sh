SRC_URL=https://github.com/jhinzuo/virglrenderer-venus/archive/refs/tags/1.0.1.tar.gz
MESON_ARGS="--cross-file=../../../meson-cross-file-$ARCHITECTURE --libdir lib -Dplatforms=egl,glx -Dvenus=true"
CFLAGS="-I$PREFIX/include"

SRC_URL=https://github.com/jhinzuo/virglrenderer-venus/archive/refs/tags/1.0.1.tar.gz
MESON_ARGS="-Dplatforms=egl,glx -Dvenus=true"
CFLAGS="-Wno-gnu-offsetof-extensions -I$PREFIX/include"

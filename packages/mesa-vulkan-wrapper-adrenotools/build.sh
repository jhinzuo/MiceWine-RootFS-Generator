PKG_VER=25.0.0-1-[gss]-adrenotools
PKG_CATEGORY="AdrenoTools"
PKG_PRETTY_NAME="Mesa Android Wrapper (AdrenoTools)"
VK_DRIVER_LIB="libvulkan_wrapper.so"

BLACKLIST_ARCH=x86_64

GIT_URL=https://github.com/leegao/bionic-vulkan-wrapper
GIT_COMMIT=34576e9995ec6a27038d960265fb4447ee810445
LDFLAGS="-L$PREFIX/lib -landroid-shmem -ladrenotools -llinkernsbypass"
MESON_ARGS="-Dgallium-drivers= -Dvulkan-drivers=wrapper -Dglvnd=disabled -Dplatforms=x11 -Dxmlconfig=disabled -Dllvm=disabled -Dopengl=false -Degl=disabled -Dzstd=enabled"

PKG_VER=24.2.5-0.0.4r6
PKG_CATEGORY="VulkanDriver"
PKG_PRETTY_NAME="Mesa Android Wrapper By LeeGao (Rev 9)"
PKG_OPTIONAL=1
VK_DRIVER_LIB="libvulkan_wrapper.so"

GIT_URL=https://github.com/tokokudo/bionic-vulkan-wrapper
GIT_COMMIT=a06cdae83f1aa17844c4c4c0728327f84566b7be
LDFLAGS="-L$PREFIX/lib -landroid-shmem -ladrenotools -llinkernsbypass"
MESON_ARGS="-Dgallium-drivers= -Dvulkan-drivers=wrapper -Dglvnd=disabled -Dplatforms=x11 -Dxmlconfig=enabled -Dllvm=disabled -Dopengl=false -Degl=disabled -Dzstd=enabled"

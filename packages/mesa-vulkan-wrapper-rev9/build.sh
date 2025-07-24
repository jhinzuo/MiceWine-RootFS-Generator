PKG_VER=24.2.5
PKG_CATEGORY="VulkanDriver"
PKG_PRETTY_NAME="Mesa Android Wrapper By LeeGao (Rev 9)"
PKG_OPTIONAL=1
VK_DRIVER_LIB="libvulkan_wrapper.so"

GIT_URL=https://github.com/leegao/bionic-vulkan-wrapper
GIT_COMMIT=664e59a3539e62874884d407a3eb6c4d356e99c4
LDFLAGS="-L$PREFIX/lib -landroid-shmem"
MESON_ARGS="-Dgallium-drivers= -Dvulkan-drivers=wrapper -Dglvnd=disabled -Dplatforms=x11 -Dxmlconfig=enabled -Dllvm=disabled -Dopengl=false -Degl=disabled -Dzstd=enabled"

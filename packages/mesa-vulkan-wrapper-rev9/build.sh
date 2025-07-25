PKG_VER=24.2.5-0.0.4r6
PKG_CATEGORY="VulkanDriver"
PKG_PRETTY_NAME="Mesa Android Wrapper By LeeGao (Rev 9)"
PKG_OPTIONAL=1
VK_DRIVER_LIB="libvulkan_wrapper.so"

GIT_URL=https://github.com/tokokudo/bionic-vulkan-wrapper
GIT_COMMIT=f38afb3aca7dffd3011eb71ac3f1eb1a4fd5a7c6
LDFLAGS="-L$PREFIX/lib -landroid-shmem"
MESON_ARGS="-Dgallium-drivers= -Dvulkan-drivers=wrapper -Dglvnd=disabled -Dplatforms=x11 -Dxmlconfig=enabled -Dllvm=disabled -Dopengl=false -Degl=disabled -Dzstd=enabled"

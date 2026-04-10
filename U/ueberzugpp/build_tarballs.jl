using BinaryBuilder

name = "ueberzugpp"
version = v"2.9.8"

sources = [
    GitSource("https://github.com/jstkdng/ueberzugpp.git",
              "c1c76e34bac97403ed3f2f403fcf96b5cfd0b914"),
    GitSource("https://github.com/CLIUtils/CLI11.git",
              "6c7b07a878ad834957b98d0f9ce1dbe0cb204fc9"),
    GitSource("https://github.com/ericniebler/range-v3.git",
              "a81477931a8aa2ad025c6bda0609f38e09e4d7ec"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ueberzugpp
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/make_libvips_optional.patch

# Build an OpenCV-only variant for now.
# Yggdrasil doesn't have a libvips recipe at the moment.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DUEBERZUGPP_CLI11_SOURCE_DIR=${WORKSPACE}/srcdir/CLI11 \
    -DUEBERZUGPP_RANGE_V3_SOURCE_DIR=${WORKSPACE}/srcdir/range-v3 \
    -DTBB_DIR=${libdir}/cmake/TBB \
    -DOpenCV_DIR=${libdir}/cmake/opencv4 \
    -DENABLE_VIPS=OFF \
    -DENABLE_X11=ON \
    -DENABLE_WAYLAND=OFF \
    -DENABLE_DBUS=OFF \
    -DENABLE_OPENCV=ON \
    -DENABLE_TURBOBASE64=OFF \
    -DENABLE_OPENGL=OFF

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

# Match the Linux/FreeBSD similar to OpenCV_jll
# also skip musl/32-bit ARM since OpenCV_jll does not provide those
platforms = filter(p ->
    (Sys.islinux(p) || Sys.isfreebsd(p)) &&
    (Sys.isfreebsd(p) || libc(p) != "musl") &&
    arch(p) != "armv6l" &&
    arch(p) != "armv7l",
    supported_platforms(),
)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("ueberzug", :ueberzug),
    ExecutableProduct("ueberzugpp", :ueberzugpp),
]

dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("oneTBB_jll"; compat="2022.0.0"),
    Dependency("OpenCV_jll"; compat="4.10.0"),
    Dependency("Chafa_jll"; compat="1.8.0"),
    Dependency("libsixel_jll"; compat="1.10.5"),
    Dependency("Fmt_jll"; compat="11.1.1"),
    Dependency("spdlog_jll"; compat="1.15.0"),
    BuildDependency("nlohmann_json_jll"; compat="3.12.0"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xcb_util_image_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")

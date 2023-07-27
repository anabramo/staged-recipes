#!/usr/bin/env bash
set -eux

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${HOST} =~ .*darwin.* ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
else
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")
fi

if [[ ${HOST} =~ .*darwin.* ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DGEANT4_USE_OPENGL_X11=OFF)
  CMAKE_PLATFORM_FLAGS+=(-DGEANT4_USE_RAYTRACER_X11=OFF)
else
  CMAKE_PLATFORM_FLAGS+=(-DGEANT4_USE_OPENGL_X11=ON)
  CMAKE_PLATFORM_FLAGS+=(-DGEANT4_USE_RAYTRACER_X11=ON)
fi
if [[ "${target_platform}" == "osx-64" ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi
if [[ ${DEBUG_C:-no} == yes ]]; then
  CMAKE_BUILD_TYPE=Debug
else
  CMAKE_BUILD_TYPE=Release
fi

# cmake_minimum_required(VERSION 3.1) is required to compile
# the examples to compile using conda's compiler packages
sed -r -i -E 's#cmake_minimum_required\(VERSION [0-9]\.[0-9]#cmake_minimum_required(VERSION 3.1#gI' \
  $(find examples -name 'CMakeLists.txt')

mkdir geant4-build
cd geant4-build

cmake                                                          \
      -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}"                 \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}"                       \
      -DBUILD_SHARED_LIBS=ON                                   \
      -DCMAKE_CXX_STANDARD=17                                 \
      -DGEANT4_BUILD_MULTITHREADED=OFF                         \
      -DGEANT4_BUILD_TLS_MODEL=global-dynamic                  \
      -DGEANT4_INSTALL_DATA=ON                                 \
      -DGEANT4_INSTALL_DATADIR="${PREFIX}/share/Geant4/data"   \
      -DGEANT4_INSTALL_EXAMPLES=ON                             \
      -DGEANT4_INSTALL_PACKAGE_CACHE=OFF                       \
      -DGEANT4_USE_FREETYPE=ON                                 \
      -DGEANT4_USE_GDML=ON                                     \
      -DGEANT4_USE_QT=ON                                       \
      -DGEANT4_USE_SYSTEM_CLHEP=ON                             \
      -DGEANT4_USE_SYSTEM_EXPAT=ON                             \
      -DGEANT4_USE_SYSTEM_ZLIB=ON                              \
      "${CMAKE_PLATFORM_FLAGS[@]}"                             \
      "${SRC_DIR}"

make "-j${CPU_COUNT}" ${VERBOSE_CM:-}
make install "-j${CPU_COUNT}"

# Print the contents of geant4.sh in case of problems
echo "Contents of ${PREFIX}/bin/geant4.sh is"
cat "${PREFIX}/bin/geant4.sh"

# Remove the geant4.(c)sh scripts and replace with a dummy version
for suffix in sh csh; do
  rm "${PREFIX}/bin/geant4.${suffix}"
  cp "${RECIPE_DIR}/geant4-setup" "${PREFIX}/bin/geant4.${suffix}"
  chmod +x "${PREFIX}/bin/geant4.${suffix}"
done

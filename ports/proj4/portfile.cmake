vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OSGeo/PROJ
    REF "${VERSION}"
    SHA512 05443c3b25d51ae6dedaf5343b8bda4024f3b6f8bed34a8d684d5948c5a7a388afc0c73abc248a270e6ed141d6826f4c9e9e84675c8d6f25c635b8aca558286a
    HEAD_REF master
    PATCHES
        fix-sqlite3-bin.patch
        disable-projdb-with-arm-uwp.patch
        fix-win-output-name.patch
        fix-sqlite-dependency-export.patch
        fix-linux-build.patch
        use-sqlite3-config.patch
)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH_DATA
    REPO OSGeo/proj-datumgrid
    REF 1.8
    SHA512 f0f8b18b8c421cd2bc1f535421c5c051dca72f2b9b7f3a8d3036feda0d3413aa15aa63bba0e9c8f37225eff2089323db3ea58b46cd0f174961a3ea5e9a90ea4d
    HEAD_REF master
)

file(COPY ${SOURCE_PATH_DATA}/ DESTINATION ${SOURCE_PATH}/data
    REGEX ".github|cmake|CMakeLists.txt|europe|HOWTORELEASE|lla|north-america|oceania|README.DATUMGRID" EXCLUDE 
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" PROJ_SHARED_LIBS)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        database BUILD_PROJ_DATABASE
)

if ("database" IN_LIST FEATURES)
    if (VCPKG_TARGET_IS_WINDOWS)
        set(BIN_SUFFIX .exe)
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL arm)
            if (NOT EXISTS ${CURRENT_INSTALLED_DIR}/tools/sqlite3.exe)
                message(FATAL_ERROR "Proj4 database need to install sqlite3[tool]:x86-windows first.")
            endif()
            set(SQLITE3_BIN_PATH ${CURRENT_INSTALLED_DIR}/tools)
        elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL arm64 OR (VCPKG_TARGET_ARCHITECTURE STREQUAL x64 AND VCPKG_LIBRARY_LINKAGE STREQUAL dynamic))
            if (NOT EXISTS ${CURRENT_INSTALLED_DIR}/tools/sqlite3.exe)
                message(FATAL_ERROR "Proj4 database need to install sqlite3[tool]:x64-windows first.")
            endif()
            set(SQLITE3_BIN_PATH ${CURRENT_INSTALLED_DIR}/tools)
        elseif (NOT TRIPLET_SYSTEM_ARCH STREQUAL "arm" AND EXISTS ${CURRENT_INSTALLED_DIR}/tools/sqlite3.exe)
            set(SQLITE3_BIN_PATH ${CURRENT_INSTALLED_DIR}/tools)
        else()
            set(SQLITE3_BIN_PATH ${CURRENT_INSTALLED_DIR}/tools)
        endif()
    else()
        set(BIN_SUFFIX)
        set(SQLITE3_BIN_PATH ${CURRENT_INSTALLED_DIR}/tools)
    endif()
endif()

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS ${FEATURE_OPTIONS}
        -DBUILD_LIBPROJ_SHARED=${PROJ_SHARED_LIBS}
        -DPROJ_LIB_SUBDIR=lib
        -DPROJ_INCLUDE_SUBDIR=include
        -DPROJ_DATA_SUBDIR=share/proj4
        -DBUILD_CCT=OFF
        -DBUILD_CS2CS=OFF
        -DBUILD_GEOD=OFF
        -DBUILD_GIE=OFF
        -DBUILD_PROJ=OFF
        -DBUILD_PROJINFO=OFF
        -DPROJ_TESTS=OFF
        -DEXE_SQLITE3=${SQLITE3_BIN_PATH}/sqlite3${BIN_SUFFIX}
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/proj4)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# for gdal
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

cmake_minimum_required(VERSION 3.14)
project(sldl_ui LANGUAGES CXX)

set(BINARY_NAME "sldl_ui")
set(APPLICATION_ID "com.github.fiso64.sldlui")

cmake_policy(SET CMP0063 NEW)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Profile" "Release")
endif()

function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

add_definitions(-DUNICODE -D_UNICODE)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})
add_subdirectory("runner")

# Generated plugin build rules, which manage building the plugins and their
# temporary output directories.
include(flutter/generated_plugins.cmake OPTIONAL)

# === Installation ===
# Install for the runner target.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")

# Make the "install" step default to a "bin" directory under the project root.
set(AUTO_INSTALL_BUNDLES TRUE CACHE BOOL "Automatically install build artifacts in bundle dir")

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${CMAKE_INSTALL_PREFIX}"
    COMPONENT Runtime)
endforeach(bundled_library)

set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

install(FILES "${AOT_LIBRARY}" DESTINATION "${CMAKE_INSTALL_PREFIX}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

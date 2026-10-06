cmake_minimum_required(VERSION 3.20)
project(edot_browser LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Widgets Quick QuickWidgets Qml Network Sql Svg Concurrent
    WebEngineCore WebEngineWidgets)

# Rust adblock-rust (uBlock-сумісний рушій). -DEDOT_NO_RUST=ON збирає з заглушкою
# (без фільтрації) - для CI та перевірки UI на системі без свіжого cargo.
option(EDOT_NO_RUST "Build with a no-op adblock stub instead of the Rust engine" OFF)

set(RUST_DIR ${CMAKE_CURRENT_SOURCE_DIR}/rust-adblock)
set(RUST_LIB ${RUST_DIR}/target/release/libedot_adblock.a)

if(EDOT_NO_RUST)
    add_library(edot_adblock STATIC src/adblock_stub.c)
    set(ADBLOCK_LIB edot_adblock)
else()
    find_program(CARGO_EXECUTABLE cargo REQUIRED)
    add_custom_command(
        OUTPUT ${RUST_LIB}
        COMMAND ${CARGO_EXECUTABLE} build --release --manifest-path ${RUST_DIR}/Cargo.toml
        WORKING_DIRECTORY ${RUST_DIR}
        DEPENDS ${RUST_DIR}/Cargo.toml ${RUST_DIR}/src/lib.rs
        COMMENT "Building Rust uBlock-compatible filter engine"
    )
    add_custom_target(edot_adblock ALL DEPENDS ${RUST_LIB})
    set(ADBLOCK_LIB ${RUST_LIB})
endif()

add_executable(edot-browser
    src/main.cpp
    src/browser_window.cpp   src/browser_window.h
    src/app_settings.cpp     src/app_settings.h
    src/data_store.cpp       src/data_store.h
    src/theme.cpp            src/theme.h
    src/image_providers.cpp  src/image_providers.h  src/icon_paths.h
    src/popup_window.cpp     src/popup_window.h
    src/rounded_frame.h      src/snackbar.h
    src/filter_engine.cpp    src/filter_engine.h
    src/filter_updater.cpp   src/filter_updater.h
    src/permissions.cpp      src/permissions.h
    src/request_interceptor.cpp src/request_interceptor.h
    qml.qrc
)

add_dependencies(edot-browser edot_adblock)
target_include_directories(edot-browser PRIVATE ${RUST_DIR}/include)

target_link_libraries(edot-browser PRIVATE
    Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Quick Qt6::QuickWidgets Qt6::Qml
    Qt6::Network Qt6::Sql Qt6::Svg Qt6::Concurrent
    Qt6::WebEngineCore Qt6::WebEngineWidgets
    ${ADBLOCK_LIB}
    dl pthread m
)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(edot-browser PRIVATE -O3 -march=native -flto)
    target_link_options(edot-browser PRIVATE -flto)
endif()

install(TARGETS edot-browser RUNTIME DESTINATION bin)

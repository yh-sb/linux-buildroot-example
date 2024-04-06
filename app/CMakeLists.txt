cmake_minimum_required(VERSION 3.21)

project(app)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Distinguish whether it's build for embedded target or build for PC
if(CMAKE_C_COMPILER MATCHES "arm-.*linux-.*gcc|aarch64-.*linux-.*gcc")
    set(EMBEDDED_TARGET ON)
    add_compile_definitions(EMBEDDED_TARGET)
endif()

add_executable(${CMAKE_PROJECT_NAME} main.cpp)

target_link_options(${CMAKE_PROJECT_NAME} PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-static-libgcc;-static-libstdc++;$<$<PLATFORM_ID:Windows>:-static>>
)

# Deploy
if(UNIX)
    # Create AppImage
    install(TARGETS ${CMAKE_PROJECT_NAME} DESTINATION "${CMAKE_BINARY_DIR}/appdir/usr/bin")
    install(CODE "execute_process(
        COMMAND linuxdeploy.AppImage --appdir appdir --desktop-file ${CMAKE_CURRENT_LIST_DIR}/app.desktop --icon-file ${CMAKE_CURRENT_LIST_DIR}/icon.png --output appimage
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMAND_ERROR_IS_FATAL ANY)"
    )
    # Get rid of hash and cpu arch in AppImage name
    install(CODE "execute_process(
        COMMAND sh -c \"mv ${CMAKE_PROJECT_NAME}*.AppImage ${CMAKE_PROJECT_NAME}.AppImage\"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMAND_ERROR_IS_FATAL ANY)"
    )
    install(FILES ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}.AppImage DESTINATION .
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
endif()

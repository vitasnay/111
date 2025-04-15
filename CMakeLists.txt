cmake_minimum_required(VERSION 3.15)
project(ColorizeStudio VERSION 1.0.0 LANGUAGES CXX)

# Включение FetchContent
include(FetchContent)

# Настройка типа сборки
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Тип сборки (Debug/Release)" FORCE)
endif()

# Настройка C++ стандарта
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Настройка предупреждений компилятора
if(MSVC)
    add_compile_options(/W4 /WX /permissive-)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
else()
    add_compile_options(-Wall -Wextra -Werror -Wpedantic -Wconversion -Wsign-conversion)
    add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)
endif()

# Настройка std::filesystem
if(MSVC)
    add_definitions(-D_HAS_AUTO_PTR_ETC=1)
endif()

# Настройка для разных операционных систем
if(WIN32)
    add_definitions(-D_WIN32_WINNT=0x0A00) # Windows 10
    add_definitions(-DNOMINMAX)
    add_definitions(-DUNICODE)
    add_definitions(-D_UNICODE)
elseif(UNIX AND NOT APPLE)
    add_definitions(-D_POSIX_C_SOURCE=200809L)
    add_definitions(-D_XOPEN_SOURCE=700)
elseif(APPLE)
    add_definitions(-D_DARWIN_C_SOURCE)
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Настройка выходных директорий
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Загрузка и настройка GTest
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG release-1.12.1
)
FetchContent_MakeAvailable(googletest)

# Загрузка и настройка OpenCV
FetchContent_Declare(
    opencv
    GIT_REPOSITORY https://github.com/opencv/opencv.git
    GIT_TAG 4.8.0
)
FetchContent_MakeAvailable(opencv)

# Проверка версии и компонентов OpenCV
if(NOT OpenCV_VERSION)
    message(FATAL_ERROR "OpenCV не найден. Пожалуйста, установите OpenCV.")
endif()

if(OpenCV_VERSION VERSION_LESS "4.8.0")
    message(FATAL_ERROR "Требуется OpenCV версии 4.8.0 или выше. Текущая версия: ${OpenCV_VERSION}")
endif()

# Проверка наличия необходимых компонентов OpenCV
set(REQUIRED_OPENCV_MODULES core imgproc imgcodecs highgui)
foreach(MODULE ${REQUIRED_OPENCV_MODULES})
    if(NOT TARGET opencv_${MODULE})
        message(FATAL_ERROR "Модуль OpenCV ${MODULE} не найден")
    endif()
endforeach()

# Настройка CUDA
find_package(CUDA 11.0 REQUIRED)
if(NOT CUDA_FOUND)
    message(FATAL_ERROR "CUDA не найден. Пожалуйста, установите CUDA Toolkit версии 11.0 или выше.")
endif()

# Проверка версии CUDA
if(CUDA_VERSION VERSION_LESS "11.0")
    message(FATAL_ERROR "Требуется CUDA версии 11.0 или выше. Текущая версия: ${CUDA_VERSION}")
endif()

# Настройка архитектуры CUDA
if(WIN32)
    set(CUDA_ARCHITECTURES "50;52;60;61;70;75;80;86")
else()
    set(CUDA_ARCHITECTURES "50;52;60;61;70;75;80;86")
endif()

set_target_properties(ColorizeStudio PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_ARCHITECTURES "${CUDA_ARCHITECTURES}"
)

# Поиск Qt6 с указанием минимальной версии
find_package(Qt6 6.2.0 COMPONENTS Core Gui Widgets REQUIRED)
if(NOT Qt6_FOUND)
    message(FATAL_ERROR "Qt6 версии 6.2.0 или выше не найден. Пожалуйста, установите Qt6.")
endif()

# Проверка версии Qt6
if(Qt6_VERSION VERSION_LESS "6.2.0")
    message(FATAL_ERROR "Требуется Qt6 версии 6.2.0 или выше. Текущая версия: ${Qt6_VERSION}")
endif()

# Проверка заголовочных файлов Qt
find_path(QT_INCLUDE_DIR QtCore/QtCore
    PATHS ${Qt6_DIR}/include
    NO_DEFAULT_PATH
)
if(NOT QT_INCLUDE_DIR)
    message(FATAL_ERROR "Заголовочные файлы Qt не найдены")
endif()

# Проверка версии CUDA Toolkit
if(CUDA_VERSION VERSION_LESS "11.0")
    message(FATAL_ERROR "Требуется CUDA Toolkit версии 11.0 или выше. Текущая версия: ${CUDA_VERSION}")
endif()

# Настройка путей к заголовочным файлам
include_directories(
    ${QT_INCLUDE_DIR}
    ${OpenCV_INCLUDE_DIRS}
    ${CUDA_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/src
)

# Настройка установки
include(GNUInstallDirs)
set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR})
set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR})
set(INSTALL_INCLUDE_DIR ${CMAKE_INSTALL_INCLUDEDIR})
set(INSTALL_DATA_DIR ${CMAKE_INSTALL_DATADIR})

# Настройка путей установки для разных ОС
if(WIN32)
    set(INSTALL_BIN_DIR "bin")
    set(INSTALL_LIB_DIR "lib")
    set(INSTALL_INCLUDE_DIR "include")
    set(INSTALL_DATA_DIR "share")
endif()

# Добавление поддиректорий
add_subdirectory(src)

# Настройка тестов
enable_testing()
include(GoogleTest)

# Проверка существования тестового исполняемого файла
if(TARGET ColorizeStudioTests)
    gtest_discover_tests(ColorizeStudioTests)
else()
    message(WARNING "Тестовый исполняемый файл ColorizeStudioTests не найден")
endif()

# Функция для проверки и установки зависимостей
function(check_and_install_dependencies)
    # Проверка наличия необходимых инструментов
    find_program(GIT_EXECUTABLE git)
    if(NOT GIT_EXECUTABLE)
        message(FATAL_ERROR "Git не найден. Пожалуйста, установите Git.")
    endif()

    find_program(CMAKE_EXECUTABLE cmake)
    if(NOT CMAKE_EXECUTABLE)
        message(FATAL_ERROR "CMake не найден. Пожалуйста, установите CMake.")
    endif()

    # Проверка наличия компилятора
    if(NOT CMAKE_CXX_COMPILER)
        message(FATAL_ERROR "C++ компилятор не найден. Пожалуйста, установите компилятор.")
    endif()

    # Проверка наличия Qt6
    if(NOT Qt6_FOUND)
        message(FATAL_ERROR "Qt6 не найден. Пожалуйста, установите Qt6.")
    endif()

    # Проверка наличия CUDA
    if(NOT CUDA_FOUND)
        message(FATAL_ERROR "CUDA не найден. Пожалуйста, установите CUDA Toolkit.")
    endif()

    # Проверка операционной системы
    if(WIN32)
        message(STATUS "Операционная система: Windows")
    elseif(UNIX AND NOT APPLE)
        message(STATUS "Операционная система: Linux")
    elseif(APPLE)
        message(STATUS "Операционная система: macOS")
    else()
        message(WARNING "Неизвестная операционная система")
    endif()
endfunction()

# Функция для проверки файлов переводов
function(check_translation_files)
    set(TRANSLATION_FILES
        "src/GUI/translations/colorize_studio_ru.ts"
    )
    
    foreach(TS_FILE ${TRANSLATION_FILES})
        if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${TS_FILE})
            message(WARNING "Файл перевода ${TS_FILE} не найден")
            # Создаем пустой файл перевода, если он отсутствует
            file(WRITE ${CMAKE_SOURCE_DIR}/${TS_FILE} 
                "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                "<!DOCTYPE TS>\n"
                "<TS version=\"2.1\" language=\"ru\">\n"
                "</TS>"
            )
            message(STATUS "Создан пустой файл перевода: ${TS_FILE}")
        endif()
    endforeach()
endfunction()

# Вызов функций проверки
check_and_install_dependencies()
check_translation_files() 
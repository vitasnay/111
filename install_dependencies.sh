#!/bin/bash

# Скрипт установки зависимостей для Linux
# Требует прав суперпользователя

# Проверка прав суперпользователя
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт требует прав суперпользователя. Запустите с sudo."
    exit 1
fi

# Функция для проверки наличия программы
check_program() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 не установлен."
        return 1
    fi
    return 0
}

# Функция для проверки версии программы
check_version() {
    local program=$1
    local required_version=$2
    local current_version=$($program --version | head -n1 | grep -oP '\d+\.\d+\.\d+')
    
    if [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" = "$required_version" ]; then
        return 0
    else
        return 1
    fi
}

# Проверка и установка необходимых пакетов
required_programs=(
    "git 2.0.0"
    "cmake 3.15.0"
    "g++ 9.0.0"
    "make 4.0.0"
)

for program_info in "${required_programs[@]}"; do
    program=$(echo $program_info | cut -d' ' -f1)
    version=$(echo $program_info | cut -d' ' -f2)
    
    if ! check_program $program; then
        echo "Установка $program..."
        apt-get update
        apt-get install -y $program
    fi
    
    if ! check_version $program $version; then
        echo "Требуется обновление $program до версии $version или выше."
        apt-get update
        apt-get install -y $program
    fi
done

# Установка CUDA Toolkit
cuda_version="11.0"
if [ ! -d "/usr/local/cuda-$cuda_version" ]; then
    echo "Установка CUDA Toolkit $cuda_version..."
    wget https://developer.download.nvidia.com/compute/cuda/$cuda_version/local_installers/cuda_${cuda_version}_linux.run
    sh cuda_${cuda_version}_linux.run --silent --toolkit
    rm cuda_${cuda_version}_linux.run
else
    echo "CUDA Toolkit $cuda_version уже установлен."
fi

# Установка Qt6
qt_version="6.2.0"
if [ ! -d "/opt/Qt/$qt_version" ]; then
    echo "Установка Qt $qt_version..."
    wget https://download.qt.io/online/qtsdkrepository/linux_x64/desktop/qt6_$qt_version/qt.qt6.$qt_version.gcc_64/linux_x64/qt.qt6.$qt_version.gcc_64.run
    chmod +x qt.qt6.$qt_version.gcc_64.run
    ./qt.qt6.$qt_version.gcc_64.run --script qt-installer-script.js
    rm qt.qt6.$qt_version.gcc_64.run
else
    echo "Qt $qt_version уже установлен."
fi

# Установка vcpkg
if [ ! -d "vcpkg" ]; then
    echo "Установка vcpkg..."
    git clone https://github.com/Microsoft/vcpkg.git
    cd vcpkg
    ./bootstrap-vcpkg.sh
    ./vcpkg integrate install
    cd ..
else
    echo "vcpkg уже установлен."
fi

# Установка OpenCV через vcpkg
echo "Установка OpenCV..."
./vcpkg/vcpkg install opencv4:x64-linux

# Установка дополнительных зависимостей
echo "Установка дополнительных зависимостей..."
./vcpkg/vcpkg install gtest:x64-linux
./vcpkg/vcpkg install nlohmann-json:x64-linux

# Настройка переменных окружения
echo "Настройка переменных окружения..."
echo "export PATH=/usr/local/cuda-$cuda_version/bin:\$PATH" >> /etc/profile.d/cuda.sh
echo "export LD_LIBRARY_PATH=/usr/local/cuda-$cuda_version/lib64:\$LD_LIBRARY_PATH" >> /etc/profile.d/cuda.sh
echo "export PATH=/opt/Qt/$qt_version/gcc_64/bin:\$PATH" >> /etc/profile.d/qt.sh
echo "export PATH=\$(pwd)/vcpkg:\$PATH" >> /etc/profile.d/vcpkg.sh

# Установка прав на скрипты
chmod +x /etc/profile.d/*.sh

echo "Установка зависимостей завершена успешно!"
echo "Пожалуйста, перезапустите терминал для применения изменений переменных окружения." 
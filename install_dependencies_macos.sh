#!/bin/bash

# Скрипт установки зависимостей для macOS
# Требует установленного Homebrew

# Проверка наличия Homebrew
if ! command -v brew &> /dev/null; then
    echo "Установка Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

# Проверка и установка необходимых программ
required_programs=(
    "git 2.0.0"
    "cmake 3.15.0"
    "gcc 9.0.0"
    "make 4.0.0"
)

for program_info in "${required_programs[@]}"; do
    program=$(echo $program_info | cut -d' ' -f1)
    version=$(echo $program_info | cut -d' ' -f2)
    
    if ! check_program $program; then
        echo "Установка $program..."
        brew install $program
    fi
    
    if ! check_version $program $version; then
        echo "Требуется обновление $program до версии $version или выше."
        brew upgrade $program
    fi
done

# Установка CUDA Toolkit
cuda_version="11.0"
if [ ! -d "/usr/local/cuda-$cuda_version" ]; then
    echo "Установка CUDA Toolkit $cuda_version..."
    brew install --cask cuda
else
    echo "CUDA Toolkit $cuda_version уже установлен."
fi

# Установка Qt6
qt_version="6.2.0"
if [ ! -d "/opt/Qt/$qt_version" ]; then
    echo "Установка Qt $qt_version..."
    brew install qt@6
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
./vcpkg/vcpkg install opencv4:x64-osx

# Установка дополнительных зависимостей
echo "Установка дополнительных зависимостей..."
./vcpkg/vcpkg install gtest:x64-osx
./vcpkg/vcpkg install nlohmann-json:x64-osx

# Настройка переменных окружения
echo "Настройка переменных окружения..."
echo "export PATH=/usr/local/cuda-$cuda_version/bin:\$PATH" >> ~/.zshrc
echo "export DYLD_LIBRARY_PATH=/usr/local/cuda-$cuda_version/lib:\$DYLD_LIBRARY_PATH" >> ~/.zshrc
echo "export PATH=/opt/Qt/$qt_version/clang_64/bin:\$PATH" >> ~/.zshrc
echo "export PATH=\$(pwd)/vcpkg:\$PATH" >> ~/.zshrc

# Применение изменений
source ~/.zshrc

echo "Установка зависимостей завершена успешно!"
echo "Пожалуйста, перезапустите терминал для применения изменений переменных окружения." 
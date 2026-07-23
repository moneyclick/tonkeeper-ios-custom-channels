# 🚀 Tonkeeper iOS - Custom Channels Edition

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2014.0+-lightgrey.svg)](https://www.apple.com/ios)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> Модифицированная версия Tonkeeper iOS с функцией добавления пользовательских Telegram-каналов

![Custom Channels Feature](https://img.shields.io/badge/Feature-Custom%20Channels-brightgreen)

## ✨ Новая функция: Custom Channels

### Что это?
Добавлена возможность быстро добавлять пользовательские Telegram-каналы в раздел "Коллекции" через **двойное нажатие** на навигационную панель.

### 🎯 Как использовать

1. Откройте вкладку **"Коллекции"** (Collectibles)
2. **Дважды нажмите** на заголовок "Коллекции"
3. Введите username (например: `bobico`)
4. Нажмите **"Add"**
5. Готово! Канал появится в списке 🎉

### 📸 Пример
```
Username: bobico
Display: @bobico
Subtitle: Telegram User
Image: https://cache.tonapi.io/imgproxy/.../bobico.webp
```

### 🔧 Технические детали

- **Двойное нажатие**: порог 0.5 секунды
- **Локальное хранение**: UserDefaults
- **Формат изображений**: WebP 500x500 через imgproxy
- **API**: TON API cache + imgproxy для оптимизации

### 📝 Структура данных

```swift
struct CustomChannel: Codable {
    let username: String
    let imageURL: String
    
    var displayName: String {
        "@\(username)"
    }
}
```

## 📚 Документация

- [📖 Подробная документация](CUSTOM_CHANNELS_README.md)
- [💡 Примеры использования](EXAMPLES.md)
- [🔨 CodeMagic CI/CD конфигурация](codemagic.yaml)

## 🛠 Измененные файлы

```
LocalPackages/App/Sources/App/CollectiblesModule/Modules/CollectiblesList/
├── CollectiblesListViewController.swift  ✅ Добавлен обработчик двойного нажатия
├── CollectiblesListViewModel.swift       ✅ Логика сохранения/загрузки каналов
└── CollectiblesListItems.swift          ✅ Новый тип элемента: customChannel
```

## 🚀 Установка и сборка

### Требования
- Xcode 15.0+
- iOS 14.0+
- CocoaPods / Swift Package Manager

### Шаги установки

```bash
# 1. Клонировать репозиторий
git clone https://github.com/moneyclick/tonkeeper-ios-custom-channels.git
cd tonkeeper-ios-custom-channels

# 2. Установить зависимости
make setup

# 3. Открыть в Xcode
open Tonkeeper.xcodeproj

# 4. Выбрать target и запустить
# Выберите TonkeeperDev для debug-сборки
# Выберите Tonkeeper для release-сборки
```

## 🎨 Особенности реализации

### 1️⃣ Обработка двойного нажатия
```swift
@objc func handleNavigationBarTap() {
    let currentTime = Date().timeIntervalSince1970
    if currentTime - lastTapTime < doubleTapThreshold {
        showAddChannelDialog()
        lastTapTime = 0
    } else {
        lastTapTime = currentTime
    }
}
```

### 2️⃣ Генерация URL изображения
```swift
func addCustomChannel(username: String) {
    let imageURL = "https://cache.tonapi.io/imgproxy/\(signature)/rs:fill:500:500:1/g:no/\(encodeUsername(username)).webp"
    // Сохраняем локально в UserDefaults
}
```

### 3️⃣ Отображение в списке
Пользовательские каналы отображаются **первыми**, затем идут NFT:
- Grid: 3 колонки
- Размер карточки: 166pt высота
- Отступы: 16pt по бокам, 8pt между элементами

## 🔐 Безопасность

- ✅ Локальное хранилище (UserDefaults)
- ✅ Нет отправки данных на сервер
- ✅ Изображения загружаются через официальный TON API
- ✅ Нет синхронизации между устройствами

## 📦 CodeMagic CI/CD

Проект готов к сборке в CodeMagic! Конфигурация включает:

- ✅ Автоматическая сборка при push
- ✅ Подпись кода для App Store
- ✅ Отправка в TestFlight
- ✅ Debug и Release конфигурации

См. [codemagic.yaml](codemagic.yaml) для деталей.

## 🤝 Вклад в проект

Основано на официальном [Tonkeeper iOS](https://github.com/tonkeeper/ios)

### Автор модификации
- Custom Channels Feature
- GitHub: [@moneyclick](https://github.com/moneyclick)

## 📄 Лицензия

Apache License 2.0 - см. [LICENSE](LICENSE)

---

## 🔗 Полезные ссылки

- [Оригинальный Tonkeeper](https://tonkeeper.com)
- [TON API Documentation](https://tonapi.io)
- [Fragment Username Marketplace](https://fragment.com)

---

<p align="center">
  Сделано с ❤️ для TON сообщества
</p>

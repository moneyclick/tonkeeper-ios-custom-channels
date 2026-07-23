# Примеры использования Custom Channels

## Пример 1: Добавление канала "bobico"

1. Откройте Collectibles
2. Дважды нажмите на заголовок
3. Введите: `bobico`
4. Результат:
   - Username: @bobico
   - Subtitle: Telegram User
   - Image URL: `https://cache.tonapi.io/imgproxy/6bjc3arFMRcsqoh80US6jmQ6_OIflSLewvFd1XxcuIk/rs:fill:500:500:1/g:no/aHR0cHM6Ly9uZnQuZnJhZ21lbnQuY29tL3VzZXJuYW1lL2JvYmljby53ZWJw.webp`

## Пример 2: Добавление нескольких каналов

```swift
// Можно добавить несколько каналов:
- publishingsystem
- oxygenization  
- litecoin_network
- fcbanikostrava
- helminthite
```

## Структура данных канала

```swift
struct CustomChannel: Codable {
    let username: String        // "bobico"
    let imageURL: String        // Full imgproxy URL
    
    var displayName: String {   // "@bobico"
        "@\(username)"
    }
}
```

## JSON структура в UserDefaults

```json
[
  {
    "username": "bobico",
    "imageURL": "https://cache.tonapi.io/imgproxy/6bjc3arFMRcsqoh80US6jmQ6_OIflSLewvFd1XxcuIk/rs:fill:500:500:1/g:no/aHR0cHM6Ly9uZnQuZnJhZ21lbnQuY29tL3VzZXJuYW1lL2JvYmljby53ZWJw.webp"
  },
  {
    "username": "publishingsystem",
    "imageURL": "https://cache.tonapi.io/imgproxy/6bjc3arFMRcsqoh80US6jmQ6_OIflSLewvFd1XxcuIk/rs:fill:500:500:1/g:no/aHR0cHM6Ly9uZnQuZnJhZ21lbnQuY29tL3VzZXJuYW1lL3B1Ymxpc2hpbmdzeXN0ZW0ud2VicA.webp"
  }
]
```

## Как работает encoding URL

```swift
func encodeUsername(_ username: String) -> String {
    // Шаг 1: Создаем полный URL
    let urlString = "https://nft.fragment.com/username/\(username).webp"
    // "https://nft.fragment.com/username/bobico.webp"
    
    // Шаг 2: Конвертируем в Data
    let data = urlString.data(using: .utf8)
    
    // Шаг 3: Кодируем в Base64
    return data.base64EncodedString()
    // "aHR0cHM6Ly9uZnQuZnJhZ21lbnQuY29tL3VzZXJuYW1lL2JvYmljby53ZWJw"
}
```

## API imgproxy

### Формат URL:
```
https://cache.tonapi.io/imgproxy/{signature}/rs:fill:500:500:1/g:no/{base64_source_url}.webp
```

### Параметры:
- `signature`: `6bjc3arFMRcsqoh80US6jmQ6_OIflSLewvFd1XxcuIk`
- `rs:fill:500:500:1`: Resize to 500x500, fill mode
- `g:no`: Gravity: none
- `base64_source_url`: Base64-encoded source URL
- `.webp`: Output format

## Визуальное отображение

Каналы отображаются как карточки 3x3 grid:

```
┌─────────┬─────────┬─────────┐
│ @bobico │  @user2 │  @user3 │
├─────────┼─────────┼─────────┤
│   NFT1  │   NFT2  │   NFT3  │
└─────────┴─────────┴─────────┘
```

## Отладка

Для проверки сохраненных каналов:

```swift
// В Xcode Console
po UserDefaults.standard.data(forKey: "customChannels")
```

Для очистки всех каналов:

```swift
UserDefaults.standard.removeObject(forKey: "customChannels")
```

## Ограничения

1. Нет проверки дублирования username
2. Нет валидации формата username
3. Нет возможности удалить канал через UI
4. Изображение загружается только если оно есть на Fragment

## Возможные улучшения

1. Добавить долгое нажатие для удаления канала
2. Добавить проверку существования username
3. Добавить предпросмотр изображения перед добавлением
4. Добавить экспорт/импорт списка каналов
5. Добавить поиск по каналам
6. Добавить категории/теги для каналов

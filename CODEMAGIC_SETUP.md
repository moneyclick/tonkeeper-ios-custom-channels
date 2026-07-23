# 🚀 CodeMagic Setup - Пошаговая инструкция

## Проблема решена! ✅

Конфигурация обновлена для **сборки без Apple Developer аккаунта**.

## 📋 Что делать в CodeMagic:

### Шаг 1: Выбери тип аккаунта
На экране "How will you be using Codemagic?":
- Нажми **"Individual"** → **"Get started"**
- Зарегистрируйся (можно через GitHub)

### Шаг 2: Подключи репозиторий
1. Нажми **"Add application"**
2. Выбери **"GitHub"**
3. Авторизуйся через GitHub
4. Найди репозиторий: **`moneyclick/tonkeeper-ios-custom-channels`**
5. Нажми **"Select"** или **"Add"**

### Шаг 3: Выбери workflow
CodeMagic автоматически найдет файл `codemagic.yaml` и покажет доступные workflows:

#### Вариант 1 (Рекомендуется): 
**`ios-tonkeeper-custom-channels`**
- ✅ Не требует подписи кода
- ✅ Собирает для iOS Simulator
- ✅ Работает без Apple Developer Account
- ⚡ Быстрая сборка (~10-15 минут)

#### Вариант 2:
**`ios-tonkeeper-debug-build`**
- ✅ Альтернативная debug-сборка
- ✅ Тоже без подписи

### Шаг 4: Запусти сборку
1. Выбери workflow: **`ios-tonkeeper-custom-channels`**
2. Выбери ветку: **`main`**
3. Нажми **"Start new build"** или **"Start build"**

### Шаг 5: Смотри процесс
- CodeMagic начнет сборку
- Увидишь логи в реальном времени:
  - ✅ Install dependencies
  - ✅ Build for iOS Simulator
- Процесс займет 10-15 минут

### Шаг 6: Получи результат
После успешной сборки:
- В разделе **"Artifacts"** будет файл `.app`
- Это приложение для iOS Simulator
- Можешь скачать и запустить в Xcode Simulator

## 🎯 Что изменилось:

### ❌ БЫЛО (с ошибкой):
```yaml
environment:
  ios_signing:
    distribution_type: app_store
    bundle_identifier: com.tonkeeper.app
```
**Проблема**: Требовался Apple Developer Account и provisioning profile

### ✅ СТАЛО (без ошибки):
```yaml
environment:
  xcode: 15.0
scripts:
  - name: Build for iOS Simulator
    script: |
      xcodebuild \
        -sdk iphonesimulator \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO
```
**Решение**: Сборка для симулятора БЕЗ подписи кода

## 📱 Что получишь:

- ✅ Приложение `.app` для iOS Simulator
- ✅ Работает на Mac с Xcode
- ✅ Можно тестировать все функции включая Custom Channels
- ❌ НЕ работает на реальном iPhone (нужна подпись)

## 🔧 Если хочешь собрать для реального iPhone:

### Нужно:
1. Apple Developer Account ($99/год)
2. Provisioning Profile
3. Сертификат подписи кода
4. Изменить Bundle ID с `com.tonkeeper.app` на свой

### Тогда в CodeMagic:
1. Settings → Code signing identities
2. Добавить iOS certificate
3. Добавить Provisioning profile
4. Обновить `codemagic.yaml`:
```yaml
environment:
  ios_signing:
    distribution_type: development
    bundle_identifier: com.yourname.tonkeeper
```

## ❓ FAQ

**Q: Зачем нужен Simulator build?**
A: Для тестирования без Apple Developer Account. Можно проверить все функции приложения.

**Q: Как запустить .app файл?**
A: 
1. Скачай артефакт из CodeMagic
2. Открой Xcode
3. Window → Devices and Simulators
4. Запусти симулятор iPhone
5. Перетащи .app файл на симулятор

**Q: Можно ли запустить на реальном iPhone?**
A: Нет, для этого нужен Apple Developer Account и правильная подпись.

**Q: Сборка упала с другой ошибкой?**
A: Скинь лог ошибки, помогу исправить!

## 🎉 Готово!

Теперь жми в CodeMagic:
1. **Individual** → **Get started**
2. **Add application** → **GitHub**
3. Выбрать **`tonkeeper-ios-custom-channels`**
4. Workflow: **`ios-tonkeeper-custom-channels`**
5. **Start build**

И наблюдай как собирается твое приложение! 🚀

---

**Репозиторий**: https://github.com/moneyclick/tonkeeper-ios-custom-channels

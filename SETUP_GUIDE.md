# Детальное руководство по настройке

## 📋 Содержание

1. [Настройка Android](#android-setup)
2. [Настройка iOS](#ios-setup)
3. [Настройка Firebase](#firebase-setup)
4. [Частые проблемы](#troubleshooting)

---

## Android Setup

### 1. Разрешения

Приложение автоматически запросит все необходимые разрешения при первом запуске.

#### Если разрешения не работают:

**Xiaomi (MIUI):**
1. Настройки → Приложения → Context Keeper → Разрешения
2. Включите все разрешения
3. Настройки → Приложения → Context Keeper → Другие разрешения
4. Включите "Показ поверх других приложений"
5. Настройки → Приложения → Context Keeper → Автозапуск → Включить

**Huawei (EMUI):**
1. Настройки → Приложения → Context Keeper → Разрешения
2. Включите все разрешения
3. Настройки → Приложения → Context Keeper → Управление батареей
4. Выберите "Ручное управление" и включите все

**Samsung (One UI):**
1. Настройки → Приложения → Context Keeper → Разрешения
2. Включите все разрешения
3. Настройки → Приложения → Context Keeper → Отображение поверх других приложений → Включить

### 2. Тестирование overlay

Для тестирования функции overlay:

```bash
# Запустите приложение
flutter run

# В другом терминале симулируйте входящий звонок
adb shell am broadcast -a android.intent.action.PHONE_STATE --es state RINGING --es incoming_number +1234567890
```

### 3. Сборка APK

```bash
# Debug версия
flutter build apk --debug

# Release версия
flutter build apk --release

# APK будет в: build/app/outputs/flutter-apk/
```

---

## iOS Setup

### 1. Настройка Xcode

1. Откройте проект в Xcode:
```bash
open ios/Runner.xcworkspace
```

2. В Xcode:
   - Выберите Runner в Project Navigator
   - Выберите Runner target
   - В "Signing & Capabilities":
     - Выберите ваш Team
     - Измените Bundle Identifier на уникальный

### 2. Настройка Push Notifications

1. В Xcode → Signing & Capabilities → + Capability
2. Добавьте:
   - Push Notifications
   - Background Modes (включите "Remote notifications")

### 3. Настройка Apple Developer Portal

1. Перейдите на [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → Identifiers
3. Выберите ваш App ID
4. Включите "Push Notifications"
5. Создайте APNs Key:
   - Keys → + (Create a key)
   - Выберите "Apple Push Notifications service (APNs)"
   - Скачайте .p8 файл (сохраните, показывается только раз!)

---

## Firebase Setup

### 1. Создание проекта

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Add project"
3. Введите имя проекта: "Context Keeper"
4. Отключите Google Analytics (необязательно)
5. Нажмите "Create project"

### 2. Добавление Android приложения

1. В Firebase Console → Project Settings → Add app → Android
2. Введите package name: `com.example.context_keeper`
3. Скачайте `google-services.json`
4. Поместите файл в `android/app/google-services.json`
5. Убедитесь, что в `android/build.gradle` есть:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```
6. И в `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. Добавление iOS приложения

1. В Firebase Console → Project Settings → Add app → iOS
2. Введите Bundle ID (тот же что в Xcode)
3. Скачайте `GoogleService-Info.plist`
4. Откройте Xcode
5. Перетащите файл в `Runner` (убедитесь что "Copy items if needed" включен)

### 4. Настройка Cloud Messaging для iOS

1. В Firebase Console → Project Settings → Cloud Messaging → iOS app configuration
2. Upload APNs Key (.p8 файл)
3. Введите:
   - Key ID (из Apple Developer Portal)
   - Team ID (из Apple Developer Portal)

### 5. Backend для iOS push-уведомлений

Для работы на iOS нужен backend, который будет:

1. Получать webhook о входящем звонке от вашего телефонного провайдера
2. Отправлять FCM push-уведомление на устройство

#### Пример простого Node.js backend:

```javascript
const admin = require('firebase-admin');
const express = require('express');

// Инициализация Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json'))
});

const app = express();
app.use(express.json());

// Endpoint для webhook входящих звонков
app.post('/webhook/incoming-call', async (req, res) => {
  const { phoneNumber, userId } = req.body;

  // Получить FCM token пользователя из вашей БД
  const fcmToken = await getUserFcmToken(userId);

  // Получить заметку о контакте из вашей БД
  const note = await getContactNote(userId, phoneNumber);

  if (note) {
    // Отправить push-уведомление
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: `📞 ${note.contactName}`,
        body: note.notes
      },
      data: {
        phoneNumber: phoneNumber,
        contactName: note.contactName,
        notes: note.notes
      }
    });
  }

  res.sendStatus(200);
});

app.listen(3000);
```

---

## Troubleshooting

### Проблема: Overlay не показывается на Android

**Решение:**
1. Проверьте разрешение "Показ поверх других окон"
2. Проверьте логи: `adb logcat | grep ContextKeeper`
3. На некоторых устройствах нужно вручную включить в настройках

### Проблема: iOS уведомления не приходят

**Решение:**
1. Убедитесь что Firebase настроен правильно
2. Проверьте что APNs ключ загружен
3. Проверьте что устройство зарегистрировано и получило FCM token
4. Проверьте логи в Firebase Console → Cloud Messaging → Messaging Report

### Проблема: Не видит контакты

**Решение:**
1. Проверьте что разрешение на контакты выдано
2. Перезапустите приложение
3. Проверьте что в телефоне есть контакты

### Проблема: Build fails на iOS

**Решение:**
1. Обновите CocoaPods: `sudo gem install cocoapods`
2. Очистите и переустановите pods:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### Проблема: Permission denied на Android

**Решение:**
1. Убедитесь что в AndroidManifest.xml есть все permissions
2. Запросите разрешения через экран Permissions в приложении
3. Для Android 11+ может потребоваться добавить в AndroidManifest.xml:
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="tel" />
    </intent>
</queries>
```

---

## 🎯 Следующие шаги

После успешной настройки:

1. ✅ Создайте несколько тестовых заметок
2. ✅ Протестируйте входящий звонок (или симулируйте на Android)
3. ✅ Проверьте что overlay/уведомление работает
4. ✅ Настройте backend для iOS (если нужно)

---

**Если возникли проблемы, создайте Issue на GitHub!**

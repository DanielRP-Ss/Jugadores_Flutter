# GameArena App — Demo Flutter 
Integrantes: *Daniel Rojas, Yariel Jiménez, Malcolm Méndez*
---

## 1. Requisitos

| Componente | Versión |
| --- | --- |
| Flutter SDK | 3.47.x stable |
| Android Studio | última estable |
| Android SDK | 36 + NDK (Side by side) 28.2.13676358 |
| Backend | api.zip → Django 5.2 + DRF + corsheaders + dotenv |
| Python | 3.12+ (mismo entorno del proyecto GameArena) |
| Emulador | API 34+ x86_64 |

---

## 2. Preparación del entorno (pasos exactos, Windows)

### 2.1 Flutter SDK

1. Extraer en `C:\Users\<usuario>\Flutter\` (sin espacios).
2. Agregar a PATH: `C:\Users\<usuario>\Flutter\bin`.
3. `flutter doctor` → todo `[✓]` salvo Visual Studio (opcional, solo Windows desktop).

### 2.2 Android Studio y SDK (errores reales que pueden aparecer)

**Settings → Android SDK → SDK Tools**, instalar:

- ☑ Android SDK **Command-line Tools (latest)** — sin esto `flutter doctor --android-licenses`
  falla con `cmdline-tools component is missing`.
- ☑ **NDK (Side by side) 28.2.13676358** — sin esto el build falla con
  `sdkmanager did not install NDK`. Si el CLI de Google no lo puede descargar
  (algunas máquinas Windows bloquean el JRE embebido por directiva de Control de
  aplicaciones), instalarlo **desde la interfaz de Android Studio**, que descarga por otro canal.

```bash
flutter doctor --android-licenses   # aceptar con y
```

**Banner "Dart SDK is not configured"** (al clonar el repo):
`Settings → Languages & Frameworks → Dart` → Dart SDK path:
`C:\Users\<usuario>\Flutter\flutter\bin\cache\dart-sdk`. O ejecutar `flutter pub get`.

1. Arrancar:

```bash
pip install django djangorestframework django-cors-headers python-dotenv mysqlclient
python manage.py migrate
python manage.py createsuperuser    
python manage.py runserver          
```

2. Verificar en PC: http://127.0.0.1:8000/api/videojuegos/

### 2.4 App Flutter — HTTP en claro

`android/app/src/main/AndroidManifest.xml` → dentro de `<application>`:

```xml
android:usesCleartextTraffic="true"
```

(Django en desarrollo no usa TLS; CORS del backend solo aplica a navegadores,
la app Android nativa no lo necesita.)

### 2.5 Emulador

Device Manager → Create Device → API 34+ x86_64 → encender **uno solo**.
Si `Running multiple emulators with the same AVD`:

```bash
taskkill /F /IM emulator.exe
taskkill /F /IM qemu-system-x86_64.exe
```

---

## 3. Ejecución

```bash
git https://github.com/DanielRP-Ss/Jugadores_Flutter.git
cd gamearena_app
flutter pub get
flutter run -d emulator-5554
```

Orden obligatorio: primero Django (`runserver`), después Flutter.

Durante la ejecución: `r` hot reload, `R` hot restart, `q` salir.

---

## 4. Estructura del proyecto

```javascript
gamearena_app/
├── lib/
│   ├── main.dart                     
│   ├── models/
│   │   ├── videojuego.dart           
│   │   └── jugador.dart              
│   ├── services/
│   │   └── api_service.dart          
│   └── screens/
│       ├── videojuegos_screen.dart   
│       └── registro_screen.dart      
├── android/                          
└── pubspec.yaml                     
```

---

## 5. Cómo funciona

| Aspecto | Implementación |
| --- | --- |
| Punto de entrada | `main()` → `runApp` → `MaterialApp` → `VideojuegosScreen` |
| Petición GET | `api_service.fetchVideojuegos()` → `http.get` → `jsonDecode` → `Videojuego.fromJson` |
| Estados de la petición | `FutureBuilder`: cargando (spinner) / error (botón reintentar) / datos (ListView) |
| Filtro | query param `?plataforma=` enviado por `DropdownButton` |
| Refresco | `RefreshIndicator` (pull-to-refresh) + recarga al volver del formulario |
| POST | `http.post` con `jsonEncode`; la API exige admin → sin token responde **403** |
| Manejo de errores | `ApiException(status, message)` → SnackBar naranja (403) / rojo (400) |
| Navegación | `Navigator.push` / `Navigator.pop` |


### Contrato de la API consumida

| Endpoint | Método | Respuesta | Auth |
| --- | --- | --- | --- |
| `/api/videojuegos/` | GET | array de videojuegos (activos, orden por nombre) | pública, filtro `plataforma` |
| `/api/jugadores/` | GET | paginada: `resultados[]`, `total_paginas` | pública, filtros `pais/buscar/page` |
| `/api/jugadores/` | POST | 201 objeto creado / 403 sin admin | **root** |
| `/api/token/` | POST | token de autenticación | credenciales root |

---

## 6. Datos de prueba

Precargar videojuegos por el admin de Django (http://127.0.0.1:8000/admin):
mínimo 3 títulos en 2 plataformas distintas para demostrar el filtro.

Casos de demo:

1. Lista carga con spinner → aparecen los juegos.
2. Filtro "PlayStation" → solo esos títulos (verificable contra el admin).
3. Apagar `runserver` → pantalla de error → encender de nuevo → "Reintentar" → lista vuelve.
4. Formulario vacío → validaciones inline.
5. Email inválido → "Email inválido".
6. Registro válido sin login → SnackBar **403** (la API protege el POST).
7. (Opcional) Con token de admin → 201 y el jugador aparece en `/api/jugadores/`.

---

## 7. Limitaciones conocidas

- POST de jugadores bloqueado sin token (por diseño del backend); la app lo maneja
  visualmente pero no implementa login todavía.
- Paginación de `/api/jugadores/` y `/api/torneos/` no consumida aún (usa solo page 1).
- Sin persistencia local (todo viene de la red).
- iOS requiere macOS + Xcode; Windows desktop requiere VS con workload C++ (no usados).

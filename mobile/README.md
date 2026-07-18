# 🌦️ Clima UTEM

Aplicación móvil desarrollada en **Flutter** que permite a un usuario autenticado visualizar las condiciones climáticas y la farmacia de turno más cercana según su ubicación actual.

El proyecto fue desarrollado como trabajo práctico de la asignatura de Desarrollo de Aplicaciones Móviles.

---

# Características

- Inicio de sesión mediante Google Sign-In.
- Persistencia de la sesión del usuario.
- Obtención de la ubicación mediante GPS.
- Visualización de la ubicación en un mapa interactivo.
- Consulta de condiciones meteorológicas desde un servicio REST.
- Consulta de la farmacia de turno más cercana.
- Cálculo de la distancia entre el usuario y la farmacia.
- Manejo de estados:
    - Carga
    - Error
    - Sin datos
    - Datos obtenidos correctamente
- Interfaz moderna utilizando Material 3.

---

# Tecnologías utilizadas

- Flutter
- Dart
- Provider
- Dio
- Google Sign-In
- Flutter Map
- Geolocator
- LatLong2
- Shared Preferences / Secure Storage
- Logger

---

# Arquitectura

La aplicación utiliza una arquitectura basada en **Provider (ChangeNotifier)** con separación de responsabilidades.

```
lib/
│
├── consts/
│
├── controller/
│
├── model/
│
├── screen/
│
├── services/
│
├── widgets/
│
└── main.dart
```

Cada capa posee una responsabilidad específica:

### Models

Representan las estructuras de datos recibidas desde la API.

Ejemplos:

- ObservacionMeteo
- Farmacia
- Coordenada

---

### Services

Encapsulan toda la lógica relacionada con servicios externos.

- Servicio REST
- GPS
- Google Sign-In
- Almacenamiento local
- Cálculo de distancia

---

### Controllers

Gestionan el estado de la aplicación utilizando Provider.

Son los encargados de:

- obtener información
- actualizar la UI
- manejar errores
- notificar cambios

---

### Widgets

Componentes reutilizables de la interfaz.

Ejemplos:

- mapa
- tarjeta del clima
- estados de carga
- estados de error

---

### Screens

Representan las pantallas completas de la aplicación.

- Login
- Home
- Farmacia
- Error
- Success

---

# Consumo de API

La aplicación consume los servicios REST proporcionados por:

https://api.sebastian.cl/cmutem/swagger-ui/index.html

Servicios utilizados:

- autenticación
- observaciones meteorológicas
- farmacias
- información geográfica

---

# Instalación

## 1. Clonar el repositorio

```bash
git clone https://github.com/estefyserja/utem-weather-app.git
```

---

## 2. Entrar al proyecto

```bash
cd mobile
```

---

## 3. Instalar dependencias

```bash
flutter pub get
```

---

## 4. Configurar Google Sign-In

Agregar el archivo correspondiente:

Android

```
android/app/google-services.json
```

iOS

```
ios/Runner/GoogleService-Info.plist
```

Además registrar el SHA-1 del proyecto en Firebase.

---

## 5. Ejecutar

```bash
flutter run
```

---

# Dependencias principales

- provider
- dio
- flutter_map
- geolocator
- google_sign_in
- google_fonts
- flutter_secure_storage
- logger

---

# Funcionalidades

## Autenticación

- Login con Google
- Persistencia de sesión
- Logout

---

## Geolocalización

- Solicitud de permisos
- Obtención de coordenadas
- Visualización en mapa

---

## Clima

- Temperatura
- Humedad
- Radiación UV
- ID Observación

---

## Farmacia

- Nombre
- Dirección
- Horario
- Distancia aproximada

---

# Estructura del proyecto

```
lib
├── consts
│   ├── app_colors.dart
│   └── app_const.dart
│
├── controller
│   ├── farmacia_controller.dart
│   └── weather_screen_controller.dart
│
├── model
│   ├── coordenada.dart
│   ├── farmacia.dart
│   └── observacion_meteo.dart
│
├── screen
│   ├── login_screen.dart
│   ├── weather_screen.dart
│   ├── farmacia_screen.dart
│   ├── success_screen.dart
│   └── error_screen.dart
│
├── services
│   ├── servicio_rest.dart
│   ├── servicio_google.dart
│   ├── servicio_ubicacion.dart
│   ├── servicio_distancia.dart
│   └── servicio_almacenamiento.dart
│
├── widgets
│   ├── clima_widget.dart
│   ├── widget_mapa.dart
│   ├── estado_carga_widget.dart
│   ├── estado_error_widget.dart
│   ├── estado_vacio_widget.dart
│   └── my_menu.dart
│
└── main.dart
```

---

# Autor

Estefany Scarlette Serrano Jaque

Universidad Tecnológica Metropolitana

Desarrollo de Aplicaciones Móviles

2026
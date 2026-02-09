# PixelMap Deploy Guide

## Opção 1: Build Local (Mais Rápido)

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- [Android Studio](https://developer.android.com/studio) (com SDK)
- Git

### Passos

```bash
# 1. Clonar o projeto (ou copiar a pasta)
cd /data/.openclaw/workspace/pixelmap

# 2. Correr o script de build
chmod +x build.sh
./build.sh
```

O APK vai estar em: `build/app/outputs/flutter-apk/app-release.apk`

### Instalar no telemóvel

```bash
# Com cabo USB e depuração ativada
flutter install

# Ou via ADB
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Opção 2: GitHub Actions (Build Automático)

1. Cria um repositório no GitHub
2. Faz push do código:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TONYUSERNAME/pixelmap.git
git push -u origin main
```

3. Vai a **Actions** → **Build Android APK**
4. Clica em **Run workflow**
5. Faz download do APK em **Artifacts**

---

## Opção 3: Docker (Full Stack)

Para correr backend + app local:

```bash
# Subir Supabase + n8n + Redis
docker-compose up -d

# App vai usar http://localhost:54321 (Supabase local)
```

---

## Configuração da App

Antes de fazer build, configura o Supabase:

1. Cria projeto em [supabase.com](https://supabase.com)
2. Corre o schema: `supabase/schema.sql`
3. Copia `.env.example` para `.env`
4. Preenche as tuas credenciais
5. Faz rebuild

---

## Troubleshooting

### "Flutter not found"
```bash
export PATH="$PATH:/usr/local/flutter/bin"
```

### "Android SDK not found"
```bash
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH="$PATH:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools"
```

### Build falha
```bash
flutter clean
flutter pub get
flutter build apk --verbose
```

---

## Quick Test (Sem Build)

Para testar a UI sem backend:
```bash
flutter run --debug
```

Isto corre em modo debug com hot reload.

# تثبيت Traefik مينيمال (Minimal)

## المحتوى

- Traefik (Reverse Proxy)
- Whoami (Service for testing)
- Portainer (Docker Management)

## المتطلبات

- Ubuntu/Linux
- Docker Engine
- Docker Compose v2

## الخطوات

### 1. إنشاء المجلدات المطلوبة

```bash
mkdir -p traefik/certs traefik/dynamic
```

### 2. إضافة odoo-com إلى /etc/hosts

```bash
echo "127.0.0.1 odoo-com" | sudo tee -a /etc/hosts
```

### 3. إنشاء الشبكة

```bash
docker network create proxy 2>/dev/null || true
```

### 4. تشغيل

```bash
docker compose -f docker-compose.minimal.yml up -d
```

### 5. التحقق

```bash
docker compose -f docker-compose.minimal.yml ps
```

## النتائج المتوقعة

- `http://odoo-com` → Traefik Dashboard
- `http://whoami.odoo-com` → Whoami container info
- `http://portainer.odoo-com` → Portainer UI

## أو restarting

```bash
docker compose -f docker-compose.minimal.yml down
```

## ملاحظات

- هذا الملف مينيمال فقط. الملف الأصلي `docker-compose.yml` يحتوي على Services إضافية.
- لاستخدام الملف الأصلي: `docker compose up -d`
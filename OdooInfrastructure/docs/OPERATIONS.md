# التشغيل والصيانة

نفّذ الأوامر على خادم Docker (Ubuntu) من المسار الذي يحتوي `OdooInfrastructure` (مثال: `/opt/OdooInfrastructure`).

## التحضير لمرة واحدة

```bash
cd /opt/OdooInfrastructure
cp .env.example .env && chmod 600 .env
# حرر .env بقيم حقيقية
touch traefik/acme/acme.json && chmod 600 traefik/acme/acme.json
docker network create proxy || true
```

## التشغيل

```bash
docker compose -f docker-compose.traefik.yml up -d
docker compose --env-file .env -f odoo17/docker-compose.yml up -d
docker compose --env-file .env -f odoo19/docker-compose.yml up -d
```

## الإيقاف (يحافظ على البيانات)

```bash
docker compose --env-file .env -f odoo19/docker-compose.yml down
docker compose --env-file .env -f odoo17/docker-compose.yml down
docker compose -f docker-compose.traefik.yml down
```

## إعادة التشغيل

```bash
docker compose --env-file .env -f odoo17/docker-compose.yml restart
docker compose --env-file .env -f odoo19/docker-compose.yml restart
docker compose -f docker-compose.traefik.yml restart traefik
```

## تحديث الصور

```bash
docker compose -f docker-compose.traefik.yml pull && docker compose -f docker-compose.traefik.yml up -d
docker compose --env-file .env -f odoo17/docker-compose.yml pull && docker compose --env-file .env -f odoo17/docker-compose.yml up -d
docker compose --env-file .env -f odoo19/docker-compose.yml pull && docker compose --env-file .env -f odoo19/docker-compose.yml up -d
```

اختبر التحديث في بيئة مناسبة قبل الإنتاج؛ راجع توافق Odoo/PostgreSQL.

## السجلات والتحقق

```bash
docker ps
docker compose -f docker-compose.traefik.yml logs --tail=200 traefik
docker compose --env-file .env -f odoo17/docker-compose.yml logs --tail=100 odoo17 db17
docker compose --env-file .env -f odoo19/docker-compose.yml logs --tail=100 odoo19 db19
```

## النسخ الاحتياطي والاستعادة (مثال)

انظر `scripts/backup.sh`. يجب أيضًا نسخ `.env` (بأمان)، و`traefik/acme/acme.json` (بأمان)، وملفات compose/config. اختبر الاستعادة دوريًا.

**استعادة (مبدأ عام):** أعد إنشاء البيئة، استعد volumes/DB dumps، شغّل الحاويات، تحقق من تسجيل الدخول والبيانات. وثّق الخطوات الفعلية لبيئتك.
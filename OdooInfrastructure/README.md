# OdooInfrastructure

بنية تحتية مستقلة داخل هذا المجلد لتشغيل **Odoo 17** و**Odoo 19** خلف **Traefik** مع **HTTPS** وأسماء دومينات (بدون كتابة منافذ Odoo مثل `:10019`).

> **بيئة العمل الحالية:** Windows بدون Docker CLI متاح (`docker` غير موجود في PATH). تم إنشاء الملفات والتوثيق فقط داخل `OdooInfrastructure/`. اختبارات Docker الفعلية (compose config / up / health / SSL) **لم تُنفَّذ** على هذا الجهاز؛ يجب تنفيذها على خادم Ubuntu المستهدف. انظر `IMPLEMENTATION_REPORT.md`.

## الهدف

| الخدمة | الدومين | الوصول |
|---|---|---|
| Odoo 17 | `https://odoo17.devops-odoo.com` | عبر Traefik فقط |
| Odoo 19 | `https://odoo19.devops-odoo.com` | عبر Traefik فقط |
| Portainer (موثّق) | `https://portainer.devops-odoo.com` | يتطلب إضافة خدمة/labels؛ غير مُنشأة كـ compose هنا |
| pgAdmin (موثّق) | `https://pgadmin.devops-odoo.com` | يتطلب إضافة خدمة/labels؛ غير مُنشأة كـ compose هنا |

PostgreSQL لكل نسخة **داخلي فقط** على شبكة Docker الخاصة بالنسخة ولا يُنشر منفذ.

## هيكل المجلد

```text
OdooInfrastructure/
├── .env.example                 # قالب متغيرات البيئة (انسخه إلى .env)
├── .gitignore                   # يستبعد .env و acme.json والبيانات الحساسة
├── docker-compose.traefik.yml   # Traefik (نقطة الدخول 80/443)
├── traefik/
│   ├── dynamic/middlewares.yml  # إعادة توجيه HTTP→HTTPS، ترويسات أمان
│   ├── acme/                    # تخزين شهادات ACME (acme.json، chmod 600)
│   └── certs/                   # شهادات محلية اختيارية
├── odoo17/
│   ├── docker-compose.yml       # Odoo 17 + PostgreSQL 16 (بدون نشر منافذ)
│   ├── entrypoint.sh            # حقن الإعداد من البيئة + انتظار DB
│   ├── config/odoo.conf         # قالب إعداد Odoo 17
│   └── addons/                  # إضافات مخصصة
├── odoo19/
│   ├── docker-compose.yml       # Odoo 19 + PostgreSQL 18 (بدون نشر منافذ)
│   ├── entrypoint.sh
│   ├── config/odoo.conf
│   └── addons/
├── scripts/
│   ├── validate.sh              # فحص compose config (على خادم Docker)
│   ├── status.sh                # حالة الحاويات/الشبكات/volumes
│   └── backup.sh                # مثال نسخ احتياطي (pg_dump + filestore)
├── docs/
│   ├── DNS.md                   # Cloudflare / DNS داخلي (LAN)
│   ├── SSL.md                   # Let's Encrypt / DNS challenge
│   ├── TRAEFIK.md               # Labels، Host rules، الشبكات
│   └── OPERATIONS.md            # تشغيل/إيقاف/تحديث/سجلات
└── IMPLEMENTATION_REPORT.md     # تقرير التنفيذ والاختبارات
```

## الإصدارات (مستخرجة من المشاريع الموجودة)

| المكوّن | الإصدار/الصورة | المصدر |
|---|---|---|
| Odoo 17 | `odoo:17` | `InstallingOdoo17-Docker-Deployment` |
| PostgreSQL لـ Odoo 17 | `postgres:16` | `InstallingOdoo17-Docker-Deployment` |
| Odoo 19 | `odoo:19` | `InstallingOdoo19-Docker-Deployment` (المحدّث محليًا) |
| PostgreSQL لـ Odoo 19 | `postgres:18` | `InstallingOdoo19-Docker-Deployment` |
| Traefik | `traefik:v3.6.1` | نمط `InstallingTraefik-Docker-Deployment/docker-compose.yml` |

## التشغيل على Ubuntu (بعد النقل إلى السيرفر)

يفضّل المسار: `/opt/OdooInfrastructure`

```bash
sudo mkdir -p /opt/OdooInfrastructure
sudo cp -a . /opt/OdooInfrastructure/   # من داخل مجلد OdooInfrastructure
cd /opt/OdooInfrastructure

cp .env.example .env
chmod 600 .env
nano .env   # ضع كلمات مرور قوية، CF_DNS_API_TOKEN، LETSENCRYPT_EMAIL، الدومينات

mkdir -p traefik/acme traefik/dynamic traefik/certs
touch traefik/acme/acme.json
chmod 600 traefik/acme/acme.json

docker network create proxy || true

# 1) Traefik
docker compose -f docker-compose.traefik.yml up -d

# 2) Odoo 17
docker compose --env-file .env -f odoo17/docker-compose.yml up -d

# 3) Odoo 19
docker compose --env-file .env -f odoo19/docker-compose.yml up -d
```

## أوامر Docker Compose الأساسية

| الغرض | الأمر (نفّذه من `/opt/OdooInfrastructure` أو المسار المناسب) |
|---|---|
| التحقق من صحة Traefik compose | `docker compose -f docker-compose.traefik.yml config` |
| تشغيل Traefik | `docker compose -f docker-compose.traefik.yml up -d` |
| سجلات Traefik | `docker compose -f docker-compose.traefik.yml logs -f traefik` |
| تشغيل Odoo 17 | `docker compose --env-file .env -f odoo17/docker-compose.yml up -d` |
| تشغيل Odoo 19 | `docker compose --env-file .env -f odoo19/docker-compose.yml up -d` |
| حالة الحاويات | `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'` |
| فحص شبكة proxy | `docker network inspect proxy` |
| إيقاف Odoo 17 (يحافظ على البيانات) | `docker compose --env-file .env -f odoo17/docker-compose.yml down` |
| إيقاف Traefik | `docker compose -f docker-compose.traefik.yml down` |

> **تحذير:** لا تستخدم `down -v` إلا إذا كنت تقصد حذف volumes والبيانات.

## الأمان والبيانات

- الأسرار في `.env` فقط؛ لا تضع كلمات مرور حقيقية في التوثيق أو compose.
- PostgreSQL غير منشور للمضيف/الإنترنت.
- Odoo يُنشر عبر Traefik على 80/443 فقط (وضع الـ compose المرفق لا يعرّف `ports:` لـ Odoo/DB).
- لوحة تحكم Traefik API/Dashboard غير منشورة عبر port mapping؛ الوصول الآمن يكون عبر SSH tunnel عند الحاجة.
- بيانات Odoo/DB على named volumes (`odoo17_db_data`, `odoo17_filestore`, `odoo19_db_data`, `odoo19_filestore`).

راجع `docs/` و`IMPLEMENTATION_REPORT.md` للتفاصيل والنتائج الفعلية.
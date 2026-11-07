# أوامر تثبيت Traefik باستخدام Docker Compose (Ubuntu/Linux)

هذا الدليل يركّز على تثبيت Traefik تحت المسار القياسي **`/opt`** على خادم
Ubuntu/Linux، مع إعداد Docker Compose وملفات ACME والصلاحيات.

> راجع ملف [`docker-compose.yml`](docker-compose.yml) قبل التشغيل: قد يحتوي على
> خدمات إضافية غير Traefik. انشر فقط الخدمات التي تحتاجها، واستبدل النطاقات
> والأسرار التجريبية.

## 1. المتطلبات

- Ubuntu 22.04/24.04 (أو توزيعة Linux مناسبة).
- Docker Engine وDocker Compose v2.
- أسماء نطاق (DNS) تشير إلى الخادم إذا كنت ستستخدم HTTPS عبر Let's Encrypt/ACME.
- توفر المنافذ `80` و`443`. تجنّب نشر منفذ لوحة تحكم Traefik `8080` للعامة دون حماية.

تحقق:

```bash
sudo apt-get update
docker --version
docker compose version
sudo ss -tulpn | grep -E ':80|:443|:8080' || true
```

## 2. التثبيت تحت `/opt` (المسار الموصى به)

المسار الموصى به:

```text
/opt/traefik
```

أنشئ المسار وانسخ/استنسخ ملفات النشر إليه:

```bash
# إنشاء مجلد النشر تحت /opt
sudo mkdir -p /opt/traefik
sudo chown "$USER":"$USER" /opt/traefik

# استنساخ المستودع مباشرة إلى /opt/traefik
git clone https://github.com/abdalazeim/InstallingTraefik-Docker-Deployment.git /opt/traefik

# بديل: إذا كانت الملفات موجودة محليًا، انسخها إلى /opt/traefik
# sudo rsync -a --exclude '.git' ./ /opt/traefik/
# sudo chown -R "$USER":"$USER" /opt/traefik

cd /opt/traefik
```

لماذا `/opt`؟

- مسار نظامي مناسب للتطبيقات والخدمات الإضافية.
- يسهل النسخ الاحتياطي والمراقبة والتوثيق التشغيلي.
- يفصل ملفات النشر عن مجلدات المستخدمين الشخصية.

## 3. إعداد ملف البيئة `.env`

```bash
cd /opt/traefik
cp .env.example .env
chmod 600 .env
nano .env   # أو vim
```

عدّل القيم الحقيقية (رموز DNS/Cloudflare أو مزود ACME، البريد، النطاقات، كلمات
المرور إن وُجدت). لا ترفع `.env` إلى Git.

## 4. إعداد مجلدات Traefik وملف ACME

```bash
cd /opt/traefik
mkdir -p traefik/certs traefik/dynamic shared
touch traefik/acme.json
chmod 600 traefik/acme.json
chmod 700 traefik
```

مهم: ملف `acme.json` يجب أن تكون صلاحياته `600`، وإلا قد يرفض Traefik استخدامه.

تحقق:

```bash
ls -ld /opt/traefik /opt/traefik/traefik
ls -l /opt/traefik/traefik/acme.json
```

## 5. إنشاء شبكة Docker المشتركة

إذا كانت خدماتك تستخدم شبكة خارجية باسم `proxy` (شائع مع Traefik):

```bash
docker network create proxy || true
docker network ls | grep proxy
```

## 6. مراجعة `docker-compose.yml` ثم التشغيل

قبل التشغيل، راجع [`docker-compose.yml`](docker-compose.yml):

- احذف/عطّل الخدمات غير المطلوبة.
- تأكد من صحة النطاقات (`Host(...)`) والبريد وإعدادات ACME.
- لا تترك لوحة التحكم/واجهة API مكشوفة للعامة بدون مصادقة.
- تأكد أن المسارات تشير إلى `/opt/traefik/...` عند الحاجة.

تشغيل:

```bash
cd /opt/traefik
docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f traefik
```

## 7. أوامر التشغيل اليومية (من `/opt/traefik`)

```bash
cd /opt/traefik

# الحالة
docker compose ps

# السجلات
docker compose logs -f traefik
docker compose logs --tail=200 traefik

# تحديث الصور وإعادة الإنشاء
docker compose pull
docker compose up -d

# إعادة تشغيل Traefik
docker compose restart traefik

# إيقاف مع الحفاظ على البيانات/الملفات
docker compose down
```

## 8. النسخ الاحتياطي

احتفظ بنسخة آمنة من:

- `/opt/traefik/.env`
- `/opt/traefik/docker-compose.yml`
- `/opt/traefik/traefik/acme.json`
- مجلدات `traefik/dynamic/` و`traefik/certs/` و`shared/` حسب الاستخدام

لا تضع الأسرار أو `acme.json` في Git.

## 9. استكشاف الأخطاء

| المشكلة | الفحص |
|---|---|
| المنفذ 80/443 مستخدم | `sudo ss -tulpn \| grep -E ':80|:443'` |
| لم تُصدر الشهادة | سجلات Traefik، DNS، صلاحيات رمز المزود، صلاحيات `acme.json` |
| الخدمة لا تظهر عبر Traefik | الشبكة `proxy`، labels، اسم النطاق، منفذ الخدمة الداخلي |
| خطأ صلاحيات | `chmod 600 /opt/traefik/.env /opt/traefik/traefik/acme.json` |

أوامر مفيدة:

```bash
cd /opt/traefik
docker compose config
docker network inspect proxy
docker compose logs --tail=200 traefik
```

## 10. قائمة أمان سريعة

- ثبّت تحت `/opt/traefik`.
- استخدم `chmod 600` للأسرار و`acme.json`.
- لا تنشر لوحة تحكم Traefik بدون حماية.
- راكب Docker socket بوضع القراءة فقط إن أمكن: `/var/run/docker.sock:ro`.
- حدّث الصور وخادم Docker بانتظام.
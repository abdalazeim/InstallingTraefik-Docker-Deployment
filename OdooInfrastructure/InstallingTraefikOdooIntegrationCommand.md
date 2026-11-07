# أوامر تكامل Odoo مع Traefik (إخفاء المنافذ + HTTPS + دومينات)

يُنفَّذ هذا التكامل **بعد نجاح تثبيت Traefik** (يفضّل تحت `/opt/traefik`).
الهدف: الوصول إلى Odoo عبر HTTPS بالدومين فقط، بدون كشف منافذ Odoo على المضيف.

**أمثلة:**
- `http://IP:10019` / `http://localhost:10019` → **`https://odoo19.devops-odoo.com`**
- Odoo 17 → **`https://odoo17.devops-odoo.com`**

> ملاحظة: Traefik في هذا المستودع يستخدم مُحلل الشهادات باسم **`le`**
> (`--certificatesresolvers.le...`). لذلك اضبط `CERTSRESOLVER=le` في `.env` لكل Odoo
> (إلا إذا غيّرت اسم المُحلل في Traefik).

## 0) المتطلبات المسبقة

```bash
# Traefik يعمل
cd /opt/traefik
docker compose ps

# شبكة proxy موجودة (نفس شبكة Traefik)
docker network create proxy || true
docker network inspect proxy >/dev/null
```

DNS: سجلات A/AAAA لكل دومين تشير إلى IP خادم Traefik.

## 1) تكامل Odoo 19 → `https://odoo19.devops-odoo.com`

انتقل إلى مجلد نشر Odoo 19 (عدّل المسار حسب مكان مشروعك):

```bash
cd /path/to/InstallingOdoo19-Docker-Deployment
```

أوقف وضع المنافذ المباشر إن كان يعمل (يحافظ على البيانات):

```bash
docker compose down
```

جهّز `.env` (انسخ المثال إن لم يوجد، ثم عدّل القيم الحساسة والدومين):

```bash
cp .env.example .env
chmod 600 .env
```

اضبط/تأكد من القيم التالية في `.env` (قيم تجريبية للأسرار — غيّرها):

```dotenv
# Traefik / domain integration
ODOO_DOMAIN=odoo19.devops-odoo.com
DOCKER_PROXY_NETWORK=proxy
CERTSRESOLVER=le
```

شغّل وضع Traefik (بدون نشر منافذ Odoo/DB):

```bash
docker compose -f docker-compose.traefik.yml up -d
docker compose -f docker-compose.traefik.yml ps
```

تحقق من السجلات:

```bash
docker compose -f docker-compose.traefik.yml logs --tail=100 odoo19
cd /opt/traefik && docker compose logs --tail=100 traefik
```

النتيجة المتوقعة: **https://odoo19.devops-odoo.com** يعمل، و`/websocket` يعمل عبر Traefik.

## 2) تكامل Odoo 17 → `https://odoo17.devops-odoo.com`

```bash
cd /path/to/InstallingOdoo17-Docker-Deployment
docker compose down   # إن كان وضع المنافذ المباشر يعمل

cp .env.example .env
chmod 600 .env
```

في `.env`:

```dotenv
ODOO_DOMAIN=odoo17.devops-odoo.com
DOCKER_PROXY_NETWORK=proxy
CERTSRESOLVER=le
```

تشغيل:

```bash
docker compose -f docker-compose.traefik.yml up -d
docker compose -f docker-compose.traefik.yml ps
docker compose -f docker-compose.traefik.yml logs --tail=100 odoo17
```

النتيجة المتوقعة: **https://odoo17.devops-odoo.com**

## 3) إخفاء المنافذ (Firewall / Security Group)

عند الاعتماد على Traefik فقط، اسمح علنًا بالمنافذ الضرورية:

- `80/tcp` (HTTP → redirect)
- `443/tcp` (HTTPS)
- منفذ SSH الذي تستخدمه (مثلاً `22/tcp`) من مصادر موثوقة

**لا تفتح علنًا** منافذ Odoo المباشرة مثل `10017,20017,10019,20019` عند استخدام وضع Traefik.
(استخدم UFW/firewalld/Security Group حسب بيئتك.)

## 4) إعادة التنفيذ (Repeatable)

يمكن تكرار التكامل لأي نسخة Odoo إضافية:
1. انسخ نمط `.env.traefik.example` المناسب.
2. اختر دومينًا فريدًا و`ODOO_DOMAIN` فريدًا.
3. تأكد من أسماء حاويات/شبكة داخلية فريدة لكل نسخة (خاصة عند تعدد النسخ).
4. شغّل `docker compose -f docker-compose.traefik.yml up -d` من مجلد تلك النسخة.

## 5) استكشاف الأخطاء

| المشكلة | الإجراء |
|---|---|
| شهادة لا تُصدر | تحقق DNS، سجلات Traefik، `CERTSRESOLVER=le`، صلاحيات ACME/token |
| 404/Bad Gateway | الحاوية ليست على شبكة `proxy`، أو labels خاطئة، أو Odoo غير جاهز |
| Websocket/Live chat | تأكد من route `/websocket` إلى منفذ `8072` (موجود في compose Traefik) |
| لا يزال المنفذ القديم يعمل | تأكد أنك شغّلت `docker-compose.traefik.yml` وأوقفت compose المنافذ المباشر |

أوامر مفيدة:

```bash
docker network inspect proxy
cd /opt/traefik && docker compose logs --tail=200 traefik
```
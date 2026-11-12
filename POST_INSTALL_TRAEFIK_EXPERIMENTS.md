# تجارب ما بعد تثبيت Traefik (الناجحة)

يوثّق هذا الملف التجارب الناجحة التي تمت **بعد تثبيت Traefik** ضمن هذا المشروع، استناداً إلى المحادثة السابقة وسجلات التنفيذ والملفات الموجودة في المستودع.

لكل تجربة: **المشكلة**، **الشرح**، **الحل**، و**الأوامر/التعديلات المستخدمة**.

> ملاحظة: نُفذت بعض الأوامر على سيرفر Ubuntu/Linux (غالباً تحت `/opt/traefik`) بصلاحيات `sudo`، بينما تم إعداد/تعديل بعض الملفات محلياً داخل المستودع.

---

## 1) تنظيف بيئة Docker والبدء من جديد

### المشكلة
- فشل أو تعارض عند تشغيل `docker compose up -d` بسبب حاويات/شبكات قديمة من محاولات سابقة.
- ظهور تعارضات أسماء (مثل حاوية `portainer` موجودة مسبقاً) ونتائج غير متوقعة.

### الشرح
عند تكرار التجارب وتغيير ملفات Compose، قد تبقى حاويات أو شبكات قديمة تسبب تعارضاً. التنظيف يضمن بيئة واضحة قبل إعادة التشغيل.

### الحل
إيقاف وإزالة الحاويات القديمة، إزالة الشبكة القديمة، ثم إعادة إنشاء الشبكة وتشغيل الخدمات المطلوبة.

### الأوامر المستخدمة
```bash
# إيقاف جميع الحاويات
sudo docker stop $(sudo docker ps -q) 2>/dev/null

# إزالة جميع الحاويات
sudo docker rm $(sudo docker ps -aq) 2>/dev/null

# إزالة الشبكة القديمة (إن وجدت)
sudo docker network rm proxy 2>/dev/null

# إعادة إنشاء الشبكة
sudo docker network create proxy
```

### النتيجة
تم تجهيز بيئة نظيفة لإعادة تشغيل Traefik والخدمات المرتبطة بدون تعارضات أسماء/شبكات قديمة.

---

## 2) تعارض اسم حاوية Portainer الموجودة مسبقاً

### المشكلة
ظهور الخطأ أثناء التشغيل:
```text
Conflict. The container name "/portainer" is already in use by container ...
```

### الشرح
Docker لا يسمح بإنشاء حاوية جديدة بنفس اسم حاوية موجودة (حتى لو كانت متوقفة)، وهذا يحدث كثيراً عند إعادة التجارب بملفات Compose مختلفة.

### الحل
إيقاف/إزالة التعارض ثم إعادة التشغيل.

### الأوامر المستخدمة
```bash
# إيقاف مكدس compose الحالي (إن لزم)
sudo docker compose down

# إزالة الحاوية المتعارضة
sudo docker rm -f portainer

# إعادة التشغيل
sudo docker compose up -d
# أو عند استخدام ملف minimal
sudo docker compose -f docker-compose.minimal.yml up -d
```

### النتيجة
تمت إزالة التعارض وأصبح بالإمكان إنشاء/تشغيل خدمة Portainer بنجاح.

---

## 3) فشل حاوية `7dtd` (و`7dtde`) بسبب خطأ bind mount

### المشكلة
عند تشغيل `docker-compose.yml` الكبير فشلت حاوية `7dtd` بخطأ mount:
```text
error mounting "/home/alex/7dtd-shared/server_backup.sh" to rootfs at "/home/sdtdserver/scripts/server_backup.sh": ... not a directory: Are you trying to mount a directory onto a file (or vice-versa)?
```
وفشل `7dtd` أدى إلى مقاطعة إنشاء/تشغيل خدمات أخرى في نفس الأمر.

### الشرح
المسار داخل صورة `vinanrra/7dtd-server` (`/home/sdtdserver/scripts/server_backup.sh`) لم يكن متوافقاً مع عملية bind mount للملف من المضيف، مما تسبب في فشل إنشاء الحاوية.

### الحل
تعطيل (تعليق) سطر الـ volume الخاص بـ `server_backup.sh` في خدمتي `7dtd` و`7dtde` داخل `docker-compose.yml`.

### التعديل المطبق (في `docker-compose.yml`)
```yaml
# 7dtd
#    - /home/alex/7dtd-shared/server_backup.sh:/home/sdtdserver/scripts/server_backup.sh

# 7dtde
#    - /home/alex/7dtd-shared/server_backup.sh:/home/sdtdserver/scripts/server_backup.sh
```

### أوامر التشغيل/التحقق
```bash
sudo docker compose up -d
sudo docker compose ps
```

### النتيجة
تم تجاوز خطأ mount الخاص بـ `7dtd/7dtde` ومنع تعطل بقية الخدمات بسبب هذا التعارض.

---

## 4) تعارض المنفذ `25565` بين `minecraft` و`pufferpanel`

### المشكلة
فشل إعداد الشبكة/ربط المنافذ لخدمة `pufferpanel` مع الخطأ:
```text
Bind for 0.0.0.0:25565 failed: port is already allocated
```

### الشرح
- `pufferpanel` ينشر نطاق المنافذ `25550-25599`
- `minecraft` كان ينشر `25565:25565`
- النتيجة تعارض مباشر على المنفذ `25565`

### الحل
تغيير منفذ المضيف لخدمة `minecraft` إلى منفذ غير متعارض مع إبقاء منفذ الحاوية الداخلي `25565`.

### التعديل المطبق (في `docker-compose.yml`)
```yaml
# قبل
- '25565:25565'

# بعد
- '25570:25565'
```

### أوامر التشغيل
```bash
sudo docker compose up -d
```

### النتيجة
تمت إزالة تعارض المنفذ بين `minecraft` و`pufferpanel`.

---

## 5) فشل حاوية `ww` بسبب mount ملف `httpd.conf`

### المشكلة
ظهور خطأ عند تشغيل خدمة `ww`:
```text
error mounting "/root/ww/httpd.conf" to rootfs at "/usr/local/apache2/conf/httpd.conf": ... not a directory: Are you trying to mount a directory onto a file (or vice-versa)?
```

### الشرح
نفس نمط مشكلة mount ملف/مسار غير متوافق أثناء إنشاء الحاوية، مما أدى لفشل خدمة `ww`.

### الحل
تعطيل (تعليق) سطر mount الخاص بـ `httpd.conf` في خدمة `ww`.

### التعديل المطبق (في `docker-compose.yml`)
```yaml
#      - /root/ww/httpd.conf:/usr/local/apache2/conf/httpd.conf
```

### النتيجة
تمت إزالة سبب فشل الحاوية `ww` الناتج عن mount الملف.

---

## 6) إصلاح أخطاء YAML/B Compose في `docker-compose.yml` بعد التعديلات

### المشكلة
بعد التعديلات اليدوية ظهرت أخطاء مثل:
```text
go-yaml load error in parser ... did not find expected key
validating ... networks.proxy additional properties 'volumes' not allowed
```

### الشرح
أثناء تعديل ملف Compose الكبير حدثت مشاكل بنية/محاذاة، من أهمها:
- محاذاة خاطئة لتعليق/تعريف خدمة `minecraft` تحت `services`.
- بقاء/موضع خاطئ لمفتاح `volumes:` في خدمة `ww` بعد تعليق mount.
- وضع قسم `volumes:` (top-level) بالخطأ داخل قسم `networks:`، مما جعله خاصية غير مسموحة تحت `networks.proxy`.

### الحل
- تصحيح محاذاة خدمة `minecraft` وتعليقها لتكون ضمن `services` بشكل صحيح.
- تصحيح بنية خدمة `ww` بعد تعطيل mount الملف.
- نقل قسم `volumes:` top-level إلى مكانه الصحيح خارج `networks`.

### مثال على البنية الصحيحة (مختصر)
```yaml
networks:
  proxy:
    external: true

volumes:
  traefik_certs:
  traefik_acme:
  traefik_logs:
```

### أوامر الفحص/التشغيل المستخدمة
```bash
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps

# فحص صياغة YAML أثناء الإصلاح (محلياً عند توفر Python)
# python -c "import yaml; yaml.safe_load(open('docker-compose.yml', encoding='utf-8')); print('YAML OK')"
```

### النتيجة
أصبح ملف `docker-compose.yml` صالحاً من ناحية الصياغة والبنية بعد التصحيحات، وتم تجاوز الأخطاء التي كانت تمنع تشغيل Compose.

---

## 7) تشغيل Traefik على المنفذ 80 (Minimal) بنجاح

### المشكلة
الهدف الأول كان تشغيل Traefik على المنفذ 80 بنجاح بأبسط إعداد ممكن، بدون تشغيل/سحب جميع الخدمات والصور غير الضرورية الموجودة في `docker-compose.yml` الكبير.

### الشرح
تشغيل إعداد minimal (Traefik + خدمة اختبار) يسهّل التأكد من:
- عمل Traefik على المنفذ 80
- عمل Docker provider والـ routing
- صحة الشبكة والـ labels
- إمكانية الانتقال لاحقاً لإعدادات أكبر (مثل OdooInfrastructure)

### الحل
استخدام إعداد مبسّط يحتوي على `traefik` و`whoami` مع نشر `80:80` وتفعيل dashboard/routers المناسبة للاختبار المحلي.

### الأوامر المستخدمة (نموذج)
```bash
# إنشاء الشبكة إذا لم تكن موجودة
docker network create proxy 2>/dev/null || true

# تشغيل الإعداد
docker compose up -d

# التحقق
docker compose ps
curl -I http://localhost
curl http://localhost
```

### النتيجة
تم تشغيل Traefik بنجاح على المنفذ 80، مع إمكانية اختبار التوجيه عبر خدمة `whoami` ولوحة تحكم Traefik (حسب إعداد الـ Host).

---

## 8) استخدام Hostname مخصص `odoo-com` بدلاً من `localhost`

### المشكلة
الحاجة للوصول إلى الخدمات عبر اسم مضيف مخصص (`odoo-com`) بدل `localhost`.

### الشرح
Traefik يوجّه الطلبات اعتماداً على ترويسة `Host`. لذلك يجب:
1. حل الاسم `odoo-com` إلى عنوان السيرفر/الجهاز (محلياً `127.0.0.1`).
2. تعديل قواعد الراوتر (`Host(...)`) في labels لتشمل الاسم المطلوب.

### الحل
- إضافة سجل hosts على السيرفر.
- تحديث قواعد Traefik/Whoami لاستخدام `odoo-com` (وأسماء فرعية مثل `whoami.odoo-com`, `traefik.odoo-com`).

### الأوامر/التعديلات المستخدمة
```bash
# إضافة السجل إلى /etc/hosts
echo "127.0.0.1 odoo-com" | sudo tee -a /etc/hosts

# التحقق
cat /etc/hosts | grep odoo-com
```

أمثلة على قواعد الراوتر المستخدمة (ضمن Compose):
```yaml
- "traefik.http.routers.traefik.rule=Host(`traefik.odoo-com`) || Host(`odoo-com`)"
- "traefik.http.routers.whoami.rule=Host(`whoami.odoo-com`) || Host(`odoo-com`)"
```

### أوامر التحقق
```bash
docker compose up -d
curl -I http://odoo-com
curl http://whoami.odoo-com
```

### النتيجة
تم الوصول إلى الخدمات عبر `odoo-com` بنجاح بعد ضبط `/etc/hosts` وقواعد التوجيه.

---

## 9) إنشاء تشغيل Minimal منفصل (Traefik + Whoami + Portainer) مع ملف شرح

### المشكلة
- `docker-compose.yml` الرئيسي يحتوي خدمات وصور كثيرة غير ضرورية لمرحلة التحقق.
- الحاجة لتشغيل حزمة صغيرة مستقلة (Traefik + Whoami + Portainer) دون التأثير على الملف الأصلي.
- الحاجة إلى توثيق خطوات التثبيت/التشغيل لهذا الإعداد.

### الشرح
فصل الإعداد minimal في ملف Compose مستقل مع ملف شرح installation يسهل إعادة التجربة، العزل، والتشخيص، ثم الانتقال لاحقاً إلى `OdooInfrastructure`.

### الحل
تم إنشاء:
- `docker-compose.minimal.yml` (Traefik + Whoami + Portainer)
- `INSTALLATION_MINIMAL.md` (شرح التثبيت والتشغيل والتحقق)

كما تم اعتماد نهج التشغيل عبر تحديد الملف:
```bash
docker compose -f docker-compose.minimal.yml up -d
```

### أبرز ما تم ضبطه في `docker-compose.minimal.yml`
- شبكة خارجية باسم `traefik_proxy`:
```yaml
networks:
  proxy:
    external: true
    name: traefik_proxy
```
- ربط Docker provider بالشبكة الصحيحة:
```yaml
- "--providers.docker.network=traefik_proxy"
```
- خدمات:
  - `traefik` (لوحة تحكم + entrypoints 80/443)
  - `whoami` (خدمة اختبار)
  - `portainer` (إدارة Docker عبر Traefik)
- قواعد Host للتوجيه (من الإعداد النهائي):
  - `odoo-com`, `traefik.odoo-com`, `whoami.odoo-com`, `portainer.odoo-com` (مع دعم `localhost` وIP محلي في بعض القواعد)

### الأوامر المستخدمة للتشغيل/التحقق
```bash
# (اختياري) استعادة الملف الأصلي إذا تم تعديله
git checkout docker-compose.yml

# تشغيل الإعداد minimal
docker compose -f docker-compose.minimal.yml up -d

# التحقق
docker compose -f docker-compose.minimal.yml ps
curl -I http://odoo-com
curl http://whoami.odoo-com
curl http://portainer.odoo-com
```

### ملاحظات عملية ظهرت وتم حلها
- **صلاحيات Docker** (`permission denied ... /var/run/docker.sock`):
  - الحل: إضافة المستخدم لمجموعة `docker` أو استخدام `sudo`.
  ```bash
  sudo usermod -aG docker odoo
  newgrp docker
  # أو تشغيل الأوامر بـ sudo
  sudo docker compose -f docker-compose.minimal.yml up -d
  ```
- **تكرار إضافة سجل hosts**:
  - تكرار الأمر قد يضيف السطر أكثر من مرة في `/etc/hosts`؛ هذا لا يعطل العمل عادةً لكن يُفضّل تنظيف التكرار لاحقاً.

### عناوين التحقق النهائية (المستخدمة بعد النجاح)
```text
http://portainer.odoo-com  → Portainer UI
http://whoami.odoo-com     → Whoami info
http://odoo-com/dashboard/ → Traefik Dashboard
```
(كما هو موثق في `777.txt`)

### النتيجة
تم تجهيز وتشغيل إعداد Minimal منفصل وموثّق بنجاح بعد تثبيت Traefik، مع عزل التجارب عن `docker-compose.yml` الرئيسي.

---

## 10) اختبار `whoami` كوسيلة تحقق سريعة (ناجحة ومفيدة)

### المشكلة
الحاجة إلى اختبار سريع يؤكد أن سلسلة التوجيه تعمل بالكامل بعد التثبيت/التعديلات.

### الشرح
خدمة `whoami` تُرجع معلومات عن الطلب والحاوية، لذا نجاح الاستجابة يعني غالباً أن:
- اسم المضيف (DNS/hosts) صحيح
- Traefik يستقبل الطلب على المنفذ الصحيح
- قاعدة الراوتر (`Host(...)`) مطابقة
- Traefik يصل إلى الخدمة الخلفية عبر الشبكة الصحيحة

### الأمر المستخدم
```bash
curl http://whoami.odoo-com
```

### النتيجة المتوقعة
استجابة تحتوي معلومات مثل `Hostname` و`IP` وغيرها، مما يؤكد أن التوجيه يعمل end-to-end.

---

## الملفات المرتبطة بهذه التجارب

- `docker-compose.yml` — ملف Compose رئيسي تم فيه معالجة مشاكل (mounts، تعارض منافذ، أخطاء YAML/بنية) أثناء التجارب.
- `docker-compose.minimal.yml` — إعداد minimal ناجح (Traefik + Whoami + Portainer).
- `INSTALLATION_MINIMAL.md` — توثيق خطوات التثبيت/التشغيل للإعداد minimal.
- `traefik/dynamic/middlewares.yml` — إعدادات dynamic file provider (middlewares).
- `777.txt` — عناوين التحقق النهائية المستخدمة.
- `POST_INSTALL_TRAEFIK_EXPERIMENTS.md` — هذا الملف (توثيق التجارب الناجحة بعد التثبيت).  

# Traefik: الشبكات، Labels، Host Rules

## الشبكات

| الشبكة | النوع | الغرض |
|---|---|---|
| `proxy` | external (تنشأ مسبقًا أو بواسطة Traefik compose) | شبكة مشتركة بين Traefik وخدمات الويب (Odoo، وخدمات مستقبلية مثل Portainer/pgAdmin) |
| `odoo17_internal` | bridge داخلية لكل stack | اتصال Odoo 17 ↔ PostgreSQL 17 فقط؛ DB غير متصل بـ `proxy` |
| `odoo19_internal` | bridge داخلية لكل stack | اتصال Odoo 19 ↔ PostgreSQL 19 فقط |

PostgreSQL **لا** ينضم إلى `proxy`، ولا يوجد `ports:` له.

## Docker Provider

Traefik يكتشف الحاويات عبر:
- `--providers.docker=true`
- `--providers.docker.exposedbydefault=false` (يجب وضع `traefik.enable=true` صراحة)
- `--providers.docker.network=proxy`

## Host Rules وLabels (Odoo)

لكل نسخة:
- **Web:** `Host(\`odooXX.devops-odoo.com\`)` → خدمة Odoo منفذ `8069`
- **WebSocket/longpolling:** نفس Host + `PathPrefix(\`/websocket\`)` → منفذ `8072`، بأولوية أعلى
- `entrypoints=websecure`, `tls=true`, `tls.certresolver=le` (أو قيمة `CERTSRESOLVER`)
- HTTP→HTTPS على مستوى entrypoint/global redirect في Traefik

## إضافة Portainer / pgAdmin (نمط موثّق)

عند إضافة الخدمة لاحقًا (compose منفصل أو ملحق)، اربطها بـ `proxy` وضع labels مشابهة:
- `traefik.enable=true`
- `traefik.http.routers.portainer.rule=Host(\`portainer.devops-odoo.com\`)`
- `traefik.http.routers.portainer.entrypoints=websecure`
- `traefik.http.routers.portainer.tls.certresolver=le`
- `traefik.http.services.portainer.loadbalancer.server.port=<internal-port>`

احمِ Portainer/pgAdmin بالمصادقة وقيود الشبكة؛ لا تنشر منافذ إدارة حساسة للعامة.

## Dashboard

`api.insecure=false` ولا يوجد port mapping لـ 8080. للوصول المؤقت الآمن استخدم SSH tunnel إلى الخادم ثم افتح API محليًا حسب إعداداتك، أو أضف router محمي بمصادقة قوية (خارج النطاق الافتراضي هنا).
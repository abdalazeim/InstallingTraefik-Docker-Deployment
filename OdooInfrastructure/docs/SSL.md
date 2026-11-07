# SSL / HTTPS / Let's Encrypt

## الإعداد في هذا المشروع

- Traefik يستمع على `80` (HTTP) و`443` (HTTPS).
- إعادة توجيه HTTP → HTTPS مفعّلة على entrypoint `web` وفي `traefik/dynamic/middlewares.yml`.
- Resolver ACME باسم **`le`** (متغير `CERTSRESOLVER=le` افتراضيًا).
- يستخدم **DNS challenge** مع مزود **Cloudflare** (`CF_DNS_API_TOKEN`).
- تخزين الشهادات: `./traefik/acme/acme.json` (داخل الحاوية `/acme.json`).

## متطلبات ACME

1. `LETSENCRYPT_EMAIL` بريد صالح.
2. `CF_DNS_API_TOKEN` رمز Cloudflare بصلاحيات DNS المناسبة.
3. DNS للدومينات يشير بشكل صحيح (Cloudflare zone/nameservers حسب إعدادك).
4. `acme.json` موجود وصلاحياته **600** قبل التشغيل:
   ```bash
   touch traefik/acme/acme.json
   chmod 600 traefik/acme/acme.json
   ```

## بدائل (وثّق ما تختاره)

- **HTTP challenge:** أبسط أحيانًا لكنه يتطلب وصولًا عامًا مباشرًا إلى المنفذ 80 للدومين.
- **DNS challenge:** مناسب لـ Cloudflare وبيئات LAN/الوصول المقيد؛ المستخدم هنا.
- **شهادات داخلية/مؤسسية:** استبدل ACME بإعداد certs محلي في `traefik/certs` وdynamic TLS config.

## التحقق

```bash
docker compose -f docker-compose.traefik.yml logs -f traefik | grep -i acme
curl -Iv https://odoo17.devops-odoo.com
curl -Iv https://odoo19.devops-odoo.com
openssl s_client -connect odoo17.devops-odoo.com:443 -servername odoo17.devops-odoo.com </dev/null | openssl x509 -noout -issuer -subject -dates
```

لا تعتبر SSL ناجحًا إلا بعد التحقق الفعلي من الشهادة والسلسلة على الشبكة المستهدفة.
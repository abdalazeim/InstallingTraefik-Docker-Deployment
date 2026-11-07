# DNS والنطاقات (Cloudflare + LAN)

## الدومينات المطلوبة

| الخدمة | الدومين | ملاحظة |
|---|---|---|
| Odoo 17 | `odoo17.devops-odoo.com` | Host rule في Traefik |
| Odoo 19 | `odoo19.devops-odoo.com` | Host rule في Traefik |
| Portainer | `portainer.devops-odoo.com` | موثّق؛ يتطلب نشر خدمة Portainer خلف Traefik بنفس الشبكة/labels |
| pgAdmin | `pgadmin.devops-odoo.com` | موثّق؛ يتطلب نشر خدمة pgAdmin خلف Traefik |

## Cloudflare (وصول عام/خارجي)

1. أنشئ سجل `A` (أو `AAAA`) لكل دومين فرعي يشير إلى IP العام لخادم Traefik.
2. للحصول على شهادة Let's Encrypt عبر **DNS challenge** (مناسب خلف NAT أو عند تقييد HTTP challenge)، أنشئ Cloudflare API Token بصلاحيات تعديل DNS للمنطقة المطلوبة.
3. ضع الرمز في `.env` كـ `CF_DNS_API_TOKEN` (لا تضعه في Git).
4. إذا كان Cloudflare Proxy (السحابة البرتقالية) مفعّلًا، تأكد من توافق إعدادات SSL (Full/Strict حسب إعداد الأصل) وأن Traefik يُصدر/يخدم الشهادة المتوقعة. وثّق الإعداد الفعلي في بيئتك؛ لا تفترض سلوكًا واحدًا لكل شبكة.

## الوصول من شبكة الشركة المحلية (LAN)

Cloudflare وحده **لا يكفي** دائمًا للوصول الداخلي. تحقق من:

- **DNS داخلي (Split-horizon DNS):** اجعل `*.devops-odoo.com` (أو السجلات المطلوبة) تشير إلى **IP الخاص** لخادم Traefik داخل LAN.
- **Hairpin NAT / NAT loopback:** بديل إذا لم يتوفر DNS داخلي وكان الراوتر يدعمه.
- **ملف hosts (للاختبار فقط):** على جهاز عميل:
  ```text
  192.168.x.x  odoo17.devops-odoo.com odoo19.devops-odoo.com portainer.devops-odoo.com pgadmin.devops-odoo.com
  ```
  استبدل `192.168.x.x` بـ IP الفعلي لخادم Traefik.

## التحقق

```bash
# من عميل على الشبكة المستهدفة
nslookup odoo17.devops-odoo.com
nslookup odoo19.devops-odoo.com
curl -Ik https://odoo17.devops-odoo.com
curl -Ik https://odoo19.devops-odoo.com
```

إذا فشل DNS أو أرجع IP خاطئًا، أصلح DNS/Firewall قبل تشخيص Traefik/SSL.
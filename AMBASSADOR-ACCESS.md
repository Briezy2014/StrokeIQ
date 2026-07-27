# SwimIQ ambassadors

## Important: two different jobs

| Link type | What it does | Unique per person? |
|-----------|--------------|--------------------|
| Preview unlock (`?amb=`) | Free 14-day Pro + Elite peek | Optional (shared OK) |
| Commission / 30% (`?via=` + Rewardful) | Credits paid Stripe sales | **Yes — required** |

Named links below include **both** so one URL does preview unlock **and** is ready for Rewardful attribution.

---

## Ruslan

| | |
|--|--|
| **Code** | `AMB-RUSLAN` |
| **Share link (send this)** | https://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan |
| **Rewardful token** | `ruslan` |

Paste to Ruslan:

```
Your SwimIQ ambassador link:
https://swimiqapp.com/?amb=AMB-RUSLAN&via=ruslan

Code if needed: AMB-RUSLAN
(Settings → Plans → Unlock preview)
```

---

## Nyah

| | |
|--|--|
| **Code** | `AMB-NYAH` |
| **Share link (send this)** | https://swimiqapp.com/?amb=AMB-NYAH&via=nyah |
| **Rewardful token** | `nyah` |

Paste to Nyah:

```
Your SwimIQ ambassador link:
https://swimiqapp.com/?amb=AMB-NYAH&via=nyah

Code if needed: AMB-NYAH
(Settings → Plans → Unlock preview)
```

---

## Shared (no commission attribution)

Only use when you do **not** need to know who referred the signup:

- Code: `AMBASSADOR-SWIMIQ`
- Link: https://swimiqapp.com/?amb=AMBASSADOR-SWIMIQ

---

## Coach preview codes (not ambassadors)

| Code | Use |
|------|-----|
| `COACH-EVAL-14` | Standard coach preview |
| `COACH-TRIAL-30` | Legacy coach preview |

---

## Adding a new ambassador later

1. Add them in `swimiq/lib/core/subscription/ambassador_catalog.dart` (name, `AMB-NAME`, slug).
2. Create the same affiliate in Rewardful with token = that slug.
3. Merge, rebuild, upload GoDaddy.
4. Send them `https://swimiqapp.com/?amb=AMB-NAME&via=slug`.

Full deploy + Rewardful steps: **`swimiq/docs/REWARDFUL_AND_DEPLOY.md`**

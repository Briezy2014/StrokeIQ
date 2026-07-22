# Put the REAL Flutter SwimIQ app on swimiqapp.com

**Critical:** Do **NOT** upload the `swimiq/website/` marketing folder to the site root.  
That is the **old brochure**. Coaches need the **Flutter web build** (`build/web` with `main.dart.js`).

| Wrong (old brochure) | Right (real app) |
|----------------------|------------------|
| `swimiq/website/index.html` | `swimiq/build/web/index.html` |
| has `css/site.css` | has **`main.dart.js`** |
| “Coming soon / features” page | **SwimIQ login** screen |

---

## One-click on Kara’s Windows PC

1. Double-click:

   `Desktop\StrokeIQ\PUBLISH-SWIMIQAPP-COM.bat`

2. Wait for the zip (several minutes).

3. GoDaddy → **File Manager** → **`public_html`**

4. Rename old `index.html` → `index-OLD-MARKETING.html` (or delete old site files)

5. Upload **`swimiq\build\swimiq-web-godaddy.zip`**

6. Extract in `public_html` (overwrite)

7. Confirm these exist in `public_html`:
   - `main.dart.js`
   - `flutter_bootstrap.js` or `flutter.js`
   - `SWIMIQ-FLUTTER-BUILD.txt`
   - `.htaccess`

8. Open **https://swimiqapp.com** in **Incognito** → you must see **login**, not the brochure.

---

## How to tell what’s live

| What you see | Meaning |
|--------------|---------|
| Marketing / “Coming soon” / feature cards | Still the old `website/` upload |
| SwimIQ **login** (email/password) | Flutter app is live ✅ |
| Blank white page | Incomplete upload — missing `canvaskit` / `main.dart.js` |

---

## After every app update you want coaches to see

1. `PUBLISH-SWIMIQAPP-COM.bat` again  
2. Re-upload / extract the new zip into `public_html`

---

## Legal pages

The publish script also copies `privacy.html`, `terms.html`, `ai.html` into the Flutter build so  
`https://swimiqapp.com/privacy` still works.

The `swimiq/website/` folder remains for legal sync / marketing drafts only — **not** the homepage.

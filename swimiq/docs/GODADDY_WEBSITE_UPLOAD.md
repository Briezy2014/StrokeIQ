# GoDaddy step-by-step for Kara (swimiqapp.com)

**Read this first:** GoDaddy does **NOT** install the Flutter phone app.  
GoDaddy only hosts your **website** (the pages people see in Safari/Chrome).

| What | Where it lives |
|------|----------------|
| **Phone app** (Flutter) | iPhone via **TestFlight** later — not GoDaddy |
| **Website** (features, updates, privacy) | **GoDaddy** — files in `swimiq/website/` |

---

## PART 1 — Find the files on your computer

After you `git pull` on `S:\swimiq`, the website files are here:

```
S:\swimiq\website\
    index.html       ← main homepage
    privacy.html
    terms.html
    ai.html
    css\
        site.css
```

You upload **those 5 things** to GoDaddy. Nothing else from the Flutter project.

---

## PART 2 — Log into GoDaddy

1. Open a browser (Chrome is fine).
2. Go to **https://www.godaddy.com**
3. Click **Sign In** (top right).
4. Sign in with your GoDaddy account (the one that owns swimiqapp.com).

---

## PART 3 — Figure out which GoDaddy product you have

You need **one** of these. Check what you see:

### Option A — You have **Web Hosting** (best — easy upload)

1. After login: **My Products**
2. Scroll to **swimiqapp.com**
3. You see a button like **Manage** or **Hosting** or **cPanel**

→ **Go to PART 4A**

### Option B — You only have **Website Builder** (drag-and-drop)

You might see “Edit Website” or “Website Builder.”

Custom HTML upload is **hard** with Website Builder alone.

**Easiest fix:** In GoDaddy chat or phone support, say:

> “I want to upload my own HTML files to swimiqapp.com. Do I have cPanel hosting, or only Website Builder?”

They can tell you in 2 minutes. You may need to add **Web Hosting** (~$6–10/month) OR they help you paste pages.

→ If they say you have **cPanel**, use **PART 4A**

---

## PART 4A — Upload with File Manager (cPanel)

### Step 1 — Open File Manager

1. **My Products** → **swimiqapp.com** → **Manage**
2. Click **cPanel Admin** or **Hosting** → **cPanel**
3. Find **File Manager** (under “Files”) and click it

### Step 2 — Open the right folder

1. In File Manager, open folder **`public_html`**
   - Sometimes it is called **`httpdocs`** — same idea
2. This folder = what the world sees at swimiqapp.com

### Step 3 — Back up old files (optional but safe)

1. If you see an old `index.html`, click it → **Rename** → `index-old.html`
2. That way you can undo if needed

### Step 4 — Upload new files

1. Click **Upload** (top menu)
2. Click **Select File** or drag files from Windows:
   - From `S:\swimiq\website\` upload:
     - `index.html`
     - `privacy.html`
     - `terms.html`
     - `ai.html`
3. For the CSS file:
   - First in File Manager click **+ Folder** → name it **`css`** (exactly)
   - Open the **`css`** folder
   - Upload **`site.css`** from `S:\swimiq\website\css\`

### Step 5 — Check it worked

1. Wait 1–2 minutes
2. Open a **new private/incognito** browser window
3. Go to **https://swimiqapp.com**
4. You should see:
   - “Built in the Water. Driven by Possibility.”
   - Sections: **Features**, **Latest updates**, **Plans**, **Try SwimIQ**
5. Also test:
   - https://swimiqapp.com/privacy
   - https://swimiqapp.com/terms

**If you still see the old short page:** press **Ctrl+F5** (hard refresh) or wait 10 minutes for cache.

---

## PART 4B — Upload with FTP (if File Manager is confusing)

GoDaddy can give you FTP login info in cPanel → **FTP Accounts**.

1. Download **FileZilla** (free): https://filezilla-project.org
2. Connect with GoDaddy FTP host, username, password
3. On the right side, open `public_html`
4. On the left side, open `S:\swimiq\website`
5. Drag the same files across (html files + css folder)

Same result as Part 4A.

---

## PART 5 — Email (support@swimiqapp.com)

Separate from the website files:

1. GoDaddy → **swimiqapp.com** → **Email** or **Forwarders**
2. Create **forwarder**:
   - `support@swimiqapp.com` → your Gmail/personal email
   - `privacy@swimiqapp.com` → same email

Takes a few minutes to start working.

---

## PART 6 — Other domains (.net etc.)

For each extra domain you own:

1. GoDaddy → that domain → **Forwarding** or **Redirect**
2. Forward to: **https://swimiqapp.com**
3. Type: **Permanent (301)**

---

## PART 7 — What about the FLUTTER APP?

The app does **not** go to GoDaddy.

```
Flutter app  →  build on a Mac  →  TestFlight  →  parent's iPhone
Website      →  upload to GoDaddy  →  swimiqapp.com in browser
```

When a parent says “I want to try it”:
1. They visit **swimiqapp.com** (website — you just uploaded)
2. Later you send **TestFlight invite** (phone app — separate step, needs Apple Developer $99 + Mac)

See **docs/TESTFLIGHT.md** for the phone app part.

---

## PART 8 — When you update the app later

1. Pull latest code on `S:\swimiq`
2. If legal text changed, run in PowerShell:
   ```powershell
   S:
   cd swimiq
   python website/sync_legal.py
   ```
3. Re-upload changed files to GoDaddy `public_html` (same as Part 4)
4. Edit `website/index.html` **Latest updates** section when you add big features

---

## Stuck? Do these 3 checks

1. **Am I in `public_html`?** (not the wrong folder)
2. **Did I upload the `css` folder** with `site.css` inside?
3. **Hard refresh** the browser (Ctrl+F5)

---

## Get help from GoDaddy

Call or chat GoDaddy support and say:

> “I need to upload HTML files to public_html for swimiqapp.com. Can you walk me through File Manager?”

They do this every day.

---

## One sentence summary

**Copy the `website` folder to GoDaddy’s `public_html` — that’s the whole website. The Flutter app is a separate thing for the iPhone later.**

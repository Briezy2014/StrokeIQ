#!/usr/bin/env python3
"""Copy swimiq/assets/legal/*.txt into website legal HTML pages."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEGAL = ROOT / "assets" / "legal"
WEB = ROOT / "website"

PAGES = {
    "privacy_policy.txt": ("privacy.html", "Privacy Policy"),
    "terms_of_service.txt": ("terms.html", "Terms of Service"),
    "ai_data_disclosure.txt": ("ai.html", "AI &amp; Data Disclosure"),
}

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} — SwimIQ</title>
  <link rel="stylesheet" href="css/site.css">
</head>
<body>
  <header class="site-header">
    <div class="container">
      <a href="index.html" class="logo">SWIM<span>IQ</span></a>
      <nav class="nav">
        <a href="index.html#features">Features</a>
        <a href="index.html#updates">Updates</a>
        <a href="privacy.html">Privacy</a>
        <a href="terms.html">Terms</a>
        <a href="ai.html">AI</a>
      </nav>
    </div>
  </header>
  <main class="legal-page">
    <div class="container">
      <a href="index.html" class="back-link">← Back to SwimIQ</a>
      <h1>{title_plain}</h1>
      <p class="meta">swimiqapp.com · Same text as the in-app legal document</p>
      <div class="legal-body">{body}</div>
    </div>
  </main>
  <footer class="site-footer">
    <div class="container">
      <p>© 2026 SwimIQ · <a href="mailto:support@swimiqapp.com">support@swimiqapp.com</a></p>
    </div>
  </footer>
</body>
</html>
"""


def escape_html(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def main() -> None:
    for src_name, (out_name, title) in PAGES.items():
        body = escape_html((LEGAL / src_name).read_text(encoding="utf-8"))
        title_plain = title.replace("&amp;", "&")
        html = TEMPLATE.format(title=title, title_plain=title_plain, body=body)
        (WEB / out_name).write_text(html, encoding="utf-8")
        print(f"Wrote {WEB / out_name}")


if __name__ == "__main__":
    main()

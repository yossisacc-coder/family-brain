# Family Brain landing page

This folder is a **standalone static website** for Family Brain. It does not change the Flutter mobile app.

Official logo: **08E — Two-tone** (`assets/brand` in the app; copied here as `images/logo-mark.png`).

## Run locally

From this folder:

```bash
cd landing
python3 -m http.server 4173
```

Open [http://127.0.0.1:4173](http://127.0.0.1:4173).

Any static file server works (`npx serve .`, VS Code Live Server, etc.). There is no build step and no paid API.

## Deploy for free

Do **not** buy a domain or hosting. Pick one free static host:

### Option A — GitHub Pages (free)

1. In the GitHub repo: **Settings → Pages**.
2. Source: **GitHub Actions**.
3. The workflow in `.github/workflows/deploy-landing.yml` publishes this `landing/` folder.
4. After the workflow succeeds, the site URL is typically:
   `https://<user>.github.io/<repo>/`
5. Update these files to that exact public URL:
   - `robots.txt` (`Sitemap:` line)
   - `sitemap.xml` (`<loc>` values)
   - canonical / Open Graph URLs in `index.html`

Private repositories may need GitHub Pro for public Pages. If Pages is unavailable, use Option B or C.

You can also copy **only the contents of `landing/`** into a new **public** GitHub repository and enable Pages from the root (`/`).

### Option B — Cloudflare Pages (free)

1. Go to [Cloudflare Pages](https://pages.cloudflare.com/).
2. Create a project from this GitHub repo.
3. Set **build command** empty and **output directory** to `landing`.
4. Deploy. You get a `*.pages.dev` URL at no cost.
5. Update `robots.txt`, `sitemap.xml`, and the canonical/OG URLs to that hostname.

### Option C — Netlify Drop (free, no account required for a trial upload)

1. Zip the **contents** of `landing/` (not the Flutter project).
2. Open [https://app.netlify.com/drop](https://app.netlify.com/drop).
3. Drop the folder or zip. You get a free `*.netlify.app` URL.
4. Update the SEO URLs as above.

## Google Search

This site includes:

- Title and meta description
- Open Graph tags
- JSON-LD (`SoftwareApplication` + `FAQPage`)
- Semantic headings
- `robots.txt`
- `sitemap.xml`

Indexing is **not guaranteed**. After the site is on a public HTTPS URL:

1. Confirm `robots.txt` and `sitemap.xml` use that URL.
2. Open [Google Search Console](https://search.google.com/search-console).
3. Add the property, verify ownership, and submit the sitemap (`/sitemap.xml`).

## Appearance

The landing page defaults to the Personal (light) Family Brain identity. Use the ◐ control in the header to preview the Professional (dark) companion theme from the app.

## Beta form

The “Join the Beta” form stores interest in the browser (`localStorage`) so this page needs no paid backend. Replace it later with any free form tool if you want email delivery.

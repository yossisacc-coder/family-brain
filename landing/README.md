# Family Brain landing page

This folder is a **standalone static website** for Family Brain. It does not change the Flutter mobile app.

Official logo: **08E — Two-tone** (`assets/brand` in the app; copied here as `images/logo-mark.png`).

Expected GitHub Pages URL (project site for this repository):

`https://yossisacc-coder.github.io/family-brain/`

That URL is not live until GitHub Pages is enabled on the repository (see below). This repository is currently **private**. GitHub Pages on a private repo requires GitHub Pro. On the free plan, make the repository **public** first.

## Run locally

From this folder:

```bash
cd landing
python3 -m http.server 4173
```

Open [http://127.0.0.1:4173](http://127.0.0.1:4173).

There is no build step and no paid API.

## Deploy for free with GitHub Pages

Do **not** buy a domain or hosting.

### What you must click in GitHub

1. Open [https://github.com/yossisacc-coder/family-brain](https://github.com/yossisacc-coder/family-brain).
2. If the repo is private and you are on the free plan: **Settings → General → Danger Zone → Change repository visibility → Public**.
3. Open **Settings → Pages**.
4. Under **Build and deployment → Source**, choose **GitHub Actions**.
5. Save.
6. Open **Actions**, select **Deploy landing page**, and confirm a run succeeded (or wait for the next push of `landing/`).
7. After a green deploy, open:

`https://yossisacc-coder.github.io/family-brain/`

The workflow `.github/workflows/deploy-landing.yml` publishes **only** the `landing/` folder. It does not build or deploy the Flutter app.

Canonical, Open Graph, `robots.txt`, and `sitemap.xml` already use that GitHub Pages project URL.

## Google Search Console

Indexing is **not immediate and not guaranteed**. Google decides if and when to crawl and index.

1. Open [https://search.google.com/search-console](https://search.google.com/search-console) and sign in with a Google account.
2. Click **Add property**.
3. Choose **URL prefix**.
4. Enter `https://yossisacc-coder.github.io/family-brain/` (include the trailing path).
5. Verify ownership with the easiest method that Search Console offers:
   - **HTML file** (usually easiest for GitHub Pages): download the `google*.html` file Google gives you, put it in this `landing/` folder, commit and push, wait for Pages to deploy, then click **Verify**.
   - **HTML tag**: paste the meta tag Google gives you into `landing/index.html` `<head>`, commit, push, wait for deploy, then **Verify**.
6. After verification, open **Sitemaps**, enter `sitemap.xml`, and click **Submit**.
7. Open **URL inspection**, enter `https://yossisacc-coder.github.io/family-brain/`, and click **Request indexing**.

Do this only after the GitHub Pages URL loads in a browser over HTTPS.

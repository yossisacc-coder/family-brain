(function () {
  var LANG_KEY = "fb-lang";
  var toggle = document.querySelector(".menu-toggle");
  var links = document.querySelector(".nav-links");
  var themeBtn = document.querySelector(".theme-toggle");
  var form = document.getElementById("beta-form");
  var formMsg = document.getElementById("form-msg");
  var download = document.getElementById("download");

  function currentLang() {
    try {
      var saved = localStorage.getItem(LANG_KEY);
      if (saved === "he" || saved === "en") return saved;
    } catch (err) {
      /* ignore */
    }
    return document.documentElement.lang === "he" ? "he" : "en";
  }

  function t(key) {
    return window.FB_I18N ? window.FB_I18N.t(currentLang(), key) : "";
  }

  function setExpanded(open) {
    if (!toggle || !links) return;
    links.classList.toggle("open", open);
    toggle.setAttribute("aria-expanded", open ? "true" : "false");
    toggle.setAttribute("aria-label", open ? t("nav.closeMenu") : t("nav.openMenu"));
  }

  function refreshStoreButtons() {
    if (!download) return;
    var androidUrl = (download.getAttribute("data-android-store") || "").trim();
    var iosUrl = (download.getAttribute("data-ios-store") || "").trim();
    download.querySelectorAll("[data-store]").forEach(function (btn) {
      var kind = btn.getAttribute("data-store");
      var url = kind === "ios" ? iosUrl : androidUrl;
      if (url) {
        btn.setAttribute("href", url);
        btn.setAttribute("target", "_blank");
        btn.setAttribute("rel", "noopener noreferrer");
        btn.removeAttribute("aria-disabled");
        btn.textContent = kind === "ios" ? t("cta.appLive") : t("cta.playLive");
      } else {
        btn.setAttribute("href", "#download");
        btn.removeAttribute("target");
        btn.removeAttribute("rel");
        btn.setAttribute("aria-disabled", "true");
        btn.textContent = kind === "ios" ? t("cta.appSoon") : t("cta.playSoon");
      }
    });
  }

  function applyLang(lang) {
    if (lang !== "he" && lang !== "en") lang = "en";
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "he" ? "rtl" : "ltr";
    try {
      localStorage.setItem(LANG_KEY, lang);
    } catch (err) {
      /* ignore */
    }
    if (window.FB_I18N) window.FB_I18N.apply(lang);
    document.querySelectorAll(".lang-btn").forEach(function (btn) {
      btn.setAttribute("aria-pressed", btn.getAttribute("data-lang") === lang ? "true" : "false");
    });
    refreshStoreButtons();
    if (toggle) {
      var open = links && links.classList.contains("open");
      toggle.setAttribute("aria-label", open ? t("nav.closeMenu") : t("nav.openMenu"));
    }
  }

  applyLang(currentLang());

  document.querySelectorAll(".lang-btn").forEach(function (btn) {
    btn.addEventListener("click", function () {
      applyLang(btn.getAttribute("data-lang"));
    });
  });

  if (toggle && links) {
    toggle.addEventListener("click", function () {
      setExpanded(!links.classList.contains("open"));
    });
    links.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        setExpanded(false);
      });
    });
  }

  var saved = localStorage.getItem("fb-theme");
  if (saved === "professional") {
    document.documentElement.setAttribute("data-theme", "professional");
  }

  if (themeBtn) {
    themeBtn.addEventListener("click", function () {
      var next =
        document.documentElement.getAttribute("data-theme") === "professional"
          ? "personal"
          : "professional";
      if (next === "professional") {
        document.documentElement.setAttribute("data-theme", "professional");
      } else {
        document.documentElement.removeAttribute("data-theme");
      }
      localStorage.setItem("fb-theme", next);
    });
  }

  if (download) {
    download.querySelectorAll("[data-store]").forEach(function (btn) {
      btn.addEventListener("click", function (event) {
        if (btn.getAttribute("aria-disabled") === "true") {
          event.preventDefault();
        }
      });
    });
  }

  if (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      var data = new FormData(form);
      var name = String(data.get("name") || "").trim();
      var email = String(data.get("email") || "").trim();
      var note = String(data.get("note") || "").trim();
      if (!name || !email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        if (formMsg) {
          formMsg.hidden = false;
          formMsg.textContent = t("beta.error");
        }
        return;
      }
      var payload = {
        name: name,
        email: email,
        note: note,
        at: new Date().toISOString(),
      };
      try {
        var existing = JSON.parse(localStorage.getItem("fb-beta") || "[]");
        existing.push(payload);
        localStorage.setItem("fb-beta", JSON.stringify(existing));
      } catch (err) {
        /* ignore quota */
      }
      form.reset();
      if (formMsg) {
        formMsg.hidden = false;
        formMsg.textContent = t("beta.thanks");
      }
    });
  }
})();

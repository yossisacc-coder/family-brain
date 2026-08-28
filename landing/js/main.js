(function () {
  var toggle = document.querySelector(".menu-toggle");
  var links = document.querySelector(".nav-links");
  var themeBtn = document.querySelector(".theme-toggle");
  var form = document.getElementById("beta-form");
  var formMsg = document.getElementById("form-msg");
  var download = document.getElementById("download");

  function setExpanded(open) {
    if (!toggle || !links) return;
    links.classList.toggle("open", open);
    toggle.setAttribute("aria-expanded", open ? "true" : "false");
    toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  }

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
    var androidUrl = (download.getAttribute("data-android-store") || "").trim();
    var iosUrl = (download.getAttribute("data-ios-store") || "").trim();
    download.querySelectorAll("[data-store]").forEach(function (btn) {
      var kind = btn.getAttribute("data-store");
      var url = kind === "ios" ? iosUrl : androidUrl;
      if (url) {
        btn.setAttribute("href", url);
        btn.removeAttribute("aria-disabled");
        btn.textContent =
          kind === "ios" ? "Download on the App Store" : "Get it on Google Play";
      } else {
        btn.addEventListener("click", function (event) {
          event.preventDefault();
        });
      }
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
          formMsg.textContent = "Please enter your name and a valid email.";
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
        formMsg.textContent =
          "Thanks — your interest is saved on this device. We will follow up when beta invitations go out.";
      }
    });
  }
})();

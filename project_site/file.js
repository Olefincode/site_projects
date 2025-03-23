document.addEventListener("DOMContentLoaded", function () {
    const scrollToAbout = document.getElementById("scrollToAbout");
    const scrollToAboutAlt = document.getElementById("scrollToAboutAlt");
    const scrollToHome = document.getElementById("scrollToHome");
  
    const aboutSection = document.getElementById("about");
    const homeSection = document.getElementById("home");
  
    if (scrollToAbout) {
      scrollToAbout.addEventListener("click", () => {
        aboutSection.scrollIntoView({ behavior: "smooth" });
      });
    }
  
    if (scrollToAboutAlt) {
      scrollToAboutAlt.addEventListener("click", () => {
        aboutSection.scrollIntoView({ behavior: "smooth" });
      });
    }
  
    if (scrollToHome) {
      scrollToHome.addEventListener("click", () => {
        homeSection.scrollIntoView({ behavior: "smooth" });
      });
    }
  });

window.addEventListener('scroll', function() {
    const nav = document.querySelector('.nav');
    if (window.scrollY > 0) {
      nav.classList.add('sticky');
    } else {
      nav.classList.remove('sticky');
    }
  });
  document.addEventListener("DOMContentLoaded", () => {
    const heroImage = document.querySelector(".hero-image");
    const heroText = document.querySelector(".hero-overlay-text");
  
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          heroImage.classList.add("fade-in-right");
          heroText.classList.add("fade-in-left");
        } else {
          heroImage.classList.remove("fade-in-right");
          heroText.classList.remove("fade-in-left");
        }
      });
    }, {
      threshold: 0.4
    });
  
    observer.observe(document.querySelector(".hero-image-container"));
  });
  

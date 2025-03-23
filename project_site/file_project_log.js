// Optional: Add sticky class on scroll
window.addEventListener('scroll', () => {
    const nav = document.querySelector('.nav');
    if (window.scrollY > 0) {
      nav.classList.add('scrolled');
    } else {
      nav.classList.remove('scrolled');
    }
  });
  
  // Optional: Handle anchor link to #about when going back to index.html
  document.addEventListener("DOMContentLoaded", () => {
    const hash = window.location.hash;
    if (hash === "#about") {
      setTimeout(() => {
        const target = document.getElementById("about");
        if (target) {
          target.scrollIntoView({ behavior: "smooth" });
        }
      }, 300);
    }
  });
  document.addEventListener("DOMContentLoaded", function () {
    const fadeItems = document.querySelectorAll(".fade-section");
  
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry, index) => {
        if (entry.isIntersecting) {
          entry.target.style.transitionDelay = `${index * 200}ms`;
          entry.target.classList.add("fade-in");
          // Uncomment this if you want it to re-animate on scroll back in
          // observer.unobserve(entry.target);
        } else {
          entry.target.classList.remove("fade-in");
          entry.target.style.transitionDelay = "0ms";
        }
      });
    }, {
      threshold: 0.2
    });
  
    fadeItems.forEach(item => observer.observe(item));
  });
  
  document.addEventListener("DOMContentLoaded", function () {
    const hash = window.location.hash;
  
    if (hash) {
      const target = document.querySelector(hash);
      if (target) {
        // Wait for layout to settle before scrolling
        setTimeout(() => {
          target.scrollIntoView({ behavior: "smooth" });
        }, 300);
      }
    }
  });
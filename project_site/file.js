document.addEventListener("DOMContentLoaded", function () {
  try {
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

  } catch (error) {
      console.error("Script error:", error);
  }
});

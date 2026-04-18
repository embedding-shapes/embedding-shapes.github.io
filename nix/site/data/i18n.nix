{ lib }:

let
  locales = [ "en" "es" "ca" "sv" ];
  defaultLocale = "en";

  strings = {
    en = {
      about = "About";
      builtWith = "Built with";
      email = "Email";
      home = "Home";
      intro = "Welcome to my blog. I write about technology, Nix, and other topics.";
      posts = "Posts";
      recentPosts = "Recent Posts";
      repoVersions = "Repository Versions";
      versions = "Versions";
    };

    es = {
      about = "Sobre mí";
      builtWith = "Desarrollado con";
      email = "Correo electrónico";
      home = "Inicio";
      intro = "Te doy la bienvenida a mi blog. Escribo sobre tecnología, Nix y otros temas.";
      posts = "Entradas";
      recentPosts = "Entradas recientes";
      repoVersions = "Versiones del repositorio";
      versions = "Versiones";
    };

    ca = {
      about = "Sobre mi";
      builtWith = "Desenvolupat amb";
      email = "Correu electrònic";
      home = "Inici";
      intro = "Et dono la benvinguda al meu blog. Hi escric sobre tecnologia, Nix i altres temes.";
      posts = "Entrades";
      recentPosts = "Entrades recents";
      repoVersions = "Versions del repositori";
      versions = "Versions";
    };

    sv = {
      about = "Om mig";
      builtWith = "Byggd med";
      email = "E-post";
      home = "Hem";
      intro = "Välkommen till min blogg. Jag skriver om teknik, Nix och andra ämnen.";
      posts = "Inlägg";
      recentPosts = "Senaste inläggen";
      repoVersions = "Versioner i repot";
      versions = "Versioner";
    };
  };

  ensureLocale = locale:
    if lib.elem locale locales then locale
    else builtins.throw "Unsupported locale `${locale}`.";

in {
  inherit defaultLocale locales strings;
  stringsFor = locale: strings.${ensureLocale locale};
}

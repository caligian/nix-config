{
  pkgs,
  ...
}:
{
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };
    mime.defaultApplications = {
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
      "x-scheme-handler/about" = "chromium-browser.desktop";
      "x-scheme-handler/unknown" = "chromium-browser.desktop";
      "application/pdf" = "org.gnome.Papers.desktop";
      "image/*" = "org.gnome.eog.desktop";
      "inode/directory" = "pcmanfm-qt.desktop";
      "application/msword" = "libreoffice-writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
        "libreoffice-writer.desktop";
      "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
      "application/rtf" = "libreoffice-writer.desktop";
      "application/vnd.ms-excel" = "libreoffice-calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "libreoffice-calc.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "libreoffice-calc.desktop";
      "text/csv" = "libreoffice-calc.desktop";
      "text/tab-separated-values" = "libreoffice-calc.desktop";
      "application/vnd.ms-powerpoint" = "libreoffice-impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
        "libreoffice-impress.desktop";
      "application/vnd.oasis.opendocument.presentation" = "libreoffice-impress.desktop";
      "application/epub+zip" = "calibre-ebook-viewer.desktop";
      "application/x-mobipocket-ebook" = "calibre-ebook-viewer.desktop";
      "application/x-mobipocket-subscription" = "calibre-ebook-viewer.desktop";
      "application/x-mobi8-ebook" = "calibre-ebook-viewer.desktop";
      "image/vnd.djvu" = "calibre-ebook-viewer.desktop";
    };
  };
}

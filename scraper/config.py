"""
Üniversite duyuru sayfaları yapılandırması.

Her üniversite için:
  - url: Duyuru sayfasının adresi
  - type: "html" (statik) veya "rss"
  - selectors: BeautifulSoup CSS seçicileri
  - base_url: Relative link'leri tamamlamak için kök adres

Yeni üniversite eklemek için UNIVERSITIES listesine yeni bir dict ekle,
ilgili sayfanın HTML yapısına uygun selector'ları yaz.
"""

UNIVERSITIES = [
    {
        "name": "İstanbul Teknik Üniversitesi",
        "url": "https://www.itu.edu.tr/duyurular",
        "base_url": "https://www.itu.edu.tr",
        "type": "html",
        "selectors": {
            "item": "div.news-item, article.post, div.announcement-item",
            "title": "h3, h2, .title, a",
            "content": "p, .summary, .description",
            "date": ".date, time, .news-date",
            "link": "a",
        },
    },
    {
        "name": "Orta Doğu Teknik Üniversitesi",
        "url": "https://www.metu.edu.tr",
        "base_url": "https://www.metu.edu.tr",
        "type": "html",
        "selectors": {
            "item": ".view-content .views-row, article, .node",
            "title": "h3 a, h2 a, .field-title a",
            "content": ".field-body, .summary, p",
            "date": ".date-display-single, .field-date, time",
            "link": "h3 a, h2 a, a",
        },
    },
    {
        "name": "Boğaziçi Üniversitesi",
        "url": "https://bogazici.edu.tr",
        "base_url": "https://bogazici.edu.tr",
        "type": "html",
        "selectors": {
            "item": ".announcement-item, .news-item, article, .list-group-item",
            "title": "h3, h4, a.title, .announcement-title",
            "content": "p, .excerpt, .announcement-body",
            "date": ".date, time, span.date",
            "link": "a",
        },
    },
    {
        "name": "Ankara Üniversitesi",
        "url": "https://www.ankara.edu.tr",
        "base_url": "https://www.ankara.edu.tr",
        "type": "html",
        "selectors": {
            "item": "article, .post, .duyuru-item, .news-item",
            "title": "h2 a, h3 a, .entry-title a",
            "content": ".entry-content p, .excerpt, p",
            "date": ".date, time, .entry-date",
            "link": "h2 a, h3 a, a",
        },
    },
    {
        "name": "Ege Üniversitesi",
        "url": "https://www.ege.edu.tr",
        "base_url": "https://www.ege.edu.tr",
        "type": "html",
        "selectors": {
            "item": ".news-item, article, .duyuru, .list-group-item",
            "title": "h3, h4, a",
            "content": "p, .summary",
            "date": ".date, time",
            "link": "a",
        },
    },
]

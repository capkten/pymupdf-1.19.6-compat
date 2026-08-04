import fitz


def test_binding_versions():
    assert fitz.VersionBind == "1.19.6"
    assert fitz.VersionFitz == "1.19.0"


def test_basic_document_lifecycle():
    document = fitz.open()
    page = document.new_page(width=200, height=100)
    page.insert_text((20, 40), "compatibility smoke test")
    assert "compatibility smoke test" in page.get_text()
    pixmap = page.get_pixmap()
    assert pixmap.width > 0
    assert pixmap.height > 0
    document.close()

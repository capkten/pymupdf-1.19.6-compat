import fitz


print("open", flush=True)
doc = fitz.open()
page = doc.new_page()
widget = fitz.Widget()
widget.field_name = "text"
widget.field_type = fitz.PDF_WIDGET_TYPE_TEXT
widget.rect = fitz.Rect(50, 72, 400, 200)
widget.field_value = "Times-Roman"
print("add_widget", flush=True)
page.add_widget(widget)
print(page.first_widget.field_type_string, flush=True)
doc.close()
print("closed", flush=True)


# Enter your Ruby code here

module MyMacro

  include RBA

  app = Application.instance
  mw = app.main_window

  lv = mw.current_view
  if lv == nil
    raise "Shape Statistics: No view selected"
  end

  paths = 0
  polygons = 0
  boxes = 0
  texts = 0

  lv.each_object_selected do |sel|

    shape = sel.shape

    if shape.is_path?
      paths += 1
    elsif shape.is_box?
      boxes += 1
    elsif shape.is_polygon?
      polygons += 1
    elsif shape.is_text?
      texts += 1
    end

  end

  s = "Paths: #{paths}\n"
  s += "Polygons: #{polygons}\n"
  s += "Boxes: #{boxes}\n"
  s += "Texts: #{texts}\n"

  MessageBox::info("Shape Statistics", s, MessageBox::Ok)

end
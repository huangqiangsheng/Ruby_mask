
# Enter your Ruby code here


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
  dbu = CellView::active.layout.dbu
  lv.each_object_selected do |sel|
    p1 = DPoint::new(0,1050/dbu)
    p2 = DPoint::new(0,-250/dbu)
    p3 = DPoint::new(0,-2450/dbu)
    p4 = DPoint::new(0,-250/dbu)
    shape = sel.shape
    dup_shape1 = shape.dup
    shape.shapes.insert(dup_shape1)
    dup_shape1.transform(CplxTrans::new(1,0,false,p1))
    dup_shape2 = dup_shape1.dup
    shape.shapes.insert(dup_shape2)  
    dup_shape2.transform(CplxTrans::new(1,0,false,p2))
    dup_shape3 = dup_shape2.dup
    shape.shapes.insert(dup_shape3)
    dup_shape3.transform(CplxTrans::new(1,0,false,p3))
    dup_shape4 = dup_shape3.dup
    shape.shapes.insert(dup_shape4)
    dup_shape4.transform(CplxTrans::new(1,0,false,p4))
  end

#  MessageBox::info("Shape Statistics", s, MessageBox::Ok)

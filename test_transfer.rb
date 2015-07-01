# create a new view (mode 1) with an empty layout
main_window = RBA::Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = main_window.current_view
# set the database unit (shown as an example, the default is 0.001)
layout.dbu = 0.001
# create a cell
cell = layout.create_cell("TOP")
# create a layer
layer_index1 = layout.insert_layer(RBA::LayerInfo::new(10, 0))
layer_index2 = layout.insert_layer(RBA::LayerInfo::new(11, 0))

pt1 = RBA::Point.new(-10,-10)
pt2 = RBA::Point.new(-10,10)
pt3 = RBA::Point.new(100,25)
pt4 = RBA::Point.new(100,-25)
taper = RBA::Polygon.new([pt1,pt2,pt3,pt4])
start_angle = 0
t1 = RBA::Trans::new(RBA::Trans::M90)
t2 = RBA::Trans::new(0.0,0.0)
trans_taper = taper.transformed(t1).transformed(t2)
cell.shapes(layer_index1).insert(taper)
cell.shapes(layer_index2).insert(trans_taper)
# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
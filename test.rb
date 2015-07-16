load "waveguide.rb"
include MyBasic
include RBA

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(1).layout
layout_view = main_window.current_view
# set the database unit (shown as an example, the default is 0.001)
dbu = 0.001
layout.dbu = dbu
# create a cell
cell = layout.create_cell("top")
layer_index = layout.insert_layer(LayerInfo::new(1, 0,'FPR'))

pts = [DPoint.new(0.0,0.0), DPoint.new(1000.0,1000.0)]
width = 500.0
wg = Waveguide.new(pts,width)
wg.start_face_angle = 73.0
wg.end_face_angle = 73.0
puts wg.start_face_angle/Math::PI*180.0
cell.shapes(layer_index).insert(wg.poly)

# fit the viewport to the extensions of our layout
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
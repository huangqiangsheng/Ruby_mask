load "waveguide.rb"
include RBA
include MyBasic
# create a new view (mode 1) with an empty layout
main_window = RBA::Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = main_window.current_view
# set the database unit (shown as an example, the default is 0.001)
layout.dbu = 0.001
# create a cell
cell = layout.create_cell("TOP")
# create a layer
layer_index1 = layout.insert_layer(RBA::LayerInfo::new(1, 0))
layer_index2 = layout.insert_layer(RBA::LayerInfo::new(2, 0))
layer_index3 = layout.insert_layer(RBA::LayerInfo::new(3, 0))

# add a shape
p1 = DPoint.new(0.0,0.0)
radius = 10.0/layout.dbu
start_angle = 270.0
span_angle = 90.0
pts = linearc_one_point_two_angle(p1,radius,start_angle,span_angle)
wg1 = Waveguide.new(pts,width,90,0)
cell.shapes(layer_index2).insert(wg1.poly)

width = 4.0/layout.dbu
len = 10.0/layout.dbu
dx = 30.0/layout.dbu
dy = 20.0/layout.dbu
p0 = RBA::DPoint.new(0, 0)
p1 = RBA::DPoint.new(len, -len/5)
dir1 = line_angle(p0,p1)/Math::PI*180.0
p2 = RBA::DPoint.new(len+dx, dy)
p3 = RBA::DPoint.new(len+dx+len, dy+len/10.0)
dir2 = line_angle(p2,p3)/Math::PI*180.0
pts1 = [p0, p1]
pts2 = [p2, p3]
radius = 10.0/layout.dbu
pts3 = sbend(p1,dir1,p2,dir2,radius)
pts = pts1+pts3+pts2
wg1 = Waveguide.new(pts,width)
cell.shapes(layer_index1).insert(wg1.poly)

# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout

tst = RBA::Text.new('Hello',0,0)
cell.shapes(layer_index1).insert(tst)
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
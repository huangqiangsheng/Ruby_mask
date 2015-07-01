load "waveguide.rb"
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
pts1 = [RBA::DPoint.new(0, 0), RBA::DPoint.new(10.0/layout.dbu, 0.0), RBA::DPoint.new(10.0/layout.dbu,10.0/layout.dbu)]
wg1 = Waveguide.new(pts1,4.0/layout.dbu,90,0)
cell.shapes(layer_index1).insert(wg1.poly)
t = RBA::DCplxTrans::new(1,0, false, 10.0/layout.dbu,0)
cell.shapes(layer_index1).insert(wg1.transformed(t))

pts2 = [RBA::DPoint.new(20.0/layout.dbu, 0), RBA::DPoint.new(30.0/layout.dbu, 0.0), RBA::DPoint.new(20.0/layout.dbu,20.0/layout.dbu)]
wg2 = Waveguide.new(pts2,4.0/layout.dbu,nil,nil,1)
cell.shapes(layer_index2).insert(wg2.poly)

pts3 = [RBA::DPoint.new(40.0/layout.dbu, 0), RBA::DPoint.new(40.0/layout.dbu, 40.0/layout.dbu), RBA::DPoint.new(60.0/layout.dbu,20.0/layout.dbu)]
wg3 = Waveguide.new(pts3,4.0/layout.dbu,nil,nil,1)
cell.shapes(layer_index3).insert(wg3.poly)

pts1 = [RBA::DPoint.new(0, 0), RBA::DPoint.new(10.0/layout.dbu, 0.0), RBA::DPoint.new(10.0/layout.dbu,10.0/layout.dbu)]
wg1 = Waveguide.new(pts1,4.0/layout.dbu)
cell.shapes(layer_index1).insert(wg1.poly)

pts2 = [RBA::DPoint.new(20.0/layout.dbu, 0), RBA::DPoint.new(30.0/layout.dbu, 0.0), RBA::DPoint.new(20.0/layout.dbu,20.0/layout.dbu)]
wg2 = Waveguide.new(pts2,4.0/layout.dbu)
cell.shapes(layer_index2).insert(wg2.poly)

pts3 = [RBA::DPoint.new(40.0/layout.dbu, 0), RBA::DPoint.new(40.0/layout.dbu, 40.0/layout.dbu), RBA::DPoint.new(60.0/layout.dbu,20.0/layout.dbu)]
wg3 = Waveguide.new(pts3,4.0/layout.dbu)
cell.shapes(layer_index3).insert(wg3.poly)
pts3_r = round_corners(pts3,5.0/layout.dbu)
wg3r = Waveguide.new(pts3_r,4.0/layout.dbu)
cell.shapes(layer_index2).insert(wg3r.poly)
wg3r2 = Waveguide.new(pts3_r,4.0/layout.dbu,nil,nil,1)
cell.shapes(layer_index1).insert(wg3r2.poly)
# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout

tst = RBA::Text.new('Hello',0,0)
cell.shapes(layer_index1).insert(tst)
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
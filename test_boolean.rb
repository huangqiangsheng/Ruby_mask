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
layer_index3 = layout.insert_layer(RBA::LayerInfo::new(12, 0))
pt1 = RBA::DPoint.new(-10/layout.dbu,-10/layout.dbu)
pt2 = RBA::DPoint.new(-10/layout.dbu,10/layout.dbu)
pts = [pt1,pt2]
wg1 = Waveguide.new(pts,1.0/layout.dbu)
wg2 = Waveguide.new(pts,2.0/layout.dbu)
poly1 = wg1.poly
poly2 = wg2.poly
cell.shapes(layer_index1).insert(poly1)
cell.shapes(layer_index2).insert(poly2)
ep = RBA::EdgeProcessor::new()
out = ep.boolean_p2p([poly1],[poly2],RBA::EdgeProcessor::ModeBNotA,false, false)
out.each {|p| cell.shapes(layer_index3).insert(p)}
# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
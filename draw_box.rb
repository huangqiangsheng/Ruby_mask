
# Enter your Ruby code here

# create a new view (mode 1) with an empty layout
main_window = RBA::Application::instance.main_window
layout = main_window.create_layout(2).layout
layout_view = main_window.current_view

# set the database unit (shown as an example, the default is 0.001)
layout.dbu = 0.001

# create a cell
cell = layout.create_cell("TOP")

# create a layer
layer_index = layout.insert_layer(RBA::LayerInfo::new(10, 0,'box'))

# add a shape
length = Array(1..10)
length.each do |alength|
box = RBA::Box::new(1000*(alength-1), 0, 1000*alength, 2000*alength)
cell.shapes(layer_index).insert(box)
end 

# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
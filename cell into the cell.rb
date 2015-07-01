
# Enter your Ruby code here



include RBA

# Enter your Ruby code here ..

app = Application.instance
# create a new view (mode 1) with an empty layout
main_window = RBA::Application::instance.main_window
#layout = main_window.create_layout(1).layout
layout = main_window.create_layout(1).layout
layout_view = main_window.current_view
# get the current layout
layer_align = layout.insert_layer(RBA::LayerInfo::new(10, 0))
cell1 = layout.create_cell("TOP")
cell2 = layout.create_cell("BOTTOM")
cell2.shapes(layer_align).insert(RBA::Box::new(0, 0, 400, 400))
array1 = CellInstArray::new(cell2.cell_index,Trans::new(0,0), Point::new(500,0),Point::new(0,0),10,1)
cell1.insert(array1)
layout_view.select_cell(cell1.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
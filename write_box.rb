
# Enter your Ruby code here

# create the layout
layout = RBA::Layout::new

# set the database unit (shown as an example, the default is 0.001)
layout.dbu = 0.001

# create a cell
cell = layout.create_cell("TOP")

# create a layer
layer_index = layout.insert_layer(RBA::LayerInfo::new(10, 0))

# add a shape
cell.shapes(layer_index).insert((10))

# save the layout
layout.write("my_layout.gds")
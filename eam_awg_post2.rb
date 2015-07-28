load "Eam_class.rb"
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = CellView::active.layout
layout_view = LayoutView::current
dbu = layout.dbu

top = layout.top_cell

#chane layer
index = [1,3,4,5,7,8,9]
index.each do |i|
  layer_index1 = layout.layer(i,0)
  layer_index2 = layout.layer(i,1)
  top.each_shape(layer_index2) do |shape|
    shape.layer = layer_index1
  end
end

layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
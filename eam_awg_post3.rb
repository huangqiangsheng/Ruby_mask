load "Eam_class.rb"
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = CellView::active.layout
layout_view = LayoutView::current
dbu = layout.dbu

top = layout.top_cell
target = layout.create_cell('Modulator_AWG')
#chane layer
index = [1,3,4,5,7,8,9]
index.each do |i|
  cell_name = "layer#{i}"
  tcell = layout.create_cell(cell_name)
  layer_index = layout.layer(i,0)
  top.each_shape(layer_index) do |shape|
    tcell.shapes(layer_index).insert(shape)
  end
  angle = 0.0
  disp = DPoint.new(0.0,0.0)
  t = CplxTrans::new(1.0, angle,false,disp)
  tmp = CellInstArray::new(tcell.cell_index,t)
  target.insert(tmp)
end

layout_view.select_cell(target.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
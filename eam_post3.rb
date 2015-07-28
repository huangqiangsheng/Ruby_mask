load "Eam_class.rb"
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = CellView::active.layout
layout_view = LayoutView::current
dbu = layout.dbu

top = layout.top_cell
top.each_inst do |child|
  #puts child.cell.name
  case child.cell.name
  when 'layer1'
    iter = 0
  when 'layer3'
    iter = 1
  when 'layer4'
    iter = 2
  when 'layer5'
    iter = 3
  when 'layer7'
    iter = 4
  when 'layer8'
    iter = 5
  when 'layer9'
    iter = 6
  end 
  i = iter.modulo(2)
  j = iter/2
  child.trans = Trans::new(6000*i/dbu,-4500*j/dbu)
end

layout_view.select_cell(top.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit

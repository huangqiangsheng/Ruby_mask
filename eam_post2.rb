load "Eam_class.rb"
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = LayoutView::current
dbu = layout.dbu

filename = 'G:\\Gent\\TW_modulator_mask\\TEST_00_test.gds'

layout.read(filename)
cell = layout.top_cell
target = Cell.new
puts cell.name
cell.each_inst do |child|
  #puts child.cell.name
  child.trans = Trans::new(0.0,0.0)
  if child.cell.name == 'layer1_resit_t_1'
    target=child.cell
  end
end


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit

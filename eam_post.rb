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
  #child.trans = Trans::new(0.0,0.0)
  if child.cell.name == 'layer1_resit_t_1'
    target=child.cell
  end
end


layer_index=layout.layer(1,0)
target_layer_index = layout.layer(4,0)
target.each_shape(layer_index) do |shape|
  if shape.is_box?
    puts shape.box_height
    if 2.0/dbu == shape.box_height && 40.0/dbu < shape.box_width
      shape.layer=target_layer_index
    end
  end
end

vp0 = []
vlength = []
target.each_shape(target_layer_index) do |shape|
  vp0.push(shape.box_p1 + Point::new(0.0,shape.box_height/2.0))
  vlength.push(shape.box_width)
end

wg35 = Eam_Lump.new()
#wg35.shapes(eamcell)

vp0.each_index do |iter|
  eamcell = layout.create_cell("EAM_LUMP#{vlength[iter]/1000}")
  wg35.wg_length(vlength[iter])
  wg35.shapes(eamcell)
  t = CplxTrans::new(1.0, 0,false,vp0[iter].x,vp0[iter].y)
  tmp = CellInstArray::new(eamcell.cell_index,t)
  cell.insert(tmp)
end


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
load "Eam_class.rb"
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = LayoutView::current
dbu = layout.dbu

#get filename
filename = 'G:\\Gent\\TW_modulator_mask\\TEST_00_test.gds'

#get target cell
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

#chane particular structure color
layer_index=layout.layer(1,0)
target_layer_index = layout.layer(100,1)
target.each_shape(layer_index) do |shape|
  if shape.is_box?
    puts shape.box_height
    if 2.0/dbu == shape.box_height && 40.0/dbu < shape.box_width
      shape.layer=target_layer_index
    end
  end
end


#get start_point and length
vp0 = []
vlength = []
target.each_shape(target_layer_index) do |shape|
  vp0.push(shape.box_p1 + Point::new(0.0,shape.box_height/2.0))
  vlength.push(shape.box_width)
end

mesa_width_in = 1.4/dbu
mesa_width_hybrid = 3.2/dbu
mqw_width_in = 2.5/dbu
mqw_width_hybrid = 4.5/dbu
taper1 = 90.0/dbu
taper2 = 20.0/dbu
#initial all structure
lump = Eam_Lump.new()
lump.mesa_width_in = mesa_width_in
lump.mesa_width_hybrid = mesa_width_hybrid
lump.mqw_width_in = mqw_width_in
lump.mqw_width_hybrid = mqw_width_hybrid
lump.taper1 = taper1
lump.taper2 = taper2

tw = Eam_TW.new()
tw.mesa_width_in = mesa_width_in
tw.mesa_width_hybrid = mesa_width_hybrid
tw.mqw_width_in = mqw_width_in
tw.mqw_width_hybrid = mqw_width_hybrid
tw.taper1 = taper1
tw.taper2 = taper2

stw = Eam_STW.new()
stw.mesa_width_in = mesa_width_in
stw.mesa_width_hybrid = mesa_width_hybrid
stw.mqw_width_in = mqw_width_in
stw.mqw_width_hybrid = mqw_width_hybrid
stw.taper1 = taper1
stw.taper2 = taper2

tw_lump = Eam_TW_LUMP.new()
tw_lump.mesa_width_in = mesa_width_in
tw_lump.mesa_width_hybrid = mesa_width_hybrid
tw_lump.mqw_width_in = mqw_width_in
tw_lump.mqw_width_hybrid = mqw_width_hybrid
tw_lump.taper1 = taper1
tw_lump.taper2 = taper2

# sort vp0, and sort vlength arounding the order of vp0
tvp0 = vp0.sort {|p1,p2| p2.y <=> p1.y}
sort_order = tvp0.map{|p| vp0.index(p)}
tvlength = sort_order.map{|ind| vlength[ind]}
vlength = tvlength
vp0 = tvp0

eamcell=nil
vp0.each_index do |iter|
  case iter
  when 0
    cell_name = "EAM_TW_LUMP#{vlength[iter]/1000}"
    eamcell = layout.cell(cell_name)
    if eamcell == nil
      eamcell = layout.create_cell(cell_name)
    end
    tw_lump.wg_length=vlength[iter]
    tw_lump.shapes(eamcell)
  when 2,3,4
    cell_name = "EAM_LUMP#{vlength[iter]/1000}"
    eamcell = layout.cell(cell_name)
    if eamcell == nil
      eamcell = layout.create_cell(cell_name)
    end
    lump.wg_length(vlength[iter])
    lump.shapes(eamcell)   
  when 6,9
    cell_name = "EAM_TW#{vlength[iter]/1000}"
    eamcell = layout.cell(cell_name)
    if eamcell == nil
      eamcell = layout.create_cell(cell_name)
    end
    tw.wg_length=vlength[iter]
    tw.shapes(eamcell)    
  when 11,15
    cell_name = "EAM_STW200"
    eamcell = layout.cell(cell_name)
    if eamcell == nil
      eamcell = layout.create_cell(cell_name)
    end
    stw.shapes(eamcell)    
  end    
  if eamcell
    t = CplxTrans::new(1.0, 0,false,vp0[iter].x,vp0[iter].y)
    tmp = CellInstArray::new(eamcell.cell_index,t)
    cell.insert(tmp)
  end
  eamcell = nil
end


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
load "Eam_class.rb"
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = LayoutView::current
dbu = layout.dbu

#get filename
filename = 'G:\\Gent\\TW_modulator_mask\\R_GROUP1.gds'

#get target cell
layout.read(filename)
cell = layout.top_cell
target = Cell.new
puts cell.name
cell.each_inst do |child|
  #puts child.cell.name
  child.trans = Trans::new(0.0,0.0)
  if child.cell.name == '1st'
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

#initial all structure
lump = Eam_Lump.new()
# sort vp0, and sort vlength arounding the order of vp0
tvp0 = vp0.sort {|p1,p2| p2.y <=> p1.y}
sort_order = tvp0.map{|p| vp0.index(p)}
tvlength = sort_order.map{|ind| vlength[ind]}
vlength = tvlength
vp0 = tvp0

eamcell=nil
vp0.each_index do |iter|
  cell_name = "EAM_LUMP#{vlength[iter]/1000}"
  eamcell = layout.cell(cell_name)
  if eamcell == nil
    eamcell = layout.create_cell(cell_name)
  end
  lump.wg_length(vlength[iter])
  lump.shapes(eamcell)    
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
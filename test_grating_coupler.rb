require "waveguide.rb"
include MyBasic
include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = main_window.current_view
# set the database unit (shown as an example, the default is 0.001)
dbu = 0.001
layout.dbu = dbu
# create a cell
cell = layout.create_cell("Grating_coupler")
# create a layer
layer_index1 = layout.insert_layer(LayerInfo::new(1, 0,'Grating'))

#awg parameter
period = 0.63/dbu
duty = 0.38
width_in = 0.45/dbu
width_out = 10./dbu
grating_length = 15/dbu
behind_length = 5.0/dbu
taper_length = 150.0/dbu
p0 = DPoint::new(0.0,0.0)

pts = [DPoint::new(0.0,0.0),DPoint::new(taper_length,0.0)]
taper = Taper.new(pts,width_in,width_out,'x')
cell.shapes(layer_index1).insert(taper.poly)

grtg_len = 0
while grtg_len < grating_length do
  pts = [DPoint::new(taper_length+grtg_len+period*(1-duty),0.0),
         DPoint::new(taper_length+grtg_len+period,0.0)]
  wg = Waveguide.new(pts,width_out)
  cell.shapes(layer_index1).insert(wg.poly)
  grtg_len = grtg_len+period
end

pts = [DPoint::new(taper_length+grtg_len+period*(1-duty),0.0),
       DPoint::new(taper_length+grtg_len+behind_length,0.0)]
wg = Waveguide.new(pts,width_out)
cell.shapes(layer_index1).insert(wg.poly)


# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
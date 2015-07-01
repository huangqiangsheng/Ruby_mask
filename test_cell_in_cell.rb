load "AWG_class.rb"
load "GratingCoupler_class.rb"
include MyBasic
include RBA
# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(1).layout
layout_view = main_window.current_view
# set the database unit (shown as an example, the default is 0.001)
dbu = 0.001
layout.dbu = dbu
# create a cell
#################200G################
cell = layout.create_cell("AWG_200G_width450")
awg_200G = Awg.new()
awg_200G.narms=40
awg_200G.nchannel=6
awg_200G.ra=54.0/dbu
awg_200G.theta_da=0.9
awg_200G.theta_cs=1.4
awg_200G.w_wg=0.45/dbu
awg_200G.w_aperture=2.0/dbu
awg_200G.array_aperture=1.68/dbu
awg_200G.array_w=0.45/dbu
awg_200G.array_R=30.0/dbu
awg_200G.delta_L=32.935/dbu
awg_200G.arrayed_taper=30.0/dbu
awg_200G.w_taper=30.0/dbu
awg_200G.arrayed_spacing=2.8/dbu
awg_200G.ports_spacing=100.0/dbu
awg_200G.overlap_fpr1=0.1/dbu
awg_200G.overlap_fpr2=0.25/dbu
awg_200G.overlap_array=0.1/dbu
awg_200G.overlap_ports=0.1/dbu
awg_200G.fsr_angle1 = 57.0
awg_200G.fsr_angle2 = 53.0
awg_200G.layer_fsr= layout.layer(1, 0)
awg_200G.layer_arrayed= layout.layer(2, 0)
awg_200G.layer_ports = layout.layer(3, 0)
awg_200G.centre_line = 1
#awg_200G.straight_neff = 2.82371
#awg_200G.bend_neff = 2.824144
awg_200G.shapes(cell)
#################Grating Coupler##############
gccell = layout.create_cell("Grating_Coupler_340nm")
gcoupler = GratingCoupler.new()
gcoupler.width_in = awg_200G.ports[0].width
gcoupler.period = 0.64/dbu
gcoupler.duty = 0.38
gcoupler.shapes(gccell)

awg_200G.ports.each do |port|
  angle = (port.direction-gcoupler.ports[0].direction-Math::PI)/Math::PI*180.0
  disp = port.point-gcoupler.ports[0].point
  t = CplxTrans::new(1.0, angle,false,disp)
  tmp = CellInstArray::new(gccell.cell_index,t)
  cell.insert(tmp)
end


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
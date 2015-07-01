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
cell = layout.create_cell("EDG")
# create a layer
layer_index1 = layout.insert_layer(LayerInfo::new(1, 0,'Grating'))
layer_index2 = layout.insert_layer(LayerInfo::new(2, 0,'Ports'))
layer_index3 = layout.insert_layer(LayerInfo::new(3, 0,'Others'))
#edg parameter
thetai = 45.0*Math::PI/180.0
thetad = 41.0*Math::PI/180.0
w_wg = 0.8/dbu
ra = 340.356/dbu
wg_spacing = 3.0/dbu
output_num = 6
bend_R = 50.0/dbu
output_spacing = 15.0/dbu
grating_period = 0.336/dbu
grating_width = 0.168/dbu
grating_num = 3

overlap_fpr1 = 0.1/dbu
overlap_fpr2 = 0.25/dbu
overlap_array = 0.04/dbu
overlap_ports = 0.04/dbu

p0 = DPoint.new(0.0,0.0)
ex_len = 60.0/dbu
ex_len2 = 100.0/dbu

grating_pos = []
filename = "G:\\Gent\\AWG\\EDG\\huannan_grating_parameter.txt"
File.open(filename, "r").each_line do |line|
  data = line.split(' ').collect{|iter| iter.to_f/dbu}
  grating_pos.push(data)
end
edg_fnum = grating_pos.length/2

# Circle
c1 = Circle.new(DPoint.new(0.0,ra),ra);
cell.shapes(layer_index3).insert(c1.poly) 
c2 = Circle.new(DPoint.new(0.0,2.0*ra),2.0*ra);
cell.shapes(layer_index3).insert(c2.poly) 

# output waveguide
outP0 = p0+DPoint.new(0.0,ra)+DPoint.new(Math::sin(2*thetad)*ra,Math::cos(2*thetad)*ra)
dtheta = wg_spacing/ra
tmp_theta = 2.0*thetad+((output_num/2)-1)*dtheta
tmp_y = 0
output_x = 0 #x coorinate of outputwaveguide
for iter in 1..output_num
  pts1 = p0+DPoint.new(0.0,ra)+DPoint.new(Math::sin(tmp_theta)*ra,Math::cos(tmp_theta)*ra)
  if 1 == iter
    pts2 = pts1+DPoint.new(Math::sin(tmp_theta/2.0)*ex_len,Math::cos(tmp_theta/2.0)*ex_len)
    pts3 = pts2+DPoint.new(ex_len2,0)
    output_x = pts3.x
    tmpy = pts3.y
    pts = [pts1,pts2,pts3]
    pts = round_corners(pts,bend_R)
    wg = Waveguide.new(pts,w_wg)
    cell.shapes(layer_index2).insert(wg.poly) 
    wg = Waveguide.new([p0,pts2],0)
    cell.shapes(layer_index3).insert(wg.poly) 
  else
    pts2 = pts1+DPoint.new(((tmpy + output_spacing)-pts1.y)*Math::tan(tmp_theta/2.0),(tmpy + output_spacing)-pts1.y)
    pts3 = DPoint.new(output_x,pts2.y)
    tmpy = pts3.y
    pts = [pts1,pts2,pts3]
    pts = round_corners(pts,bend_R)
    wg = Waveguide.new(pts,w_wg)
    cell.shapes(layer_index2).insert(wg.poly)  
    wg = Waveguide.new([p0,pts2],0.0)
    cell.shapes(layer_index3).insert(wg.poly)   
  end
  tmp_theta = tmp_theta-dtheta
end
# input waveguide
pts1 = p0+DPoint.new(0.0,ra)+DPoint.new(Math::sin(2*thetai)*ra,Math::cos(2*thetai)*ra)
pts2 = pts1+DPoint.new(Math::sin(thetai)*ex_len,Math::cos(thetai)*ex_len)
pts3 = DPoint.new(output_x,pts2.y)
pts = [pts1,pts2,pts3]
pts = round_corners(pts,bend_R)
wg = Waveguide.new(pts,w_wg)
cell.shapes(layer_index2).insert(wg.poly)
wg = Waveguide.new([p0,pts2],0.0)
cell.shapes(layer_index3).insert(wg.poly)   

#EDG Grating

for iter in 0..(edg_fnum-1)
  pts = [ DPoint.new(grating_pos[iter*2][0], grating_pos[iter*2][1]), 
          DPoint.new(grating_pos[iter*2+1][0], grating_pos[iter*2+1][1])]
  wg = Waveguide.new(pts,grating_width)
  normV = DPoint.new((pts[0]-pts[1]).y, -(pts[0]-pts[1]).x)
  normV = normV*(1.0/Math::sqrt(normV.sq_abs))  
  for yiter in 0..(grating_num-1)
    t = RBA::DCplxTrans::new(1,0, false, normV*(grating_width/2.0+grating_period*yiter))
    cell.shapes(layer_index1).insert(wg.transformed(t))     
  end
end
# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
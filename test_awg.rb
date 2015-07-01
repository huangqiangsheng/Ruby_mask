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
cell = layout.create_cell("AWG")
# create a layer
layer_index1 = layout.insert_layer(LayerInfo::new(1, 0,'FPR'))
layer_index2 = layout.insert_layer(LayerInfo::new(2, 0,'Arryed'))
layer_index3 = layout.insert_layer(LayerInfo::new(3, 0,'Ports'))

#awg parameter
narms = 40
nchannel = 6
ra = 54.0/dbu
theta_da = 0.9
theta_cs = 1.4
w_wg = 0.45/dbu
w_aperture = 2.0/dbu
array_aperture = 1.69/dbu
array_w = 0.45/dbu
array_R = 50.0/dbu
delta_L = 33.117/dbu

arrayed_taper = 15.0/dbu
w_taper = 22.0/dbu;

arrayed_spacing = 2.8/dbu
ports_spacing = 4.0/dbu

overlap_fpr1 = 0.1/dbu
overlap_fpr2 = 0.25/dbu
overlap_array = 0.04/dbu
overlap_ports = 0.04/dbu

#add arrayed waveguide
midn = narms/2
start_theta = 90-theta_da*midn
round_wg_Len = Array.new(narms){|i| i = 0}
array_Len = Array.new(narms){|i| i = 0} #without consider the difference between the neff_straigth and neff_bend
manhanttan_dy = 0 #increasing length
t1 = Trans::new(DTrans::M90)
t2 = Trans::new(0.0,0.0)
for iter in 1..narms
  # add taper arrayed waveguide
  angle = ((iter-1) * theta_da + start_theta )*Math::PI/180.0
  pos1 = DPoint::new(ra*2.0*Math::cos(angle),ra*2.0*Math::sin(angle))
  pos2 = DPoint::new((ra*2.0+arrayed_taper)*Math::cos(angle),(ra*2.0+arrayed_taper)*Math::sin(angle))
  pts = [pos1,pos2]
  width_in = array_aperture
  width_out = array_w
  taper = Taper.new(pts,width_in,width_out,'x')
  cell.shapes(layer_index2).insert(taper.poly)

  # add bend taper arrayed waveguide
  #same waveguide spacing
  pts = []
  if iter <= midn
    dw =  array_R*(1-Math::sin(angle))
    w1 = arrayed_spacing*(midn+1-iter)-dw
    lw = w1/Math::cos(angle)
    pos3 =  DPoint::new(lw*Math::cos(angle),lw*Math::sin(angle))
    pts1 = [pos2,pos3]
    c0 = DPoint::new(lw*Math::cos(angle)-array_R*Math::sin(angle),lw*Math::sin(angle)+array_R*Math::cos(angle))
    c0_manhanttan = c0+DPoint::new(array_R*2.0,-overlap_array) #manhattan centre
    angle1 = ((iter-1) * theta_da + start_theta )-90
    arc = linearc(c0,array_R,angle1,0,0.5)
    pts = pts1 +arc
    array_Len[iter-1] = lw-arrayed_taper-2.0*ra+array_R*(-angle1)/180.0*Math::PI
  elsif iter >= midn+2
    dw =  array_R*(1-Math::sin(angle))
    w1 = arrayed_spacing*(iter-midn-1)-dw
    lw = w1/Math::sin(angle-Math::PI/2.0)
    pos3 =  DPoint::new(lw*Math::cos(angle),lw*Math::sin(angle))
    pts1 = [pos2,pos3]
    c0 = DPoint::new(lw*Math::cos(angle)+array_R*Math::cos(angle-Math::PI/2.0),
                    lw*Math::sin(angle)+array_R*Math::sin(angle-Math::PI/2.0))
    c0_manhanttan = c0+DPoint::new(0.0,-overlap_array)  #manhattan centre
    angle1 = -(180-(((iter-1) * theta_da + start_theta )-90))
    arc = linearc(c0,array_R,angle1,-180,0.5)
    pts = pts1 +arc  
    array_Len[iter-1] = lw-arrayed_taper-2.0*ra+array_R*(180.0+angle1)/180.0*Math::PI
  else
    angle = (90-theta_da)*Math::PI/180.0
    dw =  array_R*(1-Math::sin(angle))
    w1 = arrayed_spacing-dw
    lw = w1/Math::cos(angle)
    pos3 =  DPoint::new(0,lw)
    pts1 = [pos2,pos3]
    pts = pts1
    array_Len[iter-1] = lw-arrayed_taper-2.0*ra
    c0_manhanttan = DPoint::new(array_R,lw-overlap_array)  #manhattan centre
  end
  wg1 = Waveguide.new(pts,array_w,nil,180)
  cell.shapes(layer_index2).insert(wg1.poly)
  round_wg_Len[iter-1] = array_Len[iter-1]
  # add manhattan
  if 1 == iter
    arc = linearc(c0_manhanttan,array_R,180.0,90.0,0.5)
    pts = arc
    array_Len[iter-1] =  round_wg_Len[iter-1]+Math::PI/2.0*array_R
    t2 = Trans::new(c0_manhanttan.x*2.0,0.0)    
  else
    pts1 = [DPoint::new(c0_manhanttan.x-array_R,c0_manhanttan.y)]
    manhanttan_dy = delta_L/2.0 - (round_wg_Len[iter-1]-round_wg_Len[iter-2]) - arrayed_spacing+manhanttan_dy
    c0_manhanttan.y = c0_manhanttan.y + manhanttan_dy
    arc = linearc(c0_manhanttan,array_R,180.0,90.0,0.5)
    pts2 = [DPoint::new(c0_manhanttan.x+arrayed_spacing*(iter-1),c0_manhanttan.y+array_R)]
    pts =  pts1+arc+pts2
    array_Len[iter-1] =  round_wg_Len[iter-1]+(iter-1)*arrayed_spacing+manhanttan_dy+Math::PI/2.0*array_R
  end
  wg = Waveguide.new(pts,array_w,180,90)
  cell.shapes(layer_index2).insert(wg.poly)
  cell.shapes(layer_index2).insert(wg.poly.transformed(t1).transformed(t2))
  cell.shapes(layer_index2).insert(wg1.poly.transformed(t1).transformed(t2))
  cell.shapes(layer_index2).insert(taper.poly.transformed(t1).transformed(t2))
end
# check array length difference
array_Len[0..-2].each_index { |index| puts (array_Len[index+1]-array_Len[index])*2}

# add Free Propagation Region
centre = DPoint::new(0, 0)
angle = 57.0
arc1 = linearc(centre,ra*2.0+overlap_fpr1,90.0-angle/2.0,90.0+angle/2.0,1.0)
centre = DPoint::new(0, ra)
angle2 = 54.0
arc2 = linearc(centre,ra+overlap_fpr2,-90-angle2/2.0,-90.0+angle2/2.0)
arc = arc1+arc2
fpr = DPolygon::new(arc)
cell.shapes(layer_index1).insert(Polygon::from_dpoly(fpr))
cell.shapes(layer_index1).insert(Polygon::from_dpoly(fpr).transformed(t1).transformed(t2))


# add taper ports waveguide
centre = DPoint::new(0, ra)
midn = nchannel/2
start_theta = -90-theta_cs*midn*2.0
start_theta2 = -90-theta_cs*midn
port_y = 50.0/dbu #ports extension_y direction
port_x = 100.0/dbu #ports extension_x direction
xmin = 0
for iter in 1..nchannel
  angle = ((iter-1) * theta_cs*2.0 + start_theta )*Math::PI/180.0
  angle2 = ((iter-1) * theta_cs + start_theta2 )*Math::PI/180.0
  pos1 = DPoint::new(ra*Math::cos(angle),ra*Math::sin(angle)) + centre
  pos2 = DPoint::new(w_taper*Math::cos(angle2),w_taper*Math::sin(angle2)) + pos1
  pts = [pos1,pos2]
  width_in = w_aperture
  width_out = w_wg
  taper = Taper.new(pts,width_in,width_out,'x',0.1)
  cell.shapes(layer_index3).insert(taper.poly)
  cell.shapes(layer_index3).insert(taper.poly.transformed(t1).transformed(t2))
  if 1 == iter
    pts = [DPoint::new(pos2.x + overlap_ports/Math.tan(angle2),pos2.y + overlap_ports),
           DPoint::new(pos2.x - port_y/Math.tan(angle2),pos2.y - port_y),
           DPoint::new(pos2.x - port_y/Math.tan(angle2)-port_x,pos2.y - port_y)]
    xmin = pos2.x - port_y/Math.tan(angle2)-port_x
    pts = round_corners(pts,array_R)
  else
    tmp_y = port_y+(iter-1)*ports_spacing
    pts = [DPoint::new(pos2.x + overlap_ports/Math.tan(angle2),pos2.y + overlap_ports),
           DPoint::new(pos2.x - tmp_y/Math.tan(angle2),pos2.y - tmp_y),
           DPoint::new(xmin,pos2.y - tmp_y)]
    pts = round_corners(pts,array_R)
  end
  wg = Waveguide.new(pts,w_wg)
  cell.shapes(layer_index3).insert(wg.poly)
  cell.shapes(layer_index3).insert(wg.poly.transformed(t1).transformed(t2))
end


# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout


layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
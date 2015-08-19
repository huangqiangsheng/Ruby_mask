require "waveguide.rb"
#creat awg with same waveguide spacing
class Awg
  include MyBasic
  include RBA
  attr_accessor :narms, :nchannel, :ra, :theta_da, :theta_cs, :w_wg, :w_aperture, 
                :array_aperture, :array_w, :array_R,
                :delta_L, :arrayed_taper, :w_taper, :arrayed_spacing, :ports_spacing,
                :fsr_angle1, :fsr_angle2,
                :overlap_fpr1, :overlap_fpr2, :overlap_array, :overlap_ports,
                :layer_fsr, :layer_arrayed, :layer_ports,
                :centre_line,
                :straight_neff, :bend_neff
  def initialize(narms=34,
                 nchannel=8,
                 ra=54.0,
                 theta_da=1.06,
                 theta_cs=1.406,
                 w_wg=0.8,
                 w_aperture=1.9,
                 array_aperture=1.5,
                 array_w=0.8,
                 array_R=50.0,
                 delta_L=17.27,
                 arrayed_taper=15.0,
                 w_taper=22.0,
                 arrayed_spacing=3.0,
                 ports_spacing=100.0,
                 overlap_fpr1=0.1,
                 overlap_fpr2=0.25,
                 overlap_array=0.04,
                 overlap_ports=0.04,
                 fsr_angle1 = 57.0,
                 fsr_angle2 = 53.0,
                 layer_fsr = CellView::active.layout.layer(1, 0),
                 layer_arrayed = CellView::active.layout.layer(2, 0),
                 layer_ports = CellView::active.layout.layer(3, 0),
                 centre_line = nil,
                 straight_neff = 1.0,
                 bend_neff = 1.0)
  #awg parameter
    @active_layout = CellView::active.layout
    @dbu = @active_layout.dbu
    @narms = narms
    @nchannel = nchannel
    @ra = ra/@dbu
    @theta_da = theta_da
    @theta_cs = theta_cs
    @w_wg = w_wg/@dbu
    @w_aperture = w_aperture/@dbu
    @array_aperture = array_aperture/@dbu
    @array_w = array_w/@dbu
    @array_R = array_R/@dbu
    @delta_L = delta_L/@dbu
    
    @arrayed_taper = arrayed_taper/@dbu
    @w_taper = w_taper/@dbu;
    
    @arrayed_spacing = arrayed_spacing/@dbu
    @ports_spacing = ports_spacing/@dbu
    
    @overlap_fpr1 = overlap_fpr1/@dbu
    @overlap_fpr2 = overlap_fpr2/@dbu
    @overlap_array = overlap_array/@dbu
    @overlap_ports = overlap_ports/@dbu
    
    @fsr_angle1 = fsr_angle1
    @fsr_angle2 =  fsr_angle2
    
    @layer_fsr = layer_fsr
    @layer_arrayed = layer_arrayed
    @layer_ports = layer_ports
    
    @centre_line = nil
    
    @straight_neff = straight_neff  #straigth waveguide neff
    @bend_neff = bend_neff  #bend waveguide neff
    @ports = []
    
  end
  def shapes(cell)
    #add arrayed waveguide
    dbu = @dbu
    narms = @narms
    nchannel = @nchannel
    ra = @ra
    theta_da = @theta_da
    theta_cs = @theta_cs
    w_wg = @w_wg
    w_aperture = @w_aperture
    array_aperture = @array_aperture
    array_w = @array_w
    array_R = @array_R
    delta_L = @delta_L
    
    arrayed_taper = @arrayed_taper
    w_taper = @w_taper
    arrayed_spacing = @arrayed_spacing
    ports_spacing = @ports_spacing
    
    overlap_fpr1 = @overlap_fpr1
    overlap_fpr2 = @overlap_fpr2
    overlap_array = @overlap_array
    overlap_ports = @overlap_ports
    
    layer_index1 = @layer_fsr
    layer_index2 = @layer_arrayed
    layer_index3 = @layer_ports
    @ports = []
    if @centre_line
      layer_index_c2 = @active_layout.layer(2, 1)
      layer_index_c3 = @active_layout.layer(3, 1)
    end
    midn = narms/2
    start_theta = 90-theta_da*midn
    round_wg_Len = Array.new(narms){|i| i = 0} #bendling length
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
        pts1 = [pos2,pos3] #calculate the position for same spacing
        c0 = DPoint::new(lw*Math::cos(angle)-array_R*Math::sin(angle),lw*Math::sin(angle)+array_R*Math::cos(angle))
        c0_manhanttan = c0+DPoint::new(array_R*2.0,0.0) #manhattan centre
        angle1 = ((iter-1) * theta_da + start_theta )-90
        arc = linearc(c0,array_R,angle1,0,0.5)
        arc.push(DPoint::new(arc[-1].x,arc[-1].y+overlap_array)) #overlap length
        pts = pts1 +arc
        array_Len[iter-1] = lw-arrayed_taper-2.0*ra+(array_R*(-angle1)/180.0*Math::PI)*@bend_neff/@straight_neff
      elsif iter >= midn+2
        dw =  array_R*(1-Math::sin(angle))
        w1 = arrayed_spacing*(iter-midn-1)-dw
        lw = w1/Math::sin(angle-Math::PI/2.0)
        pos3 =  DPoint::new(lw*Math::cos(angle),lw*Math::sin(angle))
        pts1 = [pos2,pos3]
        c0 = DPoint::new(lw*Math::cos(angle)+array_R*Math::cos(angle-Math::PI/2.0),
                        lw*Math::sin(angle)+array_R*Math::sin(angle-Math::PI/2.0))
        c0_manhanttan = c0  #manhattan centre
        angle1 = -(180-(((iter-1) * theta_da + start_theta )-90))
        arc = linearc(c0,array_R,angle1,-180,0.5)
        arc.push(DPoint::new(arc[-1].x,arc[-1].y+overlap_array)) #overlap length
        pts = pts1 +arc  
        array_Len[iter-1] = lw-arrayed_taper-2.0*ra+(array_R*(180.0+angle1)/180.0*Math::PI)*@bend_neff/@straight_neff
      else
        angle = (90-theta_da)*Math::PI/180.0
        dw =  array_R*(1-Math::sin(angle))
        w1 = arrayed_spacing-dw
        lw = w1/Math::cos(angle)
        pos3 =  DPoint::new(0,lw)
        pos4 = DPoint::new(pos3.x,pos3.y + overlap_array)#overlap length
        pts1 = [pos2,pos3,pos4]
        pts = pts1
        array_Len[iter-1] = lw-arrayed_taper-2.0*ra
        c0_manhanttan = DPoint::new(array_R,lw)  #manhattan centre
      end
      wg1 = Waveguide.new(pts,array_w,nil,180,nil,90.0)
      cell.shapes(layer_index2).insert(wg1.poly)    
      round_wg_Len[iter-1] = array_Len[iter-1] #round section length
      array_Len[iter-1]=wg1.wg_length
      # add manhattan
      if 1 == iter
        pts1 = [DPoint::new(c0_manhanttan.x-array_R,c0_manhanttan.y)]
        manhanttan_dy = 0
        c0_manhanttan.y = c0_manhanttan.y + manhanttan_dy + overlap_array#overlpap
        arc = linearc(c0_manhanttan,array_R,180.0,90.0,0.5)
        pts = pts1+arc
#        array_Len[iter-1] =  round_wg_Len[iter-1]+Math::PI/2.0*array_R*@bend_neff/@straight_neff+overlap_array
        t2 = Trans::new(c0_manhanttan.x*2.0,0.0)    
      else
        pts1 = [DPoint::new(c0_manhanttan.x-array_R,c0_manhanttan.y)]
        manhanttan_dy = delta_L/2.0 - (round_wg_Len[iter-1]-round_wg_Len[iter-2]) - arrayed_spacing+manhanttan_dy
        c0_manhanttan.y = c0_manhanttan.y + manhanttan_dy + overlap_array#overlpap
        arc = linearc(c0_manhanttan,array_R,180.0,90.0,0.5)
        pts2 = [DPoint::new(c0_manhanttan.x+arrayed_spacing*(iter-1),c0_manhanttan.y+array_R)]
        pts =  pts1+arc+pts2
#        array_Len[iter-1] =  (round_wg_Len[iter-1]+(iter-1)*arrayed_spacing+manhanttan_dy+
#                             Math::PI/2.0*array_R*@bend_neff/@straight_neff+overlap_array)
      end
      wg = Waveguide.new(pts,array_w,180,90,90.0,0.0)
      array_Len[iter-1]=array_Len[iter-1]+wg.wg_length
      cell.shapes(layer_index2).insert(wg.poly)
      cell.shapes(layer_index2).insert(wg.poly.transformed(t1).transformed(t2))
      cell.shapes(layer_index2).insert(wg1.poly.transformed(t1).transformed(t2))
      cell.shapes(layer_index2).insert(taper.poly.transformed(t1).transformed(t2))
      
      if @centre_line
        newpts = [] #connect the pts and pts_transformed line
        pt_end = pts[-1]
        newpts.insert(0,pt_end) #insert last point
        pts[0..-2].each_index do |iter|
          newpts.insert(iter,pts[iter])
          newpts.insert(-1-iter,DPoint::new(2.0*pt_end.x-pts[iter].x,pts[iter].y))
        end 
        wg03 = Waveguide.new(newpts,0)
        cell.shapes(layer_index_c2).insert(wg03.poly) 
      end    
      
    end
    # check array length difference
    array_Len[0..-2].each_index { |index| puts (array_Len[index+1]-array_Len[index])*2}
    
    # add Free Propagation Region
    centre = DPoint::new(0, 0)
    angle = @fsr_angle1
    arc1 = linearc(centre,ra*2.0+overlap_fpr1,90.0-angle/2.0,90.0+angle/2.0,1.0)
    centre = DPoint::new(0, ra)
    angle2 = @fsr_angle2
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
    port_y = array_R #ports extension_y direction
    port_x = 100.0/dbu #ports extension_x direction
    xmin = 0 #the leftest position
    for iter in 1..nchannel
      angle = ((iter-1) * theta_cs*2.0 + start_theta )*Math::PI/180.0
      angle2 = ((iter-1) * theta_cs + start_theta2 )*Math::PI/180.0
      pos1 = DPoint::new(ra*Math::cos(angle),ra*Math::sin(angle)) + centre
      pos2 = DPoint::new(w_taper*Math::cos(angle2),w_taper*Math::sin(angle2)) + pos1
      pts = [pos1,pos2]
      width_in = w_aperture
      width_out = w_wg
      taper = Taper.new(pts,width_in,width_out,'x')
      cell.shapes(layer_index3).insert(taper.poly)
      cell.shapes(layer_index3).insert(taper.poly.transformed(t1).transformed(t2))
      if 1 == iter
        pts = [DPoint::new(pos2.x + overlap_ports/Math.tan(angle2),pos2.y + overlap_ports),
               DPoint::new(pos2.x - port_y/Math.tan(angle2),pos2.y - port_y),
               DPoint::new(pos2.x - port_y/Math.tan(angle2)-array_R*2.0,pos2.y - port_y),
               DPoint::new(pos2.x - port_y/Math.tan(angle2)-array_R*2.0,pos2.y - port_y+(nchannel-iter)*@ports_spacing),
               DPoint::new(pos2.x - port_y/Math.tan(angle2)-array_R*2.0-port_x,pos2.y - port_y+(nchannel-iter)*@ports_spacing)]
        xmin = pts[-1].x
        pts = round_corners(pts,array_R)
      else
        tmp_y = port_y+(iter-1)*arrayed_spacing
        pts = [DPoint::new(pos2.x + overlap_ports/Math.tan(angle2),pos2.y + overlap_ports),
               DPoint::new(pos2.x - tmp_y/Math.tan(angle2),pos2.y - tmp_y),
               DPoint::new(xmin+port_x-(iter-1)*@arrayed_spacing,pos2.y - tmp_y),
               DPoint::new(xmin+port_x-(iter-1)*@arrayed_spacing,pos2.y - tmp_y+(nchannel-iter)*@ports_spacing),
               DPoint::new(xmin,pos2.y - tmp_y+(nchannel-iter)*@ports_spacing)]
        pts = round_corners(pts,array_R)
      end
      wg = Waveguide.new(pts,w_wg)
      cell.shapes(layer_index3).insert(wg.poly)
      cell.shapes(layer_index3).insert(wg.poly.transformed(t1).transformed(t2))
      @ports.push(Ports::new(width = w_wg,
                             direction = line_angle(pts[-2],pts[-1]),
                             face_angle = direction+Math::PI/2.0,
                             point = pts[-1]))
      tpoint = DTrans::from_itrans(t2).trans(DTrans::from_itrans(t1).trans(pts[-1]))
      @ports.push(Ports::new(width = w_wg,
                             direction = Math::PI+line_angle(pts[-2],pts[-1]),
                             face_angle = direction+Math::PI/2.0,
                             point = tpoint))      
      if @centre_line
        wg01 = Waveguide.new(pts,0)
        cell.shapes(layer_index_c3).insert(wg01.poly)
        cell.shapes(layer_index_c3).insert(wg01.poly.transformed(t1).transformed(t2))      
      end      
    end

  end
  def ports
    return @ports
  end
end

# create a new view (mode 1) with an empty layout
if __FILE__ == $0
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
  cell = layout.create_cell("AWG")
  
  awg = Awg.new()
  awg.nchannel = 6
  awg.shapes(cell)
  
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
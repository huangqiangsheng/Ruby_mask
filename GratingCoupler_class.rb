load "waveguide.rb"
#creat grating coupler
class GratingCoupler
  include MyBasic
  include RBA
  attr_accessor :period, :duty, :width_in, :width_out, :grating_length,
                :taper_length, :layer_grating, :dbu
                
  def initialize(period = 0.64,
                 duty = 0.38,
                 width_in = 0.45,
                 width_out = 10.0,
                 grating_length = 15.0,
                 taper_length = 150.0,
                 layer_grating = CellView::active.layout.layer(1, 0),
                 dbu = CellView::active.layout.dbu)
    @dbu = dbu             
    @period = period/@dbu
    @duty = duty
    @width_in = width_in/@dbu
    @width_out = width_out/@dbu
    @grating_length = grating_length/@dbu
    @behind_length = 5.0/@dbu
    @taper_length = taper_length/@dbu
    @layer_grating = layer_grating
    @ports = []
  end
  
  def shapes(cell)
  
    pts = [DPoint::new(0.0,0.0),DPoint::new(@taper_length,0.0)]
    @ports.push(Ports::new(width = @width_in,
                          direction = line_angle(pts[1],pts[0]),
                          face_angle = direction+Math::PI/2.0,
                          point = pts[0]))     
    taper = Taper.new(pts,@width_in,@width_out,'x')
    cell.shapes(@layer_grating).insert(taper.poly)
  
    grtg_len = 0
    while grtg_len < @grating_length do
      pts = [DPoint::new(@taper_length+grtg_len+@period*(1-@duty),0.0),
             DPoint::new(@taper_length+grtg_len+@period,0.0)]
      wg = Waveguide.new(pts,@width_out)
      cell.shapes(@layer_grating).insert(wg.poly)
      grtg_len = grtg_len+@period
    end
    pts = [DPoint::new(@taper_length+grtg_len+@period*(1-@duty),0.0),
           DPoint::new(@taper_length+grtg_len+@behind_length,0.0)]     
    wg = Waveguide.new(pts,@width_out)
    cell.shapes(@layer_grating).insert(wg.poly)
  end
  
  def ports
    return @ports
  end
end

class FocusingGratingCoupler
# reference :'Reflectionless grating couplers for Silicon-on-Insulator photonic integrated circuits'
# reference :'Compact Focusing Grating Couplers for Silicon-on-Insulator Integrated Circuits'
  include MyBasic
  include RBA
  attr_accessor :period, :duty, :width_in, :width_out, :grating_length,
                :taper_length, :layer_grating,
                :phi, :nc, :lambda0, :eta, :r0, :dbu
                
  def initialize(period = 0.64,
                 duty = 0.50,
                 width_in = 0.5,
                 width_out = 0.5,                 
                 grating_length =15.5,
                 taper_length = 1.0,
                 phi = 10.0, #incident angle
                 nc = 1.0,  #cladding index
                 lambda0 = 1.55, #centre wavelength
                 eta = 36.56, #aperture opening angle degree
                 r0 = 12.5, #focusing length
                 layer_grating = CellView::active.layout.layer(1, 0),
                 dbu = CellView::active.layout.dbu)
    @dbu = dbu             
    @period = period/@dbu
    @duty = duty
    @width_in = width_in/@dbu
    @width_out = width_out/@dbu
    @grating_length = grating_length/@dbu
    @taper_length = taper_length/@dbu
    @phi = phi
    @nc = nc
    @lambda0 = lambda0/@dbu
    @ns = @lambda0/@period+@nc*Math::sin(@phi/180.0*Math::PI)   
    @eta = eta
    @r0 = r0/@dbu
    @layer_grating = layer_grating
    @ports = []
  end
  def shapes(cell)
    shape = []
    pts = [DPoint::new(0.0,0.0),DPoint::new(@taper_length,0.0)]
    @ports.push(Ports::new(width = @width_in,
                          direction = line_angle(pts[1],pts[0]),
                          face_angle = direction+Math::PI/2.0,
                          point = pts[0]))     
    taper = Taper.new(pts,@width_in,@width_out,'x')
    shape.push(taper.poly)

    pts = [DPoint::new(@taper_length,@width_out/2.0),DPoint::new(@taper_length,-@width_out/2.0)]
    start_angle = -@eta/2.0
    end_angle = @eta/2.0
    f0 = DPoint::new(@taper_length,0.0) 
    q = @r0*(1-@nc/@ns*Math::sin(@phi/180.0*Math::PI))*@ns/@lambda0
    a = q * @lambda0 * @ns/(@ns**2-(@nc*Math::sin(@phi/180.0*Math::PI))**2)
    e = @nc*Math::sin(@phi/180.0*Math::PI)/@ns
    pts = pts + linearc_ellipse(f0,a,e,start_angle,end_angle)
    poly = DPolygon.new(pts)
    shape.push(Polygon::from_dpoly(poly))   
    
    grtg_len = 0
    q -= @duty/2.0
    while grtg_len < @grating_length do
      q = q+1.0
      a = q * @lambda0 * @ns/(@ns**2-(@nc*Math::sin(@phi/180.0*Math::PI))**2)
      e = @nc*Math::sin(@phi/180.0*Math::PI)/@ns
      pts = linearc_ellipse(f0,a,e,start_angle,end_angle)
      shape.push(Waveguide.new(pts,@duty*@period).poly)
      grtg_len = grtg_len+@period
    end
    shape.each {|p| cell.shapes(@layer_grating).insert(p)}
  end
  
  def ports
    return @ports
  end  
end

class ReflectionlessFocusingGratingCoupler < FocusingGratingCoupler
# reference :'Reflectionless grating couplers for Silicon-on-Insulator photonic integrated circuits'
# reference :'Compact Focusing Grating Couplers for Silicon-on-Insulator Integrated Circuits'
  include MyBasic
  include RBA
  attr_accessor :delta, :bend_radius, :straight_length
                
  def initialize(delta = 30.0,
                 bend_radius = 50.0,
                 straight_length = 28.4,
                 period = 0.551,
                 duty = 0.40,
                 width_in = 0.65,
                 width_out = 1.0,                 
                 grating_length =21.5,
                 taper_length = 30.0,
                 phi = 10.0, #incident angle
                 nc = 1.543,  #cladding index
                 lambda0 = 1.55, #centre wavelength
                 eta = 56.0, #aperture opening angle degree
                 r0 = 16.54, #focusing length
                 layer_grating = CellView::active.layout.layer(1, 0),
                 dbu = CellView::active.layout.dbu)
    super(period,duty,width_in,width_out,grating_length,taper_length,phi,nc,lambda0,eta,r0,layer_grating,dbu)
    @delta = delta
    @bend_radius = bend_radius/@dbu
    @straight_length = straight_length/@dbu
    @ns = @lambda0/@period+@nc*Math::sin(@phi/180.0*Math::PI)*Math::cos(@delta/180.0*Math::PI)
  end
  def shapes(cell)
    shape = []
    #r0 = @r0*(@ns-@nc*Math::sin(@phi/180.0*Math::PI)*Math::cos(@delta/180.0*Math::PI))/(@ns-@nc*Math::sin(@phi/180.0*Math::PI))
    pts = [DPoint::new(0.0,0.0),DPoint::new(-@straight_length,0.0)]
    @ports.push(Ports::new(width = @width_in,
                          direction = line_angle(pts[1],pts[0]),
                          face_angle = direction+Math::PI/2.0,
                          point = pts[0]))     
    centre = DPoint::new(-@straight_length,-@bend_radius)
    pts += linearc(centre,@bend_radius,90.0,120.0)
    offset = 2.0/@dbu
    pts += [pts[-1] - DPoint::new(offset*Math::cos(@delta/180.0*Math::PI),offset*Math::sin(@delta/180.0*Math::PI))]
    wg = Waveguide.new(pts,@width_in)
    shape.push(wg.poly)

    pts2 = [pts[-1],pts[-1]+DPoint::new(-taper_length*Math::cos(@delta/180.0*Math::PI),-taper_length*Math::sin(@delta/180.0*Math::PI))]
    taper = Taper.new(pts2,@width_in,@width_out)
    shape.push(taper.poly)
    
    pts3 = [pts2[-1] + DPoint::new(-@width_out/2.0*Math::sin(@delta/180.0*Math::PI),@width_out/2.0*Math::cos(@delta/180.0*Math::PI)),
            pts2[-1] + DPoint::new(@width_out/2.0*Math::sin(@delta/180.0*Math::PI),-@width_out/2.0*Math::cos(@delta/180.0*Math::PI))]
    start_angle =-@eta/2.0-@delta
    end_angle = @eta/2.0-@delta
    f0 = DPoint::new(-pts2[-1].x,pts2[-1].y) 
    q = @r0*(1-@nc/@ns*Math::sin(@phi/180.0*Math::PI)*Math::cos(@delta/180.0*Math::PI))*@ns/@lambda0
    a = q * @lambda0 * @ns/(@ns**2-(@nc*Math::sin(@phi/180.0*Math::PI))**2)
    e = @nc*Math::sin(@phi/180.0*Math::PI)/@ns
    tmp_pts = linearc_ellipse(f0,a,e,start_angle,end_angle)
    tmp_pts.collect! {|p| DPoint::new(-p.x,p.y)}
    pts = pts3 + tmp_pts
    poly = DPolygon.new(pts)
    shape.push(Polygon::from_dpoly(poly))   
    q -= (duty/2.0)
    grtg_len = 0
    while grtg_len < @grating_length do
      q = q+1.0
      a = q * @lambda0 * @ns/(@ns**2-(@nc*Math::sin(@phi/180.0*Math::PI))**2)
      e = @nc*Math::sin(@phi/180.0*Math::PI)/@ns
      pts = linearc_ellipse(f0,a,e,start_angle,end_angle)
      pts.collect! {|p| DPoint::new(-p.x,p.y)}
      shape.push(Polygon::from_dpoly(DPath.new(pts,@duty*@period,@duty*@period/2.0,@duty*@period/2.0,true).polygon))
      grtg_len = grtg_len+@period
    end
    shape.each {|p| cell.shapes(@layer_grating).insert(p)}
  end
  
  def ports
    return @ports
  end  
end

class ReflectionlessFocusingGratingCoupler_220nmSOI_70nmetch_1550nm  < ReflectionlessFocusingGratingCoupler
# reference :'Reflectionless grating couplers for Silicon-on-Insulator photonic integrated circuits'
# reference :'Compact Focusing Grating Couplers for Silicon-on-Insulator Integrated Circuits'                
  def initialize(delta = 30.0, #title angle
                 bend_radius = 50.0, #minmum bending radius
                 straight_length = 28.4, #extended straight wg length
                 period = 0.551,
                 duty = 0.40,
                 width_in = 0.65,
                 width_out = 1.0,                 
                 grating_length =21.5,
                 taper_length = 30.0,
                 phi = 10.0, #incident angle
                 nc = 1.543,  #cladding index
                 lambda0 = 1.55, #centre wavelength
                 eta = 56.0, #aperture opening angle degree
                 r0 = 16.54, #focusing length
                 layer_grating = CellView::active.layout.layer(1, 0),
                 dbu = CellView::active.layout.dbu)
    super(delta,bend_radius,straight_length,period,duty,width_in,width_out,grating_length,taper_length,phi,nc,lambda0,eta,r0,layer_grating,dbu)
  end
end

class FocusingGratingCoupler_220nmSOI_70nmetch_1550nm < FocusingGratingCoupler
  def initialize(period = 0.63,
                 duty = 0.50,
                 width_in = 0.5,
                 width_out = 0.5,                 
                 grating_length =15.5,
                 taper_length = 1.0,
                 phi = 10.0, #incident angle
                 nc = 1.0,  #cladding index
                 lambda0 = 1.55, #centre wavelength
                 eta = 36.56, #aperture opening angle degree
                 r0 = 12.5, #focusing length
                 layer_grating = CellView::active.layout.layer(1, 0),
                 dbu = CellView::active.layout.dbu)
    super(period,duty,width_in,width_out,grating_length,taper_length,phi,nc,lambda0,eta,r0,layer_grating,dbu)
  end
end

class GratingCoupler_340nmSOI_200nmetch_1550nm < GratingCoupler
  def initialize(period = 0.64,
                 duty = 0.38,
                 width_in = 0.45,
                 width_out = 10.0,
                 grating_length = 15.0,
                 taper_length = 150.0,
                 layer_grating = CellView::active.layout.layer(1, 0),
                 dbu = CellView::active.layout.dbu)
    super(period,duty,width_in,width_out,grating_length,taper_length,layer_grating,dbu)
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
  cell = layout.create_cell("GC_340nm")
  
  gcoupler = GratingCoupler_340nmSOI_200nmetch_1550nm.new()
  gcoupler.shapes(cell)
  
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
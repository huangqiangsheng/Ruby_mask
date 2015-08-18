load "waveguide.rb"

class PZT_Modulator
  include MyBasic
  include RBA
  attr_accessor :wsin, :wmmi, :wmmi_in, 
                :radius,:lmmi,
                :taperL, :gap, :spacing,         
                :cpw_pgap, :cpw_pwidth, 
                :cpw_radius, :cpw_agap, :cpw_awidth, :wgound,
                :lay_sin, :lay_active, :lay_via, :lay_probe,
                :dbu,:len
                
  def initialize(wsin = 0.7,
                 wmmi = 3.0,
                 lmmi = 4.0,
                 radius = 3.75,
                 taperL = 10.0,
                 gap = 1.0,
                 wmmi_in = 1.0,
                 spacing = 15.0,
                 cpw_pgap = 9.0,
                 cpw_pwidth = 8.0,
                 wground = 100.0,
                 cpw_radius = 30.0,
                 cpw_agap =5.0,
                 cpw_awidth = 10.0,
                 lay_sin = CellView::active.layout.layer(1, 1),
                 lay_active = CellView::active.layout.layer(3, 1),
                 lay_via = CellView::active.layout.layer(4, 1),
                 lay_probe = CellView::active.layout.layer(5, 1),
                 dbu = CellView::active.layout.dbu,
                 len = Array.new([100.0,50.0,100.0,100.0,50.0,200.0,200.0,100.0,300.0])) #p,a,o,p,a,o,p,...a,p
    @dbu = dbu             
    @wsin = wsin/@dbu
    @wmmi = wmmi/@dbu
    @lmmi = lmmi/@dbu
    @radius = radius/@dbu
    @taperL = taperL/@dbu
    @lbend = 2*@radius
    @gap = gap/@dbu
    @wmmi_in = wmmi_in/@dbu
    @spacing = spacing/@dbu
    @cpw_pgap = cpw_pgap/@dbu
    @cpw_pwidth = cpw_pwidth/@dbu
    @wground = wground/@dbu
    @cpw_radius = cpw_radius/@dbu
    @cpw_agap = cpw_agap/@dbu
    @cpw_awidth = cpw_awidth/@dbu
    @lay_sin = lay_sin
    @lay_active = lay_active
    @lay_via = lay_via
    @lay_probe = lay_probe
    @ports = []
    @len = len.collect{|l| l/@dbu}
  end
  def shapes(cell)
    @ports = []     
    shape = cell.shapes(@lay_sin)
    sin(shape)
    shape = cell.shapes(@lay_active)
    active(shape)
    shape = cell.shapes(@lay_via)
    via(shape)               
    shape = cell.shapes(@lay_probe)
    probe(shape)           
  end  
  def sin(shape)
    start_x = 0.0
    @ports.push(Ports::new(width = @wsin,
                           direction = Math::PI,
                           face_angle = direction+Math::PI/2.0,
                           point = DPoint::new(start_x,0.0)))     
    wglength = 0
    for iter in 0..(@len.length/3-1) do
      wglength = wglength + @len[iter*3+1]+@len[iter*3+2]
    end
    wglength = wglength -@len[-1] 
    
    #MMI in
    pts = [DPoint::new(start_x,0.0),DPoint::new(start_x+@taperL,0.0)]
    mmi_taper = Taper::new(pts,@wsin,@wmmi_in)
    shape.insert(mmi_taper.poly)
    mmi = [DPoint.new(@taperL,-@wmmi/2.0),DPoint.new(@taperL,@wmmi/2.0),
           DPoint.new(@taperL+@lmmi,@wmmi/2.0),DPoint.new(@taperL+@lmmi,-@wmmi/2.0)]
    shape.insert(Polygon::from_dpoly(DPolygon.new(mmi)))
    t1 = Trans::new(Trans::M90)
    t2 = Trans::new(2.0*@taperL+@lmmi,@gap/2.0+@wmmi_in/2.0)
    shape.insert(mmi_taper.poly.transformed(t1).transformed(t2))
    t2 = Trans::new(2.0*@taperL+@lmmi,-@gap/2.0-@wmmi_in/2.0)
    shape.insert(mmi_taper.poly.transformed(t1).transformed(t2))    
    pts = [DPoint.new(2.0*@taperL+@lmmi,@gap/2.0+@wmmi_in/2.0),
           DPoint.new(2.0*@taperL+@lmmi+@radius,@gap/2.0+@wmmi_in/2.0),
           DPoint.new(2.0*@taperL+@lmmi+@radius,@gap/2.0+@wmmi_in/2.0+2.0*@radius),
           DPoint.new(2.0*@taperL+@lmmi+@radius*3.0+wglength,@gap/2.0+@wmmi_in/2.0+2.0*@radius),
           DPoint.new(2.0*@taperL+@lmmi+@radius*3.0+wglength,@gap/2.0+@wmmi_in/2.0),
           DPoint.new(2.0*@taperL+@lmmi+@radius*4.0+wglength,@gap/2.0+@wmmi_in/2.0)]
    rpts = round_corners(pts,@radius,2)
    rwg = Waveguide.new(rpts,@wsin)
    shape.insert(rwg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(rwg.poly.transformed(t1))
    #MMI out
    ldev = wglength+@taperL*4.0+@lmmi*2.0+4.0*@radius
    t1 = Trans::new(Trans::M90)
    t2 = Trans::new(ldev,0.0)    
    shape.insert(mmi_taper.poly.transformed(t1).transformed(t2))
    shape.insert(Polygon::from_dpoly(DPolygon.new(mmi)).transformed(t1).transformed(t2))
    t1 = Trans::new(ldev-@taperL*2.0-@lmmi,@gap/2.0+@wmmi_in/2.0)
    shape.insert(mmi_taper.poly.transformed(t1))     
    t1 = Trans::new(ldev-@taperL*2.0-@lmmi,-@gap/2.0-@wmmi_in/2.0)
    shape.insert(mmi_taper.poly.transformed(t1))   
    @ports.push(Ports::new(width = @wsin,
                           direction = 0,
                           face_angle = direction+Math::PI/2.0,
                           point = DPoint::new(start_x+ldev,@gap/2.0+@wmmi_in/2.0)))  
    @ports.push(Ports::new(width = @wsin,
                           direction = 0,
                           face_angle = direction+Math::PI/2.0,
                           point = DPoint::new(start_x+ldev,-@gap/2.0-@wmmi_in/2.0)))                                                
  end
  def active(shape)
    spoly = []
    gpoly = []
    airpoly = []  
    start_x = 0.0
    lastx = start_x+@taperL*2.0+@lmmi+@lbend
    for iter in 0..(@len.length/3-1) do
      wglength = @len[iter*3+1]
      pts = [DPoint.new(lastx,0.0), DPoint.new(lastx+wglength,0.0)]
      spoly.push(Waveguide.new(pts,@cpw_awidth).poly)
      airpoly.push(Waveguide.new(pts,@cpw_awidth+@cpw_agap*2.0).poly)
      gpoly.push(Waveguide.new(pts,@wground).poly)
      lastx = lastx + @len[iter*3+1] + @len[iter*3+2]
    end     
    ep = RBA::EdgeProcessor::new()
    out = ep.boolean_p2p(airpoly,gpoly,RBA::EdgeProcessor::ModeBNotA,false, false)
    out.each {|p| shape.insert(p)}   
    spoly.each {|p| shape.insert(p)}    
  end  
  
  def via(shape)               
  end   
  
  def probe(shape)
  end
  def ports
    return @ports
  end
end

if __FILE__ == $0
  include MyBasic
  include RBA
  # create a new view (mode 1) with an empty layout
  main_window =Application::instance.main_window
  layout = main_window.create_layout(0).layout
  layout_view = main_window.current_view
  # set the database unit (shown as an example, the default is 0.001)
  dbu = 0.001
  layout.dbu = dbu
  # create a cell
  cell = layout.create_cell("PZT_Modulator")  
  pzt = PZT_Modulator.new()
  pzt.shapes(cell)
    
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
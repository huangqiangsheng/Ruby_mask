load "waveguide.rb"

class PZT_Modulator
  include MyBasic
  include RBA
  attr_accessor :wsin, :wmmi, :wmmi_in, 
                :radius,:lmmi,
                :taperL, :gap, :spacing,:sbend_len,        
                :cpw_pgap, :cpw_pwidth,
                :cpw_radius, :cpw_agap, :cpw_awidth, :wgound, :via_L,
                :lay_sin, :lay_active, :lay_via, :lay_probe,
                :dbu,:len
                
  def initialize(wsin = 0.7,
                 wmmi = 3.0,
                 lmmi = 4.0,
                 radius = 15.0,
                 taperL = 10.0,
                 gap = 1.0,
                 wmmi_in = 1.0,
                 spacing = 15.0,
                 sbend_len = 20.0,
                 cpw_pgap = 9.0,
                 cpw_pwidth = 8.0,
                 wground = 100.0,
                 via_L = 2.0,
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
    @sbend_len = sbend_len/@dbu
    @gap = gap/@dbu
    @wmmi_in = wmmi_in/@dbu
    @spacing = spacing/@dbu
    @cpw_pgap = cpw_pgap/@dbu
    @cpw_pwidth = cpw_pwidth/@dbu
    @wground = wground/@dbu
    @via_L = via_L/@dbu
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
    #Sbend
    p1 = DPoint.new(2.0*@taperL+@lmmi,@gap/2.0+@wmmi_in/2.0)
    dir1 = 0
    p2 = DPoint.new(2.0*@taperL+@lmmi+@sbend_len,@spacing/2.0)
    dir2 = 0
    pts = sbend(p1,dir1,p2,dir2,radius,1)
    pts.push(DPoint.new(2.0*@taperL+@lmmi+@sbend_len+wglength/2.0,@spacing/2.0))
    rwg = Waveguide.new(pts,@wsin)
    shape.insert(rwg.poly)
    t3 = Trans::new(Trans::M0)
    shape.insert(rwg.poly.transformed(t3))
    
    #Sbend out
    ldev = wglength+@taperL*4.0+@lmmi*2.0+2.0*@sbend_len
    t1 = Trans::new(Trans::M90)
    t2 = Trans::new(ldev,0.0) 
    shape.insert(rwg.poly.transformed(t1).transformed(t2)) 
    shape.insert(rwg.poly.transformed(t1).transformed(t2).transformed(t3))       
    #MMI out   
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
    lastx = start_x+@taperL*2.0+@lmmi+@sbend_len
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
    out = ep.boolean_p2p(out,spoly,RBA::EdgeProcessor::ModeOr,false, false)
    out.each {|p| shape.insert(p)}      
  end  
  
  def via(shape) 
    extend = 1.0/@dbu
    spoly = []
    gpoly = []
    airpoly = []  
    start_x = 0.0
    lastx = start_x+@taperL*2.0+@lmmi+@sbend_len
    for iter in 0..(@len.length/3-1) do
      wglength = @len[iter*3+1]
      if (@len[iter*3] > 0) || (iter == 0)
        pts = [DPoint.new(lastx+extend/2.0,0.0), DPoint.new(lastx+@via_L+extend/2.0,0.0)]
        spoly.push(Waveguide.new(pts,@cpw_awidth-extend).poly)
        airpoly.push(Waveguide.new(pts,@cpw_awidth+@cpw_agap*2.0+extend).poly)
        gpoly.push(Waveguide.new(pts,@wground-extend).poly)
      end
      if (@len[iter*3+2] > 0) || (iter == (@len.length/3-1))
        pts = [DPoint.new(lastx+wglength-@via_L-extend/2.0,0.0), DPoint.new(lastx+wglength-extend/2.0,0.0)]
        spoly.push(Waveguide.new(pts,@cpw_awidth-extend).poly)
        airpoly.push(Waveguide.new(pts,@cpw_awidth+@cpw_agap*2.0+extend).poly)
        gpoly.push(Waveguide.new(pts,@wground-extend).poly)
      end
      lastx = lastx + @len[iter*3+1] + @len[iter*3+2]
    end     
    ep = RBA::EdgeProcessor::new()
    out = ep.boolean_p2p(airpoly,gpoly,RBA::EdgeProcessor::ModeBNotA,false, false)
    out.each {|p| shape.insert(p)}   
    spoly.each {|p| shape.insert(p)}                  
  end   
  
  def probe(shape)
    extend = 1.0/@dbu
    spoly = []
    gpoly = []
    airpoly = []  
    start_x = 0.0
    lastx = start_x+@taperL*2.0+@lmmi+@sbend_len
    lr = 0.5*Math::PI*@cpw_radius
    len2 = Array.new(@len)
    len2[0]  = len2[0]-lr
    len2[-1] = len2[-1]-lr
    if len2[0] <= (extend*50.0)
      len2[0] = extend*50.0
    end
    if len2[-1] <= (extend*50.0)
      len2[-1] = extend*50.0
    end
    totlen = 0
    for iter in 0..(len2.length/3-1) do
      wglength = len2[iter*3]
      totlen = totlen + len2[iter*3]+len2[iter*3+1]
      if wglength > 0
        pts = [DPoint.new(lastx-wglength-@via_L-extend/2.0,0.0), DPoint.new(lastx+@via_L+extend/2.0,0.0)]
        spoly.push(Waveguide.new(pts,@cpw_pwidth).poly)
        gpoly.push(Waveguide.new(pts,@wground).poly)
      end
      lastx = lastx + len2[iter*3+1] + len2[iter*3+2]
    end     
    wglength = len2[-1]
    totlen = totlen+len2[-1]
    pts = [DPoint.new(lastx-wglength-@via_L-extend/2.0,0.0), DPoint.new(lastx+@via_L+extend/2.0,0.0)]
    spoly.push(Waveguide.new(pts,@cpw_pwidth).poly)
    gpoly.push(Waveguide.new(pts,@wground).poly)
    firstx = start_x+@taperL*2.0+@lmmi+@sbend_len
    pts = [DPoint.new(firstx-len2[0]-@via_L-extend/2.0,0.0), DPoint.new(lastx+@via_L+extend/2.0,0.0)]
    airpoly.push(Waveguide.new(pts,@cpw_pwidth+@cpw_pgap*2.0).poly)
    #probe
    probe_L = 80.0/@dbu
    taperL = 30.0/@dbu
    probe_w = 90.0/@dbu  
    probe_gap = 18.0/@dbu
    #Bend
    t1 = Trans::new(DTrans::M90) #mirroy along y axis
    lastx = start_x+@taperL*2.0+@lmmi+@sbend_len
    pts = [DPoint::new(lastx-len2[0]-@via_L-extend/2.0+extend,0.0),
           DPoint::new(lastx-len2[0]-@cpw_radius-@via_L-extend/2.0,0.0),
           DPoint::new(lastx-len2[0]-@cpw_radius-@via_L-extend/2.0,@cpw_radius+extend)]
    t2 = Trans::new(totlen+2.0*@via_L-extend+2.0*pts[0].x,0.0)            
    pts = round_corners(pts,@cpw_radius,2.0)
    spoly.push(Waveguide::new(pts,@cpw_pwidth,90.0,0,180.0,90).poly)
    airpoly.push(Waveguide::new(pts,@cpw_pwidth+@cpw_pgap*2.0,90.0,0.0,180.0,90).poly)
    spoly.push(spoly[-1].transformed(t1).transformed(t2))
    airpoly.push(airpoly[-1].transformed(t1).transformed(t2))  
    
    xp0 = lastx-len2[0]-@cpw_radius-@via_L-extend/2.0  
    #Taper
    pts = [DPoint::new(xp0,@cpw_radius),
           DPoint::new(xp0,@cpw_radius+taperL)]
    taper = Taper::new(pts,@cpw_pwidth,probe_w)    
    spoly.push(taper.poly)
    spoly.push(spoly[-1].transformed(t1).transformed(t2))
    taper = Taper::new(pts,@cpw_pwidth+@cpw_pgap*2.0,probe_w+probe_gap*2.0)
    airpoly.push(taper.poly)
    airpoly.push(airpoly[-1].transformed(t1).transformed(t2))
    #Probe
    pts = [DPoint::new(xp0,@cpw_radius+taperL),
           DPoint::new(xp0,@cpw_radius+taperL+probe_L)]    
    wg = Waveguide::new(pts,probe_w)    
    spoly.push(wg.poly)         
    spoly.push(spoly[-1].transformed(t1).transformed(t2))
    wg = Waveguide::new(pts,probe_w+probe_gap*2.0)
    airpoly.push(wg.poly)
    airpoly.push(airpoly[-1].transformed(t1).transformed(t2))
    #ground       
    pts = [DPoint::new(xp0+probe_w/2.0+probe_gap+probe_w,@cpw_radius+probe_L+taperL),
           DPoint::new(xp0+probe_w/2.0+probe_gap+probe_w,-@wground/2.0),
           DPoint::new(xp0-probe_w/2.0-probe_gap-probe_w,-@wground/2.0),
           DPoint::new(xp0-probe_w/2.0-probe_gap-probe_w,@cpw_radius+probe_L+taperL)]
    poly = Polygon::from_dpoly(DPolygon::new(pts))
    gpoly.push(poly.round_corners(0.0/@dbu,5.0/@dbu,128))   
    gpoly.push(gpoly[-1].transformed(t1).transformed(t2))    
    ep = RBA::EdgeProcessor::new()
    out = ep.boolean_p2p(airpoly,gpoly,RBA::EdgeProcessor::ModeBNotA,false, false)
    out.each {|p| shape.insert(p)}   
    spoly.each {|p| shape.insert(p)} 
    #airpoly.each {|p| shape.insert(p)} 
  end
  def ports
    return @ports
  end
end

def divL(x,activeL,num) 
  lens = Array.new()
  for iter in 0..(num-3)
      lens =lens + [x[iter]]+[activeL]+[x[iter+1]];
  end
  lens = lens+[x[num-2]]+[activeL]+[x[num-1]];
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
  cell = layout.create_cell("PZT_Modulator_40G_L4mm")  
  pzt = PZT_Modulator.new()
  len = [0.0,4000.0,0.0]
  pzt.len = len.collect{|l| l/dbu}
  pzt.shapes(cell)

  cell = layout.create_cell("PZT_Modulator_55G_L7mm")  
  pzt = PZT_Modulator.new()
  plen = [0,0,0,0,0,50,250,450,450,550,350,50,150,250,250,150,50,0,0,0,0]
  activeL = 4000.0/(plen.length-1.0)
  len = divL(plen,activeL,21) 
  pzt.len = len.collect{|l| l/dbu}
  pzt.shapes(cell)
 
  cell = layout.create_cell("PZT_Modulator_70G_L8mm")  
  pzt = PZT_Modulator.new()
  plen = [0,0,0,0,0,0,0,0,100,0,100,100,0,100,100,0,150,100,250,150,250,250,200,
          300,400,150,200,100,0,0,0,0,0,100,0,100,100,200,100,100,0,100,0,0,0,0,0,0,100,0,0]
  activeL = 4000.0/(plen.length-1.0)
  len = divL(plen,activeL,51) 
  pzt.len = len.collect{|l| l/dbu}
  pzt.shapes(cell)

  cell = layout.create_cell("PZT_Modulator_80G_L9.5mm")  
  pzt = PZT_Modulator.new()
  plen = [0.0,0.0,0.0,0.0,24.9,65.4,32.7,0.0,0.0,20.8,0.0,0.0,44.9,30.1,61.9,0.0,0.0,20.2,32.9,
          62.4,81.2,92.9,68.5,49.7,112.6,55.4,67.8,123.7,64.7,43.8,101.3,46.9,53.5,77.9,75.1,55.8,
          72.8,67.3,130.3,59.2,119.3,147.2,79.2,86.3,101.6,136.9,174.5,127.9,122.1,160.9,64.7,113.6,
          74.4,72.6,56.7,85.4,57.8,56.5,106.5,54.5,102.1,20.7,30.0,83.3,49.3,70.3,78.9,0.0,67.0,82.8,
          29.4,43.0,52.2,31.9,34.2,67.7,28.4,54.4,46.7,48.5,38.0,0.0,79.0,20.4,33.9,50.2,26.2,0.0,64.0,
          0.0,38.2,0.0,48.0,0.0,20.2,0.0,0.0,0.0,0.0,0.0,0.0]
  activeL = 4000.0/(plen.length-1.0)
  len = divL(plen,activeL,101) 
  pzt.len = len.collect{|l| l/dbu}
  pzt.shapes(cell)

  cell = layout.create_cell("PZT_Modulator_90G_L10mm")  
  pzt = PZT_Modulator.new()
  plen = [25.8,40.0,0.0,0.0,49.1,0.0,26.9,40.4,60.2,26.5,40.6,0.0,91.2,34.6,47.2,81.5,0.0,29.8,69.5,112.5,
          101.6,79.1,87.8,144.7,79.7,104.2,89.1,85.3,105.1,117.1,57.9,135.2,68.2,107.0,35.3,124.4,120.1,92.7,
          91.4,71.8,79.5,45.8,48.1,71.1,81.9,91.9,140.9,121.5,97.2,178.7,97.4,142.2,50.8,117.1,70.8,146.7,79.2,
          60.5,98.1,55.8,95.3,66.3,23.6,106.8,79.8,0.0,67.9,32.4,28.2,0.0,27.0,72.0,121.6,29.7,102.9,62.6,38.3,
          0.0,28.1,0.0,35.6,0.0,0.0,38.3,31.0,68.7,29.0,0.0,0.0,63.9,0.0,22.5,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
  activeL = 4000.0/(plen.length-1.0)
  len = divL(plen,activeL,101) 
  pzt.len = len.collect{|l| l/dbu}
  pzt.shapes(cell)
            
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
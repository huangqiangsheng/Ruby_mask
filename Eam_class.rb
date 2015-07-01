load "waveguide.rb"


class Eam_Lump
  include MyBasic
  include RBA
  attr_accessor :mesa_width_in, :mesa_width_hybrid, 
                :mqw_width_in,:mqw_width_hybrid,
                :nInP_width, :nInP_length,             
                :taper1, :taper2, :nmetal_gap,
                :lay_mesa, :lay_mqw, :lay_nInP,
                :lay_nmetal, :lay_pvia, :lay_nvia, :lay_probe,
                :dbu
                
  def initialize(mesa_width_in = 1.4,
                 mesa_width_hybrid = 3.0,
                 mqw_width_in = 1.8,
                 mqw_width_hybrid = 4.0,
                 nInP_width = 50.0,
                 nInP_length = 300.0,
                 taper1 = 90.0,
                 taper2 = 15.0,
                 wg_length = 100.0,
                 nmetal_gap = 8.0,
                 lay_mesa = CellView::active.layout.layer(1, 1),
                 lay_mqw = CellView::active.layout.layer(3, 1),
                 lay_nInP = CellView::active.layout.layer(4, 1),
                 lay_nmetal = CellView::active.layout.layer(5, 1),
                 lay_pvia = CellView::active.layout.layer(8, 1),
                 lay_nvia = CellView::active.layout.layer(7, 1),
                 lay_probe = CellView::active.layout.layer(9, 1),
                 dbu = CellView::active.layout.dbu)
    @dbu = dbu             
    @mesa_width_in = mesa_width_in/@dbu
    @mesa_width_hybrid = mesa_width_hybrid/@dbu
    @mqw_width_in = mqw_width_in/@dbu
    @mqw_width_hybrid = mqw_width_hybrid/@dbu
    @nInP_width = nInP_width/@dbu
    if wg_length+(taper1+taper2)*2.0>nInP_length
      nInP_length =  wg_length+(taper1+taper2)*2.0+60.0
    end
    @nInP_length = nInP_length/@dbu  
    @taper1 = taper1/@dbu
    @taper2 = taper2/@dbu
    @wg_length = wg_length/@dbu
    @nmetal_gap = nmetal_gap/@dbu
    @lay_mesa = lay_mesa
    @lay_mqw = lay_mqw
    @lay_nInP = lay_nInP
    @lay_nmetal = lay_nmetal
    @lay_pvia = lay_pvia
    @lay_nvia = lay_nvia
    @lay_probe = lay_probe
    @nprobe_w = (@nInP_width - @nmetal_gap - 6.0/@dbu)/2.0
    @nproble_l = 20.0/@dbu
    @ports = []
  end
  def wg_length(wg_length)
    @wg_length = wg_length
    if @wg_length+(@taper1+@taper2)*2.0>@nInP_length
      @nInP_length =  @wg_length+(@taper1+@taper2)*2.0-50.0/@dbu
    else
      @nInP_length = 300.0/@dbu
    end 
    @nprobe_w = (@nInP_width - @nmetal_gap - 6.0/@dbu)/2.0
  end
  def shapes(cell)
    @ports = []
    @ports.push(Ports::new(width = @mesa_width_hybrid,
                          direction = Math::PI,
                          face_angle = direction+Math::PI/2.0,
                          point = DPoint::new(0.0,0.0)))      
    shape = cell.shapes(@lay_mesa)
    mesa(shape)
    shape = cell.shapes(@lay_mqw)
    mqw(shape)
    shape = cell.shapes(@lay_nInP)
    nInP(shape)
    shape = cell.shapes(@lay_nmetal)
    nmetal(shape)
    shape = cell.shapes(@lay_pvia)
    pvia(shape)
    shape = cell.shapes(@lay_nvia)
    nvia(shape)   
    shape = cell.shapes(@lay_probe)
    probe(shape)              
  end  
  def mesa(shape)
    pts = [DPoint::new(0.0,0.0),DPoint::new(@wg_length,0.0)]
    wg = Waveguide::new(pts,@mesa_width_hybrid)
    shape.insert(wg.poly)
    pts = [DPoint::new(-@taper2,0.0),DPoint::new(0.0,0.0)]
    taper = Taper::new(pts,@mesa_width_in,@mesa_width_hybrid)
    shape.insert(taper.poly)
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(taper.poly.transformed(t1).transformed(t2))
    
    exten_length = 18.0/@dbu
    pts = [DPoint::new(-@taper2-exten_length,0.0),DPoint::new(-@taper2,0.0)]
    wg = Waveguide::new(pts,@mesa_width_in)
    shape.insert(wg.poly) 
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(wg.poly.transformed(t1).transformed(t2))       
  end
  def mqw(shape)
    pts = [DPoint::new(-@taper2,0.0),DPoint::new(@wg_length+@taper2,0.0)]
    wg = Waveguide::new(pts,@mqw_width_hybrid)
    shape.insert(wg.poly)
    pts = [DPoint::new(-@taper1-@taper2,0.0),DPoint::new(-@taper2,0.0)]
    taper = Taper::new(pts,@mqw_width_in,@mqw_width_hybrid)
    shape.insert(taper.poly)
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(taper.poly.transformed(t1).transformed(t2))
    tip = Circle.new(DPoint::new(-@taper1-@taper2,0.0), @mqw_width_in/2.0,90.0,270)
    shape.insert(tip.poly)
    shape.insert(tip.poly.transformed(t1).transformed(t2))
    
    tmpw = [@mqw_width_hybrid,@mqw_width_hybrid-1.5/@dbu,(@mqw_width_hybrid-1.5/@dbu)/2.0]
    (1..3).each do |iter|
      pts = [DPoint::new(0.0,-@nInP_width/2.0-10.0*iter/@dbu),DPoint::new(@wg_length,-@nInP_width/2.0-10.0*iter/@dbu)]
      wg = Waveguide::new(pts,tmpw[iter-1])
      shape.insert(wg.poly)
    end
  end  
  def nInP(shape)
    offset = 0.0/@dbu
    pts = [DPoint::new(-@taper2-@taper1-offset,0.0),DPoint::new(@wg_length+@taper2+@taper1+offset,0.0)]
    wg = Waveguide::new(pts,@nInP_width)
    shape.insert(wg.poly)
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0,@nInP_width/2.0-@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0,@nInP_width/2.0-@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(0.0,-@nInP_width+@nprobe_w)
    shape.insert(wg.poly.transformed(t1))
  end    
  def nmetal(shape)
    offset= 3.0/@dbu
    pts = [DPoint::new(0.0,-@nmetal_gap/2.0-offset/2.0),DPoint::new(@wg_length,-@nmetal_gap/2.0-offset/2.0)]
    wg = Waveguide::new(pts,offset)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))
       
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))           
  end
  
  def pvia(shape)
    offset = 1.0/@dbu
    pts = [DPoint::new(0.0,0.0),DPoint::new(@wg_length,0.0)]
    wg = Waveguide::new(pts,@mesa_width_hybrid-offset)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))
    
    offset = 1.0/@dbu
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0+offset,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0+@nproble_l+offset,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))  
           
    pts = [DPoint::new(@wg_length/2.0+@nInP_length/2.0-@nproble_l-offset,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0-offset,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))          
  end  
  
  def nvia(shape)

    offset = 1.0/@dbu
    smaller = 1.0/@dbu
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0+offset+smaller,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0+@nproble_l+offset-smaller,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w-2.0*smaller)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))  
           
    pts = [DPoint::new(@wg_length/2.0+@nInP_length/2.0-@nproble_l-offset+smaller,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0-offset-smaller,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w-2.0*smaller)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))          
  end   
  
  def probe(shape)

    pprobe_width = 10.0/@dbu
    pts = [DPoint::new(0.0,0.0),
           DPoint::new(@wg_length,0.0)]
    wg = Waveguide::new(pts,pprobe_width)
    shape.insert(wg.poly)
    
    proble_w1 = 10.0/@dbu
    proble_w2 = 90.0/@dbu
    pts = [DPoint::new(@wg_length/2.0,pprobe_width/2.0),
           DPoint::new(@wg_length/2.0,@nInP_width/2.0)]    
    wg = Waveguide::new(pts,proble_w1)
    shape.insert(wg.poly)
    
    taperL = 30.0/@dbu
    pts = [DPoint::new(@wg_length/2.0,@nInP_width/2.0),
           DPoint::new(@wg_length/2.0,@nInP_width/2.0+taperL)]    
    taper = Taper::new(pts,proble_w1,proble_w2)    
    shape.insert(taper.poly)
    
    probe_L = 80.0/@dbu
    pts = [DPoint::new(@wg_length/2.0,@nInP_width/2.0+taperL),
           DPoint::new(@wg_length/2.0,@nInP_width/2.0+taperL+probe_L)]    
    wg = Waveguide::new(pts,proble_w2)    
    shape.insert(wg.poly)         
    
    gap = 10.0/@dbu
    
    pts = [DPoint::new(@wg_length/2.0-proble_w2/2.0-gap,@nInP_width/2.0+taperL+probe_L),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0,@nInP_width/2.0+taperL+probe_L),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0,-@nInP_width/2.0),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0+@nproble_l+2.0/@dbu,-@nInP_width/2.0),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0+@nproble_l+2.0/@dbu,@nInP_width/2.0),
           DPoint::new(@wg_length/2.0-proble_w2/2.0-gap,@nInP_width/2.0+taperL)]
    poly = Polygon::from_dpoly(DPolygon::new(pts))
    shape.insert(poly)
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(poly.transformed(t1).transformed(t2))            
  end    
  def ports
    return @ports
  end
end

class Eam_TW
  include MyBasic
  include RBA
  attr_accessor :mesa_width_in, :mesa_width_hybrid, 
                :mqw_width_in,:mqw_width_hybrid,
                :nInP_width, :nInP_length,             
                :taper1, :taper2, :wg_length, :nmetal_gap,
                :cpw_radius, :cpw_gap, :cpw_width,
                :lay_mesa, :lay_mqw, :lay_nInP,
                :lay_nmetal, :lay_pvia, :lay_nvia, :lay_probe,
                :dbu
                
  def initialize(mesa_width_in = 1.4,
                 mesa_width_hybrid = 3.0,
                 mqw_width_in = 1.8,
                 mqw_width_hybrid = 4.0,
                 nInP_width = 50.0,
                 nInP_length = 300.0,
                 taper1 = 90.0,
                 taper2 = 15.0,
                 wg_length = 800.0,
                 nmetal_gap = 8.0,
                 cpw_gap = 15.0,
                 cpw_radius = 50.0,
                 cpw_width = 8.0,
                 lay_mesa = CellView::active.layout.layer(1, 0),
                 lay_mqw = CellView::active.layout.layer(3, 0),
                 lay_nInP = CellView::active.layout.layer(4, 0),
                 lay_nmetal = CellView::active.layout.layer(5, 0),
                 lay_pvia = CellView::active.layout.layer(8, 0),
                 lay_nvia = CellView::active.layout.layer(7, 0),
                 lay_probe = CellView::active.layout.layer(9, 0),
                 dbu = CellView::active.layout.dbu )
    @dbu = dbu             
    @mesa_width_in = mesa_width_in/@dbu
    @mesa_width_hybrid = mesa_width_hybrid/@dbu
    @mqw_width_in = mqw_width_in/@dbu
    @mqw_width_hybrid = mqw_width_hybrid/@dbu
    @nInP_width = nInP_width/@dbu
    if wg_length+(taper1+taper2)*2.0>nInP_length
      nInP_length =  wg_length+(taper1+taper2)*2.0+60.0
    end
    @nInP_length = nInP_length/@dbu  
    @taper1 = taper1/@dbu
    @taper2 = taper2/@dbu
    @wg_length = wg_length/@dbu
    @nmetal_gap = nmetal_gap/@dbu
    @lay_mesa = lay_mesa
    @lay_mqw = lay_mqw
    @lay_nInP = lay_nInP
    @lay_nmetal = lay_nmetal
    @lay_pvia = lay_pvia
    @lay_nvia = lay_nvia
    @lay_probe = lay_probe
    @nprobe_w = (@nInP_width - @nmetal_gap - 6.0/@dbu)/2.0
    @nproble_l = 20.0/@dbu
    @cpw_radius = cpw_radius/@dbu
    @cpw_gap = cpw_gap/@dbu
    @cpw_width = cpw_width/@dbu
    @ports = []
  end
  def shapes(cell)
    @ports = []
    @ports.push(Ports::new(width = @mesa_width_hybrid,
                          direction = Math::PI,
                          face_angle = direction+Math::PI/2.0,
                          point = DPoint::new(0.0,0.0)))      
    shape = cell.shapes(@lay_mesa)
    mesa(shape)
    shape = cell.shapes(@lay_mqw)
    mqw(shape)
    shape = cell.shapes(@lay_nInP)
    nInP(shape)
    shape = cell.shapes(@lay_nmetal)
    nmetal(shape)
    shape = cell.shapes(@lay_pvia)
    pvia(shape)
    shape = cell.shapes(@lay_nvia)
    nvia(shape)   
    shape = cell.shapes(@lay_probe)
    probe(shape)              
  end  
  def mesa(shape)
    pts = [DPoint::new(0.0,0.0),DPoint::new(@wg_length,0.0)]
    wg = Waveguide::new(pts,@mesa_width_hybrid)
    shape.insert(wg.poly)
    pts = [DPoint::new(-@taper2,0.0),DPoint::new(0.0,0.0)]
    taper = Taper::new(pts,@mesa_width_in,@mesa_width_hybrid)
    shape.insert(taper.poly)
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(taper.poly.transformed(t1).transformed(t2))
    
    exten_length = 18.0/@dbu
    pts = [DPoint::new(-@taper2-exten_length,0.0),DPoint::new(-@taper2,0.0)]
    wg = Waveguide::new(pts,@mesa_width_in)
    shape.insert(wg.poly) 
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(wg.poly.transformed(t1).transformed(t2))       
  end
  def mqw(shape)
    pts = [DPoint::new(-@taper2,0.0),DPoint::new(@wg_length+@taper2,0.0)]
    wg = Waveguide::new(pts,@mqw_width_hybrid)
    shape.insert(wg.poly)
    pts = [DPoint::new(-@taper1-@taper2,0.0),DPoint::new(-@taper2,0.0)]
    taper = Taper::new(pts,@mqw_width_in,@mqw_width_hybrid)
    shape.insert(taper.poly)
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)
    shape.insert(taper.poly.transformed(t1).transformed(t2))
    tip = Circle.new(DPoint::new(-@taper1-@taper2,0.0), @mqw_width_in/2.0,90.0,270)
    shape.insert(tip.poly)
    shape.insert(tip.poly.transformed(t1).transformed(t2))
    
    tmpw = [@mqw_width_hybrid,@mqw_width_hybrid-1.5/@dbu,(@mqw_width_hybrid-1.5/@dbu)/2.0]
    (1..3).each do |iter|
      pts = [DPoint::new(0.0,-@nInP_width/2.0-10.0*iter/@dbu),DPoint::new(@wg_length,-@nInP_width/2.0-10.0*iter/@dbu)]
      wg = Waveguide::new(pts,tmpw[iter-1])
      shape.insert(wg.poly)
    end
  end  
  def nInP(shape)
    offset = 20.0/@dbu
    pts = [DPoint::new(-@taper2-@taper1-offset,0.0),DPoint::new(@wg_length+@taper2+@taper1+offset,0.0)]
    wg = Waveguide::new(pts,@nInP_width)
    shape.insert(wg.poly)
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0,@nInP_width/2.0-@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0,@nInP_width/2.0-@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(0.0,-@nInP_width+@nprobe_w)
    shape.insert(wg.poly.transformed(t1))
  end    
  def nmetal(shape)
    offset= 3.0/@dbu
    pts = [DPoint::new(0.0,-@nmetal_gap/2.0-offset/2.0),DPoint::new(@wg_length,-@nmetal_gap/2.0-offset/2.0)]
    wg = Waveguide::new(pts,offset)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))
       
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))           
  end
  
  def pvia(shape)
    offset = 1.0/@dbu
    pts = [DPoint::new(0.0,0.0),DPoint::new(@wg_length,0.0)]
    wg = Waveguide::new(pts,@mesa_width_hybrid-offset)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))
    
    offset = 1.0/@dbu
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0+offset,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0+@nproble_l+offset,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))  
           
    pts = [DPoint::new(@wg_length/2.0+@nInP_length/2.0-@nproble_l-offset,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0-offset,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))          
  end  
  
  def nvia(shape)

    offset = 1.0/@dbu
    smaller = 1.0/@dbu
    pts = [DPoint::new(@wg_length/2.0-@nInP_length/2.0+offset+smaller,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0-@nInP_length/2.0+@nproble_l+offset-smaller,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w-2.0*smaller)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))  
           
    pts = [DPoint::new(@wg_length/2.0+@nInP_length/2.0-@nproble_l-offset+smaller,-@nInP_width/2.0+@nprobe_w/2.0),
           DPoint::new(@wg_length/2.0+@nInP_length/2.0-offset-smaller,-@nInP_width/2.0+@nprobe_w/2.0)]
    wg = Waveguide::new(pts,@nprobe_w-2.0*smaller)
    shape.insert(wg.poly)
    t1 = Trans::new(Trans::M0)
    shape.insert(wg.poly.transformed(t1))          
  end   
  
  def probe(shape)
    poly1 = []
    poly2 = []
    t1 = Trans::new(DTrans::M90)
    t2 = Trans::new(@wg_length,0.0)  
    t3 = Trans::new(DTrans::M0)   
    pts = [DPoint::new(-@cpw_radius,@cpw_radius),
           DPoint::new(-@cpw_radius,0.0),
           DPoint::new(@wg_length+@cpw_radius,0.0),
           DPoint::new(@wg_length+@cpw_radius,-@cpw_radius)]
    pts = round_corners(pts,@cpw_radius,2.0)
    wg = Waveguide::new(pts,@cpw_width,0,0)
    poly1.push(wg.poly)
    wg = Waveguide::new(pts,@cpw_width+@cpw_gap*2.0,0,0)
    poly2.push(wg.poly)
    
    taperL = 30.0/@dbu
    proble_w = 90.0/@dbu
    pts = [DPoint::new(-@cpw_radius,@cpw_radius),
           DPoint::new(-@cpw_radius,@cpw_radius+taperL)]
    taper = Taper::new(pts,@cpw_width,proble_w)    
    poly = taper.poly
    poly1.push(poly)
    poly1.push(poly.transformed(t1).transformed(t2).transformed(t3))
    taper = Taper::new(pts,@cpw_width+@cpw_gap*2.0,proble_w+@cpw_gap*2.0)
    poly = taper.poly
    poly2.push(poly)
    poly2.push(poly.transformed(t1).transformed(t2).transformed(t3))
    
    
    probe_L = 80.0/@dbu
    pts = [DPoint::new(-@cpw_radius,@cpw_radius+taperL),
           DPoint::new(-@cpw_radius,@cpw_radius+taperL+probe_L)]    
    wg = Waveguide::new(pts,proble_w)    
    poly = wg.poly
    poly1.push(poly)         
    poly1.push(poly.transformed(t1).transformed(t2).transformed(t3))
    wg = Waveguide::new(pts,proble_w+@cpw_gap*2.0)
    poly = wg.poly
    poly2.push(poly)
    poly2.push(poly.transformed(t1).transformed(t2).transformed(t3))
    nprobe_w = 90.0/@dbu
    pts = [DPoint::new(-@cpw_radius-proble_w/2.0-@cpw_gap-nprobe_w,@cpw_radius+taperL+probe_L),
           DPoint::new(-@cpw_radius-proble_w/2.0-@cpw_gap-nprobe_w,-(@cpw_radius+taperL+probe_L)),
           DPoint::new(@wg_length+@cpw_radius+proble_w/2.0+@cpw_gap+nprobe_w,-(@cpw_radius+taperL+probe_L)),
           DPoint::new(@wg_length+@cpw_radius+proble_w/2.0+@cpw_gap+nprobe_w,(@cpw_radius+taperL+probe_L))]
    poly = Polygon::from_dpoly(DPolygon::new(pts))
    rpoly = poly.round_corners(0.0/@dbu,5.0/@dbu,128)
    ep = RBA::EdgeProcessor::new()
    out = ep.boolean_p2p(poly2,[rpoly],RBA::EdgeProcessor::ModeBNotA,false, false)
    out.each {|p| shape.insert(p)}   
    poly1.each {|p| shape.insert(p)}     
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
  layout = main_window.create_layout(1).layout
  layout_view = main_window.current_view
  # set the database unit (shown as an example, the default is 0.001)
  dbu = 0.001
  layout.dbu = dbu
  # create a cell
  cell = layout.create_cell("EAM_LUMP")
  
  wg35 = Eam_Lump.new()
  wg35.shapes(cell)
  
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
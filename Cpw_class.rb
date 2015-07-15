load "waveguide.rb"
# Enter your Ruby code here

class Cpw_straight
  include MyBasic
  include RBA
  attr_accessor :cpw_gap, :cpw_swidth, :cpw_width,
                :taperL, :probe_w,:probe_L,
                :lay_cpw,:lay_gcpw,:dbu,:wg_length
                
  def initialize(cpw_gap = 18.0,
                 cpw_swidth = 10.0,
                 cpw_width = 350.0,
                 taperL = 30.0,
                 probe_w = 90.0,
                 probe_L = 90.0,
                 lay_cpw = CellView::active.layout.layer(1, 0),
                 lay_gcpw = CellView::active.layout.layer(1, 1),
                 dbu = CellView::active.layout.dbu,
                 wg_length = 100.0)
    @dbu = dbu             
    @cpw_gap = cpw_gap/@dbu
    @cpw_swidth = cpw_swidth/@dbu
    @cpw_width = cpw_width/@dbu
    @wg_length = wg_length/@dbu
    @taperL = taperL/@dbu
    @probe_w = probe_w/@dbu
    @probe_L = probe_L/@dbu
    @lay_cpw = lay_cpw
    @lay_gcpw = lay_gcpw
    @ports = []
  end
  def shapes(cell)
    @ports = []
    @ports.push(Ports::new(width = @cpw_swidth,
                          direction = Math::PI,
                          face_angle = direction+Math::PI/2.0,
                          point = DPoint::new(0.0,0.0)))      
    shape = cell.shapes(@lay_cpw) 
    gshape = cell.shapes(@lay_gcpw) 
    
    poly1 = []
    poly2 = []
    t1 = Trans::new(DTrans::M90) #mirroy along y axis
    t2 = Trans::new(@wg_length,0.0) 
    pts = [DPoint::new(0.0,0.0),
           DPoint::new(@wg_length,0.0)]
    wg = Waveguide::new(pts,@cpw_swidth)
    poly1.push(wg.poly)
    wg = Waveguide::new(pts,@cpw_swidth+2.0*@cpw_gap)
    poly2.push(wg.poly)
    
    pts = [DPoint::new(-@taperL,0.0),
           DPoint::new(0.0,0.0)]
    taper = Taper::new(pts,@probe_w,@cpw_swidth)    
    poly1.push(taper.poly)
    poly1.push(poly1[-1].transformed(t1).transformed(t2))
    taper = Taper::new(pts,@probe_w+@cpw_gap*2.0,@cpw_swidth+@cpw_gap*2.0)
    poly2.push(taper.poly)
    poly2.push(poly2[-1].transformed(t1).transformed(t2))
    
    pts = [DPoint::new(-@taperL-@probe_L,0.0),
           DPoint::new(-@taperL,0.0)]    
    wg = Waveguide::new(pts,@probe_w)    
    poly1.push(wg.poly)
    poly1.push(poly1[-1].transformed(t1).transformed(t2))
    wg = Waveguide::new(pts,@probe_w+@cpw_gap*2.0)
    poly2.push(wg.poly)
    poly2.push(poly2[-1].transformed(t1).transformed(t2))
    

    pts = [DPoint::new(-@taperL-@probe_L,0.0),
           DPoint::new(@wg_length+@taperL+@probe_L,0.0)]
    wg = Waveguide::new(pts,@cpw_width)  
    poly = wg.poly
    rpoly = poly.round_corners(0.0/@dbu,5.0/@dbu,128)
    shape.insert(rpoly)
    ep = RBA::EdgeProcessor::new()
    out = ep.boolean_p2p(poly1,poly2,RBA::EdgeProcessor::ModeBNotA,false, false)
    out.each {|p| gshape.insert(p)}   
          
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
  cell = layout.create_cell("CPW")  
  cpw = Cpw_straight.new()
  cpw.shapes(cell)
    
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end

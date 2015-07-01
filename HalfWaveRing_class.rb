require "waveguide.rb"
#creat grating coupler
class HalfWaveRing
  include MyBasic
  include RBA
  attr_accessor :radius, :width, :coupler_length, :gap,
                :extension_length, :layer_ring, :layer_coupler,
                :centre_line, :dbu
                
  def initialize(radius = 50.0,
                 width = 0.45,
                 coupler_length = 30.0,
                 gap = 0.2,
                 extension_length = 100.0,
                 layer_ring = CellView::active.layout.layer(1, 0),
                 layer_coupler = CellView::active.layout.layer(2, 0),
                 centre_line = nil,
                 dbu = CellView::active.layout.dbu)
    @dbu = dbu           
    @radius = radius/@dbu
    @width = width/@dbu
    @coupler_length = coupler_length/@dbu
    @gap = gap/@dbu
    @extension_length = extension_length/@dbu
    @layer_ring = layer_ring
    @layer_coupler = layer_coupler
    @centre_line = centre_line
    @centre_line =centre_line
    @ports = []
  end
  
  def shapes(cell)
    @ports=[]
    pts = [DPoint::new(0.0,0.0),DPoint::new(@extension_length+@coupler_length+@extension_length,0.0)]
    @ports.push(Ports::new(width = @width,
                          direction = line_angle(pts[1],pts[0]),
                          face_angle = direction+Math::PI/2.0,
                          point = pts[0]))
    @ports.push(Ports::new(width = @with,
                          direction = Math::PI+line_angle(pts[1],pts[0]),
                          face_angle = direction+Math::PI/2.0,
                          point = pts[1]))                               
    wg1 = Waveguide.new(pts,@width)
    cell.shapes(@layer_coupler).insert(wg1.poly)
    if @centre_line
      layercentre = CellView::active.layout.layer(@layer_coupler+1, 1)
      wg1 = Waveguide.new(pts,0)
      cell.shapes(layercentre).insert(wg1.poly)
    end
    gap = @width+@gap
    pts = [DPoint::new(@extension_length,gap),DPoint::new(@extension_length+@coupler_length,gap)]
    wg2 = Waveguide.new(pts,@width)
    cell.shapes(@layer_coupler).insert(wg2.poly) 
    if @centre_line
      wg2 = Waveguide.new(pts,0)
      cell.shapes(layercentre).insert(wg2.poly)
    end 
    pts = [DPoint::new(@extension_length,gap*2.0),
           DPoint::new(@extension_length+@coupler_length+@radius,gap*2.0),
           DPoint::new(@extension_length+@coupler_length+@radius,gap*2.0+@radius*2.0),
           DPoint::new(@extension_length-@radius,gap*2.0+@radius*2.0),
           DPoint::new(@extension_length-@radius,gap*2.0),
           DPoint::new(@extension_length,gap*2.0)]
    pts = round_corners(pts,@radius)
    wg3 = Waveguide.new(pts,@width,nil,nil)
    cell.shapes(@layer_ring).insert(wg3.poly)
    if @centre_line
      wg3 = Waveguide.new(pts,0)
      cell.shapes(layercentre).insert(wg3.poly)
    end      
  end
  
  def ports
    return @ports
  end
end

# create a new view (mode 1) with an empty layout
if __FILE__ == $0
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
  ltot = 377.0
  gap = [0.45,0.45,0.6,0.6]
  L = [19.0, 21.5, 43.5, 49]
  radius = L.collect {|x| (ltot - 2.0*x)/(2.0*Math::PI)} 
  cell = []
  cell.push( layout.create_cell("half_wave_ring_gap0.45_L19"))
  cell.push( layout.create_cell("half_wave_ring_gap0.45_L21.5"))
  cell.push( layout.create_cell("half_wave_ring_gap0.6_L43.5"))
  cell.push( layout.create_cell("half_wave_ring_gap0.6_L49"))
 
  ring = HalfWaveRing.new()
  ring.centre_line = true
  #################Grating Coupler##############
  gccell = layout.create_cell("Grating_Coupler_340nm")
  gcoupler = GratingCoupler.new()
  gcoupler.width_in = 0.45/dbu
  gcoupler.period = 0.64/dbu
  gcoupler.duty = 0.38
  gcoupler.shapes(gccell)
  
  for iter in 0..(cell.length-1)
    ring.radius = radius[iter]/dbu
    ring.width = 0.45/dbu
    ring.coupler_length = L[iter]/dbu
    ring.gap = gap[iter]/dbu
    ring.shapes(cell[iter])
    
    overlap = 0.1/dbu
    ring.ports.each do |port|
      angle = (port.direction-gcoupler.ports[0].direction-Math::PI)
      tmpover = DPoint::new(overlap*Math::cos(angle),overlap*Math::sin(angle))
      disp = port.point-gcoupler.ports[0].point - tmpover
      t = CplxTrans::new(1.0, angle/Math::PI*180.0,false,disp)
      tmp = CellInstArray::new(gccell.cell_index,t)
      cell[iter].insert(tmp)
    end  
  end
  topcell = layout.create_cell("Top")
  dy = 200.0/dbu
  for iter in 0..(cell.length-1)
    t = CplxTrans::new(1.0, 0,false,0.0,iter*dy)
    tmp = CellInstArray::new(cell[iter].cell_index,t)
    topcell.insert(tmp) 
  end  
  layout_view.select_cell(topcell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
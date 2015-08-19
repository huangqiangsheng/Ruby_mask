load "waveguide.rb"

class Trenchwaveguide
  include MyBasic
  include RBA
  attr_accessor :wg_width, :trench_width, 
                :end_face_angle,:start_face_angle,
                :start_angle, :end_angle,
                :lay_wg,:lay_trwg, :self_poly_flag
                
  def initialize(pts, 
                 wg_width = 2.0, 
                 trench_width = 3.0, 
                 start_face_angle = nil, 
                 end_face_angle = nil,
                 start_angle = nil,
                 end_angle = nil,
                 lay_wg = CellView::active.layout.layer(1, 0),
                 lay_trwg = CellView::active.layout.layer(1, 1),                 
                 self_poly_flag = 0,
                 dbu = CellView::active.layout.dbu) 
    @dbu = dbu
    @pts = pts.collect{|p| p*(1/@dbu)}
    @wg_width = wg_width/@dbu
    @trench_width = trench_width/@dbu      
    @start_face_angle = start_face_angle
    @end_face_angle = end_face_angle
    @self_poly_flag = self_poly_flag
    @start_angle = start_angle
    @end_angle = end_angle
    @lay_wg = lay_wg
    @lay_trwg = lay_trwg
    @ports = []
  end
  def pts=(pt)
    @pts = pt.collect{|p| p*(1/@dbu)}
  end
  def pts
    @pts
  end  
  def dbu=(unit)
    @dbu = unit
    @pts = pts.collect{|p| p*(1/@dbu)}
    @wg_width = wg_width/@dbu
    @trench_width = trench_width/@dbu    
  end
  def dbu
    @dbu
  end
  def shapes(cell)
    wg = Waveguide.new(@pts, @wg_width, @start_face_angle, @end_face_angle,@start_angle,@end_angle,@self_poly_flag)  
    @ports = []
    @ports.push(Ports::new(width = @wg_width,
                          direction = wg.start_angle+Math::PI,
                          face_angle = @start_face_angle,
                          point = pts[0]))
    @ports.push(Ports::new(width = @wg_width,
                          direction = wg.end_angle,
                          face_angle = @start_face_angle,
                          point = pts[0]))                              
    wgshape = cell.shapes(@lay_wg) 
    trshape = cell.shapes(@lay_trwg) 
    wgshape.insert(wg.poly)
    wg.width = @trench_width
    trshape.insert(wg.poly)         
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
  cell = layout.create_cell("Top")  
  pts = [DPoint.new(0.0,0.0), DPoint.new(10.0,0.0),DPoint.new(10.0,10.0),DPoint.new(20.0,30.0),DPoint.new(10.0,60.0)]
  pts = round_corners(pts,5.0)
  tr = Trenchwaveguide.new(pts,2.0,4.0)
  tr.trench_width = 6.0/dbu
  tr.shapes(cell)
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
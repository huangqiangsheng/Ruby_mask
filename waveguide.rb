module MyBasic
  include RBA
  # define the angle of the vector v1,v2
  def vector_angle(v1,v2)
    vcross = v1.x*v2.y-v1.y*v2.x
    vdot = v1.x*v2.x+v1.y*v2.y
    val = vcross/Math.sqrt(v1.sq_abs*v2.sq_abs)
    if val.abs >1
       val = val/val.abs*1      
    end
    if vdot >= 0
      return Math.asin(val)
    elsif vcross !=0
      return vcross/vcross.abs*Math::PI - Math.asin(val)
    else
      return Math::PI - Math.asin(val)
    end
  end
  
  # define the angle of the vector p1->p2 with x axis
  def line_angle(p1,p2)
    v1 = RBA::DPoint.new(1,0)
    v2 = p2-p1
    return vector_angle(v1,v2)
  end
  
  
  def remove_straight_angles(pts)
    tmppts = [] # remove the same point
    pts[0..-2].each_with_index do |pt,iter|
      v1 = pt - pts[iter+1]
      if v1.sq_abs<1e-5
        next
      end
      tmppts.push(pt)
    end
    tmppts.push(pts[-1])
    
    newpts = [tmppts[0]]
    if 3 <= tmppts.length
      tmppts[1..-2].each_with_index do |pt,iter|
        v1 = pt - tmppts[iter]
        v2 = tmppts[iter+2]-pt
        if vector_angle(v1,v2).abs< 1e-5
          next
        else
          newpts.push(pt)
        end
      end
    elsif 1 == tmppts.length
      return newpts
    end 
    newpts.push(tmppts[-1])
    return newpts
  end
  
  def linearc(centre,radius,start_angle,end_angle,delta_angle = 0.5)
      pts = []
      n = ((end_angle-start_angle)/delta_angle).abs.round.to_f
      n = (n>1024)? 1024: n    
      if end_angle>start_angle
        ndegree = Array((start_angle..end_angle).step((end_angle-start_angle)/n))
      elsif end_angle<start_angle
        ndegree = Array((end_angle..start_angle).step((start_angle-end_angle)/n))
        ndegree = ndegree.reverse
      end 
      ndegree.each do |i|
        pts.push(RBA::DPoint::new(radius * Math::cos(i * Math::PI/180.0), radius * Math::sin(i * Math::PI/180.0))+centre)
      end
      return pts   
  end

  def linearc_ellipse(f0,a,e,start_angle,end_angle,delta_angle = 0.5)
      pts = []
      n = ((end_angle-start_angle)/delta_angle).abs.round.to_f
      n = (n>1024)? 1024: n    
      if end_angle>start_angle
        ndegree = Array((start_angle..end_angle).step((end_angle-start_angle)/n))
      elsif end_angle<start_angle
        ndegree = Array((end_angle..start_angle).step((start_angle-end_angle)/n))
        ndegree = ndegree.reverse
      end 
      ndegree.each do |i|
        r = a*(1-e**2)/(1-e*Math::cos(i * Math::PI/180.0))
        x = r*Math::cos(i * Math::PI/180.0)
        y = r*Math::sin(i * Math::PI/180.0)
        pts.push(DPoint::new(x,y)+f0)      
      end
      return pts   
  end  
  
  #pts is RBA::Point
  def round_corners(pts,radius,delta_angle = 0.5)
    pts = remove_straight_angles(pts)
    newpts = [pts[0]]
    if 2 <= pts.length
      pts[1..-2].each_with_index do |pt,iter|
        v1 = pt - pts[iter]
        v2 = pts[iter+2]-pt
        beta = vector_angle(v1,v2)
        l1 = radius * Math::tan(beta.abs/2.0)
        p1 = RBA::DPoint.new(l1/Math.sqrt(v1.sq_abs)*(pts[iter].x-pt.x)+pt.x,
                             l1/Math.sqrt(v1.sq_abs)*(pts[iter].y-pt.y)+pt.y)
        #if p1 is smaller than point in newpts[]
        if (p1-pt).sq_abs <= (newpts[-1]-pt).sq_abs
          r = radius
        else
          r = Math.sqrt((newpts[-1]-pt).sq_abs)
          p1 = newpts[-1]
        end
        xdir = RBA::DPoint.new(1,0)
        start_angle = vector_angle(xdir,v1)-beta/beta.abs*Math::PI/2.0
        end_angle = start_angle+beta
        c0 = RBA::DPoint.new(p1.x + r*Math::cos(Math::PI+start_angle), p1.y+r*Math::sin(Math::PI+start_angle))
        temp_pts = linearc(c0,r,start_angle/Math::PI*180.0,end_angle/Math::PI*180.0,delta_angle)
        newpts = newpts+temp_pts
      end
    end
    newpts.push(pts[-1])
    return newpts
  end
  
  #define the waveguide structure, self_poly_falg is used to use the self path ->polygon code
  class Waveguide
    def initialize(pts, width, start_face_angle = nil, end_face_angle = nil,self_poly_flag = 0)
      pts = remove_straight_angles(pts)
      @wg = RBA::DPath::new(pts,width)
      @self_poly_flag = self_poly_flag
      if 1 == @wg.num_points
        @start_point = pts[0]
        @end_point = pts[0]
        @start_angle = nil
        @end_angle = nil
      else
        @start_point = pts[0]
        @end_point = pts[-1]
        @start_angle = line_angle(pts[0],pts[1])  
        @end_angle = line_angle(pts[-2],pts[-1])         
        if start_face_angle !=nil
          @start_face_angle = start_face_angle/180.0*Math::PI
          if @start_face_angle < @start_angle
             @start_face_angle += Math::PI
          end
          @self_poly_flag = 1
        else
           @start_face_angle = @start_angle+Math::PI/2     
        end
        if end_face_angle !=nil 
           @end_face_angle = end_face_angle/180.0*Math::PI 
           if @end_face_angle <@end_angle
             @end_face_angle += Math::PI
           end
           @self_poly_flag = 1
        else
           @end_face_angle = @end_angle+Math::PI/2 
        end
      end
      @polygon = nil
    end
    def start_point
      @start_point
    end
    def end_point
      @end_point
    end
    def start_angle
      @start_angle
    end
    def end_anlge
      @end_angle
    end
    def wg
      @wg
    end 
    def wg_length
      Path::from_dpath(@wg).length
    end
    def transformed(t = RBA::DCplxTrans::new(1,0, false, 0))
      if nil == @polygon
        poly()
      end
      return RBA::Polygon::from_dpoly(@polygon.transformed(t))
    end
    def poly
      if 0 == @wg.width
        @polygon = @wg
        return RBA::Path::from_dpath(@polygon)
      elsif 0 == @self_poly_flag
        @polygon = @wg.polygon()
        return RBA::Polygon::from_dpoly(@polygon)
      else
        pts = []
        @wg.each_point { |pt| pts.push(pt) }
        pt1s = []
        pt2s = []
        tmp_w = (@wg.width/2.0/Math.sin(@start_face_angle-@start_angle)).abs
        pt1s.push(RBA::DPoint.new(Math.cos(@start_face_angle)*tmp_w+pts[0].x,Math.sin(@start_face_angle)*tmp_w+pts[0].y))
        pt2s.push(RBA::DPoint.new(-Math.cos(@start_face_angle)*tmp_w+pts[0].x,-Math.sin(@start_face_angle)*tmp_w+pts[0].y))
        if 2 <= pts.length
          pts[1..-2].each_with_index do |pt,iter|
            v1 = pt-pts[iter]
            v2 = pts[iter+2]-pt
            beta = vector_angle(v1,v2)
            tmp_w = (@wg.width/2.0/Math.cos(beta/2)).abs
            line_dir = line_angle(pts[iter],pt)
            theta = Math::PI/2.0+beta/2.0+line_dir
            pt1s.push(RBA::DPoint.new(Math.cos(theta)*tmp_w+pt.x,Math.sin(theta)*tmp_w+pt.y))
            pt2s.insert(0,RBA::DPoint.new(-Math.cos(theta)*tmp_w+pt.x,-Math.sin(theta)*tmp_w+pt.y))      
          end
        end
        tmp_w = (@wg.width/2.0/Math.sin(@end_face_angle-@end_angle)).abs
        tmp_dir = RBA::DPoint.new(Math.cos(@end_face_angle),Math.sin(@end_face_angle))
        tmp_v = tmp_dir*tmp_w
        pt1s.push(RBA::DPoint.new(Math.cos(@end_face_angle)*tmp_w+pts[-1].x,Math.sin(@end_face_angle)*tmp_w+pts[-1].y))
        pt2s.insert(0,RBA::DPoint.new(-Math.cos(@end_face_angle)*tmp_w+pts[-1].x,-Math.sin(@end_face_angle)*tmp_w+pts[-1].y))
        @polygon = RBA::DPolygon.new(pt1s+pt2s) 
        return RBA::Polygon::from_dpoly(@polygon)     
      end
    end
  end
  
  class Taper
    def initialize(pts, width_in,width_out,eq = 'x',step = 0.01)
      @pts = pts
      if 2 == pts.length()
        @start_point = pts[0]
        @end_point = pts[1]
        @start_angle = line_angle(pts[0],pts[1])
        @end_angle = @start_angle
        @width_in = width_in
        @width_out = width_out
        @eq = eq
        @step = step
      else 
        raise "Only need 2 points"
      end
    end
    def start_point
      @start_point
    end
    def end_point
      @end_point
    end
    def start_angle
      @start_angle
    end
    def end_anlge
      @end_angle
    end
    def width_in
      @width_in
    end
    def width_out
      @width_out
    end    
    def eq
      @eq
    end   
    def polygon
      @polygon
    end  
    def poly
      if 'x' == @eq
        pt1 = RBA::DPoint.new(0,@width_in/2)
        pt2 = RBA::DPoint.new(Math.sqrt((@pts[1]-@pts[0]).sq_abs),@width_out/2)
        pt3 = RBA::DPoint.new(Math.sqrt((@pts[1]-@pts[0]).sq_abs),-@width_out/2)
        pt4 = RBA::DPoint.new(0,-width_in/2)
        @polygon = RBA::DPolygon.new([pt1,pt2,pt3,pt4])
      else
        length = Math.sqrt((@pts[1]-@pts[0]).sq_abs)
        element = Array((0..1).step(@step))
        pt1s = []
        pt2s = []
        element.each do |x|
          width = @width_in + eval(@eq)*(@width_out-@width_in)
          pt1s.push(RBA::DPoint.new(x*length,width/2.0))
          pt2s.insert(0,RBA::DPoint.new(x*length,-width/2.0))
        end
        @polygon = RBA::DPolygon.new(pt1s+pt2s)
      end
      t = RBA::DCplxTrans::new(1, @start_angle/Math::PI*180, false, @pts[0])
      @polygon = @polygon.transformed(t)
      return RBA::Polygon::from_dpoly(@polygon)      
    end
  end
  
  class Circle
    attr_accessor :p0, :start_angle, :radius, :end_angle, :delta_angle
    def initialize(p0, radius,start_angle = 0,end_angle = 360,delta_angle = 0.5) 
      @p0 = p0
      @radius = radius
      @start_angle = start_angle
      @end_angle = end_angle
      @delta_angle = delta_angle
  
    end
    def poly
      pts = linearc(@p0,@radius,@start_angle,@end_angle,@delta_angle)
      @polygon = RBA::DPolygon.new(pts)
      return RBA::Polygon::from_dpoly(@polygon)      
    end
  end

  class Ellipse
    attr_accessor :f0,:a, :e, :start_angle, :radius, :end_angle, :delta_angle
    def initialize(f0, a, e, start_angle = 0,end_angle = 360,delta_angle = 0.5) 
      @f0 = f0
      @a = a
      @e = e
      @start_angle = start_angle
      @end_angle = end_angle
      @delta_angle = delta_angle
  
    end
    def poly
      pts = linearc_ellipse(@f0,@a,@e,@start_angle,@end_angle,@delta_angle)
      @polygon = RBA::DPolygon.new(pts)
      return RBA::Polygon::from_dpoly(@polygon)      
    end
  end
    
  class Ports
    attr_accessor :width, :direction,:face_angle,:point, :trench_width                 
    def initialize(width = 450.0,
                   direction = 0.0,
                   face_angle = 90,
                   point = DPoint::new(0.0),
                   trench_width = 0.0)
      @width = width
      @direction = direction
      @face_angle = face_angle
      @point = point
      @trench_width = trench_width
    end  
  end
end

if __FILE__ == $0
  include MyBasic
  # create a new view (mode 1) with an empty layout
  main_window = RBA::Application::instance.main_window
  layout = main_window.create_layout(1).layout
  layout_view = main_window.current_view
  # set the database unit (shown as an example, the default is 0.001)
  layout.dbu = 0.001
  # create a cell
  cell = layout.create_cell("TOP")
  # create a layer
  layer_index1 = layout.insert_layer(RBA::LayerInfo::new(1, 0))
  layer_index2 = layout.insert_layer(RBA::LayerInfo::new(2, 0))
  layer_index3 = layout.insert_layer(RBA::LayerInfo::new(3, 0))
  if true
    # add a shape
    taper_length = 100/layout.dbu
    pts = [RBA::DPoint::new(0, 0), RBA::DPoint::new(taper_length, taper_length)]
    width_in = 5/layout.dbu
    width_out = 30/layout.dbu
    taper = Taper.new(pts,width_in,width_out,'x**3')
    cell.shapes(layer_index1).insert(taper.poly)
    
    taper_length = 100/layout.dbu
    pts = [RBA::DPoint::new(0, 0), RBA::DPoint::new(taper_length*Math.sqrt(2), 0)]
    width_in = 5/layout.dbu
    width_out = 30/layout.dbu
    taper2 = Taper.new(pts,width_in,width_out,'x**3')
    cell.shapes(layer_index2).insert(taper2.poly)
    
    
    pt = RBA::DPoint::new(0, 0)
    circle = Circle.new(pt,taper_length*Math.sqrt(2),0,270)
    cell.shapes(layer_index3).insert(circle.poly)
  end
  
  if true
    length = Array((1000..20000).step(1000))
    wg = []
    length.each_with_index do |alength,iter|
      if 0==iter
        vec = [RBA::DPoint::new(0, 0), RBA::DPoint::new(3*(alength-1000), alength)]
      else
        vec = [RBA::DPoint::new(0, 0)+wg.last.end_point(), RBA::DPoint::new(3*(alength-1000), alength)+wg.last.end_point()]
      end
      wg.push( Waveguide.new(vec,2000))
      cell.shapes(layer_index1).insert(wg.last().poly)
    end 
    
    wg = []
    length.each_with_index do |alength,iter|
    
      vec = [RBA::DPoint::new(0, -20000), RBA::DPoint::new(3*(alength-1000), alength-10000)]
      wg.push( Waveguide.new(vec,2000))
      cell.shapes(layer_index1).insert(wg.last().poly)
    end 
    
    vec = [RBA::DPoint::new(0, 20000.0), RBA::DPoint::new(0, 10000.0), RBA::DPoint::new(0, 10000.0)]
    wg = Waveguide.new(vec,0.0)
    cell.shapes(layer_index1).insert(wg.poly)
  end
  
  # select the top cell in the view, set up the view's layer list and
  # fit the viewport to the extensions of our layout
  layout_view.select_cell(cell.cell_index, 0)
  layout_view.add_missing_layers
  layout_view.zoom_fit
end
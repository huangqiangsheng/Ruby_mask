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
  
  def cross_point(p1,dir1,p2,dir2)
    rad1 = dir1/180.0*Math::PI
    rad2 = dir2/180.0*Math::PI
    x0 = (p1.y-p2.y-Math::tan(rad1)*p1.x+Math::tan(rad2)*p2.x)/(tan(rad2)-tan(rad1))
    y0 = (p1.y*Math::tan(rad2)-p2.y*Math::tan(rad1)-Math::tan(rad1)*Math::tan(rad2)*(p1.x-p2.x))/(tan(rad2)-tan(rad1))  
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
  def linearc_one_point_two_angle(p1,radius,start_angle,span_angle,delta_angle = 0.5) #p1 on the curve
      start_angle = start_angle
      end_angle = start_angle + span_angle
      centre = p1 - DPoint.new(radius*Math::cos(start_angle*Math::PI/180.0),radius*Math::sin(start_angle*Math::PI/180.0))
      return linearc(centre,radius,start_angle,end_angle,delta_angle)
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
  def round_corners(pts,radius,delta_angle = 0.5,ignore_flag = false)
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
        p2 = RBA::DPoint.new(l1/Math.sqrt(v2.sq_abs)*(pts[iter+2].x-pt.x)+pt.x,
                             l1/Math.sqrt(v2.sq_abs)*(pts[iter+2].y-pt.y)+pt.y)
        #if p1 is smaller than point in newpts[]
        if (((p1-pt).sq_abs - (newpts[-1]-pt).sq_abs)<=1e-3)  && (((p2-pt).sq_abs - (pts[iter+2]-pt).sq_abs) <= 1e-3)
          r = radius
        else 
          #radius is too large
          lv1 = Math.sqrt(v1.sq_abs)
          lv2 = Math.sqrt(v2.sq_abs)
          if lv1 >= lv2
            r = lv2/Math::tan(beta.abs/2.0)
            p1 = RBA::DPoint.new(lv2/Math.sqrt(v1.sq_abs)*(pts[iter].x-pt.x)+pt.x,
                                 lv2/Math.sqrt(v1.sq_abs)*(pts[iter].y-pt.y)+pt.y)
          else
            r = lv1/Math::tan(beta.abs/2.0)
            p1 = newpts[-1]
          end
          if !ignore_flag
            raise "The ' Bend radius #{radius}' is too large, min Radius #{r}."
          end
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
  
  def countercolockwise_rotate(p,angle) # angle rad
    return DPoint.new(p.x*Math::cos(angle)+p.y*Math::sin(angle),
                     -p.x*Math::sin(angle)+p.y*Math::cos(angle)) 
  end
  def sbend(p_in1,dir_in1,p_in2,dir_in2,radius,delta_angle = 0.5)
    #transform
    rotrad = dir_in1*Math::PI/180.0
    p1 = DPoint.new(0.0,0.0)
    dir1 = 0
    tmp = p_in2-p_in1 # Move
    p2 = countercolockwise_rotate(tmp,rotrad)  # countercolockwise Rotate 
    dir2 = dir_in2-dir_in1
    flag = 0; # 0 can be directly connected, 1 connected by one circle, 2 connect by two circle
    p0 = DPoint.new(0.0,0.0)  # cross point, when flag == 1
    if dir1 == dir2 #parallel
      angle1 = line_angle(p1,p2)/Math::PI*180.0
      if 1e-6> (angle1- dir1).abs
        flag = 0
      else
        flag = 2
      end    
    else
      if 90.0 == dir2.modulo(180.0)
        xcross = p2.x
      elsif 0 == dir2.modulo(180.0)
        xcross = -1
      else
        xcross = p2.x-p2.y/Math::tan(dir2/180.0*Math::PI)
      end
      p0 = DPoint.new(xcross,0.0)
      if xcross > 0
        dp1 = p2-p0
        dp2 = DPoint.new(Math::cos(dir2*Math::PI/180.0),Math::sin(dir2*Math::PI/180.0))
        dot = dp1.x*dp2.x+dp1.y*dp2.y
        if dot > 0 
          if ((p2.y.abs - (radius+radius*Math::cos(dir2/180.0*Math::PI).abs))<1e-3)
           #if cannot be connect by two circle, then flag = 1
            flag = 1
          else
            flag = 2
          end
        else
          flag = 2
        end
      elsif xcross <= 0
        flag = 2
      else
        raise "angle2 error: #{angle2}"
      end
    end
    case flag
    when 0
      pts = [p1,p2]
    when 1
      pts = [p1,p0,p2]
      pts = round_corners(pts,radius,delta_angle)
    when 2
      alpha = dir2/180.0*Math::PI
      dy = p2.y-p1.y
      dx = p2.x-p1.x
      if ((dy > 0) || (dy ==0 && dir2<0)) && (dx >0)
        tmp_v = (1+Math::cos(alpha)-dy/radius)/2.0
        if tmp_v <0
           start_angle = 270.0
           span_angle = 90.0
           dir2 = dir2.modulo(360.0)
           if (dir2<90.0) && (dir2>=0.0)
             pt2 = DPoint.new(p2.x-2*radius+radius*Math::sin(alpha),0.0)
           elsif (dir2<180.0) && (dir2>=90.0)
             pt2 = DPoint.new(p2.x-radius*Math::sin(alpha),0.0)
           elsif (dir2<270.0) && (dir2>=180.0)
             pt2 = DPoint.new(p2.x-radius*Math::sin(alpha),0.0) 
           elsif (dir2<360.0) && (dir2>=270.0)
             pt2 = DPoint.new(p2.x-2*radius+radius*Math::sin(alpha),0.0)                       
           end
           
           pts1 =  linearc_one_point_two_angle(pt2,radius,start_angle,span_angle,delta_angle)
           p3 =  pts1[-1]#the point of the 1/4 circle
           dir3 = 90.0
           pts2 = sbend(p3,dir3,p2,dir2,radius,delta_angle)
           pts = [p1,pt2]+pts1+pts2         
        else 
          theta1 = Math::acos((1+Math::cos(alpha)-dy/radius)/2.0)
          cdx = radius*(2.0*Math::sin(theta1)-Math::sin(alpha))
          dx = p2.x-p1.x
          if cdx > dx
            raise "Input 'Bend radius = #{radius}'  is too large in sbend function."
          end
          startp = DPoint.new(dx-cdx,p1.y)
          pts1 = linearc_one_point_two_angle(startp,radius,270.0,theta1/Math::PI*180.0,delta_angle)
          theta2 = theta1 - alpha
          pts2 = linearc_one_point_two_angle(pts1[-1],radius,90.0+theta1/Math::PI*180.0,-theta2/Math::PI*180.0,delta_angle)
          pts = [p1]+pts1+pts2+[p2]
        end
      elsif ((dy < 0) || (dy ==0 && dir2>0))& (dx >0) #mirror x = 0
        p2.y = -p2.y #mirror
        dir2 = -dir2 #mirror
        pts1 = sbend(p1,dir1,p2,dir2,radius,delta_angle)
        pts1.collect!{|pt| DPoint.new(pt.x, -pt.y)}
        pts = [p1]+pts1
      elsif (dx<=0) && dy.abs > 2.0*radius 
        if dy>0
          start_angle = 270.0
          span_angle = 90.0
          pts1 =  linearc_one_point_two_angle(p1,radius,start_angle,span_angle,delta_angle)
          p3 =  pts1[-1]#the point of the 1/4 circle
          dir3 = 90.0
          pts2 = sbend(p3,dir3,p2,dir2,radius,delta_angle)
          pts = [p1]+pts1+pts2
        elsif dy<0 #mirror x = 0
          p2.y = -p2.y
          dir2 = -dir2
          pts1 = sbend(p1,dir1,p2,dir2,radius,delta_angle)
          pts1.collect!{|pt| DPoint.new(pt.x, -pt.y)}
          pts = [p1]+pts1
        end             
      elsif
        raise "The ' Bend radius #{radius}' is too large. Or, the two points are too close. To be continue in sbend function"
      end
    end
    pts.collect!{|pt| pt = countercolockwise_rotate(pt,-rotrad)} # countercolockwise Rotate 
    pts.collect!{|pt| pt = pt+p_in1}
    return pts    
  end
  
  #define the waveguide structure, self_poly_falg is used to use the self path ->polygon code
  class Waveguide
    attr_accessor :self_poly_flag  
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
    def end_angle
      @end_angle
    end
    def start_face_angle=(angle)
      @start_face_angle = angle/180.0*Math::PI
      @self_poly_flag = 1
    end
    def end_face_angle=(angle)
      @end_face_angle = angle/180.0*Math::PI
      @self_poly_flag = 1
    end  
    def start_face_angle
      @start_face_angle
    end
    def end_face_angle
      @end_face_angle
    end        
    def wg
      @wg
    end
    def width=(w)
      @width = w
      @wg.width = @width
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
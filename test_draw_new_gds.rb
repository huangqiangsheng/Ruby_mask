
# Enter your Ruby code here

layout = RBA::Layout::new

# database unit 1nm:
layout.dbu = 0.001

# create a top cell
top = layout.cell(layout.add_cell("TOP"))

# create a layer: layer number 1, datatype 0
layer = layout.insert_layer(RBA::LayerInfo::new(1, 0))

# create one rectangle with lower-left coordinates at 0,0
# and width of 1um and heigth of 2um (coordinates are in
# database units)
hull =  [ RBA::Point::new(0, 0),       RBA::Point::new(6000, 0), 
          RBA::Point::new(6000, 3000), RBA::Point::new(0, 3000) ]
hole1 = [ RBA::Point::new(1000, 1000), RBA::Point::new(2000, 1000), 
          RBA::Point::new(2000, 2000), RBA::Point::new(1000, 2000) ]
hole2 = [ RBA::Point::new(3000, 1000), RBA::Point::new(4000, 1000), 
          RBA::Point::new(4000, 2000), RBA::Point::new(3000, 2000) ]
poly = RBA::Polygon::new(hull)
poly.insert_hole(hole1)
poly.insert_hole(hole2)

top.shapes(layer).insert(poly)

# write to x.gds
layout.write("/test/x4.gds")
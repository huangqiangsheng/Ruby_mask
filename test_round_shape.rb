# Enter your Ruby code here
require "waveguide.rb"
include RBA
include MyBasic
# create a new view (mode 1) with an empty layout
main_window = RBA::Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = main_window.current_view

# set the database unit (shown as an example, the default is 0.001)
layout.dbu = 0.001

# create a cell
cell = layout.create_cell("TOP")

# create a layer

layer_index1 = layout.insert_layer(RBA::LayerInfo::new(1, 0,'path'))
layer_index2 = layout.insert_layer(RBA::LayerInfo::new(10, 0,'round_path'))
18.upto(18) do |iter|
  pts1 = [RBA::DPoint.new(20.0*(iter)/layout.dbu,0),
         RBA::DPoint.new(5.0/layout.dbu+20.0*(iter)/layout.dbu,0),
         RBA::DPoint.new(10.0/layout.dbu+20.0*(iter)/layout.dbu,0),
         RBA::DPoint.new((10.0/layout.dbu*Math::cos(iter*Math::PI/36.0)+20.0*(iter)/layout.dbu)+10.0/layout.dbu,
                          10.0/layout.dbu*Math::sin(iter*Math::PI/36.0))]
  radius = 5.0/layout.dbu
  pts2 = round_corners(pts1,radius)
  path2 = DPath::new(pts2,0)
  puts path2.length
  cell.shapes(layer_index2).insert(Path::from_dpath(path2)) 
  cell.shapes(layer_index1).insert(Path::from_dpath(DPath::new(pts1,0))) 
         
end


# select the top cell in the view, set up the view's layer list and
# fit the viewport to the extensions of our layout
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
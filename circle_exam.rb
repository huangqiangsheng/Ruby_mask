
# Enter your Ruby code here
include RBA
#mw =  Application::instance.main_window
#view = mw.current_view || raise("No view open")
view = LayoutView::current
cell = view.active_cellview.cell
layer = view.current_layer.current.layer_index

n = 200    # number of points
r = 10000  # radius
da = 2 * Math::PI / n
pts = n.times.collect { |i|  Point.new(r * Math::cos(i * da), r * Math::sin(i * da)) }
poly =  Polygon::new(pts)
cell.shapes(layer).insert(poly)
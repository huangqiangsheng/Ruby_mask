
# Enter your Ruby code here
# create a new view (mode 1) with an empty layout
main_window = RBA::Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = main_window.current_view
# set the database unit (shown as an example, the default is 0.001)
layout.dbu = 0.001


top = layout.add_cell("TOP")

PCellDeclaration_Native

# find the lib
lib = RBA::Library.library_by_name("Basic")
lib || raise("Unknown lib 'Basic'")

# find the pcell
pcell_decl = lib.layout.pcell_declaration("TEXT")
pcell_decl || raise("Unknown PCell 'TEXT'")

# set the parameters
param = { "text" => "KLAYOUT RULES2", "layer" => 
RBA::LayerInfo::new(10, 0), "mag" => 2.5 }

# build a param array using the param hash as a source
pv = pcell_decl.get_parameters.collect do |p|
param[p.name] || p.default
end

# create a PCell variant cell
pcell_var = layout.add_pcell_variant(lib, pcell_decl.id, pv)

# instantiate that cell
t = RBA::Trans::new(RBA::Trans::r90, 0, 0)
pcell_inst = layout.cell(top).insert(RBA::CellInstArray::new(pcell_var, t))

layout_view.select_cell(top,0)
layout_view.add_missing_layers
layout_view.zoom_fit

# Enter your Ruby code here
main_window = RBA::Application::instance.main_window
ly = main_window.create_layout(1).layout
cell = ly.create_cell("TOP")

# Find the lib
lib = RBA::Library.library_by_name("Basic")
lib || raise("Unknown lib 'Basic'")

# Find the pcell
pcell_decl = lib.layout.pcell_declaration("TEXT")
pcell_decl || raise("Unknown PCell 'TEXT'")

# Set the parameters (text string, layer to 10/0, magnification to 2.5)
param = { "text" => "KLAYOUT RULES", "layer" => RBA::LayerInfo::new(10, 0), "mag" => 2.5 }

# Build a param array using the param hash as a source.
# Fill all remaining parameter with default values.
pv = pcell_decl.get_parameters.collect do |p|
  param[p.name] || p.default
end

# Create a PCell variant cell
pcell_var = ly.add_pcell_variant(lib, pcell_decl.id, pv)

# Instantiate that cell
t = RBA::Trans::new(RBA::Trans::r90, 0, 0)
cell.insert(RBA::CellInstArray::new(pcell_var, t))
cell.refresh()

layout_view.add_missing_layers
layout_view.zoom_fit


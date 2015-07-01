include RBA
#creat awg with same waveguide spacing

# create a new view (mode 1) with an empty layout
main_window =Application::instance.main_window
layout = main_window.create_layout(0).layout
layout_view = main_window.current_view

filename = 'G:\\piaopiaotao\\400nmRUN_2015PDK_HOMEMADE\\GDS_library\\T_GRA.GDS'

layout.read(filename)
cell = layout.top_cell
layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit
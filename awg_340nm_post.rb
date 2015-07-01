include RBA
layout = CellView::active.layout
cell = layout.create_cell("Top")
dx = 1000.0/layout.dbu
dy = -800.0/layout.dbu

subcell = layout.cell("AWG_200G_width400")
t = CplxTrans::new(1.0, 0,false,0.0,0.0)
tmp = CellInstArray::new(subcell.cell_index,t)
cell.insert(tmp)

subcell = layout.cell("AWG_200G_width450")
t = CplxTrans::new(1.0, 0,false,dx,0.0)
tmp = CellInstArray::new(subcell.cell_index,t)
cell.insert(tmp)

subcell = layout.cell("AWG_200G_width500")
t = CplxTrans::new(1.0, 0,false,2.0*dx,0.0)
tmp = CellInstArray::new(subcell.cell_index,t)
cell.insert(tmp)

subcell = layout.cell("AWG_400G_width400")
t = CplxTrans::new(1.0, 0,false,0.0,dy)
tmp = CellInstArray::new(subcell.cell_index,t)
cell.insert(tmp)

subcell = layout.cell("AWG_400G_width450")
t = CplxTrans::new(1.0, 0,false,dx,dy)
tmp = CellInstArray::new(subcell.cell_index,t)
cell.insert(tmp)

subcell = layout.cell("AWG_400G_width500")
t = CplxTrans::new(1.0, 0,false,2.0*dx,dy)
tmp = CellInstArray::new(subcell.cell_index,t)
cell.insert(tmp)

layout_view.select_cell(cell.cell_index, 0)
layout_view.add_missing_layers
layout_view.zoom_fit

# Enter your Ruby code here

#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# DESCRIPTION: dice count : gross die , yield estimation and wafermap
#
# Run the script with
#   klayout -rm gross_die.rbm ...
# or put the script as "gross_die.rbm" into the installation path (on Unix for version <=0.21:
# set $KLAYOUTPATH to the installation folder).
#

include RBA

$gross_die = MenuAction.new( "Gross die / Yield", "" ) do 

    dialog = QDialog.new(Application.instance.main_window)
    dialog.windowTitle = "WAFER & DIE characteritics"
    layout = QVBoxLayout::new(dialog)
    dialog.setLayout(layout)

### Die name
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the die or project name :"
    layout_name = QLineEdit.new(dialog)
    layout.addWidget(layout_name)
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "\n"

### Layout width : X
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the layout width X (mm) :"
    layout_X = QLineEdit.new(dialog)
    layout.addWidget(layout_X)

### Layout heigth : Y
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the layout heigth Y (mm) :"
    layout_Y = QLineEdit.new(dialog)
    layout.addWidget(layout_Y)

### Scribe width : X
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the scribe width X (mm) :"
    scribe_X = QLineEdit.new(dialog)
    layout.addWidget(scribe_X)
    scribe_X.text = "0.1"

### Scribe heigth : Y
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the scribe heigth Y (mm) :"
    scribe_Y = QLineEdit.new(dialog)
    layout.addWidget(scribe_Y)
    scribe_Y.text = "0.1"

### Wafer diameter
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the wafer diameter (mm) / (inches)"
    waf_diam = QComboBox.new(dialog)
    waf_diam.addItem("50 mm / 2 \" ")
    waf_diam.addItem("75 mm / 3 \" ")
    waf_diam.addItem("100 mm / 4 \" ")
    waf_diam.addItem("125 mm / 5 \" ")
    waf_diam.addItem("150 mm / 6 \" ")
    waf_diam.addItem("200 mm / 8 \" ")
    waf_diam.addItem("300 mm / 12 \" ")
    waf_diam.addItem("450 mm / 18 \" ")
    # waf_diam.setSizeAdjustPolicy(QComboBox::AdjustToContents)
    waf_diam.setCurrentIndex(5)  # default wafer size = 200mm
    layout.addWidget(waf_diam)

### Wafer type : P-100
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the wafer type"
    waf_typ = QComboBox.new(dialog)
    waf_typ.addItem("N-100")
    waf_typ.addItem("N-111")
    waf_typ.addItem("P-100")
    waf_typ.addItem("P-111")
    layout.addWidget(waf_typ)
    # waf_typ.setSizeAdjustPolicy(QComboBox::AdjustToContents)

### Edging loss of the wafer
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the edging loss (mm) :"
    PEE = QLineEdit.new(dialog)
    layout.addWidget(PEE)
    PEE.text = "3"

### defects / cm^2
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the defects density D0 (/cm^2) :"
    defectsE = QLineEdit.new(dialog)
    layout.addWidget(defectsE)
    defectsE.text = "0.12"

### measure of manufacturing process complexity
    label = QLabel.new(dialog)
    layout.addWidget(label)
    label.text = "Enter the manufacturing process complexity :"
    alphaE = QLineEdit.new(dialog)
    layout.addWidget(alphaE)
    alphaE.text = "2.5"

# OK button
        buttonOK = QPushButton.new(dialog)
        layout.addWidget(buttonOK)
        buttonOK.text = " OK "
        buttonOK.clicked do
            if (layout_X.text.to_f == 0.0)
                confirm = RBA::MessageBox.info("WRONG INPUTS !!!","Set the layout width X", RBA::MessageBox.b_ok + RBA::MessageBox.b_cancel)
                if confirm == RBA::MessageBox.b_cancel
                    raise "Operation aborted"
                end
            elsif (layout_Y.text.to_f == 0.0)
                confirm = RBA::MessageBox.info("WRONG INPUTS !!!","Set the layout heigth Y", RBA::MessageBox.b_ok + RBA::MessageBox.b_cancel)
                if confirm == RBA::MessageBox.b_cancel
                    raise "Operation aborted"
                end
            else
                dialog.accept()
            end
        end

    dialog.exec  # input data

### Input data from string to float
        xlayout = layout_X.text.to_f  
        ylayout = layout_Y.text.to_f
        xscribe = scribe_X.text.to_f
        yscribe = scribe_Y.text.to_f
        PE = PEE.text.to_f
        defects = defectsE.text.to_f
        alpha = alphaE.text.to_f

        if (waf_diam.currentText() == "50 mm / 2 \" ")
            diameter = 50.8
            OFL = 15.88         ## Wafer primary slice length
            CFL = 8.0           ## Length of the secondary side of the wafer
            RE  = 2.0           ## Resist damage on the side of the wafer
            thick = 279
        end
        if (waf_diam.currentText() == "75 mm / 3 \" ")
            diameter = 76.2
            OFL = 22.22
            CFL = 11.18
            RE  = 2.0
            thick = 381
        end
        if (waf_diam.currentText() == "100 mm / 4 \" ")
            diameter = 100.0
            OFL = 32.5
            CFL = 18.0
            RE  = 2.0
            thick = "525 or 625"
        end
        if (waf_diam.currentText() == "125 mm / 5 \" ")
            diameter = 125.0
            OFL = 42.5
            CFL = 27.5
            RE  = 2.0
            thick = 625
        end
        if (waf_diam.currentText() == "150 mm / 6 \" ")
            diameter = 150.0
            OFL = 57.5
            CFL = 37.5
            RE  = 2.0
            thick = 675
        end
        if (waf_diam.currentText() == "200 mm / 8 \" ")
            diameter = 200.0
            OFL = 0.0
            CFL = 0.0
            RE  = 0.1
            thick = 725
        end
        if (waf_diam.currentText() == "300 mm / 12 \" ")
            diameter = 300.0
            OFL = 0.0
            CFL = 0.0
            RE  = 0.1
            thick = 775
        end
        if (waf_diam.currentText() == "450 mm / 18 \" ")
            diameter = 450.0
            OFL = 0.0
            CFL = 0.0
            RE  = 0.1
            thick = 925
        end

### Define common constants
    PI = 3.14159
    sqrt2 = Math::sqrt(2)
    lne = 2.7183
    inchtomm = 25.4
    radius = diameter / 2.0

    height = xlayout + xscribe
    width  = ylayout + yscribe

### Formula One round in the die landed calculated the number of ways to calculate the diagonal
### Formula1 refer to Anderson School at UCLA
    DieCount1 = 0
    h = height
    w = width
    if (h > w)
        h = width
        w = height
    end

    if (w < diameter)
        rowmax = (Math::sqrt(diameter ** 2 - w ** 2) / h).to_i
        columax = (Math::sqrt(diameter ** 2 - h ** 2) / w).to_i

        for row in (1..rowmax) do
            columns = (Math::sqrt((diameter ** 2) - (row * h) ** 2) / w).to_i
            DieCount1 = DieCount1 + columns
        end
    end

### Formula 2 is calculated in terms of area and remove the edge of the die number
### Formula 2 refers to www.cse.psu.edu/~mji 
    diearea = height * width
    PreCount = PI * radius ** 2 / diearea
    Margin = PI * diameter / Math::sqrt(2 * diearea)
    DieCount2 = (PreCount-Margin).round

### Four yield models formula
    NegBinYield  = 100.0 *(1.0 +(defects * diearea * 1e-2) / alpha) **(alpha * -1.0)
    PoissonYield = 100.0 * 1.0 /(lne **(diearea * 1e-2 * defects))
    MurphyYield  = 100.0 *((1.0 -(lne **(-1.0 * diearea * 1e-2 * defects))) /(diearea * 1e-2 * defects)) ** 2
    SeedYield    = 100.0 * 1.0 /(lne ** Math::sqrt(diearea * 1e-2 * defects))

        if (waf_typ.currentText() == "N-100")
            OFR = radius - Math::sqrt(radius ** 2.0 -(OFL/2.0) ** 2)
            CFR = radius - Math::sqrt(radius ** 2.0 -(CFL/2.0) ** 2)
            cutOFR = (OFR / h + 1.0).round
            cutCFR45 = 0.0
            cutCFR90 = 0.0
            cutCFR180 = (CFR / w +1).round
        end
        if (waf_typ.currentText() == "N-111")
            OFR = radius - Math::sqrt(radius ** 2.0 -(OFL/2.0) ** 2)
            CFR = radius - Math::sqrt(radius ** 2.0 -(CFL/2.0) ** 2)
            cutOFR = (OFR / h + 1.0).round
            cutCFR45 = 1.0
            cutCFR90 = 0.0
            cutCFR180 = 0.0
        end
        if (waf_typ.currentText() == "P-100")
            OFR = radius - Math::sqrt(radius ** 2.0 -(OFL/2.0) ** 2)
            CFR = radius - Math::sqrt(radius ** 2.0 -(CFL/2.0) ** 2)
            cutOFR = (OFR / h + 1.0).round
            cutCFR45 = 0.0
            cutCFR90 = (CFR / w + 1.0).round
            cutCFR180 = 0.0
        end
        if (waf_typ.currentText() == "P-111")
            OFR = radius - Math::sqrt(radius ** 2.0 -(OFL/2.0) ** 2)
            cutOFR = (OFR / h +1.0).round
            cutCFR45 = 0.0
            cutCFR90 = 0.0
            cutCFR180 = 0.0
        end

### Draw the wafer

    app = RBA::Application.instance
    mw = app.main_window
    #  create a new layout 
    mw.create_layout( 0 )
    layout_view = mw.current_view

###  create a new layer in that layout
    layout = layout_view.cellview( 0 ).layout 
    layout_view.set_config("background-color", "0xFFFFFF")
    linfo = RBA::LayerInfo.new 

###  create a layer view for the wafer
    layer_id = layout.insert_layer( linfo )
    ln = RBA::LayerPropertiesNode::new
    ln.dither_pattern = 1
    # ln.fill_color = 0xFFFFFF
    ln.frame_color = 0x000000
    ln.width = 3
    ln.source_layer_index = layer_id
    layout_view.insert_layer( layout_view.end_layers, ln )

###  create a layer view for the safe area
    layer_id2 = layout.insert_layer( linfo )
    ln2 = RBA::LayerPropertiesNode::new
    ln2.dither_pattern = 1
    # ln2.fill_color = 0xFFFFFF
    ln2.frame_color = 0x00FF00
    ln2.width = 1
    ln2.source_layer_index = layer_id2
    layout_view.insert_layer( layout_view.end_layers, ln2 )

###  create a layer view for the safe area
    layer_id3 = layout.insert_layer( linfo )
    ln3 = RBA::LayerPropertiesNode::new
    ln3.dither_pattern = 1
    # ln3.fill_color = 0xFFFFFF
    ln3.frame_color = 0xFF0000
    ln3.width = 2
    ln3.source_layer_index = layer_id3
    layout_view.insert_layer( layout_view.end_layers, ln3 )

###  create a top cell
    wafer = layout.add_cell( "wafer" )
    dbu = 1.0/layout.dbu
    RPE = radius - (RE + PE)

### convert to micron
    radius  *= 1000.0 * dbu
    RPE     *= 1000.0 * dbu
    xlayout *= 1000.0 * dbu
    ylayout *= 1000.0 * dbu
    xscribe *= 1000.0 * dbu
    yscribe *= 1000.0 * dbu

### draw wafers
    pts = []
    n = 128
    da = Math::PI * 2 / n
    if ((waf_diam.currentText() == "200 mm / 8 \" ") || (waf_diam.currentText() == "300 mm / 12 \" ") || (waf_diam.currentText() == "450 mm / 18 \" "))
        n.times do |i|
            if (i==0)
                pts.push(Point.from_dpoint(DPoint.new(radius * Math::sin(i * da) + 1000*dbu, - radius * Math::cos(i * da))))
            else
                pts.push(Point.from_dpoint(DPoint.new(radius * Math::sin(i * da), - radius * Math::cos(i * da))))
            end
        end
        pts.push(Point.from_dpoint(DPoint.new(- 1000*dbu, - radius)))  # draw the wafer notch
        pts.push(Point.from_dpoint(DPoint.new(- 1000*dbu, - radius + 1000*dbu)))
        pts.push(Point.from_dpoint(DPoint.new(0, - radius + 1500*dbu)))
        pts.push(Point.from_dpoint(DPoint.new(+ 1000*dbu, - radius + 1000*dbu)))
    else
        flat = 0
        n.times do |i|
            if ((- Math::cos(i * da) > 0) || (radius * Math::sin(i * da) > OFL*500*dbu) || (radius * Math::sin(i * da) < -OFL*500*dbu))
                if ((waf_typ.currentText() == "N-111") && ((i * da) < (Math::asin((OFL*500*dbu) / radius) + 2 * Math::asin((CFL*500*dbu) / radius))))
                    if (flat==0)
                        theta = Math::asin((OFL*500*dbu) / radius) + 2 * Math::asin((CFL*500*dbu) / radius)
                        pts.push(Point.from_dpoint(DPoint.new( radius * Math::sin(theta), - radius * Math::cos(theta))))
                    end
                    flat = 1
                elsif ((waf_typ.currentText() == "P-100") && (Math::sin(i * da) > 0) && (radius * Math::cos(i * da) < CFL*500*dbu) && (radius * Math::cos(i * da) > -CFL*500*dbu))
                    flat = 1
                elsif ((waf_typ.currentText() == "P-111") && (- Math::cos(i * da) > 0) && (radius * Math::sin(i * da) < CFL*500*dbu) && (radius * Math::sin(i * da) > -CFL*500*dbu))
                    flat = 1
                else
                    pts.push(Point.from_dpoint(DPoint.new(radius * Math::sin(i * da), - radius * Math::cos(i * da))))
                end
        end
    end
        pts.push(Point.from_dpoint(DPoint.new(-OFL*500*dbu, - Math::sqrt(radius**2 - (OFL*500*dbu)**2 ))))
        pts.push(Point.from_dpoint(DPoint.new( OFL*500*dbu, - Math::sqrt(radius**2 - (OFL*500*dbu)**2 ))))
    end
    layout.cell(wafer).shapes(layer_id).insert(Polygon.new(pts))

### draw the safe circle
    pts = []
    n.times do |i|
        pts.push(Point.from_dpoint(DPoint.new(RPE * Math::cos(i * da), RPE * Math::sin(i * da))))
    end
    layout.cell(wafer).shapes(layer_id2).insert(Polygon.new(pts))

### line function   Calculating an angle of 45 N-111 Cutaway
    linem = 1
    lineb1 = - radius * sqrt2
    lineb2 = sqrt2 * (radius - Math::sqrt(radius**2 - (CFL/2.0)**2))
    lineb = lineb1 + lineb2
    R0x = 0.0
    R0y = linem * R0x + lineb
    R1y = 0.0
    R1x = (R1y - lineb) / linem

    P2 = -1
    DieCount = 0
    row_min = cutOFR.to_i
    row_max = (rowmax - cutCFR180).to_i
    col_max = (columax - cutCFR90).to_i

    for j in (row_min..row_max) do
        for i in (0..2*col_max) do
            gBLx = i * (xlayout + xscribe) + (xscribe/2.0) - radius
            gBLy = j * (ylayout + yscribe) + (yscribe/2.0) - radius
            gTRx = (i +1) * (xlayout + xscribe) - (xscribe/2.0) - radius
            gTRy = (j +1) * (ylayout + yscribe) - (yscribe/2.0) - radius

### point inside wafer  Calculation falls in the circle die
            ptdisc1 = Math::sqrt(gBLx**2 + gBLy**2)
            ptdisc2 = Math::sqrt(gTRx**2 + gTRy**2)
            ptdisc3 = Math::sqrt(gBLx**2 + gTRy**2)
            ptdisc4 = Math::sqrt(gTRx**2 + gBLy**2)

### in angle 45     45 Ø cutting angle calculation die within
            if (cutCFR45 == 1)
                Rnx = gBLx
                Rny = gBLy
                P0 = (R1x-Rnx) * (R0y-Rny)
                P1 = (R0x-Rnx) * (R1y-Rny)
                P2 = P0-P1
            end

### create die rectangle - Create die in the cellview
            if (ptdisc1<RPE && ptdisc2<RPE && ptdisc3<RPE && ptdisc4<RPE && P2<0)
                layout.cell(wafer).shapes(layer_id3).insert(Box.new(gBLx,gBLy,gTRx,gTRy))
                DieCount += 1
            end
        end     # for i
    end         # for j

### Add text on the layout
    txt_size = (radius / 50 / dbu).round.to_s  # set the text display size proportional to the wafer radius
    layout_view.set_config("default-text-size", txt_size)

    string = "Die / poject name :  #{layout_name.text}"
    layout.cell(wafer).shapes(layer_id3).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.85)))
    layout_size = xlayout * ylayout / 1000000 / dbu / dbu
    string = "Layout size : #{layout_X.text} x #{layout_Y.text} = #{'%.2f' %layout_size} mm2"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.72)))
    string = "Scribe size :  X = #{scribe_X.text} :  Y #{scribe_Y.text}  mm"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.62)))
    die_size = (xlayout+xscribe) * (ylayout+yscribe) / 1000000 / dbu / dbu
    string = "Die size : #{'%.3f' %(layout_X.text.to_f+scribe_X.text.to_f)} x #{'%.3f' %(layout_Y.text.to_f+scribe_Y.text.to_f)} = #{'%.2f' %die_size} mm2"
    layout.cell(wafer).shapes(layer_id3).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.52)))
    string = "Die count : (method 1) =  #{DieCount1}"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.37)))
    string = "Die count : (method 2) =  #{DieCount2}"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.27)))
    string = "Die count : (counted) =  #{DieCount}  \nBest method: counted from the wafer map"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.15)))
    string = " NegBin Yield =  #{'%.2f' %NegBinYield} %"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * 0.07)))
    string = "Poisson Yield =  #{'%.2f' %PoissonYield} %"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.03)))
    string = " Murphy Yield =  #{'%.2f' %MurphyYield} %"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.13)))
    string = "   Seed Yield =  #{'%.2f' %SeedYield} %"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.23)))
    good_die = ((NegBinYield+PoissonYield+MurphyYield)*DieCount/300).round
    string = "Expected good die / wafer = #{good_die}\n\nDepending on design, layout and test margins,\nfoundry defects density D0 and process complexity"
    layout.cell(wafer).shapes(layer_id3).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.43)))
    string = "Foundry defects density =  #{defectsE.text} /cm^2\nProcess complexity assumed : #{alphaE.text}"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.55)))
    string = "Wafer size =  #{waf_diam.currentText()}"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.65)))
    string = "Wafer type =  #{waf_typ.currentText()}"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.75)))
    string = "Wafer safety edge =  #{'%.2f' %(RE + PE)} mm"
    layout.cell(wafer).shapes(layer_id2).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.85)))
    string = "Wafer thickness =  #{thick} um-typ"
    layout.cell(wafer).shapes(layer_id).insert(RBA::Text::new(string, RBA::Trans::new(radius * 1.1, radius * -0.95)))
  ### Text box : the third parameter : radius*2.2 need to be adjusted depending on your screen resolution : it adjust the box width
    layout.cell(wafer).shapes(layer_id).insert(Box.new(radius*1.05 , -radius , radius*2.2 , radius*0.95))

### adjust layout view to fit the drawings
    layout_view.select_cell(wafer, 0)
    layout_view.update_content
    layout_view.add_missing_layers
    layout_view.zoom_fit
    layout_view.max_hier_levels=(2)

### Die count and Yield message
  # RBA::MessageBox::info("Die count and Yield", "Gross die (count1) = #{DieCount1}\nGross die (count2) = #{DieCount2}\nBest one from drawing: \nGross die (counted) = #{DieCount}\n\nNegBin  Yield #{'%.2f' %NegBinYield}%\nPoisson Yield #{'%.2f' %PoissonYield}%\nMurphy Yield #{'%.2f' %MurphyYield}%\nSeed     Yield #{'%.2f' %SeedYield}%", RBA::MessageBox::b_ok)

end

### add the command in the tools menu
app = RBA::Application.instance
mw = app.main_window

menu = mw.menu
menu.insert_separator("tools_menu.end", "name")
menu.insert_item("tools_menu.end", "gross_die", $gross_die)
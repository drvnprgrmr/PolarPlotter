/**
  Controls Setup
  Refactored for 3-Column Layout
*/

import java.util.*;

// ----------------------------------------------------------------
// SETUP & INITIALIZATION
// ----------------------------------------------------------------

void controlsSetup()
{
  cp5 = new ControlP5(this);
  
  // Define Left Sidebar Tabs
  cp5.addTab(TAB_NAME_INPUT)
     .setColorBackground(color(0, 54, 82))
     .setColorLabel(color(255))
     .setColorActive(color(0, 100, 150))
     .setHeight(20)
     .setWidth(LEFT_SIDEBAR_WIDTH / 2)
     .activateEvent(true)
     .setId(1);

  cp5.addTab(TAB_NAME_DETAILS)
     .setColorBackground(color(0, 54, 82))
     .setColorLabel(color(255))
     .setColorActive(color(0, 100, 150))
     .setHeight(20)
     .setWidth(LEFT_SIDEBAR_WIDTH / 2)
     .activateEvent(true)
     .setId(2);

  // Hide default tab
  cp5.getTab("default").hide();

  getAllControls();
  getPanels();
  recalculatePanels();
}

void recalculatePanels() {
   for (Panel p : getPanels().values()) {
      p.setSizeByHeight(p.getOutline().getHeight()); 
   }
}

void updateNumberboxValues() {
  initialiseNumberboxValues(getAllControls());
}

void initConsoleWindow() {
  // Console helper (invisible but required for cp5)
  consoleArea = cp5.addTextarea("txt")
                   .setPosition(0,0).setSize(1,1).hide();
}

// ----------------------------------------------------------------
// PANEL MAPPING
// ----------------------------------------------------------------

Map<String, Set<Panel>> buildPanelsForTabs() {
  Map<String, Set<Panel>> map = new HashMap<String, Set<Panel>>();
  
  Set<Panel> inputPanels = new HashSet<Panel>();
  inputPanels.add(getPanels().get(PANEL_NAME_INPUT));
  inputPanels.add(getPanels().get(PANEL_NAME_GENERAL));
  map.put(TAB_NAME_INPUT, inputPanels);

  Set<Panel> detailsPanels = new HashSet<Panel>();
  detailsPanels.add(getPanels().get(PANEL_NAME_DETAILS));
  detailsPanels.add(getPanels().get(PANEL_NAME_GENERAL)); 
  map.put(TAB_NAME_DETAILS, detailsPanels);
  
  return map;
}

// ----------------------------------------------------------------
// PANEL CONSTRUCTION
// ----------------------------------------------------------------

Map<String, Panel> buildPanels() {
  Map<String, Panel> panels = new HashMap<String, Panel>();

  int pWidth = LEFT_SIDEBAR_WIDTH; 
  int pHeight = height - 150; 

  // 1. INPUT PANEL
  Rectangle rInput = new Rectangle(new PVector(0, 20), new PVector(pWidth, pHeight));
  Panel inputPanel = new Panel(PANEL_NAME_INPUT, rInput);
  inputPanel.setResizable(true);
  inputPanel.setOutlineColour(color(200));
  inputPanel.setControls(getControlsForPanels().get(PANEL_NAME_INPUT));
  inputPanel.setControlPositions(buildControlPositionsForPanel(inputPanel));
  inputPanel.setControlSizes(buildControlSizesForPanel(inputPanel));
  panels.put(PANEL_NAME_INPUT, inputPanel);

  // 2. DETAILS PANEL
  Rectangle rDetails = new Rectangle(new PVector(0, 20), new PVector(pWidth, pHeight));
  Panel detailsPanel = new Panel(PANEL_NAME_DETAILS, rDetails);
  detailsPanel.setOutlineColour(color(200, 200, 255));
  detailsPanel.setResizable(true);
  detailsPanel.setControls(getControlsForPanels().get(PANEL_NAME_DETAILS));
  detailsPanel.setControlPositions(buildControlPositionsForPanel(detailsPanel));
  detailsPanel.setControlSizes(buildControlSizesForPanel(detailsPanel));
  panels.put(PANEL_NAME_DETAILS, detailsPanel);

  // 3. GENERAL PANEL
  Rectangle rGeneral = new Rectangle(new PVector(0, height - 120), new PVector(pWidth, 120));
  Panel generalPanel = new Panel(PANEL_NAME_GENERAL, rGeneral);
  generalPanel.setResizable(false);
  generalPanel.setOutlineColour(color(200, 50, 200));
  generalPanel.setControls(getControlsForPanels().get(PANEL_NAME_GENERAL));
  generalPanel.setControlPositions(buildControlPositionsForPanel(generalPanel));
  generalPanel.setControlSizes(buildControlSizesForPanel(generalPanel));
  panels.put(PANEL_NAME_GENERAL, generalPanel);

  return panels;
}

// ----------------------------------------------------------------
// CONTROL CONSTRUCTION (Builds Buttons & Dropdowns)
// ----------------------------------------------------------------

Map<String, Controller> buildAllControls()
{
  initConsoleWindow();
  Map<String, Controller> map = new HashMap<String, Controller>();

  for (String controlName : getControlNames())
  {
    if (controlName.startsWith("button_"))
    {
      // Special Case: Serial Port Dropdown
      if (controlName.equals(MODE_CHANGE_SERIAL_PORT)) 
      {
        ScrollableList list = cp5.addScrollableList(controlName)
           .setPosition(0, 0)
           .setSize(220, 200)
           .setBarHeight(20)
           .setItemHeight(20)
           .addItems(processing.serial.Serial.list())
           .setLabel("Select Serial Port")
           .close();
        list.getCaptionLabel().getStyle().marginTop = 3;
        list.getCaptionLabel().getStyle().marginLeft = 3;
        list.hide();
        map.put(controlName, list);
        continue;
      }

      Button b = cp5.addButton(controlName)
                     .setPosition(0, 0)
                     .setSize(100, 100)
                     .setLabel(getControlLabels().get(controlName));
      b.hide();
      map.put(controlName, b);
    }
    else if (controlName.startsWith("toggle_") || controlName.startsWith("minitoggle_"))
    {
      Toggle t = cp5.addToggle(controlName)
                     .setPosition(0, 0)
                     .setSize(100, 100)
                     .setValue(false)
                     .setLabel(getControlLabels().get(controlName));
      t.hide();
      controlP5.Label l = t.getCaptionLabel();
      l.getStyle().marginTop = -17;
      l.getStyle().marginLeft = 4;
      map.put(controlName, t);
    }
    else if (controlName.startsWith("numberbox_"))
    {
      Numberbox n = cp5.addNumberbox(controlName)
                        .setPosition(0, 0)
                        .setSize(100, 20)
                        .setLabel(getControlLabels().get(controlName));
      n.hide();
      n.setDecimalPrecision(0);
      n.setDirection(Controller.VERTICAL);
      controlP5.Label l = n.getCaptionLabel();
      l.getStyle().marginTop = -17;
      l.getStyle().marginLeft = 40;
      map.put(controlName, n);
    }
  }

  initialiseButtonValues(map);
  initialiseToggleValues(map);
  initialiseNumberboxValues(map);
  return map;
}

// ----------------------------------------------------------------
// INITIALIZERS
// ----------------------------------------------------------------

Map<String, Controller> initialiseButtonValues(Map<String, Controller> map)
{
  for (String key : map.keySet())
  {
    if (key.startsWith("button_") && MODE_CHANGE_POLYGONIZER.equals(key)) {
       try {
         Button n = (Button) map.get(key);
         n.setValue(polygonizer);
         n.setLabel(this.controlLabels.get(MODE_CHANGE_POLYGONIZER) + ": " + polygonizer);
       } catch (Exception e) {}
    }
  }
  return map;
}

Map<String, Controller> initialiseToggleValues(Map<String, Controller> map)
{
  try {
    ((Toggle)map.get(MODE_SHOW_QUEUE_PREVIEW)).setValue(displayingQueuePreview);
    ((Toggle)map.get(MODE_SHOW_VECTOR)).setValue(displayingVector);
    ((Toggle)map.get(MODE_SHOW_GUIDES)).setValue(displayingGuides);
  } catch (Exception e) {}
  return map;
}

Map<String, Controller> initialiseNumberboxValues(Map<String, Controller> map)
{
  for (String key : map.keySet())
  {
    if (key.startsWith("numberbox_"))
    {
      Numberbox n = (Numberbox) map.get(key);
      if (n == null) continue;
      
      if (MODE_RESIZE_VECTOR.equals(key)) {
        n.setDecimalPrecision(1).setValue(vectorScaling).setMin(0.1).setMax(1000).setMultiplier(0.5);
      }      
      else if (MODE_CHANGE_MIN_VECTOR_LINE_LENGTH.equals(key)) {
        n.setValue(minimumVectorLineLength).setMin(0).setMultiplier(1);
      }
      else if (MODE_CHANGE_MACHINE_WIDTH.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getDisplayMachine().getWidth())).setMin(20).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_MACHINE_HEIGHT.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getDisplayMachine().getHeight())).setMin(20).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_MM_PER_REV.equals(key)) {
        n.setValue(getDisplayMachine().getMMPerRev()).setMin(20).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_STEPS_PER_REV.equals(key)) {
        n.setValue(getDisplayMachine().getStepsPerRev()).setMin(20).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_PAGE_WIDTH.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getDisplayMachine().getPage().getWidth())).setMin(10).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_PAGE_HEIGHT.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getDisplayMachine().getPage().getHeight())).setMin(10).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_PAGE_OFFSET_X.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getDisplayMachine().getPage().getLeft())).setMin(0).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_PAGE_OFFSET_Y.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getDisplayMachine().getPage().getTop())).setMin(0).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_PEN_WIDTH.equals(key)) {
        n.setDecimalPrecision(2).setValue(currentPenWidth).setMin(0.01).setMultiplier(0.01);
      }
      else if (MODE_PEN_LIFT_POS_UP.equals(key)) {
        n.setDecimalPrecision(1).setValue(penLiftUpPosition).setMin(0).setMax(360).setMultiplier(0.5);
      }
      else if (MODE_PEN_LIFT_POS_DOWN.equals(key)) {
        n.setDecimalPrecision(1).setValue(penLiftDownPosition).setMin(0).setMax(360).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_MACHINE_MAX_SPEED.equals(key)) {
        n.setDecimalPrecision(0).setValue(currentMachineMaxSpeed).setMin(1).setMultiplier(1);
      }
      else if (MODE_CHANGE_MACHINE_ACCELERATION.equals(key)) {
        n.setDecimalPrecision(0).setValue(currentMachineAccel).setMin(1).setMultiplier(1);
      }
      else if (MODE_CHANGE_HOMEPOINT_X.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getHomePoint().x)).setMin(0).setMultiplier(0.5);
      }
      else if (MODE_CHANGE_HOMEPOINT_Y.equals(key)) {
        n.setValue(getDisplayMachine().inMM(getHomePoint().y)).setMin(0).setMultiplier(0.5);
      }
    }
  }
  return map;
}

// ----------------------------------------------------------------
// CONTROL LISTS
// ----------------------------------------------------------------

List<String> getControlNamesForInputPanel() {
  List<String> c = new ArrayList<String>();
  c.add(MODE_LOAD_VECTOR_FILE);
  c.add(MODE_RENDER_VECTORS);
  c.add(MODE_MOVE_VECTOR);
  c.add(MODE_RESIZE_VECTOR);
  c.add(MODE_CHANGE_MIN_VECTOR_LINE_LENGTH);
  c.add(MODE_CHANGE_POLYGONIZER_LENGTH);
  c.add(MODE_RETURN_TO_HOME);
  c.add(MODE_SET_POSITION_HOME);
  c.add(MODE_PEN_LIFT_UP);
  c.add(MODE_PEN_LIFT_DOWN);
  c.add(MODE_SET_POSITION);
  c.add(MODE_INPUT_BOX_TOP_LEFT);
  c.add(MODE_DRAW_OUTLINE_BOX);
  c.add(MODE_CONVERT_BOX_TO_PICTUREFRAME);
  c.add(MODE_SHOW_VECTOR);
  c.add(MODE_SHOW_GUIDES);
  c.add(MODE_SHOW_QUEUE_PREVIEW);
  return c;
}

List<String> getControlNamesForDetailPanel() {
  List<String> c = new ArrayList<String>();
  c.add(MODE_CHANGE_MACHINE_SPEC);
  c.add(MODE_REQUEST_MACHINE_SIZE);
  c.add(MODE_CHANGE_MACHINE_WIDTH);
  c.add(MODE_CHANGE_MACHINE_HEIGHT);
  c.add(MODE_CHANGE_PAGE_WIDTH);
  c.add(MODE_CHANGE_PAGE_HEIGHT);
  c.add(MODE_CHANGE_PAGE_OFFSET_X);
  c.add(MODE_CHANGE_PAGE_OFFSET_X_CENTRE);
  c.add(MODE_CHANGE_PAGE_OFFSET_Y);
  c.add(MODE_CHANGE_MM_PER_REV);
  c.add(MODE_CHANGE_STEPS_PER_REV);
  c.add(MODE_CHANGE_MACHINE_MAX_SPEED);
  c.add(MODE_CHANGE_MACHINE_ACCELERATION);
  c.add(MODE_SEND_MACHINE_SPEED);
  c.add(MODE_CHANGE_PEN_WIDTH);
  c.add(MODE_SEND_PEN_WIDTH);
  c.add(MODE_CHANGE_HOMEPOINT_X);
  c.add(MODE_CHANGE_HOMEPOINT_X_CENTRE);
  c.add(MODE_CHANGE_HOMEPOINT_Y);
  c.add(MODE_PEN_LIFT_POS_UP);
  c.add(MODE_PEN_LIFT_POS_DOWN);
  c.add(MODE_SEND_PEN_LIFT_RANGE);
  c.add(MODE_CHANGE_SERIAL_PORT);
  return c;
}

List<String> getControlNamesForGeneralPanel() {
  List<String> c = new ArrayList<String>();
  c.add(MODE_CLEAR_QUEUE);
  c.add(MODE_SAVE_PROPERTIES);
  c.add(MODE_LOAD_PROPERTIES);
  return c;
}

List<String> getControlNamesForQueuePanel() { return new ArrayList<String>(); }

// ----------------------------------------------------------------
// LABELS
// ----------------------------------------------------------------

Map<String, String> buildControlLabels() {
  Map<String, String> result = new HashMap<String, String>();
  
  result.put(MODE_LOAD_VECTOR_FILE, "Load Vector");
  result.put(MODE_RENDER_VECTORS, "Draw Vector");
  result.put(MODE_MOVE_VECTOR, "Move Vector");
  result.put(MODE_RESIZE_VECTOR, "Scale Vector %");
  result.put(MODE_CHANGE_MIN_VECTOR_LINE_LENGTH, "Min Line Len");
  result.put(MODE_CHANGE_POLYGONIZER_LENGTH, "Smoothness");
  
  result.put(MODE_RETURN_TO_HOME, "Go Home");
  result.put(MODE_SET_POSITION_HOME, "Set Home Here");
  result.put(MODE_PEN_LIFT_UP, "Pen Up");
  result.put(MODE_PEN_LIFT_DOWN, "Pen Down");
  result.put(MODE_SET_POSITION, "Set Pen Pos");
  
  result.put(MODE_INPUT_BOX_TOP_LEFT, "Select Area");
  result.put(MODE_DRAW_OUTLINE_BOX, "Draw Box");
  result.put(MODE_CONVERT_BOX_TO_PICTUREFRAME, "Set Frame to Box");
  
  result.put(MODE_SHOW_VECTOR, "Show Vector");
  result.put(MODE_SHOW_GUIDES, "Show Guides");
  result.put(MODE_SHOW_QUEUE_PREVIEW, "Show Queue");

  result.put(MODE_CHANGE_MACHINE_SPEC, "Upload Spec");
  result.put(MODE_REQUEST_MACHINE_SIZE, "Download Spec");
  result.put(MODE_CHANGE_MACHINE_WIDTH, "Mach Width");
  result.put(MODE_CHANGE_MACHINE_HEIGHT, "Mach Height");
  result.put(MODE_CHANGE_PAGE_WIDTH, "Page Width");
  result.put(MODE_CHANGE_PAGE_HEIGHT, "Page Height");
  
  result.put(MODE_CHANGE_MM_PER_REV, "MM / Rev");
  result.put(MODE_CHANGE_STEPS_PER_REV, "Steps / Rev");
  result.put(MODE_CHANGE_MACHINE_MAX_SPEED, "Max Speed");
  result.put(MODE_CHANGE_MACHINE_ACCELERATION, "Acceleration");
  result.put(MODE_SEND_MACHINE_SPEED, "Send Speed");
  
  result.put(MODE_CHANGE_PEN_WIDTH, "Pen Tip (mm)");
  result.put(MODE_SEND_PEN_WIDTH, "Send Pen Tip");
  result.put(MODE_PEN_LIFT_POS_UP, "Up Angle");
  result.put(MODE_PEN_LIFT_POS_DOWN, "Down Angle");
  result.put(MODE_SEND_PEN_LIFT_RANGE, "Test Lift");
  
  result.put(MODE_CHANGE_SERIAL_PORT, "Serial Port...");
  result.put(MODE_EXPORT_QUEUE, "Export Q");
  result.put(MODE_IMPORT_QUEUE, "Import Q");
  result.put(MODE_SAVE_PROPERTIES, "Save Settings");
  result.put(MODE_LOAD_PROPERTIES, "Load Settings");
  result.put(MODE_CLEAR_QUEUE, "Clear Queue");
  
  result.put(MODE_CHANGE_PAGE_OFFSET_X, "Page X");
  result.put(MODE_CHANGE_PAGE_OFFSET_Y, "Page Y");
  result.put(MODE_CHANGE_HOMEPOINT_X, "Home X");
  result.put(MODE_CHANGE_HOMEPOINT_Y, "Home Y");
  
  result.put(MODE_CHANGE_PAGE_OFFSET_X_CENTRE, "Center Page X");
  result.put(MODE_CHANGE_HOMEPOINT_X_CENTRE, "Center Home X");

  return result;
}

// ----------------------------------------------------------------
// GETTERS
// ----------------------------------------------------------------

List<Panel> getPanelsForTab(String tabName) {
  if (this.panelsForTabs == null) this.panelsForTabs = buildPanelsForTabs();
  List<Panel> result = new ArrayList<Panel>();
  Set<Panel> panelSet = this.panelsForTabs.get(tabName);
  if (panelSet != null) result.addAll(panelSet);
  return result;
}

Set<String> getPanelNames() { return getPanels().keySet(); }
Set<String> buildPanelNames() { return getPanels().keySet(); }
List<String> getTabNames() { return new ArrayList<String>(Arrays.asList(TAB_NAME_INPUT, TAB_NAME_DETAILS)); }
Set<String> getControlNames() { if (this.controlNames == null) this.controlNames = buildControlNames(); return this.controlNames; }
Set<String> buildControlNames() { return getControlLabels().keySet(); }

Map<String, List<Controller>> getControlsForPanels() {
  if (this.controlsForPanels == null) this.controlsForPanels = buildControlsForPanels();
  return this.controlsForPanels;
}
Map<String, List<Controller>> buildControlsForPanels() {
  Map<String, List<Controller>> map = new HashMap<String, List<Controller>>();
  map.put(PANEL_NAME_INPUT, getControllersForControllerNames(getControlNamesForInputPanel()));
  map.put(PANEL_NAME_DETAILS, getControllersForControllerNames(getControlNamesForDetailPanel()));
  map.put(PANEL_NAME_GENERAL, getControllersForControllerNames(getControlNamesForGeneralPanel()));
  return map;
}

Map<String, Controller> getAllControls() { if (this.allControls == null) this.allControls = buildAllControls(); return this.allControls; }
Map<String, String> getControlLabels() { if (this.controlLabels == null) this.controlLabels = buildControlLabels(); return this.controlLabels; }
Map<String, Panel> getPanels() { if (this.panels == null) this.panels = buildPanels(); return this.panels; }

List<Controller> getControllersForControllerNames(List<String> names) {
  List<Controller> list = new ArrayList<Controller>();
  for (String name : names) { Controller c = getAllControls().get(name); if (c != null) list.add(c); }
  return list;
}

Map<String, PVector> buildControlPositionsForPanel(Panel panel) {
  Map<String, PVector> map = new HashMap<String, PVector>();
  int col = 0; int row = 0;
  for (Controller controller : panel.getControls()) {
    PVector p = new PVector(col*(DEFAULT_CONTROL_SIZE.x+CONTROL_SPACING.x), row*(DEFAULT_CONTROL_SIZE.y+CONTROL_SPACING.y));
    map.put(controller.getName(), p);
    row++;
    if (p.y + (DEFAULT_CONTROL_SIZE.y*2) >= panel.getOutline().getHeight()) { row = 0; col++; }
  }
  return map;
}

Map<String, PVector> buildControlSizesForPanel(Panel panel) {
  Map<String, PVector> map = new HashMap<String, PVector>();
  for (Controller controller : panel.getControls()) {
    if (controller.getName().startsWith("minitoggle_")) map.put(controller.getName(), new PVector(DEFAULT_CONTROL_SIZE.y, DEFAULT_CONTROL_SIZE.y));
    else map.put(controller.getName(), new PVector(DEFAULT_CONTROL_SIZE.x, DEFAULT_CONTROL_SIZE.y));
  }
  return map;
}

void hideAllControls() {
  for (Controller c : getAllControls().values()) {
    c.hide();
  }
}

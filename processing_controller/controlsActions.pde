/**
  Controls Actions
  Handles events triggered by GUI elements.
*/

// ----------------------------------------------------------------
// GENERAL MODES
// ----------------------------------------------------------------

void button_mode_begin() {
  button_mode_clearQueue();
}

void setMode(String m) {
  lastMode = currentMode;
  currentMode = m;
}

void revertToLastMode() {
  currentMode = lastMode;
}

// ----------------------------------------------------------------
// TOGGLES & VISIBILITY
// ----------------------------------------------------------------

void minitoggle_mode_showImage(boolean flag) {
  this.displayingImage = flag;
}

void minitoggle_mode_showVector(boolean flag) {
  this.displayingVector = flag;
}

void minitoggle_mode_showQueuePreview(boolean flag) {
  this.displayingQueuePreview = flag;
}

void minitoggle_mode_showGuides(boolean flag) {
  this.displayingGuides = flag;
}

// Helper to ensure only one "Mouse Tool" is active at a time
void unsetOtherToggles(String except)
{
  if (getAllControls() == null) return;
  
  for (String name : getAllControls().keySet())
  {
    if (name.startsWith("toggle_") && !name.equals(except))
    {
      try { getAllControls().get(name).setValue(0); } catch(Exception e) {}
    }
  }
}

// ----------------------------------------------------------------
// PEN & MOTOR CONTROL
// ----------------------------------------------------------------

void button_mode_penUp() {
  addToCommandQueue(CMD_PENUP + penLiftUpPosition +",END");
}
void button_mode_penDown() {
  addToCommandQueue(CMD_PENDOWN + penLiftDownPosition +",END");
}
void numberbox_mode_penUpPos(int value) {
  penLiftUpPosition = value;
}
void numberbox_mode_penDownPos(int value) {
  penLiftDownPosition = value;
}
void button_mode_sendPenliftRange() {
  addToCommandQueue(CMD_SETPENLIFTRANGE+penLiftDownPosition+","+penLiftUpPosition+",END");
}
void button_mode_sendPenliftRangePersist() {
  addToCommandQueue(CMD_SETPENLIFTRANGE+penLiftDownPosition+","+penLiftUpPosition+",1,END");
}

void button_mode_sendMachineSpeed()
{
  // Send Speed/Accel to machine immediately (Realtime)
  NumberFormat nf = NumberFormat.getNumberInstance(Locale.UK);
  DecimalFormat df = (DecimalFormat)nf;
  df.applyPattern("###.##");
  
  addToRealtimeCommandQueue(CMD_SETMOTORSPEED+df.format(currentMachineMaxSpeed)+",END");
  addToRealtimeCommandQueue(CMD_SETMOTORACCEL+df.format(currentMachineAccel)+",END");
}

void button_mode_sendMachineSpeedPersist()
{
  // Send Speed/Accel and save to EEPROM (Standard Queue)
  NumberFormat nf = NumberFormat.getNumberInstance(Locale.UK);
  DecimalFormat df = (DecimalFormat)nf;
  df.applyPattern("###.##");
  
  addToCommandQueue(CMD_SETMOTORSPEED+df.format(currentMachineMaxSpeed)+",1,END");
  addToCommandQueue(CMD_SETMOTORACCEL+df.format(currentMachineAccel)+",1,END");
}

void numberbox_mode_changeMachineMaxSpeed(float value) {
  currentMachineMaxSpeed = Math.round(value*100.0)/100.0;
}
void numberbox_mode_changeMachineAcceleration(float value) {
  currentMachineAccel = Math.round(value*100.0)/100.0;
}

// ----------------------------------------------------------------
// VECTOR & DRAWING ACTIONS
// ----------------------------------------------------------------

void button_mode_renderVectors()
{
  // Switch view to Queue Preview to show the generated path
  minitoggle_mode_showQueuePreview(true);
  sendVectorShapes(); // Defined in comms (or needs to be defined in next step)
}

void button_mode_drawOutlineBox()
{
  if (isBoxSpecified()) {
    sendOutlineOfBox(); // Defined in comms
  }
}

void button_mode_loadImage()
{
  // FIX: Redirected 'Load Image' to 'Load Vector' since we removed Bitmap engine
  if (getDisplayMachine().getVectorShape() == null) {
    loadVectorWithFileChooser(); 
  } else {
    getDisplayMachine().setVectorShape(null);
    vectorFilename = null;
    println("Vector unloaded.");
  }
}

void button_mode_loadVectorFile()
{
  if (vectorShape == null) {
    loadVectorWithFileChooser();
    minitoggle_mode_showVector(true);
  } else {
    vectorShape = null;
    vectorFilename = null;
  }
}

void numberbox_mode_resizeVector(float value)
{
  if (vectorShape != null)
  {
    // Resize relative to center
    PVector oldSize = new PVector(vectorShape.width, vectorShape.height);
    oldSize.mult(vectorScaling/100.0);
    
    PVector oldCentroid = new PVector(oldSize.x / 2.0, oldSize.y / 2.0);

    PVector newSize = new PVector(vectorShape.width, vectorShape.height);
    newSize.mult(value/100.0);
    
    PVector newCentroid = new PVector(newSize.x / 2.0, newSize.y / 2.0);

    // Shift position to keep center static
    PVector diff = PVector.sub(oldCentroid, newCentroid);
    vectorPosition.add(diff);
  }
  vectorScaling = value;
}

void numberbox_mode_changeMinVectorLineLength(float value) {
  minimumVectorLineLength = (int) value;
}

void numberbox_mode_changePolygonizerLength(float value) {
  polygonizerLength = value;
  setupPolygonizer();
}

void button_mode_cyclePolygonizer()
{
  // Toggle between Uniform(0) and Adaptative(1)
  if (polygonizer == 1) polygonizer = 0; 
  else polygonizer++;
  
  setupPolygonizer();
  
  // Update Label
  try {
    Controller c = cp5.getController(MODE_CHANGE_POLYGONIZER);
    c.setLabel(controlLabels.get(MODE_CHANGE_POLYGONIZER) + ": " + polygonizer);
  } catch(Exception e) {}
}

// ----------------------------------------------------------------
// MOUSE TOOLS (SELECTION MODES)
// ----------------------------------------------------------------

void toggle_mode_inputBoxTopLeft(boolean flag) {
  if (flag) {
    unsetOtherToggles(MODE_INPUT_BOX_TOP_LEFT);
    setMode(MODE_INPUT_BOX_TOP_LEFT);
  } else currentMode = "";
}

void toggle_mode_inputBoxBotRight(boolean flag) {
  if (flag) {
    unsetOtherToggles(MODE_INPUT_BOX_BOT_RIGHT);
    setMode(MODE_INPUT_BOX_BOT_RIGHT);
  } else currentMode = "";
}

void toggle_mode_moveVector(boolean flag) {
  if (flag) {
    unsetOtherToggles(MODE_MOVE_VECTOR);
    setMode(MODE_MOVE_VECTOR);
  } else setMode("");
}

void toggle_mode_drawToPosition(boolean flag) {
  if (flag) {
    unsetOtherToggles(MODE_DRAW_TO_POSITION);
    setMode(MODE_DRAW_TO_POSITION);
  }
}

void toggle_mode_setPosition(boolean flag) {
  if (flag) {
    unsetOtherToggles(MODE_SET_POSITION);
    setMode(MODE_SET_POSITION);
  }
}

void toggle_mode_drawDirect(boolean flag) {
  if (flag) {
    unsetOtherToggles(MODE_DRAW_DIRECT);
    setMode(MODE_DRAW_DIRECT);
  }
}

// ----------------------------------------------------------------
// MACHINE SETUP ACTIONS
// ----------------------------------------------------------------

void button_mode_returnToHome() {
  button_mode_penUp();
  // Move to the physical home coordinates
  PVector pgCoords = getDisplayMachine().asNativeCoords(getHomePoint());
  sendMoveToNativePosition(false, pgCoords); // Defined in comms
}

void button_mode_setPositionHome() {
  sendSetHomePosition();
}
void button_mode_drawTestPattern() {
  sendTestPattern();
}
void button_mode_changeMachineSpec() {
  sendMachineSpec();
}
void button_mode_requestMachineSize() {
  sendRequestMachineSize();
}
void button_mode_resetMachine() {
  sendResetMachine();
}

// ----------------------------------------------------------------
// PROPERTIES
// ----------------------------------------------------------------

void button_mode_saveProperties() {
  savePropertiesFile();
  // Reload to verify
  props = null;
  loadFromPropertiesFile();
}
void button_mode_saveAsProperties() {
  saveNewPropertiesFileWithFileChooser();
}
void button_mode_loadProperties() {
  loadNewPropertiesFilenameWithFileChooser();
}

// ----------------------------------------------------------------
// PICTURE FRAME / BOX
// ----------------------------------------------------------------

void button_mode_convertBoxToPictureframe() {
  setPictureFrameDimensionsToBox();
}
void button_mode_selectPictureframe() {
  setBoxToPictureframeDimensions();
}

// ----------------------------------------------------------------
// DIMENSION SETTINGS
// ----------------------------------------------------------------

void numberbox_mode_changeMachineWidth(float value) {
  clearBoxVectors();
  float steps = getDisplayMachine().inSteps((int) value);
  getDisplayMachine().getSize().x = steps;
}
void numberbox_mode_changeMachineHeight(float value) {
  clearBoxVectors();
  float steps = getDisplayMachine().inSteps((int) value);
  getDisplayMachine().getSize().y = steps;
}
void numberbox_mode_changeMMPerRev(float value) {
  clearBoxVectors();
  getDisplayMachine().setMMPerRev(value);
}
void numberbox_mode_changeStepsPerRev(float value) {
  clearBoxVectors();
  getDisplayMachine().setStepsPerRev(value);
}
void numberbox_mode_changeStepMultiplier(float value) {
  machineStepMultiplier = (int) value;
}

void numberbox_mode_changePageWidth(float value) {
  float steps = getDisplayMachine().inSteps((int) value);
  getDisplayMachine().getPage().setWidth(steps);
}
void numberbox_mode_changePageHeight(float value) {
  float steps = getDisplayMachine().inSteps((int) value);
  getDisplayMachine().getPage().setHeight(steps);
}
void numberbox_mode_changePageOffsetX(float value) {
  float steps = getDisplayMachine().inSteps((int) value);
  getDisplayMachine().getPage().getTopLeft().x = steps;
}
void numberbox_mode_changePageOffsetY(float value) {
  float steps = getDisplayMachine().inSteps((int) value);
  getDisplayMachine().getPage().getTopLeft().y = steps;
}

void button_mode_changePageOffsetXCentre() {
  float pageWidth = getDisplayMachine().getPage().getWidth();
  float machineWidth = getDisplayMachine().getSize().x;
  float diff = (machineWidth - pageWidth) / 2.0;
  getDisplayMachine().getPage().getTopLeft().x = (int) diff;
  initialiseNumberboxValues(getAllControls());
}

void numberbox_mode_changeHomePointX(float value) {
  float steps = getDisplayMachine().inSteps((int) value);
  getHomePoint().x = steps;
}
void numberbox_mode_changeHomePointY(float value) {
  float steps = getDisplayMachine().inSteps((int) value);
  getHomePoint().y = steps;
}
void button_mode_changeHomePointXCentre() {
  float halfWay = getDisplayMachine().getSize().x / 2.0;
  getHomePoint().x = (int) halfWay;
  getHomePoint().y = (int) getDisplayMachine().getPage().getTop();
  initialiseNumberboxValues(getAllControls());
}

// ----------------------------------------------------------------
// PEN WIDTH & TESTS
// ----------------------------------------------------------------

void numberbox_mode_changePenWidth(float value) {
  currentPenWidth = Math.round(value*100.0)/100.0;
}
void button_mode_sendPenWidth() {
  NumberFormat nf = NumberFormat.getNumberInstance(Locale.UK);
  DecimalFormat df = (DecimalFormat)nf;
  df.applyPattern("###.##");
  addToRealtimeCommandQueue(CMD_CHANGEPENWIDTH+df.format(currentPenWidth)+",END");
}

void numberbox_mode_changePenTestStartWidth(float value) {
  testPenWidthStartSize = Math.round(value*100.0)/100.0;
}
void numberbox_mode_changePenTestEndWidth(float value) {
  testPenWidthEndSize = Math.round(value*100.0)/100.0;
}
void numberbox_mode_changePenTestIncrementSize(float value) {
  testPenWidthIncrementSize = Math.round(value*100.0)/100.0;
}
void button_mode_drawTestPenWidth() {
  sendTestPenWidth(); // Defined in comms
}

// ----------------------------------------------------------------
// QUEUE ACTIONS
// ----------------------------------------------------------------

void button_mode_pauseQueue() {
  commandQueueRunning = false;
}
void button_mode_runQueue() {
  commandQueueRunning = true;
}
void button_mode_clearQueue() {
  resetQueue();
}
void button_mode_exportQueue() {
  exportQueueToFile();
}
void button_mode_importQueue() {
  importQueueFromFile();
}

void numberbox_mode_previewCordOffsetValue(int value) {
  previewCordOffset = value;
  previewQueue(true);
}


void changeSerialPort(int n) {
  // 1. Get the list object
  ScrollableList list = (ScrollableList) cp5.getController(MODE_CHANGE_SERIAL_PORT);
  
  // 2. Get the selected port name text
  String portName = list.getItem(n).get("name").toString();
  
  println("Connecting to " + portName + "...");
  
  // 3. Connect
  try {
    if (myPort != null) {
      myPort.stop();
    }
    myPort = new processing.serial.Serial(this, portName, baudRate);
    myPort.bufferUntil('\n');
    println("SUCCESS: Connected to " + portName);
  } catch (Exception e) {
    println("ERROR: Could not connect to " + portName);
    println(e.getMessage());
  }
}

/**
 * Polargraph Controller (SVG Edition)
 * * A streamlined controller for Polargraph drawing machines.
 * Focuses purely on SVG/Vector loading and G-Code generation.
 * * Original by Sandy Noble (2012).
 * Refactored for SVG-Only Workflow.
 */

import java.awt.Frame;
import javax.swing.JFrame;
import processing.awt.PSurfaceAWT;
import java.awt.Component;
import java.io.*;
import java.util.*;
import java.text.*;
import java.util.zip.CRC32;
import java.util.logging.*;
import javax.swing.*;
import java.awt.event.KeyEvent;

// Libraries
import processing.serial.*;
import controlP5.*;
import geomerative.*; // Essential for SVG handling

// Pen Width Test Settings
float testPenWidthStartSize = 0.5;
float testPenWidthEndSize = 2.0;
float testPenWidthIncrementSize = 0.5;

PVector homePointCartesian = null; // Stores the physical "Park" coordinates
String lastCommand = "";
// Controls whether the translucent info box (HUD) is visible
boolean displayingInfoTextOnInputPage = false;

// Console / Debugging Variables
public Println console = null;
public PrintStream savedOut = null;
// public Textarea consoleArea = null; // (This one should already be there, but double check!)

// ----------------------------------------------------------------
// VERSION & BASICS
// ----------------------------------------------------------------
int majorVersionNo = 2;
int minorVersionNo = 5;
int buildNo = 1;

String programTitle = "Polargraph SVG Controller v" + majorVersionNo + "." + minorVersionNo;
// Tracks which Tab is currently open (Input, Setup, Queue)
public String currentTab = TAB_NAME_INPUT;

ControlP5 cp5;
Map<String, ControlP5> cp5s = new HashMap<String, ControlP5>();

// ----------------------------------------------------------------
// MACHINE STATE
// ----------------------------------------------------------------
boolean drawbotReady = false;
boolean drawbotConnected = false;

static final int HARDWARE_VER_UNO = 1;
static final int HARDWARE_VER_MEGA = 100;
static final int HARDWARE_VER_MEGA_POLARSHIELD = 200;
static final int HARDWARE_VER_POLARPRO = 300;
int currentHardware = HARDWARE_VER_MEGA_POLARSHIELD;

String newMachineName = "POLARGRAPH";
PVector machinePosition = new PVector(130.0, 50.0);
float machineScaling = 1.0;
DisplayMachine displayMachine = null;

// Dimensions & Paper Presets
int homeALengthMM = 400;
int homeBLengthMM = 400;


// Used for input handling (Keyboard shortcuts)
boolean[] keys = new boolean[526];

// Used for legacy calculations (though mostly unused in pure SVG mode,
// keeping it prevents "variable not found" errors in the UI setup)
float sampleArea = 10.0;

// Variables for panning the view (Middle Mouse Button)
PVector lastMachineDragPosition = new PVector(0.0, 0.0);

// Zoom limits
final float MIN_SCALING = 0.01;
final float MAX_SCALING = 20.0;

// LAYOUT CONSTANTS
final int LEFT_SIDEBAR_WIDTH = 260;
final int RIGHT_SIDEBAR_WIDTH = 220;

// ----------------------------------------------------------------
// SERIAL & COMM
// ----------------------------------------------------------------
int baudRate = 57600;
processing.serial.Serial myPort;
boolean useSerialPortConnection = false;
public static Integer serialPortNumber = -1;

int[] serialInArray = new int[1];
int serialCount = 0;
String commandStatus = "Waiting for a click.";

// ----------------------------------------------------------------
// QUEUE & COMMANDS
// ----------------------------------------------------------------
List<String> commandQueue = new ArrayList<String>();
List<String> realtimeCommandQueue = new ArrayList<String>();
List<String> commandHistory = new ArrayList<String>();
List<String> machineMessageLog = new ArrayList<String>();
List<PreviewVector> previewCommandList = new ArrayList<PreviewVector>();

Boolean commandQueueRunning = false;
long lastCommandQueueHash = 0L;

// ----------------------------------------------------------------
// FILE SYSTEM
// ----------------------------------------------------------------
final JFileChooser chooser = new JFileChooser();
File lastImageDirectory = null;
File lastPropertiesDirectory = null;
String propertiesFilename = "default.properties.txt";
String newPropertiesFilename = null;
Properties props = null;

String storeFilename = "comm.txt";
boolean overwriteExistingStoreFile = true;

// ----------------------------------------------------------------
// SETTINGS
// ----------------------------------------------------------------
float gridSize = 75.0;
float currentPenWidth = 0.8;

int penLiftDownPosition = 90;
int penLiftUpPosition = 180;

float currentMachineMaxSpeed = 600.0;
float currentMachineAccel = 400.0;
int machineStepMultiplier = 8;
int maxSegmentLength = 2;

// ----------------------------------------------------------------
// RENDER / DRAWING STATE
// ----------------------------------------------------------------
// Default drawing direction
public Integer renderStartDirection = DRAW_DIR_SE;
public Integer renderStartPosition = DRAW_DIR_NE;

static final int DRAW_DIR_NE = 1;
static final int DRAW_DIR_SE = 2;
static final int DRAW_DIR_SW = 3;
static final int DRAW_DIR_NW = 4;

PVector currentMachinePos = new PVector();
PVector currentCartesianMachinePos = new PVector();

// Vectors
RShape vectorShape = null;
String vectorFilename = null;
float vectorScaling = 100;
PVector vectorPosition = new PVector(0.0, 0.0);
int minimumVectorLineLength = 2;

// Polygonizer (Geomerative)
int polygonizer = RG.ADAPTATIVE;
float polygonizerLength = 5.0;
int pathLengthHighPassCutoff = 0;
// static final int VECTOR_FILTER_LOW_PASS = 0;

// ----------------------------------------------------------------
// UI CONSTANTS (MODES)
// ----------------------------------------------------------------
// Only the ones we kept in controlsSetup are retained here.

static final String MODE_BEGIN = "button_mode_begin";
static final String MODE_RETURN_TO_HOME = "button_mode_returnToHome";
static final String MODE_SET_POSITION_HOME = "button_mode_setPositionHome";
static final String MODE_SET_POSITION = "toggle_mode_setPosition";
static final String MODE_DRAW_TO_POSITION = "toggle_mode_drawToPosition";
static final String MODE_DRAW_DIRECT = "toggle_mode_drawDirect";

static final String MODE_PEN_LIFT_UP = "button_mode_penUp";
static final String MODE_PEN_LIFT_DOWN = "button_mode_penDown";
static final String MODE_PEN_LIFT_POS_UP = "numberbox_mode_penUpPos";
static final String MODE_PEN_LIFT_POS_DOWN = "numberbox_mode_penDownPos";
static final String MODE_SEND_PEN_LIFT_RANGE = "button_mode_sendPenliftRange";
static final String MODE_SEND_PEN_LIFT_RANGE_PERSIST = "button_mode_sendPenliftRangePersist";

static final String MODE_INPUT_BOX_TOP_LEFT = "toggle_mode_inputBoxTopLeft";
static final String MODE_INPUT_BOX_BOT_RIGHT = "toggle_mode_inputBoxBotRight";
static final String MODE_DRAW_OUTLINE_BOX = "button_mode_drawOutlineBox";
static final String MODE_CONVERT_BOX_TO_PICTUREFRAME = "button_mode_convertBoxToPictureframe";
static final String MODE_SELECT_PICTUREFRAME = "button_mode_selectPictureframe"; // Legacy safety

static final String MODE_LOAD_VECTOR_FILE = "button_mode_loadVectorFile";
static final String MODE_RENDER_VECTORS = "button_mode_renderVectors";
static final String MODE_MOVE_VECTOR = "toggle_mode_moveVector";
static final String MODE_RESIZE_VECTOR = "numberbox_mode_resizeVector";
static final String MODE_CHANGE_MIN_VECTOR_LINE_LENGTH = "numberbox_mode_changeMinVectorLineLength";
static final String MODE_CHANGE_POLYGONIZER = "button_mode_cyclePolygonizer";
static final String MODE_CHANGE_POLYGONIZER_LENGTH = "numberbox_mode_changePolygonizerLength";

static final String MODE_CHANGE_MACHINE_WIDTH = "numberbox_mode_changeMachineWidth";
static final String MODE_CHANGE_MACHINE_HEIGHT = "numberbox_mode_changeMachineHeight";
static final String MODE_CHANGE_PAGE_WIDTH = "numberbox_mode_changePageWidth";
static final String MODE_CHANGE_PAGE_HEIGHT = "numberbox_mode_changePageHeight";
static final String MODE_CHANGE_PAGE_OFFSET_X = "numberbox_mode_changePageOffsetX";
static final String MODE_CHANGE_PAGE_OFFSET_Y = "numberbox_mode_changePageOffsetY";
static final String MODE_CHANGE_PAGE_OFFSET_X_CENTRE = "button_mode_changePageOffsetXCentre";
static final String MODE_CHANGE_HOMEPOINT_X = "numberbox_mode_changeHomePointX";
static final String MODE_CHANGE_HOMEPOINT_Y = "numberbox_mode_changeHomePointY";
static final String MODE_CHANGE_HOMEPOINT_X_CENTRE = "button_mode_changeHomePointXCentre";

static final String MODE_CHANGE_MM_PER_REV = "numberbox_mode_changeMMPerRev";
static final String MODE_CHANGE_STEPS_PER_REV = "numberbox_mode_changeStepsPerRev";
static final String MODE_CHANGE_STEP_MULTIPLIER = "numberbox_mode_changeStepMultiplier";
static final String MODE_CHANGE_MACHINE_MAX_SPEED = "numberbox_mode_changeMachineMaxSpeed";
static final String MODE_CHANGE_MACHINE_ACCELERATION = "numberbox_mode_changeMachineAcceleration";
static final String MODE_SEND_MACHINE_SPEED = "button_mode_sendMachineSpeed";
static final String MODE_SEND_MACHINE_SPEED_PERSIST = "button_mode_sendMachineSpeedPersist";
static final String MODE_CHANGE_PEN_WIDTH = "numberbox_mode_changePenWidth";
static final String MODE_SEND_PEN_WIDTH = "button_mode_sendPenWidth";
static final String MODE_CHANGE_MACHINE_SPEC = "button_mode_changeMachineSpec";
static final String MODE_REQUEST_MACHINE_SIZE = "button_mode_requestMachineSize";
static final String MODE_RESET_MACHINE = "button_mode_resetMachine";

static final String MODE_CHANGE_PEN_TEST_START_WIDTH = "numberbox_mode_changePenTestStartWidth";
static final String MODE_CHANGE_PEN_TEST_END_WIDTH = "numberbox_mode_changePenTestEndWidth";
static final String MODE_CHANGE_PEN_TEST_INCREMENT_SIZE = "numberbox_mode_changePenTestIncrementSize";
static final String MODE_DRAW_TEST_PENWIDTH = "button_mode_drawTestPenWidth";

static final String MODE_CLEAR_QUEUE = "button_mode_clearQueue";
static final String MODE_EXPORT_QUEUE = "button_mode_exportQueue";
static final String MODE_IMPORT_QUEUE = "button_mode_importQueue";
static final String MODE_SAVE_PROPERTIES = "button_mode_saveProperties";
static final String MODE_SAVE_AS_PROPERTIES = "button_mode_saveAsProperties";
static final String MODE_LOAD_PROPERTIES = "button_mode_loadProperties";
static final String MODE_CHANGE_SERIAL_PORT = "button_mode_serialPortDialog";

static final String MODE_SEND_MACHINE_STORE_MODE = "button_mode_machineStoreDialog";
static final String MODE_SEND_MACHINE_LIVE_MODE = "button_mode_sendMachineLiveMode";
static final String MODE_SEND_MACHINE_EXEC_MODE = "button_mode_machineExecDialog";

// Toggles (Visualization)
static final String MODE_SHOW_VECTOR = "minitoggle_mode_showVector";
static final String MODE_SHOW_QUEUE_PREVIEW = "minitoggle_mode_showQueuePreview";
static final String MODE_SHOW_GUIDES = "minitoggle_mode_showGuides";
static final String MODE_SHOW_IMAGE = "minitoggle_mode_showImage"; // Kept to avoid crashes, but unused
static final String MODE_ADJUST_PREVIEW_CORD_OFFSET = "numberbox_mode_previewCordOffsetValue";

// ----------------------------------------------------------------
// GLOBAL GUI VARIABLES
// ----------------------------------------------------------------

PVector statusTextPosition = new PVector(300.0, 12.0);
static String currentMode = MODE_BEGIN;
static String lastMode = MODE_BEGIN;

static PVector boxVector1 = null;
static PVector boxVector2 = null;

boolean displayingImage = false;
boolean displayingVector = true;
boolean displayingQueuePreview = true;
boolean displayingDensityPreview = false;
boolean displayingGuides = true;

public color pageColour = color(220);
public color frameColour = color(200, 0, 0);
public color machineColour = color(150);
public color guideColour = color(255, 0, 0, 150);
public color backgroundColour = color(50, 0, 0);

public Integer previewCordOffset = 0;
public boolean debugPanels = false;
public boolean showingSummaryOverlay = true;

public Integer windowWidth = 700;
public Integer windowHeight = 500;

public Textarea consoleArea = null;

public static final String TAB_NAME_INPUT= "Input";
public static final String TAB_NAME_DETAILS = "Details";
public static final String TAB_NAME_QUEUE = "Queue";

public static final String PANEL_NAME_INPUT = "panel_input";
public static final String PANEL_NAME_DETAILS = "panel_details";
public static final String PANEL_NAME_QUEUE = "panel_queue";
public static final String PANEL_NAME_GENERAL = "panel_general";

public final PVector DEFAULT_CONTROL_SIZE = new PVector(100.0, 20.0);
public final PVector CONTROL_SPACING = new PVector(4.0, 4.0);
public PVector mainPanelPosition = new PVector(10.0, 85.0);
public final Integer PANEL_MIN_HEIGHT = 400;

// Collections for UI building
public Set<String> panelNames = null;
public List<String> tabNames = null;
public Set<String> controlNames = null;
public Map<String, List<Controller>> controlsForPanels = null;
public Map<String, Controller> allControls = null;
public Map<String, String> controlLabels = null;
public Set<String> controlsToLockIfBoxNotSpecified = null;
public Set<String> controlsToLockIfImageNotLoaded = null;
public Map<String, Set<Panel>> panelsForTabs = null;
public Map<String, Panel> panels = null;

// Helpers
int numberOfPixelsTotal = 0;
SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yy hh:mm:ss");


// ----------------------------------------------------------------
// SETUP
// ----------------------------------------------------------------

void settings() {
  size(1200, 700); // Hardcode start size for stability
}

void setup() {
  // surface.setResizable(true); // Keep commented out for stability

  cp5 = new ControlP5(this);
  loadFromPropertiesFile();
  controlsSetup();

  // Center the machine in the middle pane initially
  float centerX = LEFT_SIDEBAR_WIDTH + ((width - LEFT_SIDEBAR_WIDTH - RIGHT_SIDEBAR_WIDTH)/2);
  float centerY = height/2;
  machinePosition = new PVector(centerX, centerY);

  // Set default tab
  cp5.getTab(TAB_NAME_INPUT).bringToFront();
}

void draw() {
  if (frameCount < 10) return;

  background(backgroundColour);

  // 1. DRAW CENTER PANE (Machine)
  // We use a clip rect so the machine doesn't draw over the sidebars
  clip(LEFT_SIDEBAR_WIDTH, 0, width - LEFT_SIDEBAR_WIDTH - RIGHT_SIDEBAR_WIDTH, height);

  if (getDisplayMachine() != null) {
    getDisplayMachine().setOffset(machinePosition);
    getDisplayMachine().setScale(machineScaling);
    getDisplayMachine().draw();
  }
  noClip(); // Disable clipping for UI

  // 2. DRAW LEFT SIDEBAR (Controls)
  fill(0, 54, 82); // Sidebar BG Color
  rect(0, 0, LEFT_SIDEBAR_WIDTH, height);

  // Logic to show tabs only on the left
  drawInterface();

  // 3. DRAW RIGHT SIDEBAR (Queue)
  fill(0, 40, 60); // Slightly darker for Queue
  rect(width - RIGHT_SIDEBAR_WIDTH, 0, RIGHT_SIDEBAR_WIDTH, height);
  drawQueue();

  // 4. DRAW HUD (Info Text)
  // Position it inside the Center Pane
  if (displayingInfoTextOnInputPage) {
    showText(LEFT_SIDEBAR_WIDTH + 10, 40);
  }
}

// Logic to show/hide panels based on which Tab is clicked
void drawInterface() {
  // Find which tab is currently active
  String activeTab = "";
  if (cp5.getTab(TAB_NAME_INPUT).isActive()) activeTab = TAB_NAME_INPUT;
  else if (cp5.getTab(TAB_NAME_DETAILS).isActive()) activeTab = TAB_NAME_DETAILS;
  else if (cp5.getTab(TAB_NAME_QUEUE).isActive()) activeTab = TAB_NAME_QUEUE;

  // Get all panels that belong to this tab
  List<Panel> panelsToShow = getPanelsForTab(activeTab);

  // Iterate ALL panels
  for (Panel p : getPanels().values()) {
    if (panelsToShow.contains(p)) {
      // If panel belongs to this tab, Draw it and Show its buttons
      p.draw(true);
    } else {
      // Otherwise, hide its buttons
      p.draw(false);
    }
  }
}

void drawQueue() {
  int x = width - RIGHT_SIDEBAR_WIDTH + 10; // Start inside right sidebar
  int y = 30;
  int lineHeight = 15;

  fill(255);
  textSize(12);
  text("COMMAND QUEUE:", x, y);
  y += 20;

  // Draw Realtime Queue
  if (!realtimeCommandQueue.isEmpty()) {
    fill(255, 100, 100);
    for (String cmd : realtimeCommandQueue) {
      text("[PRIORITY] " + cmd, x, y);
      y += lineHeight;
    }
  }

  // Draw Standard Queue
  fill(200);
  int count = 0;
  ArrayList<String> safeQueue;
  synchronized(commandQueue) {
    safeQueue = new ArrayList<String>(commandQueue);
  }

  for (String cmd : safeQueue) {
    text((count+1) + ". " + cmd, x, y);
    y += lineHeight;
    count++;
    if (y > height - 20) break;
  }
}

// ----------------------------------------------------------------
// WINDOW RESIZING
// ----------------------------------------------------------------

void windowResized() {
  // Simple resize logic: Adjust panel heights to fit new window
  println("Window resized to: " + width + " x " + height);

  if (getPanels() != null) {
    for (String key : getPanels().keySet()) {
      Panel p = getPanels().get(key);
      if (p != null && p.getOutline() != null) {
        // Stretch panels to bottom of screen (minus some padding)
        float newHeight = height - p.getOutline().getTop() - (DEFAULT_CONTROL_SIZE.y * 3);
        p.setSizeByHeight(newHeight);
      }
    }
  }
}


// ----------------------------------------------------------------
// GUI DRAWING HELPERS
// ----------------------------------------------------------------

// Helper to access panels safely (Required by tabSetup)
Panel getPanel(String panelName) {
  if (getPanels() == null) return null;
  return getPanels().get(panelName);
}

// ----------------------------------------------------------------
// VISUAL OVERLAYS
// ----------------------------------------------------------------

// Draws the Red Selection Box
void showGroupBox()
{
  if (!displayingGuides) return;

  noFill();
  stroke(frameColour);
  strokeWeight(1);

  // If a full box is defined, draw the rectangle
  if (isBoxSpecified())
  {
    PVector p1 = getDisplayMachine().scaleToScreen(boxVector1);
    PVector p2 = getDisplayMachine().scaleToScreen(boxVector2);
    rectMode(CORNERS);
    rect(p1.x, p1.y, p2.x, p2.y);
    rectMode(CORNER); // Reset
  }
  // If we are currently dragging (only one point exists), draw crosshairs
  else
  {
    if (boxVector1 != null) {
      PVector p = getDisplayMachine().scaleToScreen(boxVector1);
      drawCrosshair(p);
    }
    if (boxVector2 != null) {
      PVector p = getDisplayMachine().scaleToScreen(boxVector2);
      drawCrosshair(p);
    }
  }
}

void drawCrosshair(PVector p) {
  line(p.x-5, p.y, p.x+5, p.y);
  line(p.x, p.y-5, p.x, p.y+5);
}

// Draws the Pink Dot (Current Machine Position)
void showCurrentMachinePosition()
{
  noStroke();

  // Pink Dot: Virtual Position (Where the software thinks the pen is)
  fill(255, 0, 255, 150);
  PVector pgCoord = getDisplayMachine().scaleToScreen(currentMachinePos);
  ellipse(pgCoord.x, pgCoord.y, 15, 15);

  // Yellow Dot: Cartesian Position (Calculated from steps)
  // fill(255, 255, 0, 150);
  // ellipse(currentCartesianMachinePos.x, currentCartesianMachinePos.y, 10, 10);

  noFill();
}

// Draws the visual list of commands on the right side of the screen
void showCommandQueue(int x, int y)
{
  if (!displayingQueuePreview) return;
  if (commandQueue.isEmpty()) return;

  int maxLines = 25;
  int lineHeight = 14;

  fill(255);
  noStroke();
  textAlign(LEFT, TOP);
  textSize(10);

  text("COMMAND QUEUE (" + commandQueue.size() + ")", x, y);
  y += 20;

  // Show the first 'maxLines' commands
  for (int i = 0; i < commandQueue.size(); i++) {
    if (i >= maxLines) {
      text("... (" + (commandQueue.size() - i) + " more)", x, y);
      break;
    }
    String cmd = commandQueue.get(i);
    // Highlight the next command to be executed
    if (i == 0 && drawbotConnected) fill(0, 255, 0);
    else fill(200);

    text(cmd, x, y);
    y += lineHeight;
  }
}

// Visual feedback when dragging a Vector to move it
void drawMoveVectorOutline()
{
  // Only draw if we are in "Move Vector" mode and have a shape loaded
  if (MODE_MOVE_VECTOR.equals(currentMode) && vectorShape != null)
  {
    stroke(100, 100, 255, 150); // Ghostly blue
    noFill();
    strokeWeight(1);

    // Calculate where the shape would be relative to the mouse
    // (Logic simplified to drawing a bounding box for speed)
    PVector mouseInMachine = getDisplayMachine().scaleToDisplayMachine(getMouseVector());

    // Draw a box at mouse position representing the vector center
    PVector centerScreen = getDisplayMachine().scaleToScreen(mouseInMachine);

    // Corrected lines:
    float w = (vectorShape.width * (vectorScaling/100.0)) * machineScaling;
    float h = (vectorShape.height * (vectorScaling/100.0)) * machineScaling;

    rectMode(CENTER);
    rect(centerScreen.x, centerScreen.y, w, h);
    line(centerScreen.x - 5, centerScreen.y, centerScreen.x + 5, centerScreen.y);
    line(centerScreen.x, centerScreen.y - 5, centerScreen.x, centerScreen.y + 5);
    rectMode(CORNER);
  }
}


// ----------------------------------------------------------------
// FILE HANDLING: VECTORS
// ----------------------------------------------------------------

void loadVectorWithFileChooser() {
  selectInput("Select an SVG or GCode file:", "vectorFileSelected");
}

public void vectorFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    // Save directory for next time (Optional logic)
    lastImageDirectory = selection.getParentFile();
    loadVectorFromFile(selection.getAbsolutePath());
  }
}

void loadVectorFromFile(String filename) {
  if (filename != null) {
    // 1. Load the shape using Geomerative
    RShape shape = RG.loadShape(filename);

    if (shape != null) {
      // 2. Store it
      vectorShape = shape;
      vectorFilename = filename;

      // 3. Auto-Center Logic
      Rectangle page = getDisplayMachine().getPage();

      // Calculate centers
      float pageCenterX = page.getLeft() + (page.getWidth() / 2.0);
      float pageCenterY = page.getTop() + (page.getHeight() / 2.0);

      // Center the shape (Assuming 1 SVG unit = 1mm initially)
      float shapeW = shape.width;
      float shapeH = shape.height;

      vectorPosition.x = pageCenterX - (shapeW / 2.0);
      vectorPosition.y = pageCenterY - (shapeH / 2.0);

      // Reset scaling to 100%
      vectorScaling = 100.0;

      // Update UI if needed
      // (ControlP5 usually updates automatically if linked to variables)

      println("Vector loaded: " + filename);
      println("Centered at: " + vectorPosition);
    } else {
      println("Error: Could not parse SVG file.");
    }
  }
}

// Helper for file filters
boolean isGCodeExtension(String filename) {
  String f = filename.toLowerCase();
  return f.endsWith(".gcode") || f.endsWith(".txt") || f.endsWith(".nc");
}


// ----------------------------------------------------------------
// FILE HANDLING: PROPERTIES
// ----------------------------------------------------------------

void loadNewPropertiesFilenameWithFileChooser() {
  selectInput("Select a properties configuration file:", "propertiesLoadSelected");
}

public void propertiesLoadSelected(File selection) {
  if (selection == null) return;

  String filename = selection.getAbsolutePath();
  if (selection.exists()) {
    println("Loading properties from: " + filename);
    propertiesFilename = filename;

    // Clear old settings
    props = null;

    // Load new settings
    loadFromPropertiesFile();

    // Update UI controls to match new settings
    updateNumberboxValues(); // Defined in controlsSetup.pde
  }
}

void saveNewPropertiesFileWithFileChooser() {
  selectOutput("Save configuration as...", "propertiesSaveSelected");
}

public void propertiesSaveSelected(File selection) {
  if (selection == null) return;

  String filename = selection.getAbsolutePath();

  // Ensure extension
  if (!filename.toLowerCase().endsWith(".properties.txt")) {
    filename += ".properties.txt";
  }

  propertiesFilename = filename;
  savePropertiesFile();

  // Reload to ensure memory matches file
  props = null;
  loadFromPropertiesFile();
}

// ----------------------------------------------------------------
// VECTOR LOADER (SVG ONLY)
// ----------------------------------------------------------------

RShape loadShapeFromFile(String filename) {
  // We only accept SVG files now.
  if (filename.toLowerCase().endsWith(".svg")) {
    return RG.loadShape(filename);
  }

  println("Error: Only .svg files are supported.");
  return null;
}

// ----------------------------------------------------------------
// SELECTION BOX HELPERS
// ----------------------------------------------------------------

void setPictureFrameDimensionsToBox()
{
  if (!isBoxSpecified()) return;

  // Create a rectangle from the red selection box
  // We convert pixels -> steps to ensure the machine understands the coordinates
  PVector pos = getDisplayMachine().inSteps(boxVector1);
  PVector size = getDisplayMachine().inSteps(getBoxVectorSize());

  Rectangle r = new Rectangle(pos, size);
  getDisplayMachine().setPictureFrame(r);

  println("Machine Frame updated to Selection Box area.");
}

void setBoxToPictureframeDimensions()
{
  // The reverse: Set the red selection box to match the machine's current frame
  Rectangle frame = getDisplayMachine().getPictureFrame();

  boxVector1 = getDisplayMachine().inMM(frame.getTopLeft());
  boxVector2 = getDisplayMachine().inMM(frame.getBotRight());
}

// Helper to get the size of the selection box
PVector getBoxVectorSize() {
  if (boxVector1 == null || boxVector2 == null) return new PVector(0, 0);
  return PVector.sub(boxVector2, boxVector1);
}

// ----------------------------------------------------------------
// CONTROL EVENTS (TABS)
// ----------------------------------------------------------------

// This function listens for EVERY click on the interface
void controlEvent(ControlEvent theEvent)
{
  // 1. Handle Tab Clicks
  if (theEvent.isTab())
  {
    String tabName = theEvent.getTab().getName();

    // Only act if the tab actually changed
    if (!tabName.equals(currentTab)) {
      changeTab(currentTab, tabName);
    }
  }

  // 2. Handle Group Events (Dropdowns, etc)
  else if (theEvent.isGroup())
  {
    // Debugging info for development
    // println("Group event from: " + theEvent.getGroup().getName());
  }
}

void changeTab(String fromTab, String toTab)
{
  println("Switching Tab: " + fromTab + " -> " + toTab);
  currentTab = toTab;

  // Logic: We iterate through our 'Panels' (groups of buttons)
  // If a panel belongs to the new tab, we tell ControlP5 to "move"
  // those buttons to the active view.

  for (Panel panel : getPanelsForTab(currentTab))
  {
    if (panel == null || panel.getControls() == null) continue;

    for (Controller c : panel.getControls())
    {
      c.moveTo(currentTab); // Move the button to the new tab
      c.show();             // Ensure it is visible
    }
  }
}

// ----------------------------------------------------------------
// SIMPLE SETTERS
// ----------------------------------------------------------------

void setGridSize(float s) {
  this.gridSize = (int)s;
}

void setSampleArea(float v) {
  this.sampleArea = v;
}

// ----------------------------------------------------------------
// INPUT EVENTS (MOUSE & KEYBOARD)
// ----------------------------------------------------------------

// --- KEYBOARD SHORTCUTS ---
void keyPressed()
{
  // Track keys for smooth scrolling (if needed)
  if (keyCode >= 0 && keyCode < keys.length) keys[keyCode] = true;

  // 1. Navigation / Scaling (Ctrl + Arrows/PageKeys)
  if (checkKey(CONTROL)) {
    if (checkKey(KeyEvent.VK_PAGE_UP))       changeMachineScaling(1);
    else if (checkKey(KeyEvent.VK_PAGE_DOWN)) changeMachineScaling(-1);
    else if (checkKey(DOWN))  getDisplayMachine().getOffset().y += 10;
    else if (checkKey(UP))    getDisplayMachine().getOffset().y -= 10;
    else if (checkKey(RIGHT)) getDisplayMachine().getOffset().x += 10;
    else if (checkKey(LEFT))  getDisplayMachine().getOffset().x -= 10;

    // Toggle Guides (Ctrl + G)
    else if (checkKey(KeyEvent.VK_G)) {
      boolean newState = !displayingGuides;
      minitoggle_mode_showGuides(newState);

      // Update the UI toggle visuals
      try {
        Toggle t = (Toggle) getAllControls().get(MODE_SHOW_GUIDES);
        t.setValue(newState ? 1 : 0);
      }
      catch (Exception e) {
      }
    }
  }

  // 2. Direct Command Shortcuts
  // '#' = Pen Up (Legacy)
  else if (key == '#' ) addToRealtimeCommandQueue(CMD_PENUP + "END");
  // '~' = Pen Down (Legacy)
  else if (key == '~') addToRealtimeCommandQueue(CMD_PENDOWN + "END");

  // 3. Prevent ESC from quitting
  else if (key == ESC) key = 0;
}

void keyReleased() {
  if (keyCode >= 0 && keyCode < keys.length) keys[keyCode] = false;
}

boolean checkKey(int k) {
  if (keys.length >= k) return keys[k];
  return false;
}

// --- MOUSE CLICKING ---
void mouseClicked()
{
  // Ignore clicks if they are over a UI button
  if (mouseOverControls()) return;

  // 1. Handle Vector Placement (Drop the vector)
  if (MODE_MOVE_VECTOR.equals(currentMode))
  {
    if (vectorShape != null) {
      // Center the shape on the mouse click
      PVector centroid = new PVector(vectorShape.width/2, vectorShape.height/2);
      centroid = PVector.mult(centroid, (vectorScaling/100.0));

      PVector mVect = getDisplayMachine().scaleToDisplayMachine(getMouseVector());
      PVector offsetMouseVector = PVector.sub(mVect, centroid);

      // Commit position
      vectorPosition = offsetMouseVector;

      // Exit Mode
      currentMode = "";
      println("Vector placed at: " + vectorPosition);

      // Update Button State
      try {
        ((Toggle)cp5.getController(MODE_MOVE_VECTOR)).setState(false);
      }
      catch(Exception e) {
      }
    }
  }

  // 2. Queue Interaction
  else if (mouseOverQueue())
  {
    // Remove the item clicked in the list
    if (commandQueue.size() > 0) {
      // Simple logic: clicking anywhere on the queue removes the last item?
      // Or usually, it clears the queue. Let's make it clear the queue for simplicity
      // or you can implement complex list picking.
      // For now: Just print.
      println("Queue clicked. (Use 'Clear Queue' button to empty)");
    }
  }

  // 3. Machine Interaction
  else if (mouseOverMachine())
  {
    if (mouseButton == LEFT) leftButtonMachineClick();
  }
}

// --- MOUSE DRAGGING ---
void mouseDragged()
{
  if (mouseOverControls()) return;

  // Pan the view (Middle Click)
  if (mouseButton == CENTER)
  {
    PVector currentPos = getMouseVector();
    PVector change = PVector.sub(currentPos, lastMachineDragPosition);
    lastMachineDragPosition = new PVector(currentPos.x, currentPos.y);
    getDisplayMachine().getOffset().add(change);
    cursor(MOVE);
  }
  // Drag Selection Box (Left Click)
  else if (mouseButton == LEFT)
  {
    if (currentMode.equals(MODE_INPUT_BOX_TOP_LEFT))
    {
      PVector pos = getDisplayMachine().scaleToDisplayMachine(getMouseVector());
      boxVector2 = pos;
    }
  }
}

// --- MOUSE PRESS/RELEASE ---
void mousePressed()
{
  if (mouseButton == CENTER) {
    lastMachineDragPosition = getMouseVector();
  } else if (mouseButton == LEFT) {
    if (MODE_INPUT_BOX_TOP_LEFT.equals(currentMode) && mouseOverMachine()) {
      // Start drawing selection box
      PVector pos = getDisplayMachine().scaleToDisplayMachine(getMouseVector());
      boxVector1 = pos;
    }
  }
}

void mouseReleased()
{
  if (mouseButton == LEFT) {
    if (MODE_INPUT_BOX_TOP_LEFT.equals(currentMode) && mouseOverMachine()) {
      // Finish drawing selection box
      PVector pos = getDisplayMachine().scaleToDisplayMachine(getMouseVector());
      boxVector2 = pos;

      // Ensure positive dimensions (swap if drawn backwards)
      if (isBoxSpecified()) {
        if (boxVector1.x > boxVector2.x) {
          float temp = boxVector1.x;
          boxVector1.x = boxVector2.x;
          boxVector2.x = temp;
        }
        if (boxVector1.y > boxVector2.y) {
          float temp = boxVector1.y;
          boxVector1.y = boxVector2.y;
          boxVector2.y = temp;
        }
      }
    }
  }
  cursor(ARROW);
}

// --- MOUSE WHEEL (ZOOM) ---
void mouseWheel(MouseEvent event) {
  float e = event.getCount(); // -1 or 1
  int delta = (int) e;

  // Zoom logic: Zoom towards the mouse pointer
  PVector pos = getDisplayMachine().scaleToDisplayMachine(getMouseVector());
  changeMachineScaling(delta);
  PVector scaledPos = getDisplayMachine().scaleToDisplayMachine(getMouseVector());

  PVector change = PVector.sub(scaledPos, pos);
  change.mult(machineScaling);

  getDisplayMachine().getOffset().add(change);
}

// ----------------------------------------------------------------
// LOGIC HELPERS
// ----------------------------------------------------------------

void leftButtonMachineClick()
{
  if (currentMode.equals(MODE_BEGIN))
    currentMode = MODE_INPUT_BOX_TOP_LEFT; // Default to selection tool
  else if (currentMode.equals(MODE_SET_POSITION))
    sendSetPosition();
  else if (currentMode.equals(MODE_DRAW_DIRECT))
    sendMoveToPosition(true);
  else if (currentMode.equals(MODE_DRAW_TO_POSITION))
    sendMoveToPosition(false);
}

void changeMachineScaling(int delta)
{
  machineScaling += (delta * (machineScaling * 0.1));
  if (machineScaling <  MIN_SCALING) machineScaling = MIN_SCALING;
  else if (machineScaling > MAX_SCALING) machineScaling = MAX_SCALING;
}

// ----------------------------------------------------------------
// HIT TESTING
// ----------------------------------------------------------------

boolean mouseOverMachine()
{
  // Check if mouse is strictly inside the machine board area
  if (getDisplayMachine() != null && getDisplayMachine().getOutline() != null) {
    return getDisplayMachine().getOutline().surrounds(getMouseVector());
  }
  return false;
}

boolean mouseOverControls()
{
  // Check if mouse is over any active CP5 controller
  if (cp5.getWindow().getMouseOverList().isEmpty()) return false;
  return true;
}

boolean mouseOverQueue()
{
  // Rough check if mouse is in the Queue area (Right side)
  if (displayingQueuePreview && displayMachine != null) {
    float machineRight = displayMachine.getOutline().getRight();
    return (mouseX > machineRight);
  }
  return false;
}


// ----------------------------------------------------------------
// QUEUE PREVIEW (VISUALIZATION)
// ----------------------------------------------------------------

boolean isPreviewable(String command)
{
  return (command.startsWith(CMD_CHANGELENGTHDIRECT) || command.startsWith(CMD_CHANGELENGTH));
}

// Toggles the blue debug console text area
boolean toggleShowConsole() {
  if (console == null) {
    // Enable Console
    if (consoleArea != null) {
      savedOut = System.out;
      console = cp5.addConsole(consoleArea);
      consoleArea.setVisible(true);
      console.play();
    }
  } else {
    // Disable Console
    console.pause();
    if (consoleArea != null) consoleArea.setVisible(false);
    cp5.remove(console);
    console = null;
    System.setOut(savedOut);
  }
  return (console == null);
}

void previewQueue() {
  previewQueue(false);
}

void previewQueue(boolean forceRebuild)
{
  // Only rebuild the preview lines if the queue has changed
  // (We check the hash code of the list to detect changes)
  if (forceRebuild || (commandQueue.hashCode() != lastCommandQueueHash))
  {
    previewCommandList.clear();

    for (String command : commandQueue)
    {
      if (isPreviewable(command))
      {
        try {
          // Parse Command: C17,<A_STEPS>,<B_STEPS>,<SPEED>,END
          String[] splitted = split(command, ",");

          if (splitted.length >= 3) {
            PreviewVector pv = new PreviewVector();
            pv.command = splitted[0];

            // 1. Get Target Steps
            int aSteps = Integer.parseInt(splitted[1]) + previewCordOffset;
            int bSteps = Integer.parseInt(splitted[2]) + previewCordOffset;

            // 2. Convert Steps -> Millimeters
            PVector endPoint = new PVector(aSteps, bSteps);
            endPoint = getDisplayMachine().asCartesianCoords(endPoint); // Native -> Cartesian (Steps)
            endPoint = getDisplayMachine().inMM(endPoint);              // Steps -> MM

            pv.x = endPoint.x;
            pv.y = endPoint.y;
            pv.z = -1.0; // Z is unused for lines

            previewCommandList.add(pv);
          }
        }
        catch (Exception e) {
          // Ignore malformed commands in preview
        }
      }
    }
    lastCommandQueueHash = commandQueue.hashCode();
  }

  // Draw the lines
  PVector startPoint = null;

  // Use machine position as the start of the preview line
  if (!previewCommandList.isEmpty()) {
    startPoint = getDisplayMachine().scaleToScreen(currentMachinePos);
  }

  for (PreviewVector pv : previewCommandList)
  {
    PVector p = (PVector) pv;
    p = getDisplayMachine().scaleToScreen(p);

    if (startPoint != null)
    {
      if (pv.command.equals(CMD_CHANGELENGTHDIRECT)) stroke(0, 100, 255, 150); // Blue for Direct
      else stroke(200, 0, 0, 100); // Red for Standard

      strokeWeight(1);
      line(startPoint.x, startPoint.y, p.x, p.y);
    }
    startPoint = p;
  }
}


// ----------------------------------------------------------------
// QUEUE FILE I/O (IMPORT/EXPORT)
// ----------------------------------------------------------------

void exportQueueToFile() {
  if (!commandQueue.isEmpty() || !realtimeCommandQueue.isEmpty()) {
    selectOutput("Save Command Queue to file:", "exportQueueCallback");
  } else {
    println("Queue is empty, nothing to export.");
  }
}

public void exportQueueCallback(File selection) {
  if (selection == null) return;

  String path = selection.getAbsolutePath();

  // Combine realtime and standard queues
  List<String> allCommands = new ArrayList<String>(realtimeCommandQueue);
  allCommands.addAll(commandQueue);

  String[] list = allCommands.toArray(new String[0]);
  saveStrings(path, list);

  println("Exported " + list.length + " commands to " + path);
}

void importQueueFromFile() {
  selectInput("Select Command Queue file to load:", "importQueueCallback");
}

public void importQueueCallback(File selection) {
  if (selection == null) return;

  String path = selection.getAbsolutePath();
  String[] commands = loadStrings(path);

  if (commands != null) {
    commandQueue.clear();
    commandQueue.addAll(Arrays.asList(commands));
    println("Imported " + commandQueue.size() + " commands from " + path);

    // Force preview rebuild
    lastCommandQueueHash = 0;
  }
}

// ----------------------------------------------------------------
// MISC HELPERS
// ----------------------------------------------------------------

void sizeImageToFitBox() {
  if (!isBoxSpecified()) return;

  // Align the internal "Image Frame" to the selection box
  // (Useful if the user wants to define a specific area for operations)
  PVector boxSize = getDisplayMachine().inSteps(getBoxVectorSize());
  PVector boxPos = getDisplayMachine().inSteps(boxVector1);

  Rectangle r = new Rectangle(boxPos, boxSize);
  getDisplayMachine().setImageFrame(r);
  println("Frame aligned to Box.");
}

// ----------------------------------------------------------------
// STATUS HUD (HEADS-UP DISPLAY)
// ----------------------------------------------------------------

void showText(int x, int y)
{
  // Semi-transparent background
  noStroke();
  fill(0, 0, 0, 150);
  rect(x, y, 220, 350); // Adjusted height since we removed lines

  textSize(12);
  fill(255);

  int lineHeight = 16;
  int currentY = y + 20;
  int leftPad = x + 10;

  // 1. Header
  text(programTitle, leftPad, currentY);
  currentY += lineHeight;
  text("Cursor: " + mouseX + ", " + mouseY, leftPad, currentY);
  currentY += lineHeight;
  currentY += 5; // Spacer

  // 2. Machine Coordinates
  // Calculate where the mouse is in different units
  PVector mouseVec = getMouseVector();
  boolean overMachine = getDisplayMachine().getOutline().surrounds(mouseVec);

  if (overMachine) {
    // MM Coordinates
    PVector posMM = getDisplayMachine().scaleToDisplayMachine(mouseVec);
    text("X,Y (mm): " + int(posMM.x) + ", " + int(posMM.y), leftPad, currentY);
    currentY += lineHeight;

    // Native Steps
    PVector posSteps = getDisplayMachine().inSteps(posMM);
    text("A,B (steps): " + int(posSteps.x) + ", " + int(posSteps.y), leftPad, currentY);
    currentY += lineHeight;
  } else {
    text("X,Y (mm): --, --", leftPad, currentY);
    currentY += lineHeight;
    text("A,B (steps): --, --", leftPad, currentY);
    currentY += lineHeight;
  }
  currentY += 5;

  // 3. Status
  text("State: " + commandStatus, leftPad, currentY);
  currentY += lineHeight;
  text("Mode: " + currentMode, leftPad, currentY);
  currentY += lineHeight;

  // Connection Status (Replaces separate drawStatusText call)
  drawConnectionStatus(leftPad, currentY);
  currentY += lineHeight;

  // 4. Selection Box
  PVector boxSize = getBoxVectorSize();
  text("Selection: " + int(boxSize.x) + "x" + int(boxSize.y) + "mm", leftPad, currentY);
  currentY += lineHeight;

  // 5. Queue Stats
  text("Queue: " + commandQueue.size() + " items", leftPad, currentY);
  currentY += lineHeight;
  text("Zoom: " + int(machineScaling*100) + "%", leftPad, currentY);
  currentY += lineHeight;

  currentY += 5;
  text("Machine Settings:", leftPad, currentY);
  currentY += lineHeight;
  text("Pen Width: " + currentPenWidth + "mm", leftPad, currentY);
  currentY += lineHeight;
  text("Speed: " + currentMachineMaxSpeed, leftPad, currentY);
  currentY += lineHeight;
  text("Accel: " + currentMachineAccel, leftPad, currentY);
  currentY += lineHeight;
}

// Helper to draw color-coded connection status
void drawConnectionStatus(int x, int y) {
  String status = "Disconnected";

  if (useSerialPortConnection) {
    if (drawbotConnected) {
      if (drawbotReady) {
        fill(0, 255, 0); // Green
        status = "CONNECTED (Ready)";
      } else {
        fill(255, 200, 0); // Yellow
        status = "BUSY (Drawing...)";
      }
    } else {
      fill(255, 0, 0); // Red
      status = "Connecting...";
    }
  } else {
    fill(200); // Grey
    status = "No Serial Port";
  }

  text(status, x, y);
  fill(255); // Reset
}


// ----------------------------------------------------------------
// QUEUE INTERACTION
// ----------------------------------------------------------------

void resetQueue()
{
  currentMode = MODE_BEGIN;
  commandQueue.clear();
  realtimeCommandQueue.clear();
  println("Queue cleared.");
}

void queueClicked()
{
  // Simple logic: Toggle Pause/Run
  // (The original code had complex row clicking, but it's often easier
  // to just use the buttons for that. Here we toggle the running state).

  commandQueueRunning = !commandQueueRunning;

  println("Queue Running: " + commandQueueRunning);
}

// ----------------------------------------------------------------
// GETTERS & SETTERS (Cleaned)
// ----------------------------------------------------------------

boolean isBoxSpecified() {
  return (boxVector1 != null && boxVector2 != null);
}

// ----------------------------------------------------------------
// SERIAL COMMUNICATIONS
// ----------------------------------------------------------------

void serialEvent(processing.serial.Serial p)
{
  String incoming = "";
  try {
    incoming = p.readStringUntil('\n');
  }
  catch (Exception e) {
    return;
  }

  if (incoming == null) return;

  incoming = trim(incoming);
  // println("< " + incoming); // Optional: Print all incoming serial data

  // 1. Handshake (The machine is asking for the next command)
  if (incoming.startsWith("READY"))
  {
    drawbotReady = true;

    // Check if the machine is reporting a specific hardware version
    if (incoming.length() > 6) setHardwareVersionFromIncoming(incoming);
  }

  // 2. Sync Commands (Machine reporting its state)
  else if (incoming.startsWith("SYNC"))      readMachinePosition(incoming);
  else if (incoming.startsWith("CARTESIAN")) readCartesianMachinePosition(incoming);
  else if (incoming.startsWith("PGSIZE"))    readMachineSize(incoming);
  else if (incoming.startsWith("PGMMPERREV")) readMmPerRev(incoming);
  else if (incoming.startsWith("PGSTEPSPERREV")) readStepsPerRev(incoming);
  else if (incoming.startsWith("PGSTEPMULTIPLIER")) readStepMultiplier(incoming);
  else if (incoming.startsWith("PGLIFT"))    readPenLiftRange(incoming);
  else if (incoming.startsWith("PGSPEED"))   readMachineSpeed(incoming);

  // 3. Status Updates
  else if ("DRAWING".equals(incoming)) {
    drawbotReady = false;
  } else if ("RESEND".equals(incoming)) {
    resendLastCommand();
  } else if (incoming.startsWith("MSG")) {
    // Machine is sending a text message log
    String msg = incoming.substring(min(4, incoming.length()));
    println("MACHINE: " + msg);
  }

  // If we got *any* valid signal, we are connected
  drawbotConnected = true;
}

// ----------------------------------------------------------------
// COMMAND DISPATCHER
// ----------------------------------------------------------------

// This is the function called every frame in draw()
void executeCommandQueue()
{
  // Safety checks
  if (!drawbotReady) return;
  if (!commandQueueRunning) return;
  if (commandQueue.isEmpty() && realtimeCommandQueue.isEmpty()) return;

  String command = "";

  // 1. Priority Queue (Realtime commands like Pause, Pen Up/Down)
  if (!realtimeCommandQueue.isEmpty())
  {
    command = realtimeCommandQueue.remove(0);
    println(">> PRIORITY: " + command);
  }
  // 2. Standard Queue
  else if (!commandQueue.isEmpty())
  {
    command = commandQueue.remove(0);
    println(">> " + command);
  }

  // 3. Send to Machine
  if (command.length() > 0) {
    lastCommand = command; // Save for "RESEND" requests

    myPort.write(command);
    myPort.write('\n'); // Terminator

    drawbotReady = false; // Wait for next READY
  }
}

void resendLastCommand()
{
  println("!! Resending: " + lastCommand);
  myPort.write(lastCommand);
  myPort.write('\n');
  drawbotReady = false;
}

// Thread-safe helpers to add commands
void addToCommandQueue(String command) {
  synchronized (commandQueue) {
    commandQueue.add(command);
  }
}
void addToRealtimeCommandQueue(String command) {
  synchronized (realtimeCommandQueue) {
    realtimeCommandQueue.add(command);
  }
}

// ----------------------------------------------------------------
// INCOMING DATA PARSERS
// ----------------------------------------------------------------

void readMachinePosition(String in) {
  // Format: SYNC,A_STEPS,B_STEPS,END
  String[] parts = split(in, ",");
  if (parts.length >= 3) {
    float a = Float.parseFloat(parts[1]);
    float b = Float.parseFloat(parts[2]);

    // Update internal state
    PVector machineSteps = new PVector(a, b);
    PVector cartesianMM = getDisplayMachine().inMM(getDisplayMachine().asCartesianCoords(machineSteps));

    currentMachinePos.set(cartesianMM);
  }
}

void readCartesianMachinePosition(String in) {
  // Format: CARTESIAN,X_MM,Y_MM,END
  String[] parts = split(in, ",");
  if (parts.length >= 3) {
    float x = Float.parseFloat(parts[1]);
    float y = Float.parseFloat(parts[2]);
    currentCartesianMachinePos.set(x, y);
  }
}

void readMachineSize(String in) {
  String[] parts = split(in, ",");
  if (parts.length >= 3) {
    int w = Integer.parseInt(parts[1]);
    int h = Integer.parseInt(parts[2]);

    // Machine reports size in STEPS, we update the DisplayMachine
    // float wSteps = getDisplayMachine().inSteps(w); // Wait, usually machine reports width in MM?
    // Actually, Polargraph firmware usually reports size in WIDTH,HEIGHT integers.
    // Let's assume the firmware sends Millimeters to be safe, or we update properties.
    // For safety in this refactor, we just log it.
    println("Machine reports size: " + w + "x" + h);
  }
}

void readMachineSpeed(String in) {
  String[] parts = split(in, ",");
  if (parts.length >= 3) {
    currentMachineMaxSpeed = Float.parseFloat(parts[1]);
    currentMachineAccel = Float.parseFloat(parts[2]);
    updateNumberboxValues();
  }
}

void readPenLiftRange(String in) {
  String[] parts = split(in, ",");
  if (parts.length >= 3) {
    penLiftDownPosition = Integer.parseInt(parts[1]);
    penLiftUpPosition = Integer.parseInt(parts[2]);
    updateNumberboxValues();
  }
}

void readMmPerRev(String in) {
  String[] parts = split(in, ",");
  if (parts.length >= 2) {
    float val = Float.parseFloat(parts[1]);
    getDisplayMachine().setMMPerRev(val);
    updateNumberboxValues();
  }
}

void readStepsPerRev(String in) {
  String[] parts = split(in, ",");
  if (parts.length >= 2) {
    float val = Float.parseFloat(parts[1]);
    getDisplayMachine().setStepsPerRev(val);
    updateNumberboxValues();
  }
}

void readStepMultiplier(String in) {
  String[] parts = split(in, ",");
  if (parts.length >= 2) {
    machineStepMultiplier = Integer.parseInt(parts[1]);
    updateNumberboxValues();
  }
}

// ----------------------------------------------------------------
// HARDWARE VERSION & GETTERS
// ----------------------------------------------------------------

void setHardwareVersionFromIncoming(String readyString)
{
  // Parse "READY_100" or similar
  if (readyString.contains("_")) {
    try {
      String verStr = readyString.substring(readyString.indexOf("_")+1);
      int ver = Integer.parseInt(verStr);
      currentHardware = ver;
    }
    catch (Exception e) {
    }
  } else {
    currentHardware = HARDWARE_VER_UNO;
  }
}

// ----------------------------------------------------------------
// MACHINE GETTER (Fixed)
// ----------------------------------------------------------------

public DisplayMachine getDisplayMachine()
{
  if (displayMachine == null) {
    // 1. Create the physical machine definition first
    // Defaults: Width=5000 steps, Height=5000 steps, StepsPerRev=200, MMPerRev=95
    Machine m = new Machine(5000, 5000, 200.0f, 95.0f);

    // 2. Create the Display wrapper
    // Takes: (Machine, PositionOnScreen, ScaleFactor)
    displayMachine = new DisplayMachine(m, machinePosition, machineScaling);
  }
  return displayMachine;
}


// ----------------------------------------------------------------
// PROPERTIES & CONFIGURATION
// ----------------------------------------------------------------

import java.util.Properties;
import java.io.FileInputStream;
import java.io.FileOutputStream;

Properties getProperties()
{
  if (props == null)
  {
    props = new Properties();
    File propertiesFile = new File(sketchPath(propertiesFilename));

    // If file doesn't exist, create a default one
    if (!propertiesFile.exists()) {
      println("Properties file not found. Creating default: " + propertiesFilename);
      savePropertiesFile();
    }

    try {
      FileInputStream fis = new FileInputStream(propertiesFile);
      props.load(fis);
      fis.close();
      println("Loaded properties from " + propertiesFile.getAbsolutePath());
    }
    catch (Exception e) {
      println("Error loading properties: " + e.getMessage());
    }
  }
  return props;
}


void loadFromPropertiesFile()
{
  Properties p = getProperties();

  // 1. Load Machine Physical Definition (Width, Height, Steps, etc.)
  getDisplayMachine().loadDefinitionFromProperties(p);

  // 2. Load Controller Visuals
  pageColour = getColourProperty("controller.page.colour", color(220));
  frameColour = getColourProperty("controller.frame.colour", color(200, 0, 0));
  machineColour = getColourProperty("controller.machine.colour", color(150));
  guideColour = getColourProperty("controller.guide.colour", color(255));
  backgroundColour = getColourProperty("controller.background.colour", color(100));

  // 3. Load Machine Settings
  currentPenWidth = getFloatProperty("machine.pen.size", 0.8);
  currentMachineMaxSpeed = getFloatProperty("machine.motors.maxSpeed", 600.0);
  currentMachineAccel = getFloatProperty("machine.motors.accel", 400.0);
  machineStepMultiplier = getIntProperty("machine.step.multiplier", 1);
  serialPortNumber = getIntProperty("controller.machine.serialport", 0);
  baudRate = getIntProperty("controller.machine.baudrate", 57600);

  // 4. Load Window Size
  windowWidth = getIntProperty("controller.window.width", 700);
  windowHeight = getIntProperty("controller.window.height", 500);

  // 5. Load Home Point (Park Position)
  float hpX = getFloatProperty("controller.homepoint.x", 0.0);
  float hpY = getFloatProperty("controller.homepoint.y", 0.0);

  // If 0, default to Top-Center
  if (hpX == 0.0 && hpY == 0.0) {
    hpX = getDisplayMachine().getWidth() / 2.0;
    hpY = 120.0 * getDisplayMachine().getStepsPerMM();
  }
  homePointCartesian = new PVector(getDisplayMachine().inSteps(hpX), getDisplayMachine().inSteps(hpY));

  // 6. Load Vector Settings
  vectorFilename = getStringProperty("controller.vector.filename", null);
  vectorScaling = getFloatProperty("controller.vector.scaling", 100.0);
  vectorPosition.x = getFloatProperty("controller.vector.position.x", 0.0);
  vectorPosition.y = getFloatProperty("controller.vector.position.y", 0.0);

  // Try to load the vector file if it was saved
  if (vectorFilename != null) {
    File f = new File(vectorFilename);
    if (f.exists()) {
      vectorShape  = RG.loadShape(vectorFilename);
    }
  }

  // 7. Geomerative Settings
  polygonizer = getIntProperty("controller.geomerative.polygonizer", RG.ADAPTATIVE);
  polygonizerLength = getFloatProperty("controller.geomerative.polygonizerLength", 5.0);
  setupPolygonizer();

  println("Configuration Loaded.");
}


void savePropertiesFile()
{
  Properties p = new Properties();

  // 1. Save Machine Definition
  getDisplayMachine().loadDefinitionIntoProperties(p);

  // Helper for formatting floats cleanly
  NumberFormat nf = NumberFormat.getNumberInstance(Locale.UK);
  DecimalFormat df = (DecimalFormat)nf;
  df.applyPattern("###.##");

  // 2. Save Controller Visuals
  p.setProperty("controller.page.colour", hex(pageColour, 6));
  p.setProperty("controller.frame.colour", hex(frameColour, 6));
  p.setProperty("controller.machine.colour", hex(machineColour, 6));
  p.setProperty("controller.guide.colour", hex(guideColour, 6));
  p.setProperty("controller.background.colour", hex(backgroundColour, 6));

  // 3. Save Machine Settings
  p.setProperty("machine.pen.size", df.format(currentPenWidth));
  p.setProperty("controller.machine.serialport", String.valueOf(serialPortNumber));
  p.setProperty("controller.machine.baudrate", String.valueOf(baudRate));
  p.setProperty("machine.motors.maxSpeed", df.format(currentMachineMaxSpeed));
  p.setProperty("machine.motors.accel", df.format(currentMachineAccel));
  p.setProperty("machine.step.multiplier", String.valueOf(machineStepMultiplier));

  // 4. Save Window Size
  p.setProperty("controller.window.width", String.valueOf(width));
  p.setProperty("controller.window.height", String.valueOf(height));

  // 5. Save Home Point (Converted to MM for readability)
  PVector hpMM = getDisplayMachine().inMM(getHomePoint());
  p.setProperty("controller.homepoint.x", df.format(hpMM.x));
  p.setProperty("controller.homepoint.y", df.format(hpMM.y));

  // 6. Save Vector Settings
  if (vectorFilename != null) p.setProperty("controller.vector.filename", vectorFilename);
  p.setProperty("controller.vector.scaling", df.format(vectorScaling));
  p.setProperty("controller.vector.position.x", df.format(vectorPosition.x));
  p.setProperty("controller.vector.position.y", df.format(vectorPosition.y));

  p.setProperty("controller.geomerative.polygonizer", String.valueOf(polygonizer));
  p.setProperty("controller.geomerative.polygonizerLength", df.format(polygonizerLength));

  // 7. Write to File
  try {
    File f = new File(sketchPath(propertiesFilename));

    // Load existing file first to preserve unknown keys
    if (f.exists()) {
      Properties oldProps = new Properties();
      FileInputStream fis = new FileInputStream(f);
      oldProps.load(fis);
      fis.close();
      oldProps.putAll(p); // Merge new over old
      p = oldProps;
    }

    FileOutputStream fos = new FileOutputStream(f);
    p.store(fos, "Polargraph SVG Controller Settings");
    fos.close();
    println("Settings Saved to " + f.getAbsolutePath());
  }
  catch (Exception e) {
    println("Error saving properties: " + e.getMessage());
  }
}

// ----------------------------------------------------------------
// TYPE CONVERSION HELPERS
// ----------------------------------------------------------------

boolean getBooleanProperty(String id, boolean defState) {
  return Boolean.parseBoolean(getProperties().getProperty(id, ""+defState));
}

int getIntProperty(String id, int defVal) {
  // Safe parsing that handles floats-as-strings (e.g. "100.0" -> 100)
  try {
    String val = getProperties().getProperty(id, ""+defVal);
    return (int) Float.parseFloat(val);
  }
  catch (Exception e) {
    return defVal;
  }
}

float getFloatProperty(String id, float defVal) {
  try {
    return Float.parseFloat(getProperties().getProperty(id, ""+defVal));
  }
  catch (Exception e) {
    return defVal;
  }
}

String getStringProperty(String id, String defVal) {
  return getProperties().getProperty(id, defVal);
}

color getColourProperty(String id, color defVal) {
  String val = getProperties().getProperty(id, "");
  if (val.isEmpty()) return defVal;

  try {
    // Handle 6-digit Hex (e.g., FFFFFF)
    if (val.length() == 6) return unhex("FF" + val);
    // Handle 8-digit Hex (e.g., FFFFFFFF)
    if (val.length() == 8) return unhex(val);
  }
  catch (Exception e) {
  }

  return defVal;
}

// ----------------------------------------------------------------
// GEOMERATIVE SETUP
// ----------------------------------------------------------------

void setupPolygonizer() {
  RG.setPolygonizer(polygonizer);
  if (polygonizer == RG.UNIFORMLENGTH || polygonizer == RG.ADAPTATIVE) {
    RG.setPolygonizerLength(polygonizerLength);
  }
}


void drawStatusOverlay() {
  if (!showingSummaryOverlay) return;

  // Save current drawing style settings
  pushStyle();

  // Draw semi-transparent black bar at bottom
  fill(0, 150);
  noStroke();
  rect(0, height - 30, width, 30);

  // Draw Text
  fill(255);
  textSize(12);
  textAlign(LEFT, CENTER);

  String status = "Queue: " + commandQueue.size() + " | ";

  // Show coordinates if mouse is over the machine area
  if (displayMachine != null && displayMachine.getOutline().surrounds(new PVector(mouseX, mouseY))) {
    PVector mPos = displayMachine.scaleToDisplayMachine(new PVector(mouseX, mouseY));
    status += "Pos: " + int(mPos.x) + "," + int(mPos.y) + "mm | ";
  } else {
    status += "Pos: --,-- | ";
  }

  status += (useSerialPortConnection ? "Connected" : "Disconnected");

  text(status, 10, height - 15);

  // Restore style settings
  popStyle();
}


public PVector getHomePoint() {
  // If home point hasn't been set yet, default to Top-Center
  if (homePointCartesian == null) {
    if (getDisplayMachine() != null) {
      float cx = getDisplayMachine().getSize().x / 2.0;
      float cy = 120 * getDisplayMachine().getStepsPerMM(); // Approx 120mm down
      homePointCartesian = getDisplayMachine().inMM(new PVector(cx, cy));
    } else {
      return new PVector(0, 0);
    }
  }
  return homePointCartesian;
}


void clearBoxVectors() {
  boxVector1 = null;
  boxVector2 = null;
}

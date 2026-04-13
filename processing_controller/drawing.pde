/**
  Drawing Logic
  Handles Command Generation and Vector Processing.
  Refactored for SVG-Only Polargraph Controller.
*/

// ----------------------------------------------------------------
// COMMAND PROTOCOL DEFINITIONS
// ----------------------------------------------------------------
static final String CMD_CHANGELENGTH = "C01,";
static final String CMD_CHANGEPENWIDTH = "C02,";
static final String CMD_CHANGEMOTORSPEED = "C03,";
static final String CMD_CHANGEMOTORACCEL = "C04,";
static final String CMD_SETPOSITION = "C09,";
static final String CMD_TESTPATTERN = "C10,";
static final String CMD_PENDOWN = "C13,";
static final String CMD_PENUP = "C14,";
static final String CMD_CHANGELENGTHDIRECT = "C17,"; // Primary Move Command
static final String CMD_CHANGEMACHINESIZE = "C24,";
static final String CMD_CHANGEMACHINENAME = "C25,";
static final String CMD_REQUESTMACHINESIZE = "C26,";
static final String CMD_RESETMACHINE = "C27,";
static final String CMD_DRAWDIRECTIONTEST = "C28,";
static final String CMD_CHANGEMACHINEMMPERREV = "C29,";
static final String CMD_CHANGEMACHINESTEPSPERREV = "C30,";
static final String CMD_SETMOTORSPEED = "C31,";
static final String CMD_SETMOTORACCEL = "C32,";
static final String CMD_MACHINE_MODE_LIVE = "C35,";
static final String CMD_SETMACHINESTEPMULTIPLIER = "C37,";
static final String CMD_SETPENLIFTRANGE = "C45,";
static final String CMD_TESTPENWIDTH = "C48,"; // Added missing constant
static final String CMD_ACTIVATE_MACHINE_BUTTON = "C49,";
static final String CMD_DEACTIVATE_MACHINE_BUTTON = "C50,";

// Vector Sorting Algorithms
static final int PATH_SORT_NONE = 0;
static final int PATH_SORT_MOST_POINTS_FIRST = 1;
static final int PATH_SORT_GREATEST_AREA_FIRST = 2;
static final int PATH_SORT_CENTRE_FIRST = 3;

// Internal vector filter constant
static final int VECTOR_FILTER_LOW_PASS = 1;

private PVector mouseVector = new PVector(0, 0);

// ----------------------------------------------------------------
// MACHINE CONTROL COMMANDS
// ----------------------------------------------------------------

void sendResetMachine() {
  addToCommandQueue(CMD_RESETMACHINE + "END");
}

void sendRequestMachineSize() {
  addToCommandQueue(CMD_REQUESTMACHINESIZE + "END");
}

void sendMachineSpec()
{
  // Sends physical machine parameters to the firmware
  addToCommandQueue(CMD_CHANGEMACHINENAME + "POLARGRAPH,END");
  
  addToCommandQueue(CMD_CHANGEMACHINESIZE + getDisplayMachine().inMM(getDisplayMachine().getWidth()) + "," + getDisplayMachine().inMM(getDisplayMachine().getHeight()) + ",END");
  
  addToCommandQueue(CMD_CHANGEMACHINEMMPERREV + int(getDisplayMachine().getMMPerRev()) + ",END");
  addToCommandQueue(CMD_CHANGEMACHINESTEPSPERREV + int(getDisplayMachine().getStepsPerRev()) + ",END");
  addToCommandQueue(CMD_SETMACHINESTEPMULTIPLIER + machineStepMultiplier + ",END");
  
  addToCommandQueue(CMD_SETPENLIFTRANGE + penLiftDownPosition + "," + penLiftUpPosition + ",1,END");

  // Send Speed settings
  NumberFormat nf = NumberFormat.getNumberInstance(Locale.UK);
  DecimalFormat df = (DecimalFormat)nf;  
  df.applyPattern("###.##");
  addToCommandQueue(CMD_SETMOTORSPEED + df.format(currentMachineMaxSpeed) + ",1,END");
  addToCommandQueue(CMD_SETMOTORACCEL + df.format(currentMachineAccel) + ",1,END");
}

void sendTestPattern() {
  addToCommandQueue(CMD_DRAWDIRECTIONTEST + "100,6,END");
}

void sendTestPenWidth()
{
  // Firmware based pen width calibration
  NumberFormat nf = NumberFormat.getNumberInstance(Locale.UK);
  DecimalFormat df = (DecimalFormat)nf;  
  df.applyPattern("##0.##");
  
  StringBuilder sb = new StringBuilder();
  sb.append(CMD_TESTPENWIDTH)
    .append("100") // Grid size placeholder
    .append(",")
    .append(df.format(testPenWidthStartSize))
    .append(",")
    .append(df.format(testPenWidthEndSize))
    .append(",")
    .append(df.format(testPenWidthIncrementSize))
    .append(",END");
  addToCommandQueue(sb.toString());
}

// ----------------------------------------------------------------
// MOVEMENT HELPERS
// ----------------------------------------------------------------

public PVector getMouseVector() {
  if (mouseVector == null) mouseVector = new PVector(0, 0);
  mouseVector.x = mouseX;
  mouseVector.y = mouseY;
  return mouseVector;
}

void sendMoveToPosition(boolean direct) {
  sendMoveToPosition(direct, getMouseVector());
}

void sendMoveToPosition(boolean direct, PVector position) {
  PVector p = getDisplayMachine().scaleToDisplayMachine(position);
  p = getDisplayMachine().inSteps(p);
  p = getDisplayMachine().asNativeCoords(p);
  sendMoveToNativePosition(direct, p);
}

void sendMoveToNativePosition(boolean direct, PVector p)
{
  String command = null;
  // Use C17 (Direct) for vectors/precision, C01 for loose travel
  if (direct)
    command = CMD_CHANGELENGTHDIRECT + int(p.x+0.5) + "," + int(p.y+0.5) + "," + getMaxSegmentLength() + ",END";
  else
    command = CMD_CHANGELENGTH + (int)p.x + "," + (int)p.y + ",END";

  addToCommandQueue(command);
}

void sendSetPosition()
{
  PVector p = getDisplayMachine().scaleToDisplayMachine(getMouseVector());
  p = getDisplayMachine().asNativeCoords(p);
  p = getDisplayMachine().inSteps(p);

  String command = CMD_SETPOSITION + int(p.x+0.5) + "," + int(p.y+0.5) + ",END";
  addToCommandQueue(command);
}

void sendSetHomePosition()
{
  PVector pgCoords = getDisplayMachine().asNativeCoords(getHomePoint());
  String command = CMD_SETPOSITION + int(pgCoords.x+0.5) + "," + int(pgCoords.y+0.5) + ",END";
  addToCommandQueue(command);
}

int getMaxSegmentLength() {
  return this.maxSegmentLength;
}

// ----------------------------------------------------------------
// BOX & FRAME DRAWING
// ----------------------------------------------------------------

void sendOutlineOfBox()
{
  // convert cartesian to native format
  PVector tl = getDisplayMachine().inSteps(boxVector1);
  PVector br = getDisplayMachine().inSteps(boxVector2);

  PVector tr = new PVector(br.x, tl.y);
  PVector bl = new PVector(tl.x, br.y);

  tl = getDisplayMachine().asNativeCoords(tl);
  tr = getDisplayMachine().asNativeCoords(tr);
  bl = getDisplayMachine().asNativeCoords(bl);
  br = getDisplayMachine().asNativeCoords(br);
  
  String cmd = CMD_CHANGELENGTHDIRECT;
  int seg = getMaxSegmentLength();

  // Draw Box (Top, Right, Bottom, Left)
  addToCommandQueue(cmd + (int)tl.x + "," + (int)tl.y + "," + seg + ",END");
  addToCommandQueue(cmd + (int)tr.x + "," + (int)tr.y + "," + seg + ",END");
  addToCommandQueue(cmd + (int)br.x + "," + (int)br.y + "," + seg + ",END");
  addToCommandQueue(cmd + (int)bl.x + "," + (int)bl.y + "," + seg + ",END");
  addToCommandQueue(cmd + (int)tl.x + "," + (int)tl.y + "," + seg + ",END");
}

// ----------------------------------------------------------------
// VECTOR PROCESSING ENGINE
// ----------------------------------------------------------------

void sendVectorShapes()
{
  // Default sorting
  sendVectorShapes(vectorShape, vectorScaling/100, vectorPosition, PATH_SORT_NONE);
}

void sendVectorShapes(RShape vec, float scaling, PVector position, int pathSortingAlgorithm)
{
  if (vec == null) {
     println("No vector to draw.");
     return;
  }
  
  println("Processing Vector Shapes...");
  RPoint[][] pointPaths = vec.getPointsInPaths();      

  // Optimize path order
  switch (pathSortingAlgorithm) {
    case PATH_SORT_MOST_POINTS_FIRST: pointPaths = sortPathsLongestFirst(pointPaths, pathLengthHighPassCutoff); break;
    case PATH_SORT_GREATEST_AREA_FIRST: pointPaths = sortPathsGreatestAreaFirst(vec, pathLengthHighPassCutoff); break;
    case PATH_SORT_CENTRE_FIRST: pointPaths = sortPathsCentreFirst(vec); break;
  }

  String command = "";
  PVector lastPoint = new PVector();
  boolean liftToGetToNewPoint = true;

  // Iterate through paths
  for (int i = 0; i<pointPaths.length; i++)
  {
    if (pointPaths[i] != null) 
    {
      if (pointPaths[i].length > pathLengthHighPassCutoff)
      {
        // Filter points (scaling + simplification)
        List<PVector> filteredPoints = filterPoints(pointPaths[i], minimumVectorLineLength, scaling, position);
        
        if (!filteredPoints.isEmpty())
        {
          // Check if we are already at the start point
          PVector p = filteredPoints.get(0);
          if ( p.x == lastPoint.x && p.y == lastPoint.y )
            liftToGetToNewPoint = false;
          else
            liftToGetToNewPoint = true;

          // Lift pen if needed
          if (liftToGetToNewPoint)
            addToCommandQueue(CMD_PENUP+"END");
            
          // Move to start of path
          command = CMD_CHANGELENGTHDIRECT+Math.round(p.x)+","+Math.round(p.y)+","+getMaxSegmentLength()+",END";
          addToCommandQueue(command);
          
          if (liftToGetToNewPoint)
            addToCommandQueue(CMD_PENDOWN+"END");

          // Draw the path
          for (int j=1; j<filteredPoints.size(); j++)
          {
            p = filteredPoints.get(j);
            command = CMD_CHANGELENGTHDIRECT+Math.round(p.x)+","+Math.round(p.y)+","+getMaxSegmentLength()+",END";
            addToCommandQueue(command);
          }
          lastPoint = new PVector(p.x, p.y);
        }
      }
    }
  }
  
  // Finish up
  addToCommandQueue(CMD_PENUP+"END");
  println("Vector command generation finished.");
}

// ----------------------------------------------------------------
// PATH FILTERING & OPTIMIZATION
// ----------------------------------------------------------------

List<PVector> filterPoints(RPoint[] points, long filterParam, float scaling, PVector position)
{
  List<PVector> result = new ArrayList<PVector>();

  // 1. Scale and Convert coordinate space
  List<PVector> scaled = new ArrayList<PVector>(points.length);
  for (int j = 0; j<points.length; j++)
  {
    RPoint firstPoint = points[j];
    PVector p = new PVector(firstPoint.x, firstPoint.y);
    p.mult(scaling);
    p.add(position);
    p = getDisplayMachine().inSteps(p);
    
    // Only include points inside the Picture Frame (Safety)
    if (getDisplayMachine().getPictureFrame().surrounds(p))
    {
      p = getDisplayMachine().asNativeCoords(p);
      scaled.add(p);
    }
  }

  // 2. Simplify (Low Pass Filter)
  if (scaled.size() > 1)
  {
    PVector p = scaled.get(0);
    result.add(p);

    for (int j = 1; j<scaled.size(); j++)
    {
      p = scaled.get(j);
      
      // Calculate change in motor steps
      int diffx = int(p.x) - int(result.get(result.size()-1).x);
      int diffy = int(p.y) - int(result.get(result.size()-1).y);

      // Only add point if it moved enough steps (filterParam)
      if (abs(diffx) > filterParam || abs(diffy) > filterParam)
      {
        result.add(p);
      }
    }
  }

  return result;
}

// ----------------------------------------------------------------
// PATH SORTING ALGORITHMS
// ----------------------------------------------------------------

public RPoint[][] sortPathsLongestFirst(RPoint[][] pointPaths, int highPassCutoff)
{
  List<RPoint[]> pathsList = new ArrayList<RPoint[]>();
  for (int i = 0; i<pointPaths.length; i++) {
    if (pointPaths[i] != null) pathsList.add(pointPaths[i]);
  }

  Collections.sort(pathsList, new Comparator<RPoint[]>() {
    public int compare(RPoint[] o1, RPoint[] o2) {
      // Descending order (longest first)
      return Integer.compare(o2.length, o1.length);
    }
  });

  pathsList = removeShortPaths(pathsList, highPassCutoff);

  for (int i=0; i<pathsList.size(); i++) pointPaths[i] = pathsList.get(i);
  return pointPaths;
}

public RPoint[][] sortPathsGreatestAreaFirst(RShape vec, int highPassCutoff)
{
  // Using TreeMap to automatically sort by Area (Key)
  // We use negative area to sort Descending (Largest first)
  SortedMap<Float, RPoint[]> pathsList = new TreeMap<Float, RPoint[]>();

  int noOfChildren = vec.countChildren();
  for (int i=0; i < noOfChildren; i++)
  {
    float area = vec.children[i].getArea();
    RPoint[] path = vec.children[i].getPointsInPaths()[0];
    // Add small random float to avoid key collision
    pathsList.put(-(area + (random(0,0.001f))), path);
  }

  List<RPoint[]> filtered = new ArrayList<RPoint[]>();
  for (RPoint[] path : pathsList.values())
  {
    // Check length against cutoff
    if (path.length >= highPassCutoff) filtered.add(path);
  }
  
  RPoint[][] pointPaths = new RPoint[filtered.size()][];
  for (int i = 0; i < filtered.size(); i++) pointPaths[i] = filtered.get(i);
  return pointPaths;
}

public RPoint[][] sortPathsCentreFirst(RShape vec)
{
  int noOfChildren = vec.countChildren();
  List<RShape> pathsList = new ArrayList<RShape>(noOfChildren);
  for (int i=0; i < noOfChildren; i++) pathsList.add(vec.children[i]);
  List<RShape> orderedPathsList = new ArrayList<RShape>(noOfChildren);

  float aspectRatio = vec.getHeight() / vec.getWidth();
  float w = 1.0;
  float h = w * aspectRatio;
  PVector centre = new PVector(vec.getWidth()/2, vec.getHeight()/2);
  float vecWidth = vec.getWidth();
  
  // Spiral out from center
  while (w <= vecWidth)
  {
    w += 6.0;
    h = w * aspectRatio;
    RShape field = RShape.createRectangle(centre.x-(w/2.0), centre.y-(h/2.0), w, h);
    
    ListIterator<RShape> it = pathsList.listIterator();
    while (it.hasNext())
    {
      RShape sh = it.next();
      if (field.contains(sh.getCenter()))
      {
        orderedPathsList.add(sh);
        it.remove();
      }
    }
  }
  // Add remainders
  orderedPathsList.addAll(pathsList);

  RPoint[][] pointPaths = new RPoint[orderedPathsList.size()][];
  for (int i = 0; i < orderedPathsList.size(); i++)
  {
    RPoint[][] points = orderedPathsList.get(i).getPointsInPaths();
    if (points != null && points.length > 0)
       pointPaths[i] = points[0];
  }
  return pointPaths;
}

List<RPoint[]> removeShortPaths(List<RPoint[]> list, int cutoff)
{
  if (cutoff > 0)
  {
    ListIterator<RPoint[]> it = list.listIterator();
    while (it.hasNext ())
    {
      RPoint[] paths = it.next();
      if (paths == null || paths.length <= cutoff)
        it.remove();
    }
  }
  return list;
}  

// ----------------------------------------------------------------
// LIVE MODE (Single Function)
// ----------------------------------------------------------------

void sendMachineLiveMode() {
  addToCommandQueue(CMD_MACHINE_MODE_LIVE + "END");
}

/**
  Machine.pde
  Represents the physical Polargraph hardware (Width, Height, Motor Steps).
  Handles Kinematics (Triangulation) and configuration loading.
*/

import java.util.Properties;

class Machine
{
  // ----------------------------------------------------------------
  // PHYSICAL DIMENSIONS
  // ----------------------------------------------------------------
  protected PVector machineSize = new PVector(4000, 6000); // Steps

  // Areas defined in Steps
  protected Rectangle page = new Rectangle(new PVector(1000, 1000), new PVector(2000, 3000));
  protected Rectangle imageFrame = new Rectangle(new PVector(1500, 1500), new PVector(1000, 1000));
  protected Rectangle pictureFrame = new Rectangle(new PVector(1600, 1600), new PVector(800, 800));

  // Motor Calibration
  protected Float stepsPerRev = 200.0;
  protected Float mmPerRev = 95.0;

  // Calculated values
  protected Float mmPerStep = null;
  protected Float stepsPerMM = null;
  protected Float maxLength = null;
  
  // Image filename
  protected String imageFilename = null;
  
  // Pen Lift
  protected int penLiftDownPosition = 90;
  protected int penLiftUpPosition = 180;

  // ----------------------------------------------------------------
  // PAPER SIZE CONSTANTS (Missing in original)
  // ----------------------------------------------------------------
  static final int A4_SHORT = 210;
  static final int A4_LONG = 297;
  static final int A3_SHORT = 297;
  static final int A3_LONG = 420;
  static final int A2_SHORT = 420;
  static final int A2_LONG = 594;
  static final int A1_SHORT = 594;
  static final int A1_LONG = 841;
  static final int A0_SHORT = 841;
  static final int A0_LONG = 1189;

  // "Imperial A2" approx 18x24 inches
  static final int A2_IMP_SHORT = 458; 
  static final int A2_IMP_LONG = 610; 

  static final String PRESET_A4_SHORT = "A4-Short (210mm)";
  static final String PRESET_A4_LONG = "A4-Long (297mm)";
  static final String PRESET_A3_SHORT = "A3-Short (297mm)";
  static final String PRESET_A3_LONG = "A3-Long (420mm)";
  static final String PRESET_A2_SHORT = "A2-Short (420mm)";
  static final String PRESET_A2_LONG = "A2-Long (594mm)";
  static final String PRESET_A1_SHORT = "A1-Short (594mm)";
  static final String PRESET_A1_LONG = "A1-Long (841mm)";
  static final String PRESET_A0_SHORT = "A0-Short (841mm)";
  static final String PRESET_A0_LONG = "A0-Long (1189mm)";
  
  static final String PRESET_A2_IMP_SHORT = "A2-Imp-Short (458mm)";
  static final String PRESET_A2_IMP_LONG = "A2-Imp-Long (610mm)";

  // ----------------------------------------------------------------
  // CONSTRUCTOR
  // ----------------------------------------------------------------

  public Machine(float w, float h, float stepsPerRev, float mmPerRev)
  {
    this.setSize((int)w, (int)h);
    this.setStepsPerRev(stepsPerRev);
    this.setMMPerRev(mmPerRev);
    recalculateSpecs();
  }

  // ----------------------------------------------------------------
  // GETTERS & SETTERS
  // ----------------------------------------------------------------

  public void setSize(Integer width, Integer height) {
    this.machineSize = new PVector(width, height);
    maxLength = null;
    recalculateSpecs();
  }
  public PVector getSize() { return this.machineSize; }
  public Integer getWidth() { return (int)this.machineSize.x; }
  public Integer getHeight() { return (int)this.machineSize.y; }
  
  public Float getMaxLength() {
    if (maxLength == null) maxLength = dist(0, 0, getWidth(), getHeight());
    return maxLength;
  }

  public void setPage(Rectangle r) { this.page = r; }
  public Rectangle getPage() { return this.page; }
  
  public void setImageFrame(Rectangle r) { this.imageFrame = r; }
  public Rectangle getImageFrame() { return this.imageFrame; }

  public void setPictureFrame(Rectangle r) { this.pictureFrame = r; }
  public Rectangle getPictureFrame() { return this.pictureFrame; }

  public void setStepsPerRev(Float s) { this.stepsPerRev = s; recalculateSpecs(); }
  public Float getStepsPerRev() { return this.stepsPerRev; }
  
  public void setMMPerRev(Float d) { this.mmPerRev = d; recalculateSpecs(); }
  public Float getMMPerRev() { return this.mmPerRev; }

  // Recalculate derived physics values
  void recalculateSpecs() {
    this.mmPerStep = mmPerRev / stepsPerRev;
    this.stepsPerMM = stepsPerRev / mmPerRev;
    this.maxLength = sqrt(sq(getWidth()) + sq(getHeight()));
  }

  public Float getMMPerStep() {
    if (mmPerStep == null) recalculateSpecs();
    return mmPerStep;
  }
  public Float getStepsPerMM() {
    if (stepsPerMM == null) recalculateSpecs();
    return stepsPerMM;
  }

  // ----------------------------------------------------------------
  // COORDINATE TRANSFORMS
  // ----------------------------------------------------------------

  public int inSteps(float inMM) { return (int)(inMM * getStepsPerMM() + 0.5); }
  public int inMM(float steps) { return (int)(steps / getStepsPerMM() + 0.5); }

  public PVector inSteps(PVector mm) { return new PVector(inSteps(mm.x), inSteps(mm.y)); }
  public PVector inMM(PVector steps) { return new PVector(inMM(steps.x), inMM(steps.y)); }

  // Cartesian (X,Y) -> Native (A,B)
  public PVector asNativeCoords(PVector cartCoords) {
    return asNativeCoords(cartCoords.x, cartCoords.y);
  }
  public PVector asNativeCoords(float cartX, float cartY) {
    float distA = dist(0, 0, cartX, cartY);
    float distB = dist(getWidth(), 0, cartX, cartY);
    return new PVector(distA, distB);
  }

  // Native (A,B) -> Cartesian (X,Y)
  public PVector asCartesianCoords(PVector pgCoords) {
    float w = getWidth();
    float a = pgCoords.x;
    float b = pgCoords.y;
    
    // Law of Cosines intersection
    float x = (sq(a) - sq(b) + sq(w)) / (2 * w);
    float y = sqrt(sq(a) - sq(x));
    return new PVector(x, y);
  }

  // ----------------------------------------------------------------
  // PROPERTIES & PRESETS
  // ----------------------------------------------------------------

  public Integer convertSizePreset(String preset)
  {
    if (preset.equalsIgnoreCase(PRESET_A3_SHORT)) return A3_SHORT;
    if (preset.equalsIgnoreCase(PRESET_A3_LONG)) return A3_LONG;
    if (preset.equalsIgnoreCase(PRESET_A2_SHORT)) return A2_SHORT;
    if (preset.equalsIgnoreCase(PRESET_A2_LONG)) return A2_LONG;
    if (preset.equalsIgnoreCase(PRESET_A2_IMP_SHORT)) return A2_IMP_SHORT;
    if (preset.equalsIgnoreCase(PRESET_A2_IMP_LONG)) return A2_IMP_LONG;
    if (preset.equalsIgnoreCase(PRESET_A1_SHORT)) return A1_SHORT;
    if (preset.equalsIgnoreCase(PRESET_A1_LONG)) return A1_LONG;
    if (preset.equalsIgnoreCase(PRESET_A0_SHORT)) return A0_SHORT;
    if (preset.equalsIgnoreCase(PRESET_A0_LONG)) return A0_LONG;
    
    // Default or Parse
    try { return Integer.parseInt(preset); } 
    catch (Exception e) { return A3_SHORT; }
  }

  // Load properties using the passed 'props' object (Fixes unused parameter warning)
  public void loadDefinitionFromProperties(Properties props)
  {
    setStepsPerRev(getPropFloat(props, "machine.motors.stepsPerRev", 200.0f));
    setMMPerRev(getPropFloat(props, "machine.motors.mmPerRev", 95.0f));

    // Machine Size
    float w = inSteps(getPropFloat(props, "machine.width", 600));
    float h = inSteps(getPropFloat(props, "machine.height", 800));
    setSize((int)w, (int)h);

    // Page Size
    String pW = props.getProperty("controller.page.width", PRESET_A3_SHORT);
    String pH = props.getProperty("controller.page.height", PRESET_A3_LONG);
    float pwMM = convertSizePreset(pW);
    float phMM = convertSizePreset(pH);

    // Page Position
    String pos = props.getProperty("controller.page.position.x", "CENTRE");
    float pxMM = 0;
    if (pos.equalsIgnoreCase("CENTRE")) {
      pxMM = inMM((getWidth() - inSteps(pwMM)) / 2.0);
    } else {
      pxMM = getPropFloat(props, "controller.page.position.x", 0);
    }
    float pyMM = getPropFloat(props, "controller.page.position.y", 120);

    setPage(new Rectangle(inSteps(new PVector(pxMM, pyMM)), inSteps(new PVector(pwMM, phMM))));

    // Image/Working Area
    setImageFilename(props.getProperty("controller.image.filename", ""));
    float imgX = getPropFloat(props, "controller.image.position.x", 0);
    float imgY = getPropFloat(props, "controller.image.position.y", 0);
    float imgW = getPropFloat(props, "controller.image.width", 500);
    float imgH = getPropFloat(props, "controller.image.height", 500);
    setImageFrame(new Rectangle(inSteps(new PVector(imgX, imgY)), inSteps(new PVector(imgW, imgH))));

    // Picture Frame
    float frmX = getPropFloat(props, "controller.pictureframe.position.x", 200);
    float frmY = getPropFloat(props, "controller.pictureframe.position.y", 200);
    float frmW = getPropFloat(props, "controller.pictureframe.width", 200);
    float frmH = getPropFloat(props, "controller.pictureframe.height", 200);
    setPictureFrame(new Rectangle(inSteps(new PVector(frmX, frmY)), inSteps(new PVector(frmW, frmH))));

    // Pen Lift
    penLiftDownPosition = getPropInt(props, "machine.penlift.down", 90);
    penLiftUpPosition = getPropInt(props, "machine.penlift.up", 180);
  }

  // Helpers to read from local props object
  private float getPropFloat(Properties p, String key, float def) {
    try { return Float.parseFloat(p.getProperty(key, String.valueOf(def))); } catch(Exception e) { return def; }
  }
  private int getPropInt(Properties p, String key, int def) {
    try { return (int)Float.parseFloat(p.getProperty(key, String.valueOf(def))); } catch(Exception e) { return def; }
  }

  public Properties loadDefinitionIntoProperties(Properties props)
  {
    props.setProperty("machine.motors.stepsPerRev", getStepsPerRev().toString());
    props.setProperty("machine.motors.mmPerRev", getMMPerRev().toString());
    props.setProperty("machine.width", Integer.toString(inMM(getWidth())));
    props.setProperty("machine.height", Integer.toString(inMM(getHeight())));

    props.setProperty("controller.image.filename", (getImageFilename() == null) ? "" : getImageFilename());

    // Page
    if (getPage() != null) {
      props.setProperty("controller.page.width", Integer.toString(inMM(getPage().getWidth())));
      props.setProperty("controller.page.height", Integer.toString(inMM(getPage().getHeight())));
      props.setProperty("controller.page.position.x", Integer.toString(inMM(getPage().getLeft())));
      props.setProperty("controller.page.position.y", Integer.toString(inMM(getPage().getTop())));
    }

    // Pen Lift
    props.setProperty("machine.penlift.down", Integer.toString(penLiftDownPosition));
    props.setProperty("machine.penlift.up", Integer.toString(penLiftUpPosition));

    return props;
  }
  
  // ----------------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------------
  public void setImageFilename(String filename) { this.imageFilename = filename; }
  public String getImageFilename() { return this.imageFilename; }
}

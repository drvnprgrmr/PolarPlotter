/**
 Panel Class - Handles groups of UI controls.
 Refactored for SVG-Only Polargraph Controller.
 */

class Panel
{
  private Rectangle outline = null;
  private String name = null;
  private List<Controller> controls = null;
  private Map<String, PVector> controlPositions = null;
  private Map<String, PVector> controlSizes = null;

  private boolean resizable = true;
  private float minimumHeight = DEFAULT_CONTROL_SIZE.y + 4;
  private color outlineColour = color(255);

  // Style Constants
  public final color CONTROL_COL_BG_DEFAULT = color(0, 54, 82);
  public final color CONTROL_COL_BG_DISABLED = color(20, 44, 62);
  public final color CONTROL_COL_LABEL_DEFAULT = color(255);
  public final color CONTROL_COL_LABEL_DISABLED = color(100);

  public Panel(String name, Rectangle outline) {
    this.name = name;
    this.outline = outline;
  }

  // ----------------------------------------------------------------
  // DRAWING & LOGIC
  // ----------------------------------------------------------------
  public void draw(boolean visible)
  {
    if (visible) {
      if (debugPanels) {
        stroke(outlineColour);
        strokeWeight(1);
        noFill();
        rect(outline.getLeft(), outline.getTop(), outline.getWidth(), outline.getHeight());
      }
    }
    drawControls(visible);
  }

  public void drawControls(boolean visible)
  {
    if (getControls() == null) return;

    for (Controller c : getControls())
    {
      if (visible) {
        c.show();

        // Position update
        PVector pos = getControlPositions().get(c.getName());
        if (pos != null) c.setPosition(pos.x + outline.getLeft(), pos.y + outline.getTop());

        PVector cSize = getControlSizes().get(c.getName());
        if (cSize != null) c.setSize((int)cSize.x, (int)cSize.y);

        // Logic: Locking
        boolean locked = false;
        if ((MODE_RENDER_VECTORS.equals(c.getName()) || MODE_MOVE_VECTOR.equals(c.getName()))
          && getDisplayMachine().getVectorShape() == null) locked = true;

        // Logic: Labels
        if (MODE_LOAD_VECTOR_FILE.equals(c.getName())) {
          c.setLabel(getDisplayMachine().getVectorShape() != null ? "Clear Vector" : "Load Vector");
        }

        setLock(c, locked);
      } else {
        c.hide();
      }
    }
  }
  void setLock(Controller c, boolean locked)
  {
    c.setLock(locked);
    if (locked) {
      c.setColorBackground(CONTROL_COL_BG_DISABLED);
      c.setColorLabel(CONTROL_COL_LABEL_DISABLED);
    } else {
      c.setColorBackground(CONTROL_COL_BG_DEFAULT);
      c.setColorLabel(CONTROL_COL_LABEL_DEFAULT);
    }
  }

  // ----------------------------------------------------------------
  // RESIZING LAYOUT
  // ----------------------------------------------------------------

  void setSizeByHeight(float h)
  {
    if (!resizable) return;

    float newH = (h <= minimumHeight) ? minimumHeight : h;
    outline.setHeight(newH);

    // Re-calculate positions
    setControlPositions(buildControlPositionsForPanel(this));

    // Calculate new width based on columns
    float maxX = 0;
    for (PVector pos : getControlPositions().values()) {
      if (pos.x > maxX) maxX = pos.x;
    }
    outline.setWidth(maxX + DEFAULT_CONTROL_SIZE.x);
  }

  // ----------------------------------------------------------------
  // GETTERS & SETTERS
  // ----------------------------------------------------------------

  public Rectangle getOutline() {
    return this.outline;
  }
  public String getName() {
    return this.name;
  }

  public List<Controller> getControls() {
    if (this.controls == null) this.controls = new ArrayList<Controller>();
    return this.controls;
  }
  public void setControls(List<Controller> c) {
    this.controls = c;
  }

  public Map<String, PVector> getControlPositions() {
    return this.controlPositions;
  }
  public void setControlPositions(Map<String, PVector> cp) {
    this.controlPositions = cp;
  }

  public Map<String, PVector> getControlSizes() {
    return this.controlSizes;
  }
  public void setControlSizes(Map<String, PVector> cs) {
    this.controlSizes = cs;
  }

  void setOutlineColour(color c) {
    this.outlineColour = c;
  }
  void setResizable(boolean r) {
    this.resizable = r;
  }

  void setMinimumHeight(float h) {
    this.minimumHeight = h;
  }
}

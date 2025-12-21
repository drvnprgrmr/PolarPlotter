/**
  Refactored DisplayMachine for SVG-only support.
  Handles screen-to-machine coordinate transformations and visual rendering.
*/

class DisplayMachine extends Machine
{
  private Rectangle outline = null;
  private float scaling = 1.0;
  private Scaler scaler = null;
  private PVector offset = null;
  
  // Vector Storage
  private RShape vectorShape = null;

  public DisplayMachine(Machine m, PVector offset, float scaling)
  {
    // Pass essential physical attributes
    super(m.getWidth(), m.getHeight(), m.getMMPerRev(), m.getStepsPerRev());
    super.machineSize = m.machineSize;
    super.page = m.page;
    super.pictureFrame = m.pictureFrame;
    super.stepsPerMM = m.stepsPerMM;

    this.offset = offset;
    this.scaling = scaling;
    this.scaler = new Scaler(scaling, 100.0);
  }
  
  // Default constructor for safety
  public DisplayMachine() {
    super(5000, 5000, 200.0, 95.0);
    this.offset = new PVector(0,0);
  }

  // ----------------------------------------------------------------
  // SCALING & COORDINATE TRANSFORMS
  // ----------------------------------------------------------------

  public Rectangle getOutline() {
    outline = new Rectangle(offset, new PVector(sc(super.getWidth()), sc(super.getHeight())));
    return this.outline;
  }

  private Scaler getScaler() {
    if (scaler == null) this.scaler = new Scaler(getScaling(), getMMPerStep());
    return scaler;
  }

  public void setScale(float scale) {
    this.scaling = scale;
    this.scaler = new Scaler(scale, getMMPerStep());
  }

  public float getScaling() { return this.scaling; }
  public float sc(float val) { return getScaler().scale(val); }

  public void setOffset(PVector offset) { this.offset = offset; }
  public PVector getOffset() { return this.offset; }

  // Screen (Pixels) -> Machine (MM)
  public PVector scaleToDisplayMachine(PVector screen) {
    float x = (screen.x - getOffset().x) / scaling;
    float y = (screen.y - getOffset().y) / scaling;
    return new PVector(x, y);
  }

  // Machine (MM) -> Screen (Pixels)
  public PVector scaleToScreen(PVector mach) {
    float x = (mach.x * scaling) + getOffset().x;
    float y = (mach.y * scaling) + getOffset().y;
    return new PVector(x, y);
  }

  // ----------------------------------------------------------------
  // UTILITY
  // ----------------------------------------------------------------

  public String getDimensionsAsText(Rectangle r) {
    return int(inMM(r.getWidth())) + " x " + int(inMM(r.getHeight())) + "mm";
  }

  // ----------------------------------------------------------------
  // VECTOR STORAGE
  // ----------------------------------------------------------------
  
  public void setVectorShape(RShape shape) {
    this.vectorShape = shape;
  }
  public RShape getVectorShape() {
    return this.vectorShape;
  }

  // ----------------------------------------------------------------
  // RENDERING
  // ----------------------------------------------------------------

  public void draw()
  {
    noStroke();

    // 1. Draw Machine Board Background (Grey)
    fill(machineColour);
    rect(getOutline().getLeft(), getOutline().getTop(), getOutline().getWidth(), getOutline().getHeight());

    // 2. Draw Page Area (White)
    fill(pageColour);
    rect(getOutline().getLeft()+sc(getPage().getLeft()), 
         getOutline().getTop()+sc(getPage().getTop()), 
         sc(getPage().getWidth()), 
         sc(getPage().getHeight()));
         
    // Page Labels
    fill(50);
    textAlign(LEFT, BOTTOM);
    text("Page: " + getDimensionsAsText(getPage()), 
         getOutline().getLeft()+sc(getPage().getLeft()), 
         getOutline().getTop()+sc(getPage().getTop())-5);

    // 3. Draw Guides
    if (displayingGuides)
    {
      stroke(guideColour);
      strokeWeight(2);
      
      // Center vertical line
      float centerX = getOutline().getLeft()+(getOutline().getWidth()/2);
      line(centerX, getOutline().getTop(), centerX, getOutline().getBottom());

      // Home Point horizontal line
      if (getHomePoint() != null) {
        float homeY = getOutline().getTop()+sc(inMM(getHomePoint().y)); // Ensure converted to screen Y
        line(getOutline().getLeft(), homeY, getOutline().getRight(), homeY);
      }
    }

    // 4. Draw Vector (SVG)
    if (vectorShape != null) {
       displayVectorImage(vectorShape, vectorScaling/100.0f, vectorPosition);
    }

    // 5. Draw Frame/Box Guide (Red corners)
    if (displayingGuides) {
      drawPictureFrame();
    }
    
    // 6. Draw Hanging Strings (Visualizer)
    if (displayingGuides && getOutline().surrounds(new PVector(mouseX, mouseY))) {
      stroke(255, 255, 255, 100);
      strokeWeight(1);
      line(getOutline().getLeft(), getOutline().getTop(), mouseX, mouseY);
      line(getOutline().getRight(), getOutline().getTop(), mouseX, mouseY);
    }
  }
  
  public void drawForSetup() {
    draw(); // Same as main draw
    
    // Emphasize Home Point
    if (getHomePoint() != null) {
       PVector hp = scaleToScreen(inMM(getHomePoint()));
       noFill();
       stroke(0, 255, 0);
       ellipse(hp.x, hp.y, 20, 20);
       fill(0);
       text("HOME", hp.x + 15, hp.y);
    }
  }

  // ----------------------------------------------------------------
  // VECTOR RENDERING LOGIC
  // ----------------------------------------------------------------

  public void displayVectorImage(RShape vec, float scaling, PVector position)
  {
    // Draw Centroid
    PVector centroid = new PVector(vec.width/2, vec.height/2);
    centroid.mult(scaling);
    centroid.add(position);
    centroid = scaleToScreen(centroid);

    RPoint[][] pointPaths = vec.getPointsInPaths();
    RG.ignoreStyles(); 
    strokeWeight(1);
    stroke(0); // Black lines
    noFill();

    if (pointPaths != null)
    {
      for(int i = 0; i < pointPaths.length; i++)
      {
        if (pointPaths[i] != null) 
        {
          beginShape();
          for (int j = 0; j < pointPaths[i].length; j++)
          {
            // Transform SVG points to Screen Pixels
            // SVG Point -> Scale -> Translate (Offset) -> Screen Transform
            PVector p = new PVector(pointPaths[i][j].x, pointPaths[i][j].y);
            p.mult(scaling);
            p.add(position);
            
            // Check bounds (optional optimization)
            // if (getPictureFrame().surrounds(inSteps(p))) { ... }
            
            p = scaleToScreen(p);
            vertex(p.x, p.y);
          }
          endShape();
        }
      }
      
      // Draw Red Dot at Center
      fill(255,0,0,150);
      noStroke();
      ellipse(centroid.x, centroid.y, 8, 8);
    }
  }

  // ----------------------------------------------------------------
  // FRAME RENDERING
  // ----------------------------------------------------------------

  void drawPictureFrame()
  {
    if (getPictureFrame() == null) return;
    
    strokeWeight(1);
    PVector topLeft = scaleToScreen(inMM(getPictureFrame().getTopLeft()));
    PVector botRight = scaleToScreen(inMM(getPictureFrame().getBotRight()));

    stroke(frameColour);
    noFill();
    
    // Draw simple frame box
    rectMode(CORNERS);
    rect(topLeft.x, topLeft.y, botRight.x, botRight.y);
    rectMode(CORNER);
  }
}

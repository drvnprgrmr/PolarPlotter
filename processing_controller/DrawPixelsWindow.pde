// Helper to allow running code on the child sketch thread (Place this in your main sketch if not present)
void runOnLoop(Runnable r) {
  r.run();
}


ControlFrameSimple addDrawPixelsControlFrame(String theName, int theWidth, int theHeight, int theX, int theY, int theColor ) {
  final ControlFrameSimple p = new ControlFrameSimple( this, theWidth, theHeight, theColor );

  String[] args = { theName };
  PApplet.runSketch(args, p);

  // Wait for the secondary window to initialize (prevents NullPointerException)
  long startWait = System.currentTimeMillis();
  while (p.cp5() == null) {
    try { Thread.sleep(10); } catch (Exception e) {}
    if (System.currentTimeMillis() - startWait > 5000) { 
      println("Error: ControlFrame timed out."); 
      break; 
    }
  }
  
  // FIX: Access 'surface' directly. No runOnLoop needed.
  // Note: We use 'p.surface' (the variable), not getSurface().

    p.setWindowLocation(theX, theY);
  

  // Set up controls
  RadioButton rPos = p.cp5().addRadioButton("radio_startPosition",10,10)
    .add("Top-right", DRAW_DIR_NE)
    .add("Bottom-right", DRAW_DIR_SE)
    .add("Bottom-left", DRAW_DIR_SW)
    .add("Top-left", DRAW_DIR_NW)
    .plugTo(this, "radio_startPosition");

  RadioButton rSkip = p.cp5().addRadioButton("radio_pixelSkipStyle",10,100)
    .add("Lift pen over masked pixels", 1)
    .add("Draw masked pixels as blanks", 2)
    .plugTo(this, "radio_pixelSkipStyle");

  RadioButton rStyle = p.cp5().addRadioButton("radio_pixelStyle",100,10);
  rStyle.add("Variable frequency square wave", PIXEL_STYLE_SQ_FREQ);
  rStyle.add("Variable size square wave", PIXEL_STYLE_SQ_SIZE);
  rStyle.add("Solid square wave", PIXEL_STYLE_SQ_SOLID);
  rStyle.add("Scribble", PIXEL_STYLE_SCRIBBLE);
  
  if (currentHardware >= HARDWARE_VER_MEGA) {
    rStyle.add("Spiral", PIXEL_STYLE_CIRCLE);
    rStyle.add("Sawtooth", PIXEL_STYLE_SAW);
  }
  rStyle.plugTo(this, "radio_pixelStyle");

  Button submitButton = p.cp5().addButton("submitDrawWindow",0,280,10,120,20)
    .setLabel("Generate commands")
    .plugTo(this, "submitDrawWindow");
      
  return p;
}


class DrawPixelsWindow extends ControlFrame {

  public DrawPixelsWindow () {
    // Assuming ControlFrame constructor handles PApplet parent setup
    super(parentPapplet, 450, 150);
    
    int xPos = 100;
    int yPos = 100;
    
    // --- OLD CODE REMOVED ---
    // Frame f = new Frame... 
    // f.add(this)...
    
    // --- NEW CODE ---
    // 1. Launch the sketch
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
    
    // 2. Set location (Note: surface might not exist instantly, so we try our best)
    // It is often better to put 'surface.setLocation(100, 100)' inside the setup() of this class instead.
  }
  
  // You should ensure your ControlFrame class has a settings() method!
  public void settings() {
    size(450, 150);
  }
}

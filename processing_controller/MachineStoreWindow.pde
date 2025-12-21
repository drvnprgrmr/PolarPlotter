/*------------------------------------------------------------------------
    Details about the "machine store" subwindow
------------------------------------------------------------------------*/

ControlFrameSimple addMachineStoreControlFrame(String theName, int theWidth, int theHeight, int theX, int theY, int theColor ) {
  // 1. Create the ControlFrame object
  final ControlFrameSimple p = new ControlFrameSimple( this, theWidth, theHeight, theColor );

  // 2. Launch the window using Processing 4's runSketch
  String[] args = { theName };
  PApplet.runSketch(args, p);

  // 3. WAIT for the window to initialize (Safety Loop)
  // We must wait for ControlP5 to exist inside the new window before adding buttons
  long startWait = System.currentTimeMillis();
  while (p.cp5() == null) {
    try { Thread.sleep(10); } catch (Exception e) {}
    if (System.currentTimeMillis() - startWait > 5000) { 
      println("Error: ControlFrame timed out."); 
      break; 
    }
  }
  
  // 4. Set window location directly on the surface
  p.setWindowLocation(theX, theY);
  
  // 5. Set up controls (Logic copied from your original code)
  Textfield filenameField = p.cp5().addTextfield("machineStore_storeFilename",20,20,150,20)
    .setText(getStoreFilename())
    .setLabel("Filename to store to")
    .addListener( new ControlListener() {
      public void controlEvent( ControlEvent ev ) {
        machineStore_storeFilename(ev.getController().getStringValue());
        // Note: Your original code referenced "machineExec" here. I left it as is, 
        // but you might want to check if that was a copy-paste error in the original sketch.
        try {
          Textfield tf = p.cp5().get(Textfield.class, "machineExec_execFilename");
        } catch (Exception e) { /* Ignore if field doesn't exist */ }
      }
    });

  Button submitButton = p.cp5().addButton("machineStore_submitStoreFilenameWindow",0,180,20,60,20)
    .setLabel("Submit")
    .addListener( new ControlListener() {
      public void controlEvent( ControlEvent ev ) {
        p.cp5().get(Textfield.class, "machineStore_storeFilename").submit();
        p.cp5().get(Textfield.class, "machineStore_storeFilename").setText(getStoreFilename());
      }
    });

  Toggle overwriteToggle = p.cp5().addToggle("machineStore_toggleAppendToFile",true,180,50,20,20)
    .setCaptionLabel("Overwrite existing file")
    .plugTo(this, "machineStore_toggleAppendToFile");
     
  filenameField.setFocus(true);
    
  return p;
}
void machineStore_toggleAppendToFile(boolean theFlag) {
  setOverwriteExistingStoreFile(theFlag);
}
  
void machineStore_storeFilename(String filename) {
  println("Filename event: "+ filename);
  if (filename != null 
      && filename.length() <= 12
      && !"".equals(filename.trim())) {
    filename = filename.trim();
    setStoreFilename(filename);
    sendMachineStoreMode();
  }
}

ControlFrameSimple addMachineExecControlFrame(String theName, int theWidth, int theHeight, int theX, int theY, int theColor ) {
  // 1. Create the ControlFrame object
  final ControlFrameSimple p = new ControlFrameSimple( this, theWidth, theHeight, theColor );

  // 2. Launch it properly using runSketch
  String[] args = { theName };
  PApplet.runSketch(args, p);

  // 3. WAIT for the window to initialize (Critical step!)
  long startWait = System.currentTimeMillis();
  while (p.cp5() == null) {
    try { Thread.sleep(10); } catch (Exception e) {}
    if (System.currentTimeMillis() - startWait > 5000) { 
      println("Error: ControlFrame timed out."); 
      break; 
    }
  }

  // 4. Set window location
  // We check if surface exists first to avoid crashes
  p.setWindowLocation(theX, theY);

  // 5. Set up controls
  // The rest of your logic remains mostly the same
  Textfield filenameField = p.cp5().addTextfield("machineExec_execFilename",20,20,150,20)
    .setText(getStoreFilename())
    .setLabel("Filename to execute from")
    .addListener( new ControlListener() {
      public void controlEvent( ControlEvent ev ) {
        machineExec_execFilename(ev.getController().getStringValue());
        // Note: The following line doesn't do much, but I kept it from your original code
        Textfield tf = p.cp5().get(Textfield.class, "machineExec_execFilename");
      }
    });
    
  Button submitButton = p.cp5().addButton("machineExec_submitExecFilenameWindow",0,180,20,60,20)
    .setLabel("Submit")
    .addListener( new ControlListener() {
      public void controlEvent( ControlEvent ev ) {
        // Submit the text field when the button is pressed
        p.cp5().get(Textfield.class, "machineExec_execFilename").submit();
        
        // Reset the text field to the stored filename
        p.cp5().get(Textfield.class, "machineExec_execFilename").setText(getStoreFilename());
      }
    });
    
  filenameField.setFocus(true);
    
  return p;
}

void machineExec_execFilename(String filename) {
  println("Filename event: "+ filename);
  if (filename != null 
      && filename.length() <= 12
      && !"".equals(filename.trim())) {
    filename = filename.trim();
    setStoreFilename(filename);
    sendMachineExecMode();
  }
}

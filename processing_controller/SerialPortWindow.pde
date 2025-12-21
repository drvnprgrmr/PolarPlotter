/*------------------------------------------------------------------------
 Class and controllers on the "serial port" subwindow
 ------------------------------------------------------------------------*/
  
ControlFrameSimple addSerialPortControlFrame(String theName, int theWidth, int theHeight, int theX, int theY, int theColor ) {
  // 1. Create the ControlFrame object
  final ControlFrameSimple p = new ControlFrameSimple( this, theWidth, theHeight, theColor );

  // 2. Launch using runSketch
  String[] args = { theName };
  PApplet.runSketch(args, p);

  // 3. WAIT for the window to initialize
  long startWait = System.currentTimeMillis();
  while (p.cp5() == null) {
    try { Thread.sleep(10); } catch (Exception e) {}
    if (System.currentTimeMillis() - startWait > 5000) { 
      println("Error: ControlFrame timed out."); 
      break; 
    }
  }
  
  // 4. Set window location
  p.setWindowLocation(theX, theY);

  // 5. Add the ScrollableList
  // Note: We use p.cp5() because the control belongs to the child window
  ScrollableList sl = p.cp5().addScrollableList("dropdown_serialPort")
    .setPosition(10, 10)
    .setSize(150, 150)
    .setBarHeight(20)
    .setItemHeight(16)
    .plugTo(this, "dropdown_serialPort");  

  // Add the "No connection" option manually
  sl.addItem("No serial connection", -1);

  // Get list of ports
  String[] ports = processing.serial.Serial.list();
  
  for (int i = 0; i < ports.length; i++) {
    println("Adding " + ports[i]);
    sl.addItem(ports[i], i);
  }
  
  // Handle current port selection logic
  int portNo = getSerialPortNumber();
  println("portNo: " + portNo);
  
  // Safety check for valid index
  if (portNo < 0 || portNo >= ports.length)
    portNo = -1;

  // The logic in your original code seemed to expect the list index 
  // to match the port index directly, but you added an extra item at the top.
  // Generally, you might need to adjust the value set here if 'portNo' refers 
  // to the array index of Serial.list().
  // Assuming portNo -1 is "No Connection" (index 0 in the list):
  if (portNo == -1) {
    sl.setValue(0); // Select "No serial connection"
  } else {
    sl.setValue(portNo + 1); // Offset by 1 because of the extra item
  }

  sl.setOpen(false);
  return p;
}

void dropdown_serialPort(int newSerialPort) 
{
  println("In dropdown_serialPort, newSerialPort: " + newSerialPort);

  // Fix: The dropdown returns the INDEX of the selected item (0, 1, 2...).
  // Item 0 is "No Serial Connection". Item 1 is "COM1" (or similar).
  // Your original code shifted this by -1.
  int portIndex = newSerialPort - 1;
  
  if (portIndex == -2)
  {
     // Do nothing (invalid state)
  } 
  else if (portIndex == -1) {
    println("Disconnecting serial port.");
    useSerialPortConnection = false;
    if (myPort != null)
    {
      myPort.stop();
      myPort = null;
    }
    drawbotReady = false;
    drawbotConnected = false;
    serialPortNumber = portIndex;
  } 
  else if (portIndex != getSerialPortNumber()) {
    println("About to connect to serial port in slot " + portIndex);
    
    String[] availablePorts = processing.serial.Serial.list();
    
    if (portIndex < availablePorts.length) {
      try {
        drawbotReady = false;
        drawbotConnected = false;
        if (myPort != null) {
          myPort.stop();
          myPort = null;
        }
        
        if (getSerialPortNumber() >= 0) {
            // Safety check for array bounds before printing closing message
            String[] currentPorts = processing.serial.Serial.list();
            if (getSerialPortNumber() < currentPorts.length) {
                println("closing " + currentPorts[getSerialPortNumber()]);
            }
        }

        serialPortNumber = portIndex;
        String portName = availablePorts[serialPortNumber];

        // Explicitly use processing.serial.Serial here
        myPort = new processing.serial.Serial(this, portName, getBaudRate());
        myPort.bufferUntil('\n');
        useSerialPortConnection = true;
        println("Successfully connected to port " + portName);
      }
      catch (Exception e) {
        println("Attempting to connect to serial port in slot " + getSerialPortNumber() 
          + " caused an exception: " + e.getMessage());
      }
    } else {
      println("No serial ports found.");
      useSerialPortConnection = false;
    }
  } else {
    println("no serial port change.");
  }
}

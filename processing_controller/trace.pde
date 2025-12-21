class Pixel {
  int x;
  int y;
  color c;
  
  Pixel(int x, int y, color c) {
    this.x = x;
    this.y = y;
    this.c = c;
  }
}


public void trace_initTrace(PImage img)
{
  // Feature disabled for Processing 4 migration
  println("Tracing disabled.");
}
public void trace_initCameraProcCam()
{
//  try
//  {
//    String[] cameras = Capture.list();
//    if (cameras.length > 0) {
//      liveCamera = new Capture(this, 640, 480, cameras[0]);
//      //liveCamera.start();
//      traceEnabled = true;
//    }
//  }
//  catch (Exception e)
//  {
//    println("Exception occurred trying to look for attached webcams.  Webcam will not be used. " + e.getMessage());
//    traceEnabled = false;
//  }

}  
//public PImage trace_buildLiveImage()
//{
//  //liveCamera.start();
//  PImage pimg = createImage(640, 480, RGB);
//  pimg.loadPixels();
//  if (liveCamera.available()) {
//    liveCamera.read();
//  }
//  pimg.pixels = liveCamera.pixels;
//  // flip the image left to right
//  if (flipWebcamImage)
//  {
//
//    List<int[]> list = new ArrayList<int[]>(480);
//
//    for (int r=0; r<pimg.pixels.length; r+=640)
//    {
//      int[] temp = new int[640];
//      for (int c=0; c<640; c++)
//      {
//        temp[c] = pimg.pixels[r+c];
//      }
//      list.add(temp);
//    }
//
//    // reverse the list
//    Collections.reverse(list);
//
//    for (int r=0; r<list.size(); r++)
//    {
//      for (int c=0; c<640; c++)
//      {
//        pimg.pixels[(r*640)+c] = list.get(r)[c];
//      }
//    }
//  }
//  pimg.updatePixels();
//  return pimg;
//}

public PImage trace_processImageForTrace(PImage in)
{
  PImage out = createImage(in.width, in.height, RGB);
  out.loadPixels();
  for (int i = 0; i<in.pixels.length; i++) {
    out.pixels[i] = in.pixels[i];
  }
  out.filter(BLUR, blurValue);
  out.filter(GRAY);
  out.filter(POSTERIZE, posterizeValue);
  out.updatePixels();
  return out;
}

RShape trace_traceImage(ArrayList<PImage> seps)
{
  // Return an empty shape so the drawing loop has something valid to ignore
  return new RShape();
}

Map<Integer, PImage> trace_buildSeps(PImage img, Integer keyColour)
{
  // create separations
  // pull out number of colours
  Set<Integer> colours = null;
  List<Integer> colourList = null;

  colours = new HashSet<Integer>();
  for (int i=0; i< img.pixels.length; i++) {
    colours.add(img.pixels[i]);
  }
  colourList = new ArrayList(colours);

  Map<Integer, PImage> seps = new HashMap<Integer, PImage>(colours.size());
  for (Integer colour : colours) {
    PImage sep = createImage(img.width, img.height, RGB);
    sep.loadPixels();
    seps.put(colour, sep);
  }

  for (int i = 0; i<img.pixels.length; i++) {
    Integer pixel = img.pixels[i];
    seps.get(pixel).pixels[i] = keyColour;
  }

  return seps;
}

RShape trace_convertDiewaldToRShape(List<Pixel> points)
{
  RShape shp = null;
  if (points.size() > 2) {
    shp = new RShape();
    Pixel p = points.get(0);
    shp.addMoveTo(float(p.x), float(p.y));
    for (int idx = 1; idx < points.size(); idx++) {
      p = points.get(idx);
      shp.addLineTo(float(p.x), float(p.y));
    }
    shp.addClose();
  }
  return shp;
}


public void trace_captureCurrentImage(PImage inImage)
{
  captureShape = traceShape;
}

public void trace_captureCurrentImage()
{
//  capturedImage = webcam_buildLiveImage();
  if (getDisplayMachine().imageIsReady())
    trace_captureCurrentImage(getDisplayMachine().getImage());
}

public void trace_processLoadedImage()
{
  trace_captureCurrentImage(getDisplayMachine().getImage());
}

public void trace_saveShape(RShape sh)
{
  SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddhhmmss");
  String dateCode = sdf.format(new java.util.Date());
  String filename = shapeSavePath + shapeSavePrefix + dateCode + shapeSaveExtension;
  RG.saveShape(filename, sh);
}

//public void stop() {
//  liveCamera.stop();
//  super.stop();
//}

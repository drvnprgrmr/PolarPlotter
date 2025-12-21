/**
  Misc Helper Classes
  Utilities for scaling math and queue visualization.
*/

class Scaler
{
  public float scale = 1.0;
  public float mmPerStep = 1.0;
  
  public Scaler(float scale, float mmPerStep)
  {
    this.scale = scale;
    this.mmPerStep = mmPerStep;
  }
  
  public void setScale(float scale)
  {
    this.scale = scale;
  }
  
  public float scale(float in)
  {
    return in * mmPerStep * scale;
  }
}

class PreviewVector extends PVector
{
  // A standard PVector that also holds the raw command string.
  // This is used by the "Show Queue" feature to visualize 
  // pending movements on the screen.
  public String command;
}

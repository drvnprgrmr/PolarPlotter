public interface BLOBable {
  public void init();
  public void updateOnFrame(int width, int height);
  public boolean isBLOBable(int pixel_index, int x, int y);
}

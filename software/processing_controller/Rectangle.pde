/**
  Rectangle Class
  A geometric utility helper.
*/
class Rectangle
{
  public PVector position = null;
  public PVector size = null;
  
  public Rectangle(float px, float py, float width, float height)
  {
    this.position = new PVector(px, py);
    this.size = new PVector(width, height);
  }
  public Rectangle(PVector position, PVector size)
  {
    this.position = position;
    this.size = size;
  }
  public Rectangle(Rectangle r)
  {
    this.position = new PVector(r.getPosition().x, r.getPosition().y);
    this.size = new PVector(r.getSize().x, r.getSize().y);
  }
  
  // ----------------------------------------------------------------
  // DIMENSIONS
  // ----------------------------------------------------------------

  public float getWidth()
  {
    return this.size.x;
  }
  public void setWidth(float w)
  {
    this.size.x = w;
  }
  public float getHeight()
  {
    return this.size.y;
  }
  public void setHeight(float h)
  {
    this.size.y = h;
  }
  
  // ----------------------------------------------------------------
  // POSITIONS & BOUNDS
  // ----------------------------------------------------------------

  public PVector getPosition()
  {
    return this.position;
  }
  public void setPosition(float x, float y)
  {
    if (this.position == null)
      this.position = new PVector(x, y);
    else
    {
      this.position.x = x;
      this.position.y = y;
    }
  }

  public PVector getSize()
  {
    return this.size;
  }
  public PVector getTopLeft()
  {
    return getPosition();
  }
  public PVector getTopRight()
  {
    return new PVector(this.size.x+this.position.x, this.position.y);
  }
  public PVector getBotRight()
  {
    return PVector.add(this.position, this.size);
  }
  public float getLeft()
  {
    return getPosition().x;
  }
  public float getRight()
  {
    return getPosition().x + getSize().x;
  }
  public float getTop()
  {
    return getPosition().y;
  }
  public float getBottom()
  {
    return getPosition().y + getSize().y;
  }
  
  // ----------------------------------------------------------------
  // LOGIC
  // ----------------------------------------------------------------

  // Checks if a specific point is inside this rectangle
  public Boolean surrounds(PVector p)
  {
    // Removed the "-1" offset from the original code (used for pixel array safety).
    // Standard geometric containment:
    if (p.x >= this.getLeft()
    && p.x < this.getRight()
    && p.y >= this.getTop()
    && p.y < this.getBottom())
      return true;
    else
      return false;
  }
  
  public String toString() {
    return "Rectangle pos: " + this.getPosition() + ", size: " + this.getSize();
  }
  
}

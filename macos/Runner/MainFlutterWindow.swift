import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    
    // Set tablet landscape dimensions (1280x800 for 16:10 aspect ratio)
    let tabletWidth: CGFloat = 1280
    let tabletHeight: CGFloat = 800
    
    // Center the window on screen
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let newOriginX = screenFrame.origin.x + (screenFrame.width - tabletWidth) / 2
      let newOriginY = screenFrame.origin.y + (screenFrame.height - tabletHeight) / 2
      
      let newFrame = NSRect(x: newOriginX, y: newOriginY, width: tabletWidth, height: tabletHeight)
      self.setFrame(newFrame, display: true)
    }
    
    // Set minimum window size to maintain aspect ratio
    self.minSize = NSSize(width: 1024, height: 640)
    self.title = "Glance Dashboard"

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

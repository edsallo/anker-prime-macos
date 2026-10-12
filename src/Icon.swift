import Cocoa
let out = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
for size in [16,32,64,128,256,512,1024] {
 let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:rep)
 let scale = CGFloat(size)/1024
 let transform = NSAffineTransform();transform.scale(by:scale);transform.concat()
 NSColor(calibratedRed:0.063,green:0.086,blue:0.098,alpha:1).setFill()
 NSBezierPath(roundedRect:NSRect(x:24,y:24,width:976,height:976),xRadius:220,yRadius:220).fill()
 let mint=NSColor(calibratedRed:0.725,green:0.953,blue:0.757,alpha:1)
 mint.setStroke();let body=NSBezierPath(roundedRect:NSRect(x:215,y:220,width:594,height:594),xRadius:100,yRadius:100);body.lineWidth=30;body.stroke()
 mint.setFill();let bolt=NSBezierPath();bolt.move(to:NSPoint(x:553,y:733));bolt.line(to:NSPoint(x:367,y:480));bolt.line(to:NSPoint(x:485,y:480));bolt.line(to:NSPoint(x:448,y:339));bolt.line(to:NSPoint(x:658,y:586));bolt.line(to:NSPoint(x:535,y:586));bolt.close();bolt.fill()
 mint.setStroke();for x in [385,555] {let port=NSBezierPath(roundedRect:NSRect(x:x,y:269,width:84,height:28),xRadius:14,yRadius:14);port.lineWidth=8;port.stroke()}
 NSGraphicsContext.restoreGraphicsState()
 let name:String
 if size==1024{name="icon_512x512@2x.png"}else{name="icon_\(size)x\(size).png"}
 try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:out).appendingPathComponent(name))
 if [32,64,256,512].contains(size){try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:out).appendingPathComponent("icon_\(size/2)x\(size/2)@2x.png"))}
}

//
//  WMWindow.m
//  WindowManager
//
//  Created by Steven Troughton-Smith on 23/12/2015.
//  Copyright © 2015 High Caffeine Content. All rights reserved.
//
import UIKit
enum WMResizeAxis {
	case WMResizeNone, WMResizeLeft, WMResizeRight, WMResizeTop, WMResizeBottom
}

let kStatusBarHeight:CGFloat = 0.0
let kTitleBarHeight:CGFloat = 0.0
let kMoveGrabHeight:CGFloat = 44.0
let kWindowButtonFrameSize:CGFloat = 44.0
let kWindowButtonSize:CGFloat = 24.0
let kWindowResizeGutterSize:CGFloat = 8.0
let kWindowResizeGutterTargetSize:CGFloat = 24.0
let kWindowResizeGutterKnobSize:CGFloat = 48.0
let kWindowResizeGutterKnobWidth:CGFloat = 4.0


func CGRectMake(_ x:CGFloat , _ y:CGFloat , _ w:CGFloat , _ h:CGFloat ) -> CGRect
{
	return CGRect(x: x, y: y, width: w, height: h)
}

func CGSizeMake(_ w:CGFloat , _ h:CGFloat ) -> CGSize
{
	return CGSize(width: w, height: h)
}


class WMWindow : UIWindow, UIGestureRecognizerDelegate {
	
	var _savedFrame: CGRect = CGRect.zero
	var _inWindowMove: Bool = false
	var _inWindowResize: Bool = false
	var _originPoint: CGPoint = CGPoint.zero
	var resizeAxis: WMResizeAxis = WMResizeAxis.WMResizeNone
	var title: String?
	var windowButtons: Array<UIButton>?
	var maximized: Bool = false
	
	func _commonInit() {
		self.windowButtons = Array()
		var windowButton: UIButton = UIButton(type: .custom)
		
		windowButton.frame = CGRectMake(kWindowResizeGutterSize, kWindowResizeGutterSize, kWindowButtonFrameSize, kWindowButtonFrameSize)
		windowButton.contentMode = .center
		windowButton.adjustsImageWhenHighlighted = true
		windowButton.addTarget(self, action: "close:", for: .touchUpInside)
		var fillColor: UIColor = UIColor(red: 0.953, green: 0.278, blue: 0.275, alpha: 1.000)
		var strokeColor: UIColor = UIColor(red: 0.839, green: 0.188, blue: 0.192, alpha: 1.000)
		var inactiveFillColor: UIColor = UIColor(white: 0.765, alpha: 1.000)
		var inactiveStrokeColor: UIColor = UIColor(white: 0.608, alpha: 1.000)
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(kWindowButtonSize, kWindowButtonSize), false, UIScreen.main.scale)
		fillColor.setFill()
		strokeColor.setStroke()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).fill()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).stroke()
		var img = UIGraphicsGetImageFromCurrentImageContext()
		windowButton.setImage(img, for: .normal)
		UIGraphicsEndImageContext()
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(kWindowButtonSize, kWindowButtonSize), false, UIScreen.main.scale)
		inactiveFillColor.setFill()
		inactiveStrokeColor.setStroke()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).fill()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).stroke()
		img = UIGraphicsGetImageFromCurrentImageContext()
		windowButton.setImage(img, for: .disabled)
		UIGraphicsEndImageContext()
		self.addSubview(windowButton)
		self.windowButtons?.append(windowButton)
		
		windowButton = UIButton(type: .custom)
		windowButton.frame = CGRectMake(kWindowResizeGutterSize+12+kWindowButtonSize, kWindowResizeGutterSize, kWindowButtonFrameSize, kWindowButtonFrameSize)
		windowButton.contentMode = .center
		windowButton.adjustsImageWhenHighlighted = true
		windowButton.addTarget(self, action: "maximize:", for: .touchUpInside)
		fillColor = UIColor(red: 0.188, green: 0.769, blue: 0.196, alpha: 1.000)
		strokeColor = UIColor(red: 0.165, green: 0.624, blue: 0.125, alpha: 1.000)
		inactiveFillColor = UIColor(white: 0.765, alpha: 1.000)
		inactiveStrokeColor = UIColor(white: 0.608, alpha: 1.000)
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(kWindowButtonSize, kWindowButtonSize), false, UIScreen.main.scale)
		fillColor.setFill()
		strokeColor.setStroke()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).fill()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).stroke()
		img = UIGraphicsGetImageFromCurrentImageContext()
		windowButton.setImage(img, for: .normal)
		UIGraphicsEndImageContext()
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(kWindowButtonSize, kWindowButtonSize), false, UIScreen.main.scale)
		inactiveFillColor.setFill()
		inactiveStrokeColor.setStroke()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).fill()
		UIBezierPath(ovalIn: CGRectMake(1, 1, kWindowButtonSize-2, kWindowButtonSize-2)).stroke()
		
		img = UIGraphicsGetImageFromCurrentImageContext()
		windowButton.setImage(img, for: .disabled)
		UIGraphicsEndImageContext()
		self.addSubview(windowButton)
		self.windowButtons?.append(windowButton)
		
		var panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action:"didPan:")
		panRecognizer.delegate = self
		self.addGestureRecognizer(panRecognizer)
		var focusRecognizers: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:"didTap:")
		self.addGestureRecognizer(focusRecognizers)
		self.layer.shadowRadius = 30.0
		self.layer.shadowColor = UIColor.black.cgColor
		self.layer.shadowOpacity = 0.3
	}
	
	override func layoutSubviews() {
		
		if (self.rootViewController != nil)
		{
			var rootView: UIView = (self.rootViewController?.view)!
			
			if (rootView != nil)
			{
				
				var contentRect: CGRect = CGRectMake(kWindowResizeGutterSize, kWindowResizeGutterSize+kTitleBarHeight, self.bounds.size.width-(kWindowResizeGutterSize*2), self.bounds.size.height-kTitleBarHeight-(kWindowResizeGutterSize*2))
				rootView.frame = contentRect
				self.adjustMask()
			}
		}
		
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		if self != nil {
			self._commonInit()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self._commonInit()
	}
	
	
	
	func maximize(_ sender: AnyObject) {
		self.maximized = !self.maximized
		var rootWindow: UIWindow = self.window!
		UIView.beginAnimations(nil, context: nil)
		if self.maximized {
			_savedFrame = self.frame
			self.frame = CGRectMake(-kWindowResizeGutterSize, kStatusBarHeight + -kWindowResizeGutterSize, rootWindow.bounds.size.width+(kWindowResizeGutterSize*2), rootWindow.bounds.size.height-kStatusBarHeight+(kWindowResizeGutterSize*2))
		} else {
			self.frame = _savedFrame
			
		}
		UIView.commitAnimations()
	}
	
	
	func close(_ sender: AnyObject) {
		self.isHidden = true
	}
	
	override func becomeKey() {
		self.window?.addSubview(self)
		self.setNeedsDisplay()
		
		self.layer.shadowRadius = 30.0
		for btn in self.windowButtons! {
			btn.isEnabled = true
		}
	}
	
	override func resignKey() {
		self.setNeedsDisplay()
		
		self.layer.shadowRadius = 10.0
		for btn in self.windowButtons! {
			btn.isEnabled = false
		}
	}
	
	override func addSubview(_ view: UIView) {
		super.addSubview(view)
		for btn in self.windowButtons! {
			self.insertSubview(btn, at: Int.max)
		}
	}
	
	@objc func didTap(_ rec: UIGestureRecognizer) {
		self.makeKeyAndVisible()
	}
	
	func setFrame(_frame: CGRect) {
		super.frame = frame
		self.setNeedsDisplay()
	}
	
	@objc func didPan(_ recognizer: UIPanGestureRecognizer) {
		var titleBarRect: CGRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, kMoveGrabHeight)
		var gp: CGPoint = recognizer.location(in: self.window)
		var lp: CGPoint = recognizer.location(in: self.rootViewController!.view)
		
		var leftResizeRect: CGRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, kWindowResizeGutterTargetSize, self.bounds.size.height)
		var rightResizeRect: CGRect = CGRectMake(self.bounds.origin.x+self.bounds.size.width-kWindowResizeGutterTargetSize, self.bounds.origin.y, kWindowResizeGutterTargetSize, self.bounds.size.height)
		var topResizeRect: CGRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, kWindowResizeGutterTargetSize)
		var bottomResizeRect: CGRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height-kWindowResizeGutterTargetSize, self.bounds.size.width, kWindowResizeGutterTargetSize)
		leftResizeRect = leftResizeRect.insetBy(dx: -kWindowResizeGutterTargetSize, dy: -kWindowResizeGutterTargetSize)
		rightResizeRect = rightResizeRect.insetBy(dx: -kWindowResizeGutterTargetSize, dy: -kWindowResizeGutterTargetSize)
		bottomResizeRect = bottomResizeRect.insetBy(dx: -kWindowResizeGutterTargetSize, dy: -kWindowResizeGutterTargetSize)
		if self.maximized {
			return
		}
		if recognizer.state == .began {
			_originPoint = lp
			dump(lp)
			dump(_originPoint)
			if titleBarRect.contains(lp) {
				_inWindowMove = true
				_inWindowResize = false
				return
			}
			if !self.isKeyWindow {
				return
			}
			if leftResizeRect.contains(lp) {
				_inWindowResize = true
				_inWindowMove = false
				resizeAxis = WMResizeAxis.WMResizeLeft
			}
			if rightResizeRect.contains(lp) {
				_inWindowResize = true
				_inWindowMove = false
				resizeAxis = WMResizeAxis.WMResizeRight
			}
			if topResizeRect.contains(lp) {
				_inWindowResize = true
				_inWindowMove = false
				resizeAxis = WMResizeAxis.WMResizeTop
			}
			if bottomResizeRect.contains(lp) {
				_inWindowResize = true
				_inWindowMove = false
				resizeAxis = WMResizeAxis.WMResizeBottom
			}
		} else if recognizer.state == .changed {
			if _inWindowMove {
				self.frame = CGRectMake(gp.x-_originPoint.x, gp.y-_originPoint.y, self.frame.size.width, self.frame.size.height)
			}
			if _inWindowResize {
				if resizeAxis == WMResizeAxis.WMResizeRight {
					self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, gp.x-self.frame.origin.x, self.frame.size.height)
				}
				if resizeAxis == WMResizeAxis.WMResizeLeft {
					self.frame = CGRectMake(gp.x, self.frame.origin.y, (-gp.x+self.frame.origin.x)+self.frame.size.width, self.frame.size.height)
				}
				if resizeAxis == WMResizeAxis.WMResizeBottom {
					self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, gp.y-self.frame.origin.y)
				}
			}
		} else if recognizer.state == .ended {
			_inWindowMove = false
			_inWindowResize = false
			self.setNeedsDisplay()
		}
	}
	
	func adjustMask() {
		var contentBounds: CGRect = self.rootViewController!.view.bounds
		var contentFrame: CGRect = CGRectMake(self.bounds.origin.x+kWindowResizeGutterSize, self.bounds.origin.y+kWindowResizeGutterSize, self.bounds.size.width-(kWindowResizeGutterSize*2), self.bounds.size.height-(kWindowResizeGutterSize*2))
		var maskLayer: CAShapeLayer = CAShapeLayer()
		maskLayer.path = UIBezierPath(roundedRect: contentBounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSizeMake(8.0, 8.0)).cgPath
		maskLayer.frame = contentBounds
		self.rootViewController?.view.layer.mask = maskLayer
		self.layer.shadowPath = UIBezierPath(roundedRect: contentFrame, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSizeMake(8.0, 8.0)).cgPath
		self.layer.shadowRadius = 30.0
		self.layer.shadowColor = UIColor.black.cgColor
		self.layer.shadowOpacity = 0.3
	}
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	override func draw(_ rect: CGRect) {
		if self.isKeyWindow && !self.maximized {
			if _inWindowResize {
				var leftResizeRect: CGRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y+kWindowResizeGutterSize, kWindowResizeGutterSize, self.bounds.size.height-(kWindowResizeGutterSize*2))
				var rightResizeRect: CGRect = CGRectMake(self.bounds.origin.x+self.bounds.size.width-kWindowResizeGutterSize, self.bounds.origin.y+kWindowResizeGutterSize, kWindowResizeGutterSize, self.bounds.size.height-(kWindowResizeGutterSize*2))
				var bottomResizeRect: CGRect = CGRectMake(self.bounds.origin.x+kWindowResizeGutterSize, self.bounds.origin.y+self.bounds.size.height-kWindowResizeGutterSize, self.bounds.size.width-(kWindowResizeGutterSize*2), kWindowResizeGutterSize)
				UIColor(white: 0.0, alpha: 0.3).setFill()
				
				if resizeAxis == WMResizeAxis.WMResizeRight {
					UIBezierPath(roundedRect: rightResizeRect, cornerRadius: 3.0).fill()
				}
				if resizeAxis == WMResizeAxis.WMResizeLeft {
					UIBezierPath(roundedRect: leftResizeRect, cornerRadius: 3.0).fill()
				}
				if resizeAxis == WMResizeAxis.WMResizeBottom {
					UIBezierPath(roundedRect: bottomResizeRect, cornerRadius: 3.0).fill()
				}
			}
			UIColor(white: 1, alpha: 0.3).setFill()
			UIBezierPath(roundedRect: CGRectMake(self.bounds.midX-kWindowResizeGutterKnobSize/2, self.bounds.maxY-kWindowResizeGutterKnobWidth-(kWindowResizeGutterSize-kWindowResizeGutterKnobWidth)/2, kWindowResizeGutterKnobSize, kWindowResizeGutterKnobWidth), cornerRadius: 2).fill()
			UIBezierPath(roundedRect: CGRectMake((kWindowResizeGutterSize-kWindowResizeGutterKnobWidth)/2, self.bounds.midY-kWindowResizeGutterKnobSize/2, kWindowResizeGutterKnobWidth, kWindowResizeGutterKnobSize), cornerRadius: 2).fill()
			UIBezierPath(roundedRect: CGRectMake(self.bounds.maxX-kWindowResizeGutterKnobWidth-(kWindowResizeGutterSize-kWindowResizeGutterKnobWidth)/2, self.bounds.midY-kWindowResizeGutterKnobSize/2, kWindowResizeGutterKnobWidth, kWindowResizeGutterKnobSize), cornerRadius: 2).fill()
		}
	}
	
	func wm_isOpaque() -> Bool
	{
		return false
	}
}

func swizzleUIWindow()
{
	let origMethod = class_getInstanceMethod(WMWindow.self, NSSelectorFromString("isOpaque"))
	let newMethod = class_getInstanceMethod(WMWindow.self,NSSelectorFromString("wm_isOpaque"))
	
	method_exchangeImplementations(origMethod, newMethod)
}

import PlaygroundSupport

swizzleUIWindow()

let window = UIWindow(frame: UIScreen.main.bounds)

let bgVC = UIViewController()
let iv = UIImageView(image: #imageLiteral(resourceName: "wallpaper.png"))
iv.contentMode = .scaleAspectFill
bgVC.view = iv

window.rootViewController = bgVC
window.makeKeyAndVisible()

PlaygroundPage.current.liveView = window

do {
	let window1 = WMWindow(frame: CGRectMake(50,50,400,300))
	window1.title = "View"
	
	let vc1 = UIViewController()
	vc1.title = "View"
	vc1.view = UIView()
	vc1.view.backgroundColor = UIColor.white
	let nc1 = UINavigationController(rootViewController: vc1)
	
	window1.rootViewController = nc1
	window1.makeKeyAndVisible()
	
	window.addSubview(window1)
}

do {
	let window1 = WMWindow(frame: CGRectMake(150,150,400,300))
	
	let vc1 = UIViewController()
	vc1.title = "Map View"
	
	Bundle(path: "/System/Library/Frameworks/MapKit.framework")?.load()
	vc1.view = (NSClassFromString("MKMapView") as! UIView.Type).init()
	vc1.view.backgroundColor = UIColor.white
	let nc1 = UINavigationController(rootViewController: vc1)
	
	window1.rootViewController = nc1
	window1.makeKeyAndVisible()
	
	window.addSubview(window1)
}



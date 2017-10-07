//
//  LoadingBallView.swift
//  BezierPathAnimation
//
//  Created by Takuya Okamoto on 2015/08/11.
//  Copyright (c) 2015年 Uniface. All rights reserved.
//

import UIKit

private var timeFunc : CAMediaTimingFunction!
private var upDuration: Double!

class BallView: UIView {
    
    @objc var circleLayer: CircleLayer!
    
    @objc init(frame:CGRect,
        circleSize:CGFloat = 40,
        timingFunc:CAMediaTimingFunction = timeFunc,
        moveUpDuration:CFTimeInterval = upDuration,
        moveUpDist:CGFloat,
        color:UIColor = UIColor.white)
    {
        timeFunc = timingFunc
        upDuration = moveUpDuration
        super.init(frame:frame)
        
        let circleMoveView = UIView()
        circleMoveView.frame = CGRect(x: 0, y: 0, width: moveUpDist, height: moveUpDist)
        circleMoveView.center = CGPoint(x: frame.width/2, y: frame.height + circleSize / 2)
        self.addSubview(circleMoveView)
        
        circleLayer = CircleLayer(
            size: circleSize,
            moveUpDist: moveUpDist,
            superViewFrame: circleMoveView.frame,
            color: color
        )
        circleMoveView.layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func startAnimation() {
        circleLayer.startAnimation()
    }
    @objc func endAnimation(_ complition:(()->())? = nil) {
        circleLayer.endAnimation(complition)
    }
}




class CircleLayer :CAShapeLayer, CAAnimationDelegate {
    
    let moveUpDist: CGFloat!
    @objc let spiner: SpinerLayer!
    @objc var didEndAnimation: (()->())?
    
    @objc init(size:CGFloat, moveUpDist:CGFloat , superViewFrame:CGRect, color:UIColor = UIColor.white) {
        self.moveUpDist = moveUpDist
        let selfFrame = CGRect(x: 0, y: 0, width: superViewFrame.size.width, height: superViewFrame.size.height)
        self.spiner = SpinerLayer(superLayerFrame: selfFrame, ballSize: size, color: color)
        super.init()
        
        self.addSublayer(spiner)
        
        let radius:CGFloat = size / 2
        self.frame = selfFrame
        let center = CGPoint(x: superViewFrame.size.width / 2, y: superViewFrame.size.height/2)
        let startAngle = 0 - M_PI_2
        let endAngle = M_PI * 2 - M_PI_2
        let clockwise: Bool = true
        self.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: clockwise).cgPath
        self.fillColor = color.withAlphaComponent(1).cgColor
        self.strokeColor = self.fillColor
        self.lineWidth = 0
        self.strokeEnd = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func startAnimation() {
        self.moveUp(moveUpDist)
        Timer.schedule(delay: upDuration) { timer in
            self.spiner.animation()
        }
    }
    @objc func endAnimation(_ complition:(()->())? = nil) {
        spiner.stopAnimation()
        self.moveDown(moveUpDist)
        didEndAnimation = complition
    }
    
    @objc func moveUp(_ distance: CGFloat) {
        let move = CABasicAnimation(keyPath: "position")
        
        move.fromValue = NSValue(cgPoint: position)
        move.toValue = NSValue(cgPoint: CGPoint(x: position.x, y: position.y - distance))
        
        move.duration = upDuration
        move.timingFunction = timeFunc
        
        move.fillMode = kCAFillModeForwards
        move.isRemovedOnCompletion = false
        self.add(move, forKey: move.keyPath)
    }
    
    
    @objc func moveDown(_ distance: CGFloat) {
        let move = CABasicAnimation(keyPath: "position")
        
        move.fromValue = NSValue(cgPoint: CGPoint(x: position.x, y: position.y - distance))
        move.toValue = NSValue(cgPoint: position)
        
        move.duration = upDuration
        move.timingFunction = timeFunc
        
        move.fillMode = kCAFillModeForwards
        move.isRemovedOnCompletion = false
        move.delegate = self
        self.add(move, forKey: move.keyPath)
    }
	
		func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        didEndAnimation?()
    }
}


class SpinerLayer :CAShapeLayer, CAAnimationDelegate {
    
    @objc init(superLayerFrame:CGRect, ballSize:CGFloat, color:UIColor = UIColor.white) {
        super.init()
        
        let radius:CGFloat = (ballSize / 2) * 1.2//1.45
        self.frame = CGRect(x: 0, y: 0, width: superLayerFrame.height, height: superLayerFrame.height)
        let center = CGPoint(x: superLayerFrame.size.width / 2, y: superLayerFrame.origin.y + superLayerFrame.size.height/2)
        let startAngle = 0 - M_PI_2
        let endAngle = (M_PI * 2 - M_PI_2) + M_PI / 8
        let clockwise: Bool = true
        self.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: clockwise).cgPath
        
        self.fillColor = nil
        self.strokeColor = color.withAlphaComponent(1).cgColor
        self.lineWidth = 2
        self.lineCap = kCALineCapRound
        
        self.strokeStart = 0
        self.strokeEnd = 0
        self.isHidden = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func animation() {
        self.isHidden = false
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = 0
        rotate.toValue = M_PI * 2
        rotate.duration = 1
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        rotate.repeatCount = HUGE
        rotate.fillMode = kCAFillModeForwards
        rotate.isRemovedOnCompletion = false
        self.add(rotate, forKey: rotate.keyPath)

        strokeEndAnimation()
    }

    @objc func strokeEndAnimation() {
        let endPoint = CABasicAnimation(keyPath: "strokeEnd")
        endPoint.fromValue = 0
        endPoint.toValue = 1.0
        endPoint.duration = 0.8
        endPoint.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        endPoint.repeatCount = 1
        endPoint.fillMode = kCAFillModeForwards
        endPoint.isRemovedOnCompletion = false
        endPoint.delegate = self
        self.add(endPoint, forKey: endPoint.keyPath)
    }
    
    @objc func strokeStartAnimation() {
        let startPoint = CABasicAnimation(keyPath: "strokeStart")
        startPoint.fromValue = 0
        startPoint.toValue = 1.0
        startPoint.duration = 0.8
        startPoint.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        startPoint.repeatCount = 1
//        startPoint.fillMode = kCAFillModeForwards
//        startPoint.removedOnCompletion = false
        startPoint.delegate = self
        self.add(startPoint, forKey: startPoint.keyPath)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if self.isHidden == false {
            let a:CABasicAnimation = anim as! CABasicAnimation
            if a.keyPath == "strokeStart" {
                strokeEndAnimation()
            }
            else if a.keyPath == "strokeEnd" {
                strokeStartAnimation()
            }
        }
    }
    
    @objc func stopAnimation() {
        self.isHidden = true
        self.removeAllAnimations()
    }
}

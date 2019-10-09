//
//  MLDTransitioningDelegate.swift
//  MLDTransitioningDelegate
//
//  Created by MacBook on 1/24/19.
//  Copyright © 2019 MyLuckyDay. All rights reserved.
//

import UIKit

public class MLDTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
    private let customPresentationAnimation: ((_ toView: UIView?, _ containerView: UIView)->(()->Void))?
    private let customDismissalAnimation: ((_ fromView: UIView?, _ containerView: UIView)->(()->Void))?
    
    public init(customPresentationAnimation: ((_ toView: UIView?, _ containerView: UIView)->(()->Void))? = nil, customDismissalAnimation: ((_ fromView: UIView?, _ containerView: UIView)->(()->Void))? = nil) {
        self.customPresentationAnimation = customPresentationAnimation
        self.customDismissalAnimation = customDismissalAnimation
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return MLDPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MLDPresentationAnimator(customPresentationAnimation: self.customPresentationAnimation)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MLDDismissalAnimator(customDismissalAnimation: self.customDismissalAnimation)
    }
}

internal class MLDPresentationController : UIPresentationController {
    
    private let dimmingView: UIView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override var shouldPresentInFullscreen: Bool { get { return false } }
    override var shouldRemovePresentersView: Bool { get { return false } }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        get {
            let containerBounds = containerView?.bounds ?? .zero
            var presentedViewFrame = CGRect.zero
            presentedViewFrame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerBounds.size)
            let yPos = containerBounds.height - presentedViewFrame.height
            presentedViewFrame.origin = CGPoint(x: 0, y: yPos)
            return presentedViewFrame
        }
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let preferredSize = container.preferredContentSize
        return CGSize(
            width: min(preferredSize.width, parentSize.width),
            height: min(preferredSize.height, parentSize.height)
        )
    }
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        let gr = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:)))
        dimmingView.addGestureRecognizer(gr)
    }
    
    @objc private func dimmingViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
    
    override func presentationTransitionWillBegin() {
        // Add custom views to hierarchy here and animate
        dimmingView.frame = containerView?.bounds ?? .zero
        dimmingView.alpha = 0
        
        containerView?.insertSubview(dimmingView, at: 0)
        
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { _ in self.dimmingView.alpha = 1 },
            completion: nil
        )
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // Remove managed views from hierarchy if !completed (== failed to present)
        if(!completed) {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        // animate dismissal
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { _ in self.dimmingView.alpha = 0 },
            completion: nil
        )
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        // remove any managed views from hierarchy if completed (== successfully dismissed)
        if(completed) {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        if(containerView != nil) {
            dimmingView.frame = containerView!.bounds
        }
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
}

internal class MLDPresentationAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    
    private let customPresentationAnimation: ((_ toView: UIView?, _ containerView: UIView)->(()->Void))?
    
    init(customPresentationAnimation: ((_ toView: UIView?, _ containerView: UIView)->(()->Void))?) {
        self.customPresentationAnimation = customPresentationAnimation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toView = transitionContext.view(forKey: .to)
        let containerView = transitionContext.containerView
        
        toView?.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.size.height)
        if toView != nil {
            containerView.addSubview(toView!)
        }
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            animations: { [weak self] in
                if let anim = self?.customPresentationAnimation {
                    anim(toView, containerView)()
                } else {
                    toView?.transform = CGAffineTransform.identity
                }
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

internal class MLDDismissalAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    
    private let customDismissalAnimation: ((_ toView: UIView?, _ containerView: UIView)->(()->Void))?
    
    init(customDismissalAnimation: ((_ toView: UIView?, _ containerView: UIView)->(()->Void))?) {
        self.customDismissalAnimation = customDismissalAnimation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.view(forKey: .from)
        let containerView = transitionContext.containerView
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            animations: { [weak self] in
                if let anim = self?.customDismissalAnimation {
                    anim(fromView, containerView)()
                } else {
                    fromView?.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.size.height)
                }
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}


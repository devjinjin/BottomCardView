//
//  CardViewController.swift
//  BottomCardView
//
//  Created by jylee-mac on 2021/05/20.
//

import UIKit

class CardViewController: UIViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var dimmerView: UIView!
    @IBOutlet weak var cardViewTopConstraint: NSLayoutConstraint!
    
    var cardViewState : CardViewState = .normal
    var cardPanStartingTopConstraint : CGFloat = 30.0
    
    
    enum CardViewState {
         case expanded
         case normal
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // round the top left and top right corner of card view
        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 10.0
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // hide the card view at the bottom when the View first load
        if let safeAreaHeight = UIApplication.shared.keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,
        let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
            cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
        }
        
        // dimmerViewTapped() will be called when user tap on the dimmer view
        let dimmerTap = UITapGestureRecognizer(target: self, action: #selector(dimmerViewTapped(_:)))
        dimmerView.addGestureRecognizer(dimmerTap)
        dimmerView.isUserInteractionEnabled = true
        
        
        // add pan gesture recognizer to the view controller's view (the whole screen)
           let viewPan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
           
           // by default iOS will delay the touch before recording the drag/pan information
           // we want the drag gesture to be recorded down immediately, hence setting no delay
           viewPan.delaysTouchesBegan = false
           viewPan.delaysTouchesEnded = false

           self.view.addGestureRecognizer(viewPan)
    }
    
    @IBAction func dimmerViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
      hideCardAndGoBack()
    }
    
    private func dimAlphaWithCardTopConstraint(value: CGFloat) -> CGFloat {
      let fullDimAlpha : CGFloat = 0.7
      
      // ensure safe area height and safe area bottom padding is not nil
      guard let safeAreaHeight = UIApplication.shared.keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,
        let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom else {
        return fullDimAlpha
      }
      
      // when card view top constraint value is equal to this,
      // the dimmer view alpha is dimmest (0.7)
      let fullDimPosition = (safeAreaHeight + bottomPadding) / 2.0
      
      // when card view top constraint value is equal to this,
      // the dimmer view alpha is lightest (0.0)
      let noDimPosition = safeAreaHeight + bottomPadding
      
      // if card view top constraint is lesser than fullDimPosition
      // it is dimmest
      if value < fullDimPosition {
        return fullDimAlpha
      }
      
      // if card view top constraint is more than noDimPosition
      // it is dimmest
      if value > noDimPosition {
        return 0.0
      }
      
      // else return an alpha value in between 0.0 and 0.7 based on the top constraint value
      return fullDimAlpha * 1 - ((value - fullDimPosition) / fullDimPosition)
    }
    
    // this function will be called when user pan/drag the view
    @IBAction func viewPanned(_ panRecognizer: UIPanGestureRecognizer) {
        let velocity = panRecognizer.velocity(in: self.view)
         let translation = panRecognizer.translation(in: self.view)
         
         switch panRecognizer.state {
         case .began:
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
           
         case .changed:
           if self.cardPanStartingTopConstraint + translation.y > 30.0 {
             self.cardViewTopConstraint.constant = self.cardPanStartingTopConstraint + translation.y
           }
           
           // change the dimmer view alpha based on how much user has dragged
           dimmerView.alpha = dimAlphaWithCardTopConstraint(value: self.cardViewTopConstraint.constant)

         case .ended:
           if velocity.y > 1500.0 {
             hideCardAndGoBack()
             return
           }
           
           if let safeAreaHeight = UIApplication.shared.keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,
             let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
             
             if self.cardViewTopConstraint.constant < (safeAreaHeight + bottomPadding) * 0.25 {
               showCard(atState: .expanded)
             } else if self.cardViewTopConstraint.constant < (safeAreaHeight) - 70 {
               showCard(atState: .normal)
             } else {
               hideCardAndGoBack()
             }
           }
         default:
           break
         }
    }
    
    private func hideCardAndGoBack() {
        
      // ensure there's no pending layout changes before animation runs
      self.view.layoutIfNeeded()
      
      // set the new top constraint value for card view
      // card view won't move down just yet, we need to call layoutIfNeeded()
      // to tell the app to refresh the frame/position of card view
      if let safeAreaHeight = UIApplication.shared.keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,
        let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
        
        // move the card view to bottom of screen
        cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
      }
      
      // move card down to bottom
      // create a new property animator
      let hideCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
        self.view.layoutIfNeeded()
      })
      
      // hide dimmer view
      // this will animate the dimmerView alpha together with the card move down animation
      hideCard.addAnimations {
        self.dimmerView.alpha = 0.0
      }
      
      // when the animation completes, (position == .end means the animation has ended)
      // dismiss this view controller (if there is a presenting view controller)
      hideCard.addCompletion({ position in
        if position == .end {
          if(self.presentingViewController != nil) {
            self.dismiss(animated: false, completion: nil)
          }
        }
      })
      
      // run the animation
      hideCard.startAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)

      showCard()
    }

    private func showCard(atState: CardViewState = .normal) {

       
        // ensure there's no pending layout changes before animation runs
         self.view.layoutIfNeeded()
         
         // set the new top constraint value for card view
         // card view won't move up just yet, we need to call layoutIfNeeded()
         // to tell the app to refresh the frame/position of card view
         if let safeAreaHeight = UIApplication.shared.keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
           
           if atState == .expanded {
             // if state is expanded, top constraint is 30pt away from safe area top
             cardViewTopConstraint.constant = 30.0
           } else {
             cardViewTopConstraint.constant = (safeAreaHeight + bottomPadding) / 2.0
           }
           
           cardPanStartingTopConstraint = cardViewTopConstraint.constant
         }
         
         // move card up from bottom
         // create a new property animator
         let showCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
           self.view.layoutIfNeeded()
         })
         
         // show dimmer view
         // this will animate the dimmerView alpha together with the card move up animation
         showCard.addAnimations {
           self.dimmerView.alpha = 0.7
         }
         
         // run the animation
         showCard.startAnimation()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

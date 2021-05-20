//
//  CardViewController.swift
//  BottomCardView
//
//  Created by jylee-mac on 2021/05/20.
//

import UIKit

class CardViewController: UIViewController {
    
    //실제 화면이 보여질 뷰
    @IBOutlet weak var cardView: UIView!
    
    //배경 Dimming View
    @IBOutlet weak var dimmerView: UIView!
    
    //카드뷰의 상단 값
    @IBOutlet weak var cardViewTopConstraint: NSLayoutConstraint!
    
    //초기 State 값
    var cardViewState : CardViewState = .hidden
    
    //확장시 상단 간격값
    static let CARD_VIEW_TOP_MARGIN : CGFloat = 50.0 //기본값
    
    //card뷰 상단 간격값
    var cardPanStartingTopConstraint : CGFloat = CARD_VIEW_TOP_MARGIN
    
    //카드뷰 Show버튼 클릭
    @IBAction func ShowCardViewAction(_ sender: Any) {
        showCard(atState: .half)
    }
    
    //배경 DimmingView 선택시 CardView 닫기
    @IBAction func dimmerViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
        hideCardView()
    }
    
    //CardView 제스처 처리
    @IBAction func viewPanned(_ panRecognizer: UIPanGestureRecognizer) {
        let velocity = panRecognizer.velocity(in: self.view)
        let translation = panRecognizer.translation(in: self.view)
        
        switch panRecognizer.state {
        case .began: //현재 위치값
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
            
        case .changed: //변경 될때마다
            if self.cardPanStartingTopConstraint + translation.y > 30.0 {
                self.cardViewTopConstraint.constant = self.cardPanStartingTopConstraint + translation.y
            }
            
            // change the dimmer view alpha based on how much user has dragged
            dimmerView.alpha = dimAlphaWithCardTopConstraint(value: self.cardViewTopConstraint.constant)
            
        case .ended: //종료시
            if velocity.y > 1500.0 {
                hideCardView()
                return
            }
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            
            if let safeAreaHeight = keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,
               let bottomPadding = keyWindow?.safeAreaInsets.bottom
            {
                if self.cardViewTopConstraint.constant < (safeAreaHeight + bottomPadding) * 0.70 {
                    showCard(atState: .expanded)
                } else if self.cardViewTopConstraint.constant < (safeAreaHeight) - 70 {
                    showCard(atState: .half)
                } else {//사용하지 않는 조건이지만 만약을 위해서 추가함
                    hideCardView()
                }
            }
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    //화면 초기값 설정
    func initUI() {
        //초기값
        cardViewState = .hidden
        
        // 카드뷰 라운드 처리
        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 10.0
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        //초기 CardView 안보이도록 최대값 설정
        cardViewTopConstraint.constant =  CGFloat(cardView.bounds.height)
        
        // dimmerViewTapped() 제스처 추가
        let dimmerTap = UITapGestureRecognizer(target: self, action: #selector(dimmerViewTapped(_:)))
        dimmerView.addGestureRecognizer(dimmerTap)
        dimmerView.isUserInteractionEnabled = true
        dimmerView.alpha = 0.0
        
        // CardView 제스처 추가
        let viewPan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        viewPan.delaysTouchesBegan = false
        viewPan.delaysTouchesEnded = false
        self.view.addGestureRecognizer(viewPan)
    }
}

//카드View 속성처리
extension CardViewController {
    
    enum CardViewState {
        case hidden
        case expanded //확장 상태
        case half // 일반 상태
    }
    
    private func dimAlphaWithCardTopConstraint(value: CGFloat) -> CGFloat {
        let fullDimAlpha : CGFloat = 0.7
        
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        guard let safeAreaHeight = keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height, let bottomPadding = keyWindow?.safeAreaInsets.bottom else {
            return fullDimAlpha
        }
        
        let fullDimPosition = (safeAreaHeight + bottomPadding) / 2.0
        
        let noDimPosition = safeAreaHeight + bottomPadding
        
        if value < fullDimPosition {
            return fullDimAlpha
        }
        
        if value > noDimPosition {
            return 0.0
        }
        return fullDimAlpha * 1 - ((value - fullDimPosition) / fullDimPosition)
    }
    
    //Card뷰 Hidden 처리 함수
    private func hideCardView() {
        
        // ensure there's no pending layout changes before animation runs
        self.view.layoutIfNeeded()

        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            
        if let safeAreaHeight = keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height,  let bottomPadding = keyWindow?.safeAreaInsets.bottom
        {
            // move the card view to bottom of screen
            cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
        }

        // CardView 아래로 이동시 애니메이션
        let hideCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
            self.view.layoutIfNeeded()
        })
        
        // hide dimmer view
        hideCard.addAnimations {
            self.dimmerView.alpha = 0.0
        }
        
        //CardView hidden시 현재뷰컨트롤러 사라지도록 처리 (참고용)
        // when the animation completes, (position == .end means the animation has ended)
        // dismiss this view controller (if there is a presenting view controller)
        //        hideCard.addCompletion({ position in
        //            if position == .end {
        //                if(self.presentingViewController != nil) {
        //                    self.dismiss(animated: false, completion: nil)
        //                }
        //            }
        //        })
        
        cardViewState = .hidden //현재 State
        // start animation
        hideCard.startAnimation()
    }
    
    
    //카드 보이기
    //enum 클래스 .hidden .half .extension (기본값 .half)
    private func showCard(atState: CardViewState = .half) {
        
        //현재 뷰상태 처리
        cardViewState = atState
        //화면전화 에니메이션 전까지 대기
        self.view.layoutIfNeeded()

        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let safeAreaHeight = keyWindow?.safeAreaLayoutGuide.layoutFrame.size.height, let bottomPadding = keyWindow?.safeAreaInsets.bottom
        {
            if atState == .expanded {
                // if state is expanded, top constraint is 30pt away from safe area top
                cardViewTopConstraint.constant = CardViewController.CARD_VIEW_TOP_MARGIN
            } else if atState == .half {
                cardViewTopConstraint.constant = (safeAreaHeight + bottomPadding) / 2.0
            } else { //hidden
                cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
            }
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
        }
        
        // CardView 위로 이동시 애니메이션
        let showCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
            self.view.layoutIfNeeded()
        })
        
        // hide dimmer view
        showCard.addAnimations {
            self.dimmerView.alpha = 0.7
        }
        
        // start animation
        showCard.startAnimation()
    }
}

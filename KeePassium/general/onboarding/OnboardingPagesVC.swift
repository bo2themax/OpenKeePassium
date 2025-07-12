//  KeePassium Password Manager
//  Copyright © 2018–2024 KeePassium Labs <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import Foundation
import UIKit

final class OnboardingPagesVC: UIPageViewController {

    private var previousStandardAppearance: UINavigationBarAppearance?
    private var previousScrollEdgeAppearance: UINavigationBarAppearance?
    private var previousCompactAppearance: UINavigationBarAppearance?
    private var previousIsTranslucent: Bool?

    private lazy var pages: [UIViewController] = steps.map {
        let vc = OnboardingStepVC.instantiateFromStoryboard()
        vc.step = $0
        return vc
    }

    private var currentIndex: Int? {
        viewControllers?.first.flatMap { pages.firstIndex(of: $0) }
    }

    private let steps: [OnboardingStep]

    public var currentStep: OnboardingStep? {
        guard let currentIndex else {
            return nil
        }
        return steps[currentIndex]
    }

    public var canSkipRemainingSteps: Bool {
        let remainingSteps = steps.suffix(from: currentIndex ?? 0)
        return remainingSteps.allSatisfy { $0.canSkip }
    }

    public var onStateUpdate: ((OnboardingPagesVC) -> Void)?

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = steps.count
        pageControl.backgroundStyle = .minimal
        pageControl.currentPageIndicatorTintColor = .actionTint
        pageControl.pageIndicatorTintColor = .secondaryLabel
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.isAccessibilityElement = false
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()

    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(systemItem: .close, primaryAction: UIAction {
            [weak self] _ in self?.dismiss(animated: true)
        })
        return button
    }()

    init(steps: [OnboardingStep]) {
        self.steps = steps
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = ImageAsset.backgroundPattern.asColor()

        dataSource = self
        delegate = self

        view.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 20),
        ])

        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navBar = navigationController?.navigationBar {
            previousStandardAppearance = navBar.standardAppearance.copy()
            previousScrollEdgeAppearance = navBar.scrollEdgeAppearance?.copy()
            previousCompactAppearance = navBar.compactAppearance?.copy()
            previousIsTranslucent = navBar.isTranslucent

            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance
            navBar.isTranslucent = true
        }

        updateControls()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navBar = navigationController?.navigationBar {
            if let previousStandardAppearance {
                navBar.standardAppearance = previousStandardAppearance
            }
            if let previousScrollEdgeAppearance {
                navBar.scrollEdgeAppearance = previousScrollEdgeAppearance
            }
            if let previousCompactAppearance {
                navBar.compactAppearance = previousCompactAppearance
            }
            if let previousIsTranslucent {
                navBar.isTranslucent = previousIsTranslucent
            }
        }
    }

    private func updateControls() {
        let index = currentIndex ?? 0
        pageControl.currentPage = index
        navigationItem.setLeftBarButton(canSkipRemainingSteps ? closeButton : nil, animated: true)
        onStateUpdate?(self)
    }
}

extension OnboardingPagesVC: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        updateControls()
    }
}

extension OnboardingPagesVC: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else {
            return nil
        }

        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }

        return pages[previousIndex]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController?
    {
        guard let currentIndex = pages.firstIndex(of: viewController),
              steps[currentIndex].canSkip
        else {
            return nil
        }

        let nextIndex = currentIndex + 1
        guard nextIndex < pages.count else {
            return nil
        }
        return pages[nextIndex]
    }

    @discardableResult
    func showNext() -> Bool {
        guard let currentIndex = currentIndex,
              currentIndex + 1 < pages.count
        else {
            return false
        }

        setViewControllers([pages[currentIndex + 1]], direction: .forward, animated: true) { [weak self] _ in
            self?.updateControls()
        }
        return true
    }
}

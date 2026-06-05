//
//  UserInfoSetupViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2026/5/4.
//

import UIKit

final class SexSettingsViewController: UIViewController {

    private enum Gender {
        case male
        case female
    }

    private let headerView = HeaderGradientView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let maleButton = UIButton(type: .system)
    private let femaleButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private let progressLabel = UILabel()
    private let headlineLabel = UILabel()

    private var selectedGender: Gender = .female {
        didSet { updateSelectionUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        updateSelectionUI()
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "user_info_skip".localized(),
            style: .plain,
            target: self,
            action: #selector(skipTapped)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupHeader()
        setupCard()
        setupCardContent()
        setupBottomButton()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 360)
        ])

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        progressTrack.layer.cornerRadius = 2
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressTrack)

        progressFill.backgroundColor = .white
        progressFill.layer.cornerRadius = 2
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        progressLabel.text = "1/5"
        progressLabel.textColor = .white
        progressLabel.font = .systemFont(ofSize: 32, weight: .medium)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)

        headlineLabel.text = "user_info_start_title".localized()
        headlineLabel.textColor = .white
        headlineLabel.font = .italicSystemFont(ofSize: 40)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headlineLabel)

        NSLayoutConstraint.activate([
            progressTrack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 26),
            progressTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            progressTrack.widthAnchor.constraint(equalToConstant: 220),
            progressTrack.heightAnchor.constraint(equalToConstant: 6),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 0.2),

            progressLabel.leadingAnchor.constraint(equalTo: progressTrack.trailingAnchor, constant: 16),
            progressLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),

            headlineLabel.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            headlineLabel.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 24)
        ])
    }

    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 32
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -32),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCardContent() {
        titleLabel.text = "user_info_gender_title".localized()
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.text = "user_info_gender_subtitle".localized()
        subtitleLabel.textColor = UIColor(white: 0.23, alpha: 1.0)
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        configureOptionButton(maleButton, title: "mine_male".localized(), symbolName: "mars")
        configureOptionButton(femaleButton, title: "mine_female".localized(), symbolName: "venus")
        maleButton.addTarget(self, action: #selector(selectMale), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(selectFemale), for: .touchUpInside)

        let optionsStack = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        optionsStack.axis = .vertical
        optionsStack.spacing = 22
        optionsStack.alignment = .center
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(optionsStack)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            optionsStack.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            optionsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 74),

            maleButton.widthAnchor.constraint(equalToConstant: 182),
            maleButton.heightAnchor.constraint(equalToConstant: 68),
            femaleButton.widthAnchor.constraint(equalToConstant: 182),
            femaleButton.heightAnchor.constraint(equalToConstant: 68)
        ])
    }

    private func setupBottomButton() {
        nextButton.setTitle("user_info_next".localized(), for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
        nextButton.backgroundColor = UIColor.brand
        nextButton.layer.cornerRadius = 28
        nextButton.layer.shadowColor = UIColor.brand.withAlphaComponent(0.5).cgColor
        nextButton.layer.shadowOpacity = 0.35
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configureOptionButton(_ button: UIButton, title: String, symbolName: String) {
        button.layer.cornerRadius = 34
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.tintColor = .white
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.semanticContentAttribute = .forceLeftToRight
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -12, bottom: 0, right: 12)
    }

    private func updateSelectionUI() {
        applyStyle(button: maleButton, selected: selectedGender == .male)
        applyStyle(button: femaleButton, selected: selectedGender == .female)
    }

    private func applyStyle(button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = UIColor.brand
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
        } else {
            button.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
            button.setTitleColor(UIColor(white: 0.15, alpha: 1.0), for: .normal)
            button.tintColor = UIColor(white: 0.2, alpha: 1.0)
        }
    }

    @objc private func selectMale() {
        selectedGender = .male
    }

    @objc private func selectFemale() {
        selectedGender = .female
    }

    @objc private func skipTapped() {
        // Skip to main app
        navigateToMainApp()
    }

    @objc private func nextTapped() {
        let vc = AgeSettingsViewController()
        vc.selectedGender = selectedGender == .male ? 0 : 1 // 0 for male, 1 for female
        navigationController?.pushViewController(vc, animated: true)
    }

    private func navigateToMainApp() {
        // Dismiss the setup flow
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
        } else {
            // Fallback to main app
            if let tabBarController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 0
            }
        }
    }
}

final class AgeSettingsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    private let headerView = HeaderGradientView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private let progressLabel = UILabel()
    private let headlineLabel = UILabel()
    private let pickerContainer = UIView()
    private let pickerView = UIPickerView()
    private let backCircleButton = UIButton(type: .system)
    private let clockDecoration = ClockDecorationView()

    private let months = Calendar.current.monthSymbols
    private let days = Array(1...31)
    private let years = Array(1950...2026)
    private let ages = Array(10...100)

    var selectedGender: Int = 1 // 0 male, 1 female
    var selectedAge: Int = 18

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "user_info_skip".localized(),
            style: .plain,
            target: self,
            action: #selector(skipTapped)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupHeader()
        setupCard()
        setupContent()
        setupBottomButton()
        // 设置默认选择为18岁（索引8，对应10-100中的第9个元素）
        pickerView.selectRow(8, inComponent: 0, animated: false)
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 360)
        ])

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        progressTrack.layer.cornerRadius = 2
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressTrack)

        progressFill.backgroundColor = .white
        progressFill.layer.cornerRadius = 2
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        progressLabel.text = "2/5"
        progressLabel.textColor = .white
        progressLabel.font = .systemFont(ofSize: 32, weight: .medium)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)

        headlineLabel.text = "user_info_continue_title".localized()
        headlineLabel.textColor = .white
        headlineLabel.font = .italicSystemFont(ofSize: 38)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headlineLabel)

        clockDecoration.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(clockDecoration)

        backCircleButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backCircleButton.tintColor = .white
        backCircleButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        backCircleButton.layer.cornerRadius = 22
        backCircleButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backCircleButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backCircleButton)

        NSLayoutConstraint.activate([
            progressTrack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 26),
            progressTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            progressTrack.widthAnchor.constraint(equalToConstant: 220),
            progressTrack.heightAnchor.constraint(equalToConstant: 6),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 0.4),

            progressLabel.leadingAnchor.constraint(equalTo: progressTrack.trailingAnchor, constant: 16),
            progressLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),

            headlineLabel.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            headlineLabel.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 24),

            clockDecoration.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 26),
            clockDecoration.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4),
            clockDecoration.widthAnchor.constraint(equalToConstant: 220),
            clockDecoration.heightAnchor.constraint(equalToConstant: 220),

            backCircleButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 22),
            backCircleButton.centerYAnchor.constraint(equalTo: clockDecoration.centerYAnchor, constant: 18),
            backCircleButton.widthAnchor.constraint(equalToConstant: 44),
            backCircleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 32
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -32),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupContent() {
        titleLabel.text = "user_info_age_title".localized()
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.text = "user_info_age_subtitle".localized()
        subtitleLabel.textColor = UIColor(white: 0.23, alpha: 1.0)
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        pickerContainer.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        pickerContainer.layer.cornerRadius = 12
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(pickerContainer)

        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerContainer.addSubview(pickerView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            pickerContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            pickerContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            pickerContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 74),
            pickerContainer.heightAnchor.constraint(equalToConstant: 210),

            pickerView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: pickerContainer.topAnchor),
            pickerView.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor)
        ])
    }

    private func setupBottomButton() {
        nextButton.setTitle("user_info_next".localized(), for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
        nextButton.backgroundColor = UIColor.brand
        nextButton.layer.cornerRadius = 28
        nextButton.layer.shadowColor = UIColor.brand.withAlphaComponent(0.5).cgColor
        nextButton.layer.shadowOpacity = 0.35
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ages.count
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.bounds.width
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        44
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = String(ages[row])

        return NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                .foregroundColor: UIColor(white: 0.18, alpha: 1.0)
            ]
        )
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedAge = ages[row]
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func skipTapped() {
        navigateToMainApp()
    }

    @objc private func nextTapped() {
        selectedAge = ages[pickerView.selectedRow(inComponent: 0)]
        let vc = HeightSettingsViewController()
        vc.selectedGender = selectedGender
        vc.selectedAge = selectedAge
        navigationController?.pushViewController(vc, animated: true)
    }

    private func navigateToMainApp() {
        // If this flow was presented modally, dismiss it.
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
            return
        }

        // Otherwise replace the root with the main tab bar controller.
        if let window = UIApplication.shared.windows.first {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "MTabBarController")
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}
final class HeightSettingsViewController: UIViewController {

    private let headerView = HeaderGradientView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private let progressLabel = UILabel()
    private let headlineLabel = UILabel()
    private let backCircleButton = UIButton(type: .system)
    private let heightLabel = UILabel()
    private let unitLabel = UILabel()
    private let valueLabel = UILabel()
    private let pointerLabel = UILabel()
    private let scaleView = HeightScaleView()
    private let headerDecoration = HeightHeaderDecorationView()
    private let selectorViewport = UIView()
    private var selectedHeight: Int = 170 {
        didSet {
            valueLabel.text = "\(selectedHeight)"
        }
    }

    var selectedGender: Int = 1
    var selectedAge: Int = 18

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "user_info_skip".localized(),
            style: .plain,
            target: self,
            action: #selector(skipTapped)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupHeader()
        setupCard()
        setupBottomButton()
        setupContent()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 360)
        ])

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        progressTrack.layer.cornerRadius = 2
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressTrack)

        progressFill.backgroundColor = .white
        progressFill.layer.cornerRadius = 2
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        progressLabel.text = "3/5"
        progressLabel.textColor = .white
        progressLabel.font = .systemFont(ofSize: 32, weight: .medium)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)

        headlineLabel.text = "user_info_keep_it_up".localized()
        headlineLabel.textColor = .white
        headlineLabel.font = .italicSystemFont(ofSize: 38)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headlineLabel)

        headerDecoration.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerDecoration)

        backCircleButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backCircleButton.tintColor = .white
        backCircleButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        backCircleButton.layer.cornerRadius = 22
        backCircleButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backCircleButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backCircleButton)

        NSLayoutConstraint.activate([
            progressTrack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 26),
            progressTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            progressTrack.widthAnchor.constraint(equalToConstant: 220),
            progressTrack.heightAnchor.constraint(equalToConstant: 6),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 0.6),

            progressLabel.leadingAnchor.constraint(equalTo: progressTrack.trailingAnchor, constant: 16),
            progressLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),

            headlineLabel.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            headlineLabel.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 24),

            headerDecoration.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 10),
            headerDecoration.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4),
            headerDecoration.widthAnchor.constraint(equalToConstant: 220),
            headerDecoration.heightAnchor.constraint(equalToConstant: 230),

            backCircleButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 22),
            backCircleButton.centerYAnchor.constraint(equalTo: headerDecoration.centerYAnchor, constant: 18),
            backCircleButton.widthAnchor.constraint(equalToConstant: 44),
            backCircleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 32
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -32),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupContent() {
        titleLabel.text = "user_info_height_title".localized()
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.text = "user_info_height_subtitle".localized()
        subtitleLabel.textColor = UIColor(white: 0.23, alpha: 1.0)
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        heightLabel.text = "mine_height".localized()
        heightLabel.font = .systemFont(ofSize: 36, weight: .medium)
        heightLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        heightLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(heightLabel)

        unitLabel.text = "(\("mine_cm_unit".localized()))"
        unitLabel.font = .systemFont(ofSize: 28, weight: .regular)
        unitLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(unitLabel)

        valueLabel.text = "\(selectedHeight)"
        valueLabel.font = .systemFont(ofSize: 74, weight: .bold)
        valueLabel.textColor = .black
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(valueLabel)

        selectorViewport.clipsToBounds = true
        selectorViewport.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(selectorViewport)

        scaleView.selectedValue = selectedHeight
        scaleView.onValueChanged = { [weak self] value in
            self?.selectedHeight = value
        }
        scaleView.translatesAutoresizingMaskIntoConstraints = false
        selectorViewport.addSubview(scaleView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            selectorViewport.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            selectorViewport.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -18),
            selectorViewport.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            selectorViewport.widthAnchor.constraint(equalToConstant: 120),

            scaleView.leadingAnchor.constraint(equalTo: selectorViewport.leadingAnchor),
            scaleView.trailingAnchor.constraint(equalTo: selectorViewport.trailingAnchor),
            scaleView.topAnchor.constraint(equalTo: selectorViewport.topAnchor),
            scaleView.bottomAnchor.constraint(equalTo: selectorViewport.bottomAnchor),

            heightLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 60),
            heightLabel.topAnchor.constraint(equalTo: selectorViewport.centerYAnchor, constant: -66),

            unitLabel.leadingAnchor.constraint(equalTo: heightLabel.trailingAnchor, constant: 8),
            unitLabel.firstBaselineAnchor.constraint(equalTo: heightLabel.firstBaselineAnchor),

            valueLabel.leadingAnchor.constraint(equalTo: heightLabel.leadingAnchor),
            valueLabel.topAnchor.constraint(equalTo: heightLabel.bottomAnchor, constant: 8)
        ])
    }

    private func setupBottomButton() {
        nextButton.setTitle("user_info_next".localized(), for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
        nextButton.backgroundColor = UIColor.brand
        nextButton.layer.cornerRadius = 28
        nextButton.layer.shadowColor = UIColor.brand.withAlphaComponent(0.5).cgColor
        nextButton.layer.shadowOpacity = 0.35
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func skipTapped() {
        navigateToMainApp()
    }

    @objc private func nextTapped() {
        let vc = WeightSettingsViewController()
        vc.selectedGender = selectedGender
        vc.selectedAge = selectedAge
        vc.selectedHeight = selectedHeight
        navigationController?.pushViewController(vc, animated: true)
    }

    private func navigateToMainApp() {
        // If this flow was presented modally, dismiss it.
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
            return
        }

        // Otherwise replace the root with the main tab bar controller.
        if let window = UIApplication.shared.windows.first {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "MTabBarController")
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}

final class WeightSettingsViewController: UIViewController {

    private let headerView = HeaderGradientView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private let progressLabel = UILabel()
    private let headlineLabel = UILabel()
    private let backCircleButton = UIButton(type: .system)
    private let weightLabel = UILabel()
    private let unitLabel = UILabel()
    private let valueLabel = UILabel()
    private let pointerLabel = UILabel()
    private let headerDecoration = WeightHeaderDecorationView()
    private let scaleViewport = UIView()
    private let scaleView = WeightScaleView()
    private let selectorAreaGuide = UILayoutGuide()
    private var selectedWeight: Double = 65.0 {
        didSet {
            valueLabel.text = String(format: "%.1f", selectedWeight)
        }
    }

    var selectedGender: Int = 1
    var selectedAge: Int = 18
    var selectedHeight: Int = 170

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "user_info_skip".localized(),
            style: .plain,
            target: self,
            action: #selector(skipTapped)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupHeader()
        setupCard()
        setupBottomButton()
        setupContent()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 360)
        ])

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        progressTrack.layer.cornerRadius = 2
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressTrack)

        progressFill.backgroundColor = .white
        progressFill.layer.cornerRadius = 2
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        progressLabel.text = "4/5"
        progressLabel.textColor = .white
        progressLabel.font = .systemFont(ofSize: 32, weight: .medium)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)

        headlineLabel.text = "user_info_keep_it_up".localized()
        headlineLabel.textColor = .white
        headlineLabel.font = .italicSystemFont(ofSize: 44)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headlineLabel)

        headerDecoration.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerDecoration)

        backCircleButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backCircleButton.tintColor = .white
        backCircleButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        backCircleButton.layer.cornerRadius = 22
        backCircleButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backCircleButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backCircleButton)

        NSLayoutConstraint.activate([
            progressTrack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 26),
            progressTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            progressTrack.widthAnchor.constraint(equalToConstant: 220),
            progressTrack.heightAnchor.constraint(equalToConstant: 6),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 0.8),

            progressLabel.leadingAnchor.constraint(equalTo: progressTrack.trailingAnchor, constant: 16),
            progressLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),

            headlineLabel.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            headlineLabel.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 24),

            headerDecoration.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 8),
            headerDecoration.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4),
            headerDecoration.widthAnchor.constraint(equalToConstant: 230),
            headerDecoration.heightAnchor.constraint(equalToConstant: 230),

            backCircleButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 22),
            backCircleButton.centerYAnchor.constraint(equalTo: headerDecoration.centerYAnchor, constant: 18),
            backCircleButton.widthAnchor.constraint(equalToConstant: 44),
            backCircleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 32
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -32),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBottomButton() {
        nextButton.setTitle("user_info_next".localized(), for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
        nextButton.backgroundColor = UIColor.brand
        nextButton.layer.cornerRadius = 28
        nextButton.layer.shadowColor = UIColor.brand.withAlphaComponent(0.5).cgColor
        nextButton.layer.shadowOpacity = 0.35
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupContent() {
        titleLabel.text = "user_info_weight_title".localized()
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.text = "user_info_weight_subtitle".localized()
        subtitleLabel.textColor = UIColor(white: 0.23, alpha: 1.0)
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        weightLabel.text = "mine_weight".localized()
        weightLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        weightLabel.font = .systemFont(ofSize: 30, weight: .medium)
        weightLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(weightLabel)

        unitLabel.text = "(\("mine_kg_unit".localized()))"
        unitLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        unitLabel.font = .systemFont(ofSize: 22, weight: .regular)
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(unitLabel)

        valueLabel.text = String(format: "%.1f", selectedWeight)
        valueLabel.textColor = .black
        valueLabel.font = .systemFont(ofSize: 74, weight: .bold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(valueLabel)

        pointerLabel.text = "▼"
        pointerLabel.textColor = UIColor(red: 0.09, green: 0.92, blue: 0.91, alpha: 1.0)
        pointerLabel.font = .systemFont(ofSize: 22, weight: .bold)
        pointerLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(pointerLabel)

        scaleViewport.clipsToBounds = true
        scaleViewport.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(scaleViewport)
        cardView.addLayoutGuide(selectorAreaGuide)

        scaleView.selectedValue = selectedWeight
        scaleView.onValueChanged = { [weak self] value in
            self?.selectedWeight = value
        }
        scaleView.translatesAutoresizingMaskIntoConstraints = false
        scaleViewport.addSubview(scaleView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            selectorAreaGuide.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            selectorAreaGuide.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -18),
            selectorAreaGuide.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            selectorAreaGuide.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            valueLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: selectorAreaGuide.centerYAnchor, constant: -34),

            weightLabel.trailingAnchor.constraint(equalTo: valueLabel.centerXAnchor, constant: -8),
            weightLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.topAnchor, constant: -28),

            unitLabel.leadingAnchor.constraint(equalTo: weightLabel.trailingAnchor, constant: 8),
            unitLabel.firstBaselineAnchor.constraint(equalTo: weightLabel.firstBaselineAnchor),

            pointerLabel.centerXAnchor.constraint(equalTo: valueLabel.centerXAnchor),
            pointerLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 12),

            scaleViewport.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 0),
            scaleViewport.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 0),
            scaleViewport.topAnchor.constraint(equalTo: pointerLabel.bottomAnchor, constant: 10),
            scaleViewport.heightAnchor.constraint(equalToConstant: 128),
            scaleViewport.centerYAnchor.constraint(equalTo: selectorAreaGuide.centerYAnchor, constant: 80),

            scaleView.leadingAnchor.constraint(equalTo: scaleViewport.leadingAnchor),
            scaleView.trailingAnchor.constraint(equalTo: scaleViewport.trailingAnchor),
            scaleView.topAnchor.constraint(equalTo: scaleViewport.topAnchor),
            scaleView.bottomAnchor.constraint(equalTo: scaleViewport.bottomAnchor)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func skipTapped() {
        navigateToMainApp()
    }

    @objc private func nextTapped() {
        let vc = StepLengthSettingsViewController()
        vc.selectedGender = selectedGender
        vc.selectedAge = selectedAge
        vc.selectedHeight = selectedHeight
        vc.selectedWeight = selectedWeight
        navigationController?.pushViewController(vc, animated: true)
    }

    private func navigateToMainApp() {
        // If this flow was presented modally, dismiss it.
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
            return
        }

        // Otherwise replace the root with the main tab bar controller.
        if let window = UIApplication.shared.windows.first {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "MTabBarController")
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}

final class StepLengthSettingsViewController: UIViewController {

    private let headerView = HeaderGradientView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private let progressLabel = UILabel()
    private let headlineLabel = UILabel()
    private let backCircleButton = UIButton(type: .system)
    private let stepLabel = UILabel()
    private let unitLabel = UILabel()
    private let valueLabel = UILabel()
    private let pointerLabel = UILabel()
    private let headerDecoration = StepLengthHeaderDecorationView()
    private let scaleViewport = UIView()
    private let scaleView = StepLengthScaleView()
    private let selectorAreaGuide = UILayoutGuide()
    private let stepLineGuide = UILayoutGuide()
    private var selectedStepLength: Int = 80 {
        didSet {
            valueLabel.text = "\(selectedStepLength)"
        }
    }

    var selectedGender: Int = 1
    var selectedAge: Int = 18
    var selectedHeight: Int = 170
    var selectedWeight: Double = 65.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "user_info_skip".localized(),
            style: .plain,
            target: self,
            action: #selector(skipTapped)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupHeader()
        setupCard()
        setupBottomButton()
        setupContent()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 360)
        ])

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        progressTrack.layer.cornerRadius = 2
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressTrack)

        progressFill.backgroundColor = .white
        progressFill.layer.cornerRadius = 2
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        progressLabel.text = "5/5"
        progressLabel.textColor = .white
        progressLabel.font = .systemFont(ofSize: 32, weight: .medium)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressLabel)

        headlineLabel.text = "user_info_awesome".localized()
        headlineLabel.textColor = .white
        headlineLabel.font = .italicSystemFont(ofSize: 44)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headlineLabel)

        headerDecoration.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerDecoration)

        backCircleButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backCircleButton.tintColor = .white
        backCircleButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        backCircleButton.layer.cornerRadius = 22
        backCircleButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backCircleButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backCircleButton)

        NSLayoutConstraint.activate([
            progressTrack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 26),
            progressTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),
            progressTrack.widthAnchor.constraint(equalToConstant: 220),
            progressTrack.heightAnchor.constraint(equalToConstant: 6),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 1.0),

            progressLabel.leadingAnchor.constraint(equalTo: progressTrack.trailingAnchor, constant: 16),
            progressLabel.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),

            headlineLabel.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            headlineLabel.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 24),

            headerDecoration.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 10),
            headerDecoration.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            headerDecoration.widthAnchor.constraint(equalToConstant: 250),
            headerDecoration.heightAnchor.constraint(equalToConstant: 220),

            backCircleButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 22),
            backCircleButton.centerYAnchor.constraint(equalTo: headerDecoration.centerYAnchor, constant: 12),
            backCircleButton.widthAnchor.constraint(equalToConstant: 44),
            backCircleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 32
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -32),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBottomButton() {
        nextButton.setTitle("user_info_done".localized(), for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
        nextButton.backgroundColor = UIColor.brand
        nextButton.layer.cornerRadius = 28
        nextButton.layer.shadowColor = UIColor.brand.cgColor
        nextButton.layer.shadowOpacity = 0.35
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupContent() {
        titleLabel.text = "user_info_step_length_title".localized()
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        subtitleLabel.text = "user_info_step_length_subtitle".localized()
        subtitleLabel.textColor = UIColor(white: 0.23, alpha: 1.0)
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        stepLabel.text = "user_info_step_length".localized()
        stepLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        stepLabel.font = .systemFont(ofSize: 32, weight: .medium)
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stepLabel)

        unitLabel.text = "(\("mine_cm_unit".localized()))"
        unitLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        unitLabel.font = .systemFont(ofSize: 30, weight: .regular)
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(unitLabel)

        valueLabel.text = "\(selectedStepLength)"
        valueLabel.textColor = .black
        valueLabel.font = .systemFont(ofSize: 74, weight: .bold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(valueLabel)

        pointerLabel.text = "▼"
        pointerLabel.textColor = UIColor(red: 0.09, green: 0.92, blue: 0.91, alpha: 1.0)
        pointerLabel.font = .systemFont(ofSize: 22, weight: .bold)
        pointerLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(pointerLabel)

        scaleViewport.clipsToBounds = true
        scaleViewport.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(scaleViewport)
        cardView.addLayoutGuide(selectorAreaGuide)
        cardView.addLayoutGuide(stepLineGuide)

        scaleView.selectedValue = selectedStepLength
        scaleView.onValueChanged = { [weak self] value in
            self?.selectedStepLength = value
        }
        scaleView.translatesAutoresizingMaskIntoConstraints = false
        scaleViewport.addSubview(scaleView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            selectorAreaGuide.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            selectorAreaGuide.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -18),
            selectorAreaGuide.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            selectorAreaGuide.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            valueLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: selectorAreaGuide.centerYAnchor, constant: -34),

            stepLineGuide.centerXAnchor.constraint(equalTo: valueLabel.centerXAnchor),
            stepLineGuide.topAnchor.constraint(equalTo: valueLabel.topAnchor, constant: -28),
            stepLineGuide.heightAnchor.constraint(equalToConstant: 40),

            stepLabel.leadingAnchor.constraint(equalTo: stepLineGuide.leadingAnchor),
            stepLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.topAnchor, constant: -28),

            unitLabel.leadingAnchor.constraint(equalTo: stepLabel.trailingAnchor, constant: 8),
            unitLabel.firstBaselineAnchor.constraint(equalTo: stepLabel.firstBaselineAnchor),
            unitLabel.trailingAnchor.constraint(equalTo: stepLineGuide.trailingAnchor),

            pointerLabel.centerXAnchor.constraint(equalTo: valueLabel.centerXAnchor),
            pointerLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 12),

            scaleViewport.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scaleViewport.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scaleViewport.topAnchor.constraint(equalTo: pointerLabel.bottomAnchor, constant: 10),
            scaleViewport.heightAnchor.constraint(equalToConstant: 128),
            scaleViewport.centerYAnchor.constraint(equalTo: selectorAreaGuide.centerYAnchor, constant: 80),

            scaleView.leadingAnchor.constraint(equalTo: scaleViewport.leadingAnchor),
            scaleView.trailingAnchor.constraint(equalTo: scaleViewport.trailingAnchor),
            scaleView.topAnchor.constraint(equalTo: scaleViewport.topAnchor),
            scaleView.bottomAnchor.constraint(equalTo: scaleViewport.bottomAnchor)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func skipTapped() {
        saveUserInfoAndNavigate()
    }

    @objc private func nextTapped() {
        saveUserInfoAndNavigate()
    }

    private func saveUserInfoAndNavigate() {
        // Save to UserDefaults
        let userInfo = [
            "gender": selectedGender,
            "age": selectedAge,
            "height": selectedHeight,
            "weight": selectedWeight,
            "stepLength": selectedStepLength
        ] as [String : Any]
        UserDefaults.standard.set(userInfo, forKey: "UserInfo")
        UserDefaults.standard.set(true, forKey: "UserInfoSet")
        
        // If this flow was presented modally, dismiss it.
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
            return
        }

        // Otherwise replace the root with the main tab bar controller.
        if let window = UIApplication.shared.windows.first {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "MTabBarController")
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}

// Supporting views and classes...

private final class HeaderGradientView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let lineLayerOne = CAShapeLayer()
    private let lineLayerTwo = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        drawDecorativeLines()
    }

    private func setupLayers() {
        // 使用 brand 主色创建渐变，从品牌蓝色到白色
        let brandColor = UIColor.brand
        let whiteColor = UIColor.white
        
        gradientLayer.colors = [
            brandColor.cgColor,
            whiteColor.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)

        [lineLayerOne, lineLayerTwo].forEach { layer in
            layer.strokeColor = UIColor.brand.withAlphaComponent(0.3).cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 2
            gradientLayer.addSublayer(layer)
        }
    }

    private func drawDecorativeLines() {
        let pathOne = UIBezierPath()
        pathOne.move(to: CGPoint(x: bounds.width * 0.55, y: bounds.height))
        pathOne.addCurve(
            to: CGPoint(x: bounds.width, y: bounds.height * 0.42),
            controlPoint1: CGPoint(x: bounds.width * 0.80, y: bounds.height * 0.84),
            controlPoint2: CGPoint(x: bounds.width * 0.90, y: bounds.height * 0.60)
        )
        lineLayerOne.path = pathOne.cgPath

        let pathTwo = UIBezierPath()
        pathTwo.move(to: CGPoint(x: bounds.width * 0.48, y: bounds.height))
        pathTwo.addCurve(
            to: CGPoint(x: bounds.width, y: bounds.height * 0.36),
            controlPoint1: CGPoint(x: bounds.width * 0.76, y: bounds.height * 0.83),
            controlPoint2: CGPoint(x: bounds.width * 0.88, y: bounds.height * 0.53)
        )
        lineLayerTwo.path = pathTwo.cgPath
    }
}

private final class ClockDecorationView: UIView {

    private let ringLayer = CAShapeLayer()
    private let handLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawClock()
    }

    private func setupLayers() {
        ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 2.5
        layer.addSublayer(ringLayer)

        handLayer.strokeColor = UIColor.white.cgColor
        handLayer.fillColor = UIColor.clear.cgColor
        handLayer.lineWidth = 3
        handLayer.lineCap = .round
        layer.addSublayer(handLayer)
    }

    private func drawClock() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.40
        let ringPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        ringLayer.path = ringPath.cgPath

        let handPath = UIBezierPath()
        handPath.move(to: center)
        handPath.addLine(to: CGPoint(x: center.x - 18, y: center.y - 56))
        handPath.move(to: center)
        handPath.addLine(to: CGPoint(x: center.x + 28, y: center.y + 10))
        handLayer.path = handPath.cgPath
    }
}

private final class HeightHeaderDecorationView: UIView {

    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawLines()
    }

    private func setup() {
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.85).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1.6
        layer.addSublayer(shapeLayer)
    }

    private func drawLines() {
        let path = UIBezierPath()
        for index in 0...18 {
            let x = bounds.width - CGFloat(index) * 10
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        }
        shapeLayer.path = path.cgPath
    }
}

private final class HeightScaleView: UIView {

    private let ticksLayer = CAShapeLayer()
    private let highlightLayer = CAShapeLayer()
    private var textLayers: [CATextLayer] = []
    private let minValue: CGFloat = 100
    private let maxValue: CGFloat = 230
    private var storedSelectedValue: Int = 171
    var selectedValue: Int {
        get { storedSelectedValue }
        set {
            let clamped = min(max(newValue, Int(minValue)), Int(maxValue))
            guard clamped != storedSelectedValue else { return }
            storedSelectedValue = clamped
            setNeedsLayout()
            onValueChanged?(storedSelectedValue)
        }
    }
    var onValueChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawScale()
    }

    private func setup() {
        ticksLayer.strokeColor = UIColor(white: 0.82, alpha: 1).cgColor
        ticksLayer.fillColor = UIColor.clear.cgColor
        ticksLayer.lineWidth = 1.2
        layer.addSublayer(ticksLayer)

        highlightLayer.strokeColor = UIColor(red: 0.09, green: 0.92, blue: 0.91, alpha: 1.0).cgColor
        highlightLayer.fillColor = UIColor.clear.cgColor
        highlightLayer.lineWidth = 3
        layer.addSublayer(highlightLayer)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    private func drawScale() {
        let lineXStart: CGFloat = 0
        let lineXEnd: CGFloat = 52
        let fullPath = UIBezierPath()
        let spacing: CGFloat = 8
        let centerY = bounds.midY
        let labelX: CGFloat = 62

        for value in Int(minValue)...Int(maxValue) {
            let y = centerY + CGFloat(selectedValue - value) * spacing
            guard y >= -20, y <= bounds.height + 20 else { continue }
            let isMajor = value % 10 == 0
            let width: CGFloat = isMajor ? lineXEnd : 28
            fullPath.move(to: CGPoint(x: lineXStart, y: y))
            fullPath.addLine(to: CGPoint(x: width, y: y))
        }
        ticksLayer.path = fullPath.cgPath

        let highlightPath = UIBezierPath()
        highlightPath.move(to: CGPoint(x: lineXStart, y: centerY))
        highlightPath.addLine(to: CGPoint(x: lineXEnd, y: centerY))
        highlightLayer.path = highlightPath.cgPath

        textLayers.forEach { $0.removeFromSuperlayer() }
        textLayers.removeAll()
        for value in Int(minValue)...Int(maxValue) where value % 10 == 0 {
            let y = centerY + CGFloat(selectedValue - value) * spacing
            guard y >= -24, y <= bounds.height else { continue }
            let textLayer = CATextLayer()
            textLayer.string = "\(value)"
            textLayer.fontSize = 18
            textLayer.foregroundColor = UIColor(white: 0.26, alpha: 1.0).cgColor
            textLayer.alignmentMode = .left
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.frame = CGRect(x: labelX, y: y - 11, width: 56, height: 24)
            layer.addSublayer(textLayer)
            textLayers.append(textLayer)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let step = Int((-translation.y / 8).rounded())
        if step != 0 {
            selectedValue += step
            gesture.setTranslation(.zero, in: self)
        }
    }
}

private final class WeightHeaderDecorationView: UIView {

    private let ringLayer = CAShapeLayer()
    private let tickLayer = CAShapeLayer()
    private let needleLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawGauge()
    }

    private func setup() {
        ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 2
        layer.addSublayer(ringLayer)

        tickLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        tickLayer.fillColor = UIColor.clear.cgColor
        tickLayer.lineWidth = 2
        layer.addSublayer(tickLayer)

        needleLayer.strokeColor = UIColor.white.cgColor
        needleLayer.fillColor = UIColor.clear.cgColor
        needleLayer.lineWidth = 5
        needleLayer.lineCap = .round
        layer.addSublayer(needleLayer)
    }

    private func drawGauge() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY + 50)
        let radius = min(bounds.width, bounds.height) * 0.52
        let startAngle = CGFloat.pi
        let endAngle = CGFloat.pi * 2

        ringLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath

        let ticksPath = UIBezierPath()
        for idx in 0...30 {
            let angle = startAngle + (endAngle - startAngle) * CGFloat(idx) / 30
            let outer = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            let innerOffset: CGFloat = idx % 5 == 0 ? 18 : 10
            let inner = CGPoint(x: center.x + cos(angle) * (radius - innerOffset), y: center.y + sin(angle) * (radius - innerOffset))
            ticksPath.move(to: inner)
            ticksPath.addLine(to: outer)
        }
        tickLayer.path = ticksPath.cgPath

        let needlePath = UIBezierPath()
        needlePath.move(to: center)
        needlePath.addLine(to: CGPoint(x: center.x + 2, y: center.y - radius + 20))
        needleLayer.path = needlePath.cgPath
    }
}

private final class WeightScaleView: UIView {

    private let ticksLayer = CAShapeLayer()
    private let highlightLayer = CAShapeLayer()
    private var textLayers: [CATextLayer] = []
    private let minValue: Double = 10.0
    private let maxValue: Double = 200.0
    private var storedSelectedValue: Double = 60.0
    var selectedValue: Double {
        get { storedSelectedValue }
        set {
            let clamped = min(max(newValue, minValue), maxValue)
            guard abs(clamped - storedSelectedValue) >= 0.0001 else { return }
            storedSelectedValue = clamped
            setNeedsLayout()
            onValueChanged?(round(clamped * 10) / 10.0)
        }
    }
    var onValueChanged: ((Double) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawScale()
    }

    private func setup() {
        ticksLayer.strokeColor = UIColor(white: 0.84, alpha: 1.0).cgColor
        ticksLayer.fillColor = UIColor.clear.cgColor
        ticksLayer.lineWidth = 1.4
        layer.addSublayer(ticksLayer)

        highlightLayer.strokeColor = UIColor(red: 0.09, green: 0.92, blue: 0.91, alpha: 1.0).cgColor
        highlightLayer.fillColor = UIColor.clear.cgColor
        highlightLayer.lineWidth = 3
        layer.addSublayer(highlightLayer)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    private func drawScale() {
        textLayers.forEach { $0.removeFromSuperlayer() }
        textLayers.removeAll()

        let centerX = bounds.midX
        let spacingPerTenth: CGFloat = 12
        let baselineY = bounds.height * 0.52
        let path = UIBezierPath()
        let centerStep = Int((selectedValue * 10).rounded())
        let visibleRange = 70

        for offset in -visibleRange...visibleRange {
            let step = centerStep + offset
            let value = Double(step) / 10.0
            guard value >= minValue, value <= maxValue else { continue }
            let x = centerX + CGFloat(offset) * spacingPerTenth
            guard x >= -20, x <= bounds.width + 20 else { continue }

            let isInteger = step % 10 == 0
            let isHalf = step % 5 == 0
            let lineHeight: CGFloat
            if isInteger {
                lineHeight = 34
            } else if isHalf {
                lineHeight = 24
            } else {
                lineHeight = 14
            }
            path.move(to: CGPoint(x: x, y: baselineY - lineHeight))
            path.addLine(to: CGPoint(x: x, y: baselineY))

            if isInteger {
                let textLayer = CATextLayer()
                textLayer.string = "\(Int(value))"
                textLayer.fontSize = 14
                textLayer.foregroundColor = UIColor(white: 0.25, alpha: 1.0).cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.frame = CGRect(x: x - 24, y: baselineY + 6, width: 48, height: 20)
                layer.addSublayer(textLayer)
                textLayers.append(textLayer)
            }
        }

        ticksLayer.path = path.cgPath

        let highlight = UIBezierPath()
        highlight.move(to: CGPoint(x: centerX, y: baselineY - 38))
        highlight.addLine(to: CGPoint(x: centerX, y: baselineY + 2))
        highlightLayer.path = highlight.cgPath
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let delta = Double(-translation.x / 12) * 0.1
        if abs(delta) >= 0.1 {
            selectedValue += delta
            gesture.setTranslation(.zero, in: self)
        }
    }
}

private final class StepLengthHeaderDecorationView: UIView {

    private let lineLayer = CAShapeLayer()
    private let curveLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawDecoration()
    }

    private func setup() {
        lineLayer.strokeColor = UIColor.white.withAlphaComponent(0.72).cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2
        layer.addSublayer(lineLayer)

        curveLayer.strokeColor = UIColor.white.withAlphaComponent(0.45).cgColor
        curveLayer.fillColor = UIColor.clear.cgColor
        curveLayer.lineWidth = 2
        layer.addSublayer(curveLayer)
    }

    private func drawDecoration() {
        let lines = UIBezierPath()
        let count = 20
        for idx in 0..<count {
            let t = CGFloat(idx) / CGFloat(count - 1)
            let start = CGPoint(x: bounds.width * (0.08 + t * 0.9), y: bounds.height)
            let end = CGPoint(x: bounds.width * (0.58 + t * 0.48), y: bounds.height * (0.22 + t * 0.38))
            lines.move(to: start)
            lines.addLine(to: end)
        }
        lineLayer.path = lines.cgPath

        let curve = UIBezierPath()
        curve.move(to: CGPoint(x: bounds.width * 0.0, y: bounds.height * 0.88))
        curve.addCurve(
            to: CGPoint(x: bounds.width * 0.98, y: bounds.height * 0.55),
            controlPoint1: CGPoint(x: bounds.width * 0.28, y: bounds.height * 0.64),
            controlPoint2: CGPoint(x: bounds.width * 0.70, y: bounds.height * 0.88)
        )
        curveLayer.path = curve.cgPath
    }
}

private final class StepLengthScaleView: UIView {

    private let ticksLayer = CAShapeLayer()
    private let highlightLayer = CAShapeLayer()
    private var textLayers: [CATextLayer] = []
    private let minValue: Int = 40
    private let maxValue: Int = 120
    private var storedSelectedValue: Int = 80
    var selectedValue: Int {
        get { storedSelectedValue }
        set {
            let clamped = min(max(newValue, minValue), maxValue)
            guard clamped != storedSelectedValue else { return }
            storedSelectedValue = clamped
            setNeedsLayout()
            onValueChanged?(clamped)
        }
    }
    var onValueChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawScale()
    }

    private func setup() {
        ticksLayer.strokeColor = UIColor(white: 0.84, alpha: 1.0).cgColor
        ticksLayer.fillColor = UIColor.clear.cgColor
        ticksLayer.lineWidth = 1.4
        layer.addSublayer(ticksLayer)

        highlightLayer.strokeColor = UIColor(red: 0.09, green: 0.92, blue: 0.91, alpha: 1.0).cgColor
        highlightLayer.fillColor = UIColor.clear.cgColor
        highlightLayer.lineWidth = 3
        layer.addSublayer(highlightLayer)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    private func drawScale() {
        textLayers.forEach { $0.removeFromSuperlayer() }
        textLayers.removeAll()

        let centerX = bounds.midX
        let spacing: CGFloat = 24
        let baselineY = bounds.height * 0.52
        let path = UIBezierPath()
        let visibleRange = 14

        for offset in -visibleRange...visibleRange {
            let value = selectedValue + offset
            guard value >= minValue, value <= maxValue else { continue }
            let x = centerX + CGFloat(offset) * spacing
            guard x >= -20, x <= bounds.width + 20 else { continue }

            let isMajor = value % 10 == 0
            let lineHeight: CGFloat = isMajor ? 34 : 14
            path.move(to: CGPoint(x: x, y: baselineY - lineHeight))
            path.addLine(to: CGPoint(x: x, y: baselineY))

            if isMajor {
                let textLayer = CATextLayer()
                textLayer.string = "\(value)"
                textLayer.fontSize = 14
                textLayer.foregroundColor = UIColor(white: 0.25, alpha: 1.0).cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.frame = CGRect(x: x - 24, y: baselineY + 6, width: 48, height: 20)
                layer.addSublayer(textLayer)
                textLayers.append(textLayer)
            }
        }

        ticksLayer.path = path.cgPath

        let highlight = UIBezierPath()
        highlight.move(to: CGPoint(x: centerX, y: baselineY - 38))
        highlight.addLine(to: CGPoint(x: centerX, y: baselineY + 2))
        highlightLayer.path = highlight.cgPath
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let delta = Int((-translation.x / 24).rounded())
        if delta != 0 {
            selectedValue += delta
            gesture.setTranslation(.zero, in: self)
        }
    }
}
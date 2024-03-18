import UIKit

protocol DateRangeSelectorDelegate: AnyObject {
    func didSelectDateRange(startDate: Date, endDate: Date)
}

class DateRangeSelectorViewController: UIViewController {
    
    var startDate: Date?
    var endDate: Date?
    weak var delegate: DateRangeSelectorDelegate?
    
    let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    let endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupDatePickers()
        setupDoneButton()
    }
    
    private func setupDatePickers() {
        view.addSubview(startDatePicker)
        view.addSubview(endDatePicker)
        
        let dashLabel: UILabel = {
            let label = UILabel()
            label.text = "-"
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        view.addSubview(dashLabel)
        
        if let startDate = startDate {
            startDatePicker.date = startDate
        }
        if let endDate = endDate {
            endDatePicker.date = endDate
        }
        
        NSLayoutConstraint.activate([
            startDatePicker.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            startDatePicker.trailingAnchor.constraint(equalTo: dashLabel.leadingAnchor, constant: -10)
        ])
        
        NSLayoutConstraint.activate([
            dashLabel.topAnchor.constraint(equalTo: startDatePicker.topAnchor),
            dashLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dashLabel.centerYAnchor.constraint(equalTo: startDatePicker.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            endDatePicker.topAnchor.constraint(equalTo: startDatePicker.topAnchor),
            endDatePicker.leadingAnchor.constraint(equalTo: dashLabel.trailingAnchor, constant: 10)
        ])
    }
    
    private func setupDoneButton() {
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: endDatePicker.bottomAnchor, constant: 20),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func doneButtonTapped() {
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        guard startDate <= endDate else {
            let alert = UIAlertController(
                title: "Invalid Date Range",
                message: "End date must be after or equal to start date.", preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        
        delegate?.didSelectDateRange(startDate: startDate, endDate: endDate)
        
        dismiss(animated: true, completion: nil)
    }
}

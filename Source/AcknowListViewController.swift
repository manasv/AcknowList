//
// AcknowListViewController.swift
//
// Copyright (c) 2015-2016 Vincent Tourraine (http://www.vtourraine.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

/**
 Subclass of `UITableViewController` that displays a list of acknowledgements.
 */
public class AcknowListViewController: UITableViewController {

    /**
    The represented array of `Acknow`.
    */
    var acknowledgements: [Acknow]?

    /**
    Header text to be displayed above the list of the acknowledgements.
    It needs to get set before `viewDidLoad` gets called.
    Its value can be defined in the header of the plist file.
    */
    @IBInspectable var headerText: String?

    /**
    Footer text to be displayed below the list of the acknowledgements.
    It needs to get set before `viewDidLoad` gets called.
    Its value can be defined in the header of the plist file.
    */
    @IBInspectable var footerText: String?

    /**
    Acknowledgements plist file name whose contents to be loaded.
    It expects to get set by "User Defined Runtime Attributes" in Interface Builder.
    */
    @IBInspectable var acknowledgementsPlistName: String?

    /**
    Initializes the `AcknowListViewController` instance based on default configuration.

    - returns: The new `AcknowListViewController` instance.
    */
    public convenience init() {
        let path = AcknowListViewController.defaultAcknowledgementsPlistPath()
        self.init(acknowledgementsPlistPath: path)
    }

    /**
    Initializes the `AcknowListViewController` instance for a plist file path.

    - parameter acknowledgementsPlistPath: The path to the acknowledgements plist file.

    - returns: The new `AcknowListViewController` instance.
    */
    public init(acknowledgementsPlistPath: String?) {
        super.init(style: .Grouped)

        self.commonInit(acknowledgementsPlistPath: acknowledgementsPlistPath)
    }

    /**
    Initializes the `AcknowListViewController` instance with a coder.

    - parameter aDecoder: The archive coder.

    - returns: The new `AcknowListViewController` instance.
    */
    public required init(coder aDecoder: NSCoder) {
        super.init(style: .Grouped)
        let path = AcknowListViewController.defaultAcknowledgementsPlistPath()
        self.commonInit(acknowledgementsPlistPath: path)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    func commonInit(acknowledgementsPlistPath acknowledgementsPlistPath: String?) {
        self.title = AcknowListViewController.localizedTitle()

        if let acknowledgementsPlistPath = acknowledgementsPlistPath {
            let parser = AcknowParser(plistPath: acknowledgementsPlistPath)
            let headerFooter = parser.parseHeaderAndFooter()

            let DefaultHeaderText = "This application makes use of the following third party libraries:"
            let DefaultFooterText = "Generated by CocoaPods - https://cocoapods.org"
            let DefaultFooterTextLegacy = "Generated by CocoaPods - http://cocoapods.org"

            if (headerFooter.header == DefaultHeaderText) {
                self.headerText = nil;
            }
            else if (headerFooter.header !=  "") {
                self.headerText = headerFooter.header
            }

            if (headerFooter.footer == DefaultFooterText ||
                headerFooter.footer == DefaultFooterTextLegacy) {
                self.footerText = AcknowListViewController.localizedCocoaPodsFooterText()
            }
            else if (headerFooter.footer != "") {
                self.footerText = headerFooter.footer
            }

            let acknowledgements = parser.parseAcknowledgements()
            let sortedAcknowledgements = acknowledgements.sort({
                (ack1: Acknow, ack2: Acknow) -> Bool in
                let result = ack1.title.compare(
                    ack2.title,
                    options: [],
                    range: nil,
                    locale: NSLocale.currentLocale())
                return (result.rawValue == NSComparisonResult.OrderedAscending.rawValue)
             })

            self.acknowledgements = sortedAcknowledgements
        }
    }

    /**
    The localized version of “Acknowledgements”.
    You can use this value for the button presenting the `VTAcknowledgementsViewController`, for instance.

    - return: The localized title.
    */
    public class func localizedTitle() -> String {
        return self.localizedString(forKey: "VTAckAcknowledgements", defaultString: "Acknowledgements")
    }

    class func acknowledgementsPlistPath(name name:String) -> String? {
        return NSBundle.mainBundle().pathForResource(name, ofType: "plist")
    }

    class func defaultAcknowledgementsPlistPath() -> String? {
        let DefaultAcknowledgementsPlistName = "Pods-acknowledgements"
        return self.acknowledgementsPlistPath(name: DefaultAcknowledgementsPlistName)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        let path: String?
        if let acknowledgementsPlistName = self.acknowledgementsPlistName {
            path = AcknowListViewController.acknowledgementsPlistPath(name: acknowledgementsPlistName)
        }
        else {
            path = AcknowListViewController.defaultAcknowledgementsPlistPath()
        }
        
        if let path = path {
            self.commonInit(acknowledgementsPlistPath: path)
        }
    }


    // MARK: - Localization
    
    public class func preferredLanguageCode() -> String? {
        return NSLocale.preferredLanguages().first
    }

    public class func localizedString(forKey key: String, defaultString: String) -> String {
        var bundlePath = NSBundle(forClass: AcknowListViewController.self).pathForResource("AcknowList", ofType: "bundle")
        let languageBundle: NSBundle

        if let currentBundlePath = bundlePath {
            let bundle = NSBundle(path: currentBundlePath)
            var language = "en"

            if let firstLanguage = self.preferredLanguageCode() {
                language = firstLanguage
            }

            if let bundle = bundle {
                let localizations = bundle.localizations
                if localizations.contains(language) == false {
                    language = language.componentsSeparatedByString("-").first!
                }

                if localizations.contains(language) {
                    bundlePath = bundle.pathForResource(language, ofType: "lproj")
                }
            }
        }

        if let bundlePath = bundlePath {
            let bundleWithPath = NSBundle(path: bundlePath)
            if let bundleWithPath = bundleWithPath {
                languageBundle = bundleWithPath
            }
            else {
                languageBundle = NSBundle.mainBundle()
            }
        }
        else {
            languageBundle = NSBundle.mainBundle()
        }

        let localizedDefaultString = languageBundle.localizedStringForKey(key, value:defaultString, table:nil)
        return NSBundle.mainBundle().localizedStringForKey(key, value:localizedDefaultString, table:nil)
    }

    class func CocoaPodsURLString() -> String {
        return "https://cocoapods.org"
    }

    class func localizedCocoaPodsFooterText() -> String {
        return
            self.localizedString(forKey: "VTAckGeneratedByCocoaPods", defaultString: "Generated by CocoaPods")
                + "\n"
                + self.CocoaPodsURLString()
    }


    // MARK: - View lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.configureHeaderView()
        self.configureFooterView()

        if let navigationController = self.navigationController {
            if self.presentingViewController != nil &&
                navigationController.viewControllers.first == self {
                let item = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(AcknowListViewController.dismissViewController(_:)))
                    self.navigationItem.leftBarButtonItem = item
            }
        }
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if self.acknowledgements == nil {
            print(
                "** AcknowList Warning **\n" +
                "No acknowledgements found.\n" +
                "This probably means that you didn’t import the `Pods-acknowledgements.plist` to your main target.\n" +
                "Please take a look at https://github.com/vtourraine/AcknowLister for instructions.", terminator: "\n")
        }
    }


    // MARK: - Actions

    /**
    Opens the CocoaPods website with Safari.

    - parameter sender: The event sender.
    */
    @IBAction public func openCocoaPodsWebsite(sender: AnyObject) {
        let url = NSURL(string: AcknowListViewController.CocoaPodsURLString())
        if let url = url {
            UIApplication.sharedApplication().openURL(url)
        }
    }

    /**
    Dismisses the view controller.

    - parameter sender: The event sender.
    */
    @IBAction public func dismissViewController(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    class func LabelMargin () -> CGFloat {
        return 20
    }
    
    class func FooterBottomMargin() -> CGFloat {
        return 20
    }

    func configureHeaderView() {
        let font = UIFont.systemFontOfSize(12)
        let labelWidth = CGRectGetWidth(self.view.frame) - 2 * AcknowListViewController.LabelMargin()

        if let headerText = self.headerText {
            let labelHeight = self.heightForLabel(text: headerText, width: labelWidth)
            let labelFrame = CGRectMake(
                AcknowListViewController.LabelMargin(),
                AcknowListViewController.LabelMargin(),
                labelWidth,
                labelHeight)

            let label = UILabel(frame: labelFrame)
            label.text             = self.headerText
            label.font             = font
            label.textColor        = UIColor.grayColor()
            label.backgroundColor  = UIColor.clearColor()
            label.numberOfLines    = 0
            label.textAlignment    = .Center
            label.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]

            let headerFrame = CGRectMake(
                0, 0,
                CGRectGetWidth(self.view.frame),
                CGRectGetHeight(label.frame) + 2 * AcknowListViewController.LabelMargin())
            let headerView = UIView(frame: headerFrame)
            headerView.addSubview(label)
            self.tableView.tableHeaderView = headerView
        }
    }

    func configureFooterView() {
        let font = UIFont.systemFontOfSize(12)
        let labelWidth = CGRectGetWidth(self.view.frame) - 2 * AcknowListViewController.LabelMargin()

        if let footerText = self.footerText {
            let labelHeight = self.heightForLabel(text: footerText, width: labelWidth)
            let labelFrame = CGRectMake(AcknowListViewController.LabelMargin(), 0, labelWidth, labelHeight);

            let label = UILabel(frame: labelFrame)
            label.text             = self.footerText
            label.font             = font
            label.textColor        = UIColor.grayColor()
            label.backgroundColor  = UIColor.clearColor()
            label.numberOfLines    = 0
            label.textAlignment    = .Center
            label.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
            label.userInteractionEnabled = true;

            let CocoaPodsURL = NSURL(string: AcknowListViewController.CocoaPodsURLString())
            if let CocoaPodsURL = CocoaPodsURL,
                let CocoaPodsURLHost = CocoaPodsURL.host {
                    if footerText.rangeOfString(CocoaPodsURLHost) != nil {
                        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AcknowListViewController.openCocoaPodsWebsite(_:)))
                        label.addGestureRecognizer(tapGestureRecognizer)
                    }
            }

            let footerFrame = CGRectMake(0, 0, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame) + AcknowListViewController.FooterBottomMargin())
            let footerView = UIView(frame: footerFrame)
            footerView.userInteractionEnabled = true
            footerView .addSubview(label)
            label.frame = CGRectMake(0, 0, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame));

            self.tableView.tableFooterView = footerView
        }
    }

    func heightForLabel(text labelText: NSString, width labelWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFontOfSize(12)
        let options: NSStringDrawingOptions = NSStringDrawingOptions.UsesLineFragmentOrigin
        // should be (NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin)?
        let labelBounds: CGRect = labelText.boundingRectWithSize(CGSizeMake(labelWidth, CGFloat.max), options: options, attributes: [NSFontAttributeName: font], context: nil)
        let labelHeight = CGRectGetHeight(labelBounds)

        return CGFloat(ceilf(Float(labelHeight)))
    }


    // MARK: - Table view data source

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let acknowledgements = self.acknowledgements {
            return acknowledgements.count
        }

        return 0
    }

    public override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        let dequeuedCell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        let cell: UITableViewCell
        if let dequeuedCell = dequeuedCell {
            cell = dequeuedCell
        }
        else {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
        }

        if let acknowledgements = self.acknowledgements,
            let acknowledgement = acknowledgements[indexPath.row] as Acknow?,
            let textLabel = cell.textLabel as UILabel? {
                textLabel.text = acknowledgement.title
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }

        return cell
    }

    // MARK: Table view delegate

    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let acknowledgements = self.acknowledgements,
        let acknowledgement = acknowledgements[indexPath.row] as Acknow?,
        let navigationController = self.navigationController {
                let viewController = AcknowViewController(acknowledgement: acknowledgement)
                navigationController.pushViewController(viewController, animated: true)
        }
    }
}

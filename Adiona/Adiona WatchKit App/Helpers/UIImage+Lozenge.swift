import UIKit

extension UIImage {
    static func swatchBackground(size: CGSize = CGSize(width: 42, height: 18)) -> UIImage? {
        var image: UIImage?
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        UIColor.black.set()
        let path = UIBezierPath(
            roundedRect: rect.inset(by: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)),
            cornerRadius: 4.0
        )
        path.lineWidth = 2.0
        path.stroke()
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func swatchForeground(
        name: String = "",
        size: CGSize = CGSize(width: 42, height: 18)
    ) -> UIImage? {
        var image: UIImage?
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let attr = NSAttributedString(
            string: name.firstThreeLettersCapitalized(),
            attributes: [.font: UIFont.systemFont(ofSize: 14)]
        )
        attr.draw(at: CGPoint(x: 7, y: 0))
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func swatchOnePiece(
        name: String = "",
        size: CGSize = CGSize(width: 42, height: 18)
    ) -> UIImage? {
        var image: UIImage?
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        swatchBackground()?.draw(at: .zero)
        swatchForeground(name: name)?.draw(at: .zero)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension String {
    func firstThreeLettersCapitalized() -> String {
        let value = uppercased()
        if value.count < 3 {
            return value
        }
        let toIndex = value.index(value.startIndex, offsetBy: 3)
        return String(value[..<toIndex])
    }
}

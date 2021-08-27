//
//  Extension.swift
//  RedSheet
//
//  Created by 周廷叡 on 2021/02/24.
//

import UIKit

extension String {
    //特定の文字列の後ろの数文字を取得する
    func slice(after: String, length: Int) -> Array<String> {
        
        //指定文字列で分割 => mapで処理
        let separated = self.components(separatedBy: after).map {
            $0.replacingOccurrences(of: $0, with: $0.prefix(length))
        }
        
        //返却
        return separated
    }
    
    
}

extension UIColor {
    
    /// 16進数で色を表す
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
    
    /// 16進数にする
    public func hex(withHash hash: Bool = false, uppercase up: Bool = false) -> String {
        
        if let components = self.cgColor.components {
            let r = ("0" + String(Int(components[0] * 255.0), radix: 16, uppercase: up)).suffix(2)
            let g = ("0" + String(Int(components[1] * 255.0), radix: 16, uppercase: up)).suffix(2)
            let b = ("0" + String(Int(components[2] * 255.0), radix: 16, uppercase: up)).suffix(2)
            return (hash ? "#" : "") + String(r + g + b)
        }
        
        return "000000"
    }
    
    /// 16進数に変換する用
    enum HexFormat {
        case RGB
        case ARGB
        case RGBA
        case RRGGBB
        case AARRGGBB
        case RRGGBBAA
    }
    
    enum HexDigits {
        case d3, d4, d6, d8
    }
    
    func hexString(_ format: HexFormat = .RRGGBBAA) -> String {
        let maxi = [.RGB, .ARGB, .RGBA].contains(format) ? 16 : 256
        
        func toI(_ f: CGFloat) -> Int {
            return min(maxi - 1, Int(CGFloat(maxi) * f))
        }
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = toI(r)
        let gi = toI(g)
        let bi = toI(b)
        let ai = toI(a)
        
        switch format {
        case .RGB:       return String(format: "#%X%X%X", ri, gi, bi)
        case .ARGB:      return String(format: "#%X%X%X%X", ai, ri, gi, bi)
        case .RGBA:      return String(format: "#%X%X%X%X", ri, gi, bi, ai)
        case .RRGGBB:    return String(format: "#%02X%02X%02X", ri, gi, bi)
        case .AARRGGBB:  return String(format: "#%02X%02X%02X%02X", ai, ri, gi, bi)
        case .RRGGBBAA:  return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
        }
    }
}

extension UIImage {
    //urlで指定
    public convenience init(url: String) {
        let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        do {
            let data = try Data(contentsOf: url!)
            self.init(data: data)!
            return
        } catch let err {
            print("Error : \(err.localizedDescription)")
        }
        self.init()
    }
    
    // image with rounded corners
    public func cornerRadius(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// fix image's orientation
    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
            
            
        }
        switch imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        @unknown default:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
        default:
            ctx.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
    
    /// リサイズ
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    static func PDFImageWith(_ url: URL, pageNumber: Int, width: CGFloat) -> UIImage? {
        return PDFImageWith(url, pageNumber: pageNumber, constraints: CGSize(width: width, height: 0))
    }
    static func PDFImageWith(_ url: URL, pageNumber: Int, height: CGFloat) -> UIImage? {
        return PDFImageWith(url, pageNumber: pageNumber, constraints: CGSize(width: 0, height: height))
    }
    static func PDFImageWith(_ url: URL, pageNumber: Int) -> UIImage? {
        return PDFImageWith(url, pageNumber: pageNumber, constraints: CGSize(width: 0, height: 0))
    }
    static func PDFImageWith(_ url: URL, pageNumber: Int, constraints: CGSize) -> UIImage? {
        if let pdf = CGPDFDocument(url as CFURL) {
            if let page = pdf.page(at: pageNumber) {
                let size = page.getBoxRect(.mediaBox).size.forConstraints(constraints)
//                let cacheURL = url.PDFCacheURL(pageNumber, size: size)
//                if let url = cacheURL {
//                    if FileManager.default.fileExists(atPath: url.path) {
//                        if let image = UIImage(contentsOfFile: url.path) {
//                            return UIImage(cgImage: image.cgImage!, scale: UIScreen.main.scale, orientation: .up)
//                        }
//                    }
//                }
                UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
                if let ctx = UIGraphicsGetCurrentContext() {
                    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
                    let rect = page.getBoxRect(.mediaBox)
                    ctx.translateBy(x: -rect.origin.x, y: -rect.origin.y)
                    ctx.scaleBy(x: size.width / rect.size.width, y: size.height / rect.size.height)
                    //                    CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(page, .MediaBox, CGRectMake(0, 0, size.width, size.height), 0, true))
                    ctx.drawPDFPage(page)
                    let image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    if let image = image {
//                        if let url = cacheURL {
//                            if let imageData = image.pngData() {
//                                try? imageData.write(to: url, options: [])
//                            }
//                        }
                        return UIImage(cgImage: image.cgImage!, scale: UIScreen.main.scale, orientation: .up)
                    }
                }
            }
        }
        return nil
    }
    static func PDFImageSizeWith(_ url: URL, pageNumber: Int, width: CGFloat) -> CGSize {
        if let pdf = CGPDFDocument(url as CFURL) {
            if let page = pdf.page(at: pageNumber) {
                return page.getBoxRect(.mediaBox).size.forConstraints(CGSize(width: width, height: 0))
            }
        }
        return CGSize.zero
    }
}
extension CGSize {
    func forConstraints(_ constraints: CGSize) -> CGSize {
        if constraints.width == 0 && constraints.height == 0 {
            return self
        }
        let sx = constraints.width / width, sy = constraints.height / height
        let s = sx != 0 && sy != 0 ? min(sx, sy) : max(sx, sy)
        return CGSize(width: ceil(width * s), height: ceil(height * s))
    }
}
extension URL {
    func PDFCacheURL(_ pageNumber: Int, size: CGSize) -> URL? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: self.path)
            if let fileSize = attributes[FileAttributeKey.size] as! NSNumber? {
                if let fileDate = attributes[FileAttributeKey.modificationDate] as! Date? {
                    let hashables = self.path + fileSize.stringValue + String(fileDate.timeIntervalSince1970) + String(describing: size)
                    let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/__PDF_CACHE__"
                    do {
                        try FileManager.default.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true, attributes:nil)
                    } catch {}
                    return URL(fileURLWithPath: cacheDirectory + "/" + String(format:"%2X", hashables.hash) + ".png")
                }
            }
        } catch {}
        return nil
    }
    
}

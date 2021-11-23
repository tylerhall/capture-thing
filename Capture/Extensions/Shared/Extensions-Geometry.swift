import CoreGraphics

extension CGPoint {
    
    func scaled(_ size: CGSize) -> CGPoint {
        return CGPoint(x: x * size.width, y: y * size.height)
    }

    func offsetBy(_ dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }

    func scaledAroundCenterPoint(_ scale: CGFloat, centerPoint: CGPoint) -> CGPoint {
        let xNew = (scale * (x - centerPoint.x)) + centerPoint.x
        let yNew = (scale * (y - centerPoint.y)) + centerPoint.y
        return CGPoint(x: xNew, y: yNew)
    }

    func rotatedAroundCenterPoint(_ radians: CGFloat, centerPoint: CGPoint) -> CGPoint {
        let s = sin(radians)
        let c = cos(radians)
        
        var px = self.x - centerPoint.x
        var py = self.y - centerPoint.y
        
        let newX = px * c - py * s
        let newY = px * s + py * c

        px = newX + centerPoint.x
        py = newY + centerPoint.y

        return CGPoint(x: px, y: py)
    }
}

extension CGFloat {
    var valueOrZero: CGFloat {
        return CGFloat.maximum(0, self)
    }
}

extension Array where Element == CGPoint {

    func pointsAdjacentTo(index: Int) -> (Int, Int)? {
        guard count >= 3 else { return nil }
        
        if index == 0 {
            return (count - 1, 1)
        } else if index == (count - 1) {
            return (index - 1, 0)
        } else {
            return (index - 1, index + 1)
        }
    }

    // This only works on arrays with 4 points
    func oppositeVertexIndex(vertexIndex: Int) -> Int {
        guard count == 4 else { fatalError() }
        switch vertexIndex {
        case 0:
            return 2
        case 1:
            return 3
        case 2:
            return 0
        case 3:
            return 1
        default:
            fatalError()
        }
    }
}

struct Line {
    var p1: CGPoint
    var p2: CGPoint

    var midPoint: CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    var length: CGFloat {
        return sqrt((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y))
    }
    
    var slope: CGFloat? {
        guard p2.x - p1.x != 0 else { return nil }
        return (p2.y - p1.y) / (p2.x - p1.x)
    }

    var yIntercept: CGFloat? {
        if let slope = slope {
            return p1.y - slope * p1.x
        }
        return nil
    }

    func pointAt(x: CGFloat) -> CGPoint? {
        if let slope = slope, let yIntercept = yIntercept {
            return CGPoint(x: x, y: slope * x + yIntercept)
        }
        return nil
    }
    
    func intercetionWith(line: Line) -> CGPoint? {
        // y = ax + c
        // y = bx + d
        // ax + c = bx + d
        // ax - bx = d - c
        // x = (d - c) / (a - b)

        guard let a = slope, let c = yIntercept else {
            return nil
        }
        
        guard let b = line.slope, let d = line.yIntercept else {
            return nil
        }
        
        // Check for parallel lines
        if a == b {
            return nil
        }
        
        if a - b == 0 {
            return nil
        }
        
        if d - c == 0 {
            return nil
        }
        
        let x = (d - c) / (a - b)
        let y = a * x + c

        let p = CGPoint(x: x, y: y)
        if hasXCoord(x: p.x) && hasYCoord(y: p.y) && line.hasXCoord(x: p.x) && line.hasYCoord(y: p.y) {
            return p
        }

        return nil
    }
    
    func hasXCoord(x: CGFloat) -> Bool {
        let xMin = min(p1.x, p2.x)
        let xMax = max(p1.x, p2.x)
        return (xMin <= x) && (x <= xMax)
    }

    func hasYCoord(y: CGFloat) -> Bool {
        let yMin = min(p1.y, p2.y)
        let yMax = max(p1.y, p2.y)
        return (yMin <= y) && (y <= yMax)
    }
    
    func hasPoint(point: CGPoint) -> Bool {
        return hasXCoord(x: point.x) && hasYCoord(y: point.y)
    }
}

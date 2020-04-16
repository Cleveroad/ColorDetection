//
//  OpenCVWrapper.m
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#import "OpenCVDetector.h"
#import "UIImage+OpenCV.h"
#import "BodyDetector.h"
#import "ObjectDetector.h"

#pragma mark - OpenCVDetector

using namespace cv;
using namespace std;

@interface OpenCVDetector() <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) BodyDetector* bodyDetector;
@property (nonatomic, strong) ObjectDetector* objectDetector;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) Scalar fillingScalar;
@property (nonatomic, assign) CGPoint selectedPoint;
@property (nonatomic, assign) DetectingObject detectingObject;
@property (nonatomic, assign) Scalar avarageScalar;

@end

@implementation OpenCVDetector

- (instancetype)initWithCameraView:(UIView *)view scale:(CGFloat)scale preset:(AVCaptureSessionPreset) preset type:(OpenCVDetectorType) type {
    self = [super init];
    
    if (self) {
        
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView: view];
        self.videoCamera.defaultAVCaptureSessionPreset = preset;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.delegate = self;
        
        self.scale = scale;
        self.detectionMode = OpenCVDetectorModeAvarageScalar;
        
        if (type == OpenCVDetectorTypeFront) {
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        } else {
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        }
        
        self.bodyDetector = [[BodyDetector alloc] initWithType: BodyDetectorTypeFace];
        self.objectDetector = [[ObjectDetector alloc] init];
        self.fillingScalar = Scalar(NAN, NAN, NAN);
        self.selectedPoint = CGPointMake(NAN, NAN);
    }
    
    return self;
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image {
    
    BodyObject* bodyObject;
    
    if (self.isShouldDetectFace) {
        bodyObject = [self.bodyDetector detecBodyForMat: image];
    }
   
    cv::Rect fullBodyRect = cvRect(0, 0, image.cols, image.rows);
    
    cvtColor(image, image, COLOR_BGRA2BGR);
    
    Mat bodyMat = image;
    
    if (bodyObject != nil) {
        
        CGFloat y = CGRectGetMaxY([bodyObject head]);
        CGFloat height = image.rows;
        
        if (height > y) {
            height -= y;
        } else {
            y = 0;
        }
        
        fullBodyRect = cvRect(0, y, image.cols, height);
        bodyMat = image(fullBodyRect);
        
        //Try to detect tshirtColor automatic, once
        if (self.selectedPoint.x == 0 && self.selectedPoint.y == 0) {
            if (bodyMat.cols > 0 && bodyMat.rows > 0) {
                int rows = bodyMat.rows;
                int cols = bodyMat.cols;
                self.selectedPoint = CGPointMake(cols/2 - 7, rows - 7);
            }
        }
    }
    
    if (!isnan(self.selectedPoint.x) && !isnan(self.selectedPoint.y)) {
        
        DetectingObject detectingObject = DetectingObject();
        detectingObject.fillingColor = self.detectingObject.fillingColor;
        
        self.avarageScalar = [self averageScalarForImage:image inPoint: self.selectedPoint];
        
        if (self.detectionMode == OpenCVDetectorModeAvarageScalar) {
            vector<Scalar> scalars(1);
            scalars[0] = self.avarageScalar;
            detectingObject.detectingColors = scalars;
        } else {
           detectingObject.detectingColors = scalarsForimage(image, self.selectedPoint);
        }
        
        self.selectedPoint = CGPointMake(NAN, NAN);
        self.detectingObject = detectingObject;
    }
    
    if (!isnan(self.fillingScalar[0])) {
        DetectingObject detectingObject = DetectingObject();
        detectingObject.detectingColors = self.detectingObject.detectingColors;
        detectingObject.fillingColor = [self fillingScalar];
        self.fillingScalar = Scalar(NAN, NAN, NAN);
        self.detectingObject = detectingObject;
    }
    
    if (self.detectingObject.detectingColors.size() != 0 && !isnan(self.detectingObject.fillingColor[0])) {
        bodyMat = [self.objectDetector fillImg:bodyMat withDetectingObject: self.detectingObject];
        bodyMat.copyTo(image(fullBodyRect));
    }
    
    cvtColor(image, image, COLOR_BGR2RGB);
}

#pragma mark - Private

vector<Scalar> scalarsForimage(Mat image, CGPoint point)  {
    int x = point.x;
    int y = point.y;
    
    int value = 3;
    if (x <= value || y <= value) {
        return vector<Scalar>(0);
    }
    
    Mat mat = image(cvRect(x - value, y - value, value * 2, value * 2));
    
    vector<Scalar> scalars(mat.rows * mat.cols);
    
    int size = 0;
    for (int i = 0; i < mat.rows; i++) {
        for (int j = 0; j < mat.cols; j++) {
            auto pixel = mat.at<Vec3b>(i, j);
            scalars[size++] = Scalar(pixel.val[0], pixel.val[1], pixel.val[2]);
        }
    }
    
    return scalars;
}

-(Scalar)averageScalarForImage:(Mat) image inPoint: (CGPoint) point {
    
    int x = point.x;
    int y = point.y;
    
    Mat hsv;
    cvtColor(image, hsv, CV_BGRA2BGR);
    cvtColor(hsv, hsv, CV_BGR2HSV);
    
    Mat rect = hsv(cvRect(x - 3, y - 3, 6, 6));
    
    vector<Scalar> hsvColors = scalarsForimage(image, point);
    
    cv::Mat1b mask(rect.rows, rect.cols);
    cv::Scalar hsvColor = cv::mean(rect, mask);
    
    Mat bgr(1,1, CV_8UC3, hsvColor);
    cvtColor(bgr, bgr, CV_HSV2BGR);
    
    Scalar brgColor = Scalar(bgr.data[0], bgr.data[1], bgr.data[2]);
    
    return brgColor;
}

#pragma mark - Public

- (void)setCameraType:(OpenCVDetectorType) type {
    if (type == OpenCVDetectorTypeFront) {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    } else {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    }
}

-(void)setHSVRangeValueWithHValue:(float) h sValue:(float) s vValue:(float) v {
    [self.objectDetector setHSVRangeValueWithHValue:h sValue:s vValue:v];
}

- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture {
    [self.videoCamera stop];
}

- (void)setDetectingPoint: (CGPoint) point {
    _selectedPoint = point;
}

- (void)setFillingColorWithRed:(double) red green:(double) green blue:(double) blue {
    self.fillingScalar = Scalar(blue, green, red);
}

- (void)setOffset:(float) offset {
    [self.objectDetector setOffset: offset];
}

- (void) resetFillingColor {
    DetectingObject detectingObject = DetectingObject();
    detectingObject.detectingColors = self.detectingObject.detectingColors;
    detectingObject.fillingColor = Scalar(NAN, NAN, NAN);;
    self.detectingObject = detectingObject;
}

- (UIColor*)getAvarageDetectionColor {
    return  [[UIColor alloc] initWithRed: self.avarageScalar[2] / 255 green: self.avarageScalar[1] / 255 blue:self.avarageScalar[0] / 255 alpha:1.0];
}

@end

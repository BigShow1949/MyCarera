//
//  ViewController.m
//  MyCarera
//
//  Created by apple on 16/12/13.
//  Copyright © 2016年 智慧互通. All rights reserved.
//

#import "ViewController.h"

#define YFScreen [UIScreen mainScreen].bounds.size

@interface ViewController ()
@property (nonatomic, strong) UIView *backView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self UIAbout];
    [self initAVCaptureSession];

}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        [self.session startRunning];
    }
}


- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        [self.session stopRunning];
    }
}



- (void)initAVCaptureSession{
    
    //捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    [device setFlashMode:AVCaptureFlashModeAuto];//设置闪光灯为自动
    [device unlockForConfiguration];
    
    // 初始化输入设备
    NSError *error;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    // 图片输出
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    //session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    // AVLayerVideoGravityResizeAspect
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = CGRectMake(0, 0,YFScreen.width, YFScreen.height - 64);
    
    self.backView.layer.masksToBounds = YES;
    [self.backView.layer addSublayer:self.previewLayer];
    
}

- (void)UIAbout {

    UIButton *backBtn = [[UIButton alloc] init];
    backBtn.frame = CGRectMake(20, YFScreen.height-44, 50, 44);
    [backBtn setTitle:@"后" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    backBtn.backgroundColor = [UIColor redColor];
    [self.backView addSubview:backBtn];
    
    UIButton *frontBtn = [[UIButton alloc] init];
    frontBtn.frame = CGRectMake(90, YFScreen.height-44, 50, 44);
    [frontBtn setTitle:@"前" forState:UIControlStateNormal];
    [frontBtn addTarget:self action:@selector(frontBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    frontBtn.backgroundColor = [UIColor redColor];
    [self.backView addSubview:frontBtn];
    
    UIButton *takePhotoBtn = [[UIButton alloc] init];
    takePhotoBtn.frame = CGRectMake(160, YFScreen.height-44, 50, 44);
    [takePhotoBtn setTitle:@"Photo" forState:UIControlStateNormal];
    [takePhotoBtn addTarget:self action:@selector(takePhotoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    takePhotoBtn.backgroundColor = [UIColor redColor];
    [self.backView addSubview:takePhotoBtn];
}

#pragma mark - even response
- (void)backBtnClick:(UIButton *)btn {
    [self changeCameraWithPosition:AVCaptureDevicePositionBack];
}

- (void)frontBtnClick:(UIButton *)btn {
    [self changeCameraWithPosition:AVCaptureDevicePositionFront];
}

- (void)takePhotoBtnClick:(UIButton *)btn {
    
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [connection setVideoOrientation:avcaptureOrientation];
    [connection setVideoScaleAndCropFactor:1];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限
            return ;
        }
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];
        
    }];
}

#pragma mark - private
- (void)changeCameraWithPosition:(AVCaptureDevicePosition )desiredPosition {
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        NSLog(@"d = %@", d);
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
}

-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma mark - 懒加载
- (UIView *)backView {

    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, YFScreen.width, YFScreen.height)];
        _backView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_backView];
    }
    return _backView;
}

@end

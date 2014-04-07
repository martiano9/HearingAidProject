//
//  SCWaveformView.m
//  SCWaveformView
//
//  Created by Simon CORSIN on 24/01/14.
//  Copyright (c) 2014 Simon CORSIN. All rights reserved.
//

#import "AMDataPlot.h"

#define absX(x) (x < 0 ? 0 - x : x)
#define minMaxX(x, mn, mx) (x <= mn ? mn : (x >= mx ? mx : x))
#define noiseFloor (-50.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude) / 32767.0))

@interface AMDataPlot() {
    UIImageView *_normalImageView;
    UIImageView *_progressImageView;
    UIView *_cropNormalView;
    UIView *_cropProgressView;
    BOOL _normalColorDirty;
    BOOL _progressColorDirty;
    double _maxAmplitude;
}

@end

@implementation AMDataPlot

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    _normalImageView = [[UIImageView alloc] init];
    _progressImageView = [[UIImageView alloc] init];
    _cropNormalView = [[UIView alloc] init];
    _cropProgressView = [[UIView alloc] init];
    
    _cropNormalView.clipsToBounds = YES;
    _cropProgressView.clipsToBounds = YES;
    
    [_cropNormalView addSubview:_normalImageView];
    [_cropProgressView addSubview:_progressImageView];
    
    [self addSubview:_cropNormalView];
    [self addSubview:_cropProgressView];
    
    self.normalColor = [UIColor blueColor];
    self.progressColor = [UIColor redColor];
    
    _normalColorDirty = NO;
    _progressColorDirty = NO;
}

- (void) renderPixelWaveForm:(CGContextRef)context height:(float)halfGraphHeight sample:(double)sample x:(float) x {
    float pixelHeight = halfGraphHeight * (sample/_maxAmplitude);
    
    if (pixelHeight < 0) {
        pixelHeight = 0;
    }
    
    CGContextMoveToPoint(context, x, halfGraphHeight - pixelHeight);
    CGContextAddLineToPoint(context, x, halfGraphHeight);
    CGContextStrokePath(context);
    

}

- (void)renderWaveformInContext:(CGContextRef)context data:(float *)data withColor:(UIColor *)color andSize:(CGSize)size antialiasingEnabled:(BOOL)antialiasingEnabled
{
    if (data == nil) {
        return;
    }
    
    CGFloat pixelRatio = [UIScreen mainScreen].scale;
    size.width *= pixelRatio;
    size.height *= pixelRatio;
    
    CGFloat widthInPixels = size.width;
    CGFloat heightInPixels = size.height;
    
    CGContextSetAllowsAntialiasing(context, antialiasingEnabled);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);

    // TODO:
    
    NSUInteger samplesPerPixel = _samplesCount / (widthInPixels);
    samplesPerPixel = samplesPerPixel < 1 ? 1 : samplesPerPixel;
    
    float halfGraphHeight = (heightInPixels );
    double bigSample = 0;
    NSUInteger bigSampleCount = 0;
    
    CGFloat currentX = 0;
    _maxAmplitude = 0;
    for (int i = 0; i < _samplesCount; i++) {
        float sample = _data[i];
        _maxAmplitude = MAX(_maxAmplitude, sample);
    }
    
    for (int i = 0; i < _samplesCount; i++) {
        float sample = (Float32) *_data++;
        
        bigSample += sample;
        bigSampleCount++;
        
        if (bigSampleCount == samplesPerPixel) {
            double averageSample = bigSample / (double)bigSampleCount;
            
            [self renderPixelWaveForm:context height:halfGraphHeight sample:averageSample x:currentX];
            //SCRenderPixelWaveformInContext(context, halfGraphHeight, averageSample, currentX);
            
            currentX ++;
            bigSample = 0;
            bigSampleCount  = 0;
        }
    }
    
    // Rendering the last pixels
    bigSample = bigSampleCount > 0 ? bigSample / (double)bigSampleCount : noiseFloor;
    while (currentX < size.width) {
        [self renderPixelWaveForm:context height:halfGraphHeight sample:bigSample x:currentX];
        currentX++;
    }
    
}

- (UIImage*)generateWaveformImageFromFloat:(float *)data withColor:(UIColor *)color andSize:(CGSize)size antialiasingEnabled:(BOOL)antialiasingEnabled
{
    CGFloat ratio = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width * ratio, size.height * ratio), NO, 1);
    
    [self renderWaveformInContext:UIGraphicsGetCurrentContext() data:_data withColor:color andSize:size antialiasingEnabled:antialiasingEnabled];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage*)recolorizeImage:(UIImage*)image withColor:(UIColor*)color
{
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, imageRect, image.CGImage);
    [color set];
    UIRectFillUsingBlendMode(imageRect, kCGBlendModeSourceAtop);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)generateWaveforms
{
    CGRect rect = self.bounds;
    
    if (self.generatedNormalImage == nil) {
        if (self.data) {
            self.generatedNormalImage = [self generateWaveformImageFromFloat:_data withColor:self.normalColor andSize:CGSizeMake(rect.size.width, rect.size.height) antialiasingEnabled:self.antialiasingEnabled];
            _normalColorDirty = NO;
        }
        
    }
    
    if (self.generatedNormalImage != nil) {
        if (_normalColorDirty) {
            self.generatedNormalImage = [AMDataPlot recolorizeImage:self.generatedNormalImage withColor:self.normalColor];
            _normalColorDirty = NO;
        }
        
        if (_progressColorDirty || self.generatedProgressImage == nil) {
            self.generatedProgressImage = [AMDataPlot recolorizeImage:self.generatedNormalImage withColor:self.progressColor];
            _progressColorDirty = NO;
        }
    }
    [self.delegate didFinishLoadData:YES];
}

- (void)drawRect:(CGRect)rect
{
    [self generateWaveforms];
    
    [super drawRect:rect];
}

- (void)applyProgressToSubviews
{
    CGRect bs = self.bounds;
    CGFloat progressWidth = bs.size.width * _progress;
    _cropProgressView.frame = CGRectMake(0, 0, progressWidth, bs.size.height);
    _cropNormalView.frame = CGRectMake(progressWidth, 0, bs.size.width - progressWidth, bs.size.height);
    _normalImageView.frame = CGRectMake(-progressWidth, 0, bs.size.width, bs.size.height);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bs = self.bounds;
    _normalImageView.frame = bs;
    _progressImageView.frame = bs;
    
    // If the size is now bigger than the generated images
    if (bs.size.width > self.generatedNormalImage.size.width) {
        self.generatedNormalImage = nil;
        self.generatedProgressImage = nil;
    }
    
    [self applyProgressToSubviews];
}

- (void)setNormalColor:(UIColor *)normalColor
{
    _normalColor = normalColor;
    _normalColorDirty = YES;
    [self setNeedsDisplay];
}

- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    _progressColorDirty = YES;
    [self setNeedsDisplay];
}

- (void)setData:(float *)data {
    _data = data;
    self.generatedProgressImage = nil;
    self.generatedNormalImage = nil;
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self applyProgressToSubviews];
}

- (UIImage*)generatedNormalImage
{
    return _normalImageView.image;
}

- (void)setGeneratedNormalImage:(UIImage *)generatedNormalImage
{
    _normalImageView.image = generatedNormalImage;
}

- (UIImage*)generatedProgressImage
{
    return _progressImageView.image;
}

- (void)setGeneratedProgressImage:(UIImage *)generatedProgressImage
{
    _progressImageView.image = generatedProgressImage;
}

- (void)setAntialiasingEnabled:(BOOL)antialiasingEnabled
{
    if (_antialiasingEnabled != antialiasingEnabled) {
        _antialiasingEnabled = antialiasingEnabled;
        self.generatedProgressImage = nil;
        self.generatedNormalImage = nil;
        [self setNeedsDisplay];
    }
}

@end

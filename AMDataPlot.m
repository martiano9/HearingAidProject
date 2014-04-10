//
//  SCWaveformView.m
//  SCWaveformView
//
//  Created by Simon CORSIN on 24/01/14.
//  Copyright (c) 2014 Simon CORSIN. All rights reserved.
//

#import "AMDataPlot.h"
#import "AMNiceScale.h"
#import "AMNiceGrid.h"

int pixelsPerCell = 30.00;
int smallGrids = 2;

@interface AMDataPlot(Private)

- (void)calculateGrid;
- (void)calculateMaxAmplitude;

@end

@implementation AMDataPlot

#pragma mark - Initialize

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

    
    self.normalColor = [UIColor greenColor];
    self.progressColor = [UIColor lightGrayColor];
    
    _normalColorDirty = NO;
    _progressColorDirty = NO;
    
    _bPadding = 15.0f;
}

#pragma mark -

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

// ========================================================================
// Draw
// ========================================================================

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self generateWaveforms];
}

- (void)generateWaveforms
{
    if (self.generatedNormalImage == nil) {
        if (self.data) {
            CGFloat ratio = [UIScreen mainScreen].scale;
            self.generatedNormalImage = [self generateWaveformImageFromFloat:_data withColor:self.normalColor andSize:CGSizeMake(_niceWidth*ratio, _niceHeight*ratio) antialiasingEnabled:self.antialiasingEnabled];
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

- (UIImage*)generateWaveformImageFromFloat:(float *)data withColor:(UIColor *)color andSize:(CGSize)size antialiasingEnabled:(BOOL)antialiasingEnabled
{
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self renderWaveformInContext:context data:_data withColor:color andSize:size antialiasingEnabled:antialiasingEnabled];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)renderWaveformInContext:(CGContextRef)context data:(float *)data withColor:(UIColor *)color andSize:(CGSize)size antialiasingEnabled:(BOOL)antialiasingEnabled
{
    if (data == nil) {
        return;
    }
    CGContextSetAllowsAntialiasing(context, antialiasingEnabled);
    CGContextSetShouldAntialias(context, antialiasingEnabled);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    // TODO:
    NSUInteger samplesPerPixel = _samplesCount / (size.width);
    samplesPerPixel = samplesPerPixel < 1 ? 1 : samplesPerPixel;
    
    double bigSample = 0;
    NSUInteger bigSampleCount = 0;
    
    CGFloat currentX = 0;
    
    for (int i = 0; i < _samplesCount; i++) {
        float sample = (Float32) *_data++;
        
        bigSample += sample;
        bigSampleCount++;
        
        if (bigSampleCount == samplesPerPixel) {
            double averageSample = bigSample / (double)bigSampleCount;
            
            [self renderPixelWaveForm:context height:size.height sample:averageSample x:currentX];
            currentX ++;
            bigSample = 0;
            bigSampleCount  = 0;
        }
    }
    
    // Rendering the last pixels
    ///bigSample = bigSampleCount > 0 ? bigSample / (double)bigSampleCount : 0;
    while (currentX < size.width) {
        [self renderPixelWaveForm:context height:_niceHeight sample:0 x:currentX];
        currentX++;
    }
}

- (void) renderPixelWaveForm:(CGContextRef)context height:(float)halfGraphHeight sample:(double)sample x:(float) x {
    float pixelHeight = halfGraphHeight * (sample/_vScale.niceMax);
    
    if (pixelHeight < 0) {
        pixelHeight = 0;
    }
    
    CGContextMoveToPoint(context, x, halfGraphHeight - pixelHeight);
    CGContextAddLineToPoint(context, x, halfGraphHeight);
    CGContextStrokePath(context);
}

// ========================================================================
// Layout Subviews
// ========================================================================

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    CGRect bs = self.bounds;
    bs.size.height = _niceHeight;
    bs.size.width = _niceWidth;
    _normalImageView.frame = bs;
    _progressImageView.frame = bs;
    
    // If the size is now bigger than the generated images
    if (bs.size.width > self.generatedNormalImage.size.width) {
        self.generatedNormalImage = nil;
        self.generatedProgressImage = nil;
    }
    
    [self applyProgressToSubviews];
}

- (void)applyProgressToSubviews
{
    CGFloat progressWidth = _niceWidth * _progress;
    _cropProgressView.frame = CGRectMake(0, 0, progressWidth, _niceHeight);
    _cropNormalView.frame = CGRectMake(progressWidth, 0, _niceWidth-progressWidth, _niceHeight);
    _normalImageView.frame = CGRectMake(-progressWidth, 0, _niceWidth, _niceHeight);
}

#pragma mark - Public Category

- (void)setData:(float *)data {
    _data = data;
    
    // calculate MaxAmplitude
    [self calculateMaxAmplitude];
    
    // calculate Grid
    [self calculateGrid];
    
    self.generatedProgressImage = nil;
    self.generatedNormalImage = nil;
    
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
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

- (void)setAntialiasingEnabled:(BOOL)antialiasingEnabled
{
    if (_antialiasingEnabled != antialiasingEnabled) {
        _antialiasingEnabled = antialiasingEnabled;
        self.generatedProgressImage = nil;
        self.generatedNormalImage = nil;
        [self setNeedsDisplay];
    }
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

#pragma mark - Private Category

- (void)calculateGrid {
    _vScale = [[AMNiceScale alloc] initWithMin:0.0 andMax:_maxAmplitude];
    _hScale = [[AMNiceScale alloc] initWithMin:0.0 andMax:_duration];
   
	CGFloat fullHeight  = self.bounds.size.height;
	CGFloat fullWidth   = self.bounds.size.width;
    
    int numberOfHorizontalGrid = _hScale.niceRange/_hScale.tickSpacing * smallGrids;
    _niceWidth = (int)(fullWidth / numberOfHorizontalGrid) * numberOfHorizontalGrid;

    _niceHeight = fullHeight - _bPadding;
    
    AMNiceGrid *grid = [[AMNiceGrid alloc] initWithFrame:self.bounds hScale:_hScale vScale:_vScale bPadding:_bPadding];
    [self addSubview:grid];
    [self sendSubviewToBack:grid];
}

- (void)calculateMaxAmplitude {
    _maxAmplitude = 0;
    for (int i = 0; i < _samplesCount; i++) {
        float sample = _data[i];
        _maxAmplitude = MAX(_maxAmplitude, sample);
    }
}
@end

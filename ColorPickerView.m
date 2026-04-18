#import "ColorPickerView.h"

@implementation ColorPickerView

- (instancetype)initWithFrame:(CGRect)frame initialR:(double)r g:(double)g b:(double)b {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 1.0;
        [self rgbToHSB:r g:g b:b];
        [self buildUI];
    }
    return self;
}

- (void)rgbToHSB:(double)r g:(double)g b:(double)b {
    UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    CGFloat h, s, br;
    [color getHue:&h saturation:&s brightness:&br alpha:nil];
    self.hue = h;
    self.saturation = s;
    self.brightness = br;
}

- (void)buildUI {
    CGRect bounds = self.bounds;
    double width = bounds.size.width;
    double sbHeight = width * 0.55;
    double fullWidth = width - 16.0;
    
    // Saturation-Brightness view
    self.sbView = [[UIView alloc] initWithFrame:CGRectMake(8, 8, fullWidth, sbHeight)];
    self.sbView.clipsToBounds = YES;
    self.sbView.layer.cornerRadius = 6.0;
    [self addSubview:self.sbView];
    
    // Hue base layer
    CAGradientLayer *hueBase = [CAGradientLayer layer];
    hueBase.frame = self.sbView.bounds;
    UIColor *hueColor1 = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
    UIColor *hueColor2 = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
    hueBase.colors = @[(id)hueColor1.CGColor, (id)hueColor2.CGColor];
    hueBase.name = @"hueBase";
    [self.sbView.layer addSublayer:hueBase];
    self.hueLayer = hueBase;
    
    // White gradient (left to right)
    self.sbWhiteLayer = [CAGradientLayer layer];
    self.sbWhiteLayer.frame = self.sbView.bounds;
    self.sbWhiteLayer.startPoint = CGPointMake(0, 0.5);
    self.sbWhiteLayer.endPoint = CGPointMake(1.0, 0.5);
    self.sbWhiteLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor];
    [self.sbView.layer addSublayer:self.sbWhiteLayer];
    
    // Black gradient (top to bottom)
    self.sbBlackLayer = [CAGradientLayer layer];
    self.sbBlackLayer.frame = self.sbView.bounds;
    self.sbBlackLayer.startPoint = CGPointMake(0.5, 0);
    self.sbBlackLayer.endPoint = CGPointMake(0.5, 1.0);
    self.sbBlackLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor];
    [self.sbView.layer addSublayer:self.sbBlackLayer];
    
    // SB thumb
    self.sbThumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    self.sbThumb.layer.cornerRadius = 8.0;
    self.sbThumb.layer.borderWidth = 2.0;
    self.sbThumb.layer.borderColor = [UIColor whiteColor].CGColor;
    self.sbThumb.layer.shadowColor = [UIColor blackColor].CGColor;
    self.sbThumb.layer.shadowRadius = 2.0;
    self.sbThumb.layer.shadowOpacity = 0.4;
    self.sbThumb.layer.shadowOffset = CGSizeZero;
    self.sbThumb.userInteractionEnabled = NO;
    [self.sbView addSubview:self.sbThumb];
    [self updateSBThumb];
    
    // SB gestures
    UIPanGestureRecognizer *sbPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSBPan:)];
    UITapGestureRecognizer *sbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSBTap:)];
    [self.sbView addGestureRecognizer:sbPan];
    [self.sbView addGestureRecognizer:sbTap];
    
    // Hue slider
    double hueY = sbHeight + 10.0 + 8.0;
    self.hueSliderTrack = [[UIView alloc] initWithFrame:CGRectMake(8, hueY, fullWidth, 18)];
    self.hueSliderTrack.layer.cornerRadius = 9.0;
    self.hueSliderTrack.clipsToBounds = YES;
    
    CAGradientLayer *hueGrad = [CAGradientLayer layer];
    hueGrad.frame = self.hueSliderTrack.bounds;
    hueGrad.startPoint = CGPointMake(0, 0.5);
    hueGrad.endPoint = CGPointMake(1.0, 0.5);
    
    NSMutableArray *hueColors = [NSMutableArray new];
    for (int i = 0; i < 13; i++) {
        UIColor *c = [UIColor colorWithHue:(double)i/12.0 saturation:1.0 brightness:1.0 alpha:1.0];
        [hueColors addObject:(id)c.CGColor];
    }
    hueGrad.colors = hueColors;
    [self.hueSliderTrack.layer addSublayer:hueGrad];
    [self addSubview:self.hueSliderTrack];
    
    self.hueThumb = [self makeThumb];
    [self addSubview:self.hueThumb];
    [self updateHueThumb];
    
    UIPanGestureRecognizer *huePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHuePan:)];
    UITapGestureRecognizer *hueTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHueTap:)];
    [self.hueSliderTrack addGestureRecognizer:huePan];
    [self.hueSliderTrack addGestureRecognizer:hueTap];
    
    // Alpha slider
    double alphaY = hueY + 26.0;
    self.alphaSliderTrack = [[UIView alloc] initWithFrame:CGRectMake(8, alphaY, fullWidth, 18)];
    self.alphaSliderTrack.layer.cornerRadius = 9.0;
    self.alphaSliderTrack.clipsToBounds = YES;
    
    // Checkerboard pattern
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);
    [[UIColor colorWithWhite:0.7 alpha:1.0] setFill];
    UIRectFill(CGRectMake(0, 0, 8, 8));
    UIRectFill(CGRectMake(8, 8, 8, 8));
    [[UIColor colorWithWhite:0.4 alpha:1.0] setFill];
    UIRectFill(CGRectMake(8, 0, 8, 8));
    UIRectFill(CGRectMake(0, 8, 8, 8));
    UIImage *checkerboard = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.alphaSliderTrack.backgroundColor = [UIColor colorWithPatternImage:checkerboard];
    
    CAGradientLayer *alphaGrad = [CAGradientLayer layer];
    alphaGrad.frame = self.alphaSliderTrack.bounds;
    alphaGrad.startPoint = CGPointMake(0, 0.5);
    alphaGrad.endPoint = CGPointMake(1.0, 0.5);
    alphaGrad.name = @"alphaGrad";
    [self.alphaSliderTrack.layer addSublayer:alphaGrad];
    [self addSubview:self.alphaSliderTrack];
    [self updateAlphaGrad];
    
    self.alphaThumb = [self makeThumb];
    [self addSubview:self.alphaThumb];
    [self updateAlphaThumb];
    
    UIPanGestureRecognizer *alphaPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleAlphaPan:)];
    UITapGestureRecognizer *alphaTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAlphaTap:)];
    [self.alphaSliderTrack addGestureRecognizer:alphaPan];
    [self.alphaSliderTrack addGestureRecognizer:alphaTap];
    
    // Preview swatch
    double previewY = alphaY + 28.0;
    self.previewSwatch = [[UIView alloc] initWithFrame:CGRectMake(8, previewY, 36, 36)];
    self.previewSwatch.layer.cornerRadius = 8.0;
    self.previewSwatch.layer.borderWidth = 1.0;
    self.previewSwatch.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    [self addSubview:self.previewSwatch];
    
    // Hex label
    UILabel *hexLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, previewY + 8, 14, 20)];
    hexLabel.text = @"#";
    hexLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    hexLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:hexLabel];
    
    // Hex field
    self.hexField = [[UITextField alloc] initWithFrame:CGRectMake(68, previewY + 4, fullWidth - 36 - 28, 28)];
    self.hexField.textColor = [UIColor whiteColor];
    self.hexField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.hexField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.hexField.layer.cornerRadius = 6.0;
    self.hexField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.hexField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.hexField.returnKeyType = UIReturnKeyDone;
    
    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    self.hexField.leftView = leftPadding;
    self.hexField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.hexField addTarget:self action:@selector(hexFieldDone) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self addSubview:self.hexField];
    
    [self updatePreview];
}

- (UIView *)makeThumb {
    UIView *thumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    thumb.layer.cornerRadius = 10.0;
    thumb.layer.borderWidth = 2.0;
    thumb.layer.borderColor = [UIColor whiteColor].CGColor;
    thumb.layer.shadowColor = [UIColor blackColor].CGColor;
    thumb.layer.shadowRadius = 3.0;
    thumb.layer.shadowOpacity = 0.5;
    thumb.layer.shadowOffset = CGSizeZero;
    thumb.backgroundColor = [UIColor clearColor];
    thumb.userInteractionEnabled = NO;
    return thumb;
}

// Gesture handlers
- (void)handleSBPan:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.sbView];
    [self updateSBFromPoint:point];
}

- (void)handleSBTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.sbView];
    [self updateSBFromPoint:point];
}

- (void)handleHuePan:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.hueSliderTrack];
    [self updateHueFromPoint:point];
}

- (void)handleHueTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.hueSliderTrack];
    [self updateHueFromPoint:point];
}

- (void)handleAlphaPan:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.alphaSliderTrack];
    [self updateAlphaFromPoint:point];
}

- (void)handleAlphaTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.alphaSliderTrack];
    [self updateAlphaFromPoint:point];
}

// Update methods
- (void)updateSBFromPoint:(CGPoint)point {
    CGRect bounds = self.sbView.bounds;
    self.saturation = fmax(fmin(point.x / bounds.size.width, 1.0), 0.0);
    self.brightness = fmax(fmin(1.0 - point.y / bounds.size.height, 1.0), 0.0);
    
    [self updateSBThumb];
    [self updateAlphaGrad];
    [self updatePreview];
    [self fireCallback];
}

- (void)updateHueFromPoint:(CGPoint)point {
    CGRect bounds = self.hueSliderTrack.bounds;
    self.hue = fmax(fmin(point.x / bounds.size.width, 0.9999), 0.0);
    
    // Update hue layer colors
    UIColor *c1 = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
    UIColor *c2 = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
    self.hueLayer.colors = @[(id)c1.CGColor, (id)c2.CGColor];
    
    [self updateHueThumb];
    [self updateAlphaGrad];
    [self updatePreview];
    [self fireCallback];
}

- (void)updateAlphaFromPoint:(CGPoint)point {
    CGRect bounds = self.alphaSliderTrack.bounds;
    self.alpha = fmax(fmin(point.x / bounds.size.width, 1.0), 0.0);
    
    [self updateAlphaThumb];
    [self updatePreview];
    [self fireCallback];
}

- (void)updateSBThumb {
    CGRect bounds = self.sbView.bounds;
    double x = bounds.size.width * self.saturation;
    double y = bounds.size.height * (1.0 - self.brightness);
    self.sbThumb.center = CGPointMake(x, y);
}

- (void)updateHueThumb {
    CGRect frame = self.hueSliderTrack.frame;
    double x = frame.origin.x + self.hue * frame.size.width;
    double y = frame.origin.y + frame.size.height * 0.5;
    self.hueThumb.center = CGPointMake(x, y);
}

- (void)updateAlphaThumb {
    CGRect frame = self.alphaSliderTrack.frame;
    double x = frame.origin.x + self.alpha * frame.size.width;
    double y = frame.origin.y + frame.size.height * 0.5;
    self.alphaThumb.center = CGPointMake(x, y);
}

- (void)updateAlphaGrad {
    UIColor *currentColor = [UIColor colorWithHue:self.hue 
                                        saturation:self.saturation 
                                        brightness:self.brightness 
                                             alpha:1.0];
    
    // Find and update the alpha gradient layer
    for (CALayer *layer in self.alphaSliderTrack.layer.sublayers) {
        if ([layer.name isEqualToString:@"alphaGrad"]) {
            UIColor *transparent = [currentColor colorWithAlphaComponent:0.0];
            [(CAGradientLayer *)layer setColors:@[(id)transparent.CGColor, (id)currentColor.CGColor]];
            break;
        }
    }
}

- (void)updatePreview {
    UIColor *color = [UIColor colorWithHue:self.hue 
                                saturation:self.saturation 
                                brightness:self.brightness 
                                     alpha:self.alpha];
    self.previewSwatch.backgroundColor = color;
    
    // Update hex field
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    NSString *hex = [NSString stringWithFormat:@"%02X%02X%02X%02X",
                     (unsigned int)(r * 255),
                     (unsigned int)(g * 255),
                     (unsigned int)(b * 255),
                     (unsigned int)(a * 255)];
    self.hexField.text = hex;
}

- (void)hexFieldDone {
    NSString *text = [self.hexField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Add FF if only 6 chars (RGB -> RGBA)
    if (text.length == 6) {
        text = [text stringByAppendingString:@"FF"];
    }
    
    if (text.length == 8) {
        unsigned int hexValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:text];
        [scanner scanHexInt:&hexValue];
        
        double r = ((hexValue >> 24) & 0xFF) / 255.0;
        double g = ((hexValue >> 16) & 0xFF) / 255.0;
        double b = ((hexValue >> 8) & 0xFF) / 255.0;
        self.alpha = (hexValue & 0xFF) / 255.0;
        
        [self rgbToHSB:r g:g b:b];
        
        // Update hue layer
        UIColor *c1 = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
        UIColor *c2 = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
        self.hueLayer.colors = @[(id)c1.CGColor, (id)c2.CGColor];
        
        [self updateSBThumb];
        [self updateHueThumb];
        [self updateAlphaThumb];
        [self updateAlphaGrad];
        [self updatePreview];
        [self fireCallback];
    }
}

- (void)fireCallback {
    if (self.onChange) {
        UIColor *color = [UIColor colorWithHue:self.hue 
                                    saturation:self.saturation 
                                    brightness:self.brightness 
                                         alpha:self.alpha];
        CGFloat r, g, b, a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        self.onChange();
    }
}

@end

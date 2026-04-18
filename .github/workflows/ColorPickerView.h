#import <UIKit/UIKit.h>

@interface ColorPickerView : UIView

@property (nonatomic, strong) UIView *sbView;
@property (nonatomic, strong) UIView *sbThumb;
@property (nonatomic, strong) CAGradientLayer *hueLayer;
@property (nonatomic, strong) CAGradientLayer *sbWhiteLayer;
@property (nonatomic, strong) CAGradientLayer *sbBlackLayer;

@property (nonatomic, strong) UIView *hueSliderTrack;
@property (nonatomic, strong) UIView *hueThumb;

@property (nonatomic, strong) UIView *alphaSliderTrack;
@property (nonatomic, strong) UIView *alphaThumb;

@property (nonatomic, strong) UIView *previewSwatch;
@property (nonatomic, strong) UITextField *hexField;

@property (nonatomic, assign) double hue;
@property (nonatomic, assign) double saturation;
@property (nonatomic, assign) double brightness;
@property (nonatomic, assign) double alpha;

@property (nonatomic, copy) void (^onChange)(void);

- (instancetype)initWithFrame:(CGRect)frame initialR:(double)r g:(double)g b:(double)b;
- (void)rgbToHSB:(double)r g:(double)g b:(double)b;
- (void)buildUI;
- (UIView *)makeThumb;

- (void)handleSBPan:(UIPanGestureRecognizer *)gesture;
- (void)handleSBTap:(UITapGestureRecognizer *)gesture;
- (void)handleHuePan:(UIPanGestureRecognizer *)gesture;
- (void)handleHueTap:(UITapGestureRecognizer *)gesture;
- (void)handleAlphaPan:(UIPanGestureRecognizer *)gesture;
- (void)handleAlphaTap:(UITapGestureRecognizer *)gesture;

- (void)updateSBFromPoint:(CGPoint)point;
- (void)updateHueFromPoint:(CGPoint)point;
- (void)updateAlphaFromPoint:(CGPoint)point;

- (void)updateSBThumb;
- (void)updateHueThumb;
- (void)updateAlphaThumb;
- (void)updateAlphaGrad;
- (void)updatePreview;

- (void)hexFieldDone;
- (void)fireCallback;

@end

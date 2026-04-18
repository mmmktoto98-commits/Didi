#import <UIKit/UIKit.h>

@interface MenuView : UIView

// Color row support
- (void)addColorRow:(NSString *)label 
               atY:(double)y 
            inView:(UIView *)container 
              rPtr:(float *)rPtr 
              gPtr:(float *)gPtr 
              bPtr:(float *)bPtr 
          onChange:(void (^)(void))onChange;

// Section header
- (void)addSectionHeader:(NSString *)title atY:(double)y;

// Toggle with optional color swatch
- (CAShapeLayer *)addToggle:(NSString *)label 
                        atY:(double)y 
                     action:(SEL)action 
                    enabled:(BOOL)enabled 
                     colorR:(float *)rPtr 
                          g:(float *)gPtr 
                          b:(float *)bPtr 
                       show:(BOOL)showSwatch;

// Sliders
- (void)addFovSliderAtY:(double)y;
- (void)addSmoothSliderAtY:(double)y;
- (void)addTriggerDelaySliderAtY:(double)y;
- (void)addRCSHSliderAtY:(double)y;
- (void)addRCSVSliderAtY:(double)y;
- (void)addBhopSliderAtY:(double)y;
- (void)addViewmodelXSliderAtY:(double)y;
- (void)addViewmodelYSliderAtY:(double)y;
- (void)addViewmodelZSliderAtY:(double)y;
- (void)addArrowsMarginSliderAtY:(double)y;
- (void)addMenuScaleSliderAtY:(double)y;

// Bone selector
- (void)addBoneSelectorAtY:(double)y;

// Tab management
- (void)showTab:(int)tabIndex;

// Menu control
- (void)toggleCollapse;
- (void)centerMenu;

// ESP toggle handlers
- (void)boxTapped;
- (void)boxOutlineTapped;
- (void)boxFillTapped;
- (void)boxCornerTapped;
- (void)box3DTapped;
- (void)lineTapped;
- (void)lineOutlineTapped;
- (void)nameTapped;
- (void)nameOutlineTapped;
- (void)healthTapped;
- (void)healthBarTapped;
- (void)healthBarOutlineTapped;
- (void)weaponTapped;
- (void)weaponIconTapped;
- (void)platformTapped;
- (void)avatarTapped;
- (void)arrowsTapped;
- (void)arrowsOutlineTapped;

// Cheat toggle handlers
- (void)infAmmoTapped;
- (void)noSpreadTapped;
- (void)airJumpTapped;
- (void)fastKnifeTapped;
- (void)bunnyHopTapped;
- (void)wallshotTapped;
- (void)fireRateTapped;
- (void)addskoreTapped;
- (void)invisibleTapped;

// Aimbot toggle handlers
- (void)aimbotTapped;
- (void)aimbotTeamTapped;
- (void)visibleCheckTapped;
- (void)shootingCheckTapped;
- (void)aimbotFovTapped;
- (void)triggerbotTapped;
- (void)teamTapped;
- (void)rcsTapped;

// Misc toggle handlers
- (void)viewmodelTapped;
- (void)screenshotSafeTapped;
- (void)hitSoundTapped;

@end

// UIView category for popup gestures
@interface UIView (PopupGestures)
- (void)handlePopupDrag:(UIPanGestureRecognizer *)gesture;
- (void)handleDismissTap:(UITapGestureRecognizer *)gesture;
@end

// Global reference to color picker popup
extern UIView *qword_100093BB0;

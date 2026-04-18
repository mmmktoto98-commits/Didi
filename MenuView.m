#import "MenuView.h"
#import "ColorPickerView.h"
#import <objc/runtime.h>

// External globals for colors
extern float g_textR, g_textG, g_textB;
extern float g_menuR, g_menuG, g_menuB;

// External globals for ESP settings
extern BOOL esp_box_enabled, esp_line_enabled, esp_name_enabled;
extern BOOL esp_box_outline, esp_box_fill, esp_box_corner, esp_box_3d;
extern BOOL esp_line_outline, esp_name_outline;
extern BOOL esp_health_enabled, esp_healthbar_enabled, esp_healthbar_outline;
extern BOOL esp_weapon_enabled, esp_weapon_icon;
extern BOOL esp_platform_enabled, esp_avatar_enabled;
extern BOOL esp_arrows_enabled, esp_arrows_outline;
extern float esp_arrows_margin;

// External globals for cheat settings
extern BOOL cheat_inf_ammo, cheat_no_spread, cheat_air_jump;
extern BOOL cheat_fast_knife, cheat_bunny_hop, cheat_wallshot;
extern BOOL cheat_fire_rate, cheat_add_score, cheat_invisible;

// External globals for aimbot
extern BOOL aimbot_enabled, aimbot_fov_enabled, aimbot_team_check;
extern BOOL aimbot_visible_check, aimbot_shooting_check;
extern float aimbot_fov, aimbot_smooth;
extern int aimbot_bone; // 0=head, 1=chest, 2=pelvis

// External globals for triggerbot
extern BOOL triggerbot_enabled, triggerbot_team_check;
extern float triggerbot_delay;

// External globals for RCS
extern BOOL rcs_enabled;
extern float rcs_horizontal, rcs_vertical;

// External globals for viewmodel
extern BOOL viewmodel_enabled;
extern float viewmodel_x, viewmodel_y, viewmodel_z;

// External globals for bhop
extern float bhop_speed;

// External globals for misc
extern BOOL screenshot_safe, hit_sound;
extern float menu_scale;

// Global reference to color picker popup
UIView *qword_100093BB0 = nil;

@interface MenuView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *innerContent;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *tabBar;

// Tab views
@property (nonatomic, strong) UIView *espTab;
@property (nonatomic, strong) UIView *cheatsTab;
@property (nonatomic, strong) UIView *aimbotTab;
@property (nonatomic, strong) UIView *miscTab;
@property (nonatomic, strong) UIView *configTab;
@property (nonatomic, strong) UIView *skinTab;

// Arrays for UI elements
@property (nonatomic, strong) NSMutableArray *rowViews;
@property (nonatomic, strong) NSMutableArray *toggleLabels;
@property (nonatomic, strong) NSMutableArray *sectionHeaders;

// Sliders
@property (nonatomic, strong) UISlider *fovSlider;
@property (nonatomic, strong) UILabel *fovValueLabel;
@property (nonatomic, strong) UISlider *smoothSlider;
@property (nonatomic, strong) UILabel *smoothValueLabel;
@property (nonatomic, strong) UISlider *triggerDelaySlider;
@property (nonatomic, strong) UILabel *triggerDelayValueLabel;
@property (nonatomic, strong) UISlider *rcsHSlider;
@property (nonatomic, strong) UILabel *rcsHValueLabel;
@property (nonatomic, strong) UISlider *rcsVSlider;
@property (nonatomic, strong) UILabel *rcsVValueLabel;
@property (nonatomic, strong) UISlider *bhopSlider;
@property (nonatomic, strong) UILabel *bhopValueLabel;
@property (nonatomic, strong) UISlider *viewmodelXSlider;
@property (nonatomic, strong) UILabel *viewmodelXValueLabel;
@property (nonatomic, strong) UISlider *viewmodelYSlider;
@property (nonatomic, strong) UILabel *viewmodelYValueLabel;
@property (nonatomic, strong) UISlider *viewmodelZSlider;
@property (nonatomic, strong) UILabel *viewmodelZValueLabel;
@property (nonatomic, strong) UISlider *arrowsMarginSlider;
@property (nonatomic, strong) UILabel *arrowsMarginValueLabel;
@property (nonatomic, strong) UISlider *menuScaleSlider;
@property (nonatomic, strong) UILabel *menuScaleValueLabel;

@property (nonatomic, assign) CGPoint lastPanPoint;
@property (nonatomic, assign) BOOL isCollapsed;
@property (nonatomic, assign) int currentTab;
@end

@implementation MenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.rowViews = [NSMutableArray array];
        self.toggleLabels = [NSMutableArray array];
        self.sectionHeaders = [NSMutableArray array];
        self.currentTab = 0;
        
        [self setupUI];
        [self setupTabs];
        [self buildESPTab];
        [self buildCheatsTab];
        [self buildAimbotTab];
        [self buildMiscTab];
        [self showTab:0];
    }
    return self;
}

- (void)setupUI {
    // Set background
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 12.0;
    self.clipsToBounds = YES;
    self.userInteractionEnabled = YES;
    
    // Add blur effect
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.blurView.frame = self.bounds;
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.blurView];
    
    // Create header
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 44)];
    self.headerView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
    [self addSubview:self.headerView];
    
    // Add title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.bounds.size.width - 32, 44)];
    titleLabel.text = @"WXR";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.headerView addSubview:titleLabel];
    
    // Create scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 44 + 40, self.bounds.size.width, self.bounds.size.height - 44 - 40)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.alwaysBounceVertical = YES;
    [self addSubview:self.scrollView];
    
    // Create content view
    self.innerContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, 2000)];
    [self.scrollView addSubview:self.innerContent];
    self.scrollView.contentSize = self.innerContent.bounds.size;
    
    // Add pan gesture for dragging menu
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self.headerView addGestureRecognizer:panGesture];
}

- (void)setupTabs {
    self.tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, 44, self.bounds.size.width, 40)];
    self.tabBar.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    [self addSubview:self.tabBar];
    
    NSArray *tabNames = @[@"ESP", @"Cheats", @"Aimbot", @"Misc", @"Config", @"Skins"];
    CGFloat tabWidth = self.bounds.size.width / tabNames.count;
    
    for (int i = 0; i < tabNames.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(i * tabWidth, 0, tabWidth, 40);
        [tabBtn setTitle:tabNames[i] forState:UIControlStateNormal];
        [tabBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        tabBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        tabBtn.tag = i;
        [tabBtn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabBar addSubview:tabBtn];
    }
}

#pragma mark - Build Tabs

- (void)buildESPTab {
    double y = 10;
    
    [self addSectionHeader:@"VISUAL ESP" atY:y];
    y += 26;
    
    // Box ESP
    [self addToggle:@"Box ESP" atY:y action:@selector(boxTapped) enabled:esp_box_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Outline" atY:y action:@selector(boxOutlineTapped) enabled:esp_box_outline 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Fill" atY:y action:@selector(boxFillTapped) enabled:esp_box_fill 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Corner" atY:y action:@selector(boxCornerTapped) enabled:esp_box_corner 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  3D Box" atY:y action:@selector(box3DTapped) enabled:esp_box_3d 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    // Line ESP
    [self addToggle:@"Line ESP" atY:y action:@selector(lineTapped) enabled:esp_line_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Outline" atY:y action:@selector(lineOutlineTapped) enabled:esp_line_outline 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    // Name ESP
    [self addToggle:@"Name ESP" atY:y action:@selector(nameTapped) enabled:esp_name_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Outline" atY:y action:@selector(nameOutlineTapped) enabled:esp_name_outline 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    // Health
    [self addToggle:@"Health ESP" atY:y action:@selector(healthTapped) enabled:esp_health_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Health Bar" atY:y action:@selector(healthBarTapped) enabled:esp_healthbar_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Outline" atY:y action:@selector(healthBarOutlineTapped) enabled:esp_healthbar_outline 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    // Weapon
    [self addToggle:@"Weapon ESP" atY:y action:@selector(weaponTapped) enabled:esp_weapon_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Weapon Icon" atY:y action:@selector(weaponIconTapped) enabled:esp_weapon_icon 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    // Platform & Avatar
    [self addToggle:@"Platform ESP" atY:y action:@selector(platformTapped) enabled:esp_platform_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Avatar ESP" atY:y action:@selector(avatarTapped) enabled:esp_avatar_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    // Arrows
    [self addToggle:@"Arrows ESP" atY:y action:@selector(arrowsTapped) enabled:esp_arrows_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"  Outline" atY:y action:@selector(arrowsOutlineTapped) enabled:esp_arrows_outline 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addArrowsMarginSliderAtY:y];
    y += 60;
    
    // Update content size
    self.innerContent.frame = CGRectMake(0, 0, self.innerContent.frame.size.width, y + 20);
    self.scrollView.contentSize = self.innerContent.frame.size;
}

- (void)buildCheatsTab {
    double y = 10;
    
    [self addSectionHeader:@"WEAPON CHEATS" atY:y];
    y += 26;
    
    [self addToggle:@"Infinite Ammo" atY:y action:@selector(infAmmoTapped) enabled:cheat_inf_ammo 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"No Spread" atY:y action:@selector(noSpreadTapped) enabled:cheat_no_spread 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Fire Rate" atY:y action:@selector(fireRateTapped) enabled:cheat_fire_rate 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Wallshot" atY:y action:@selector(wallshotTapped) enabled:cheat_wallshot 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Fast Knife" atY:y action:@selector(fastKnifeTapped) enabled:cheat_fast_knife 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addSectionHeader:@"MOVEMENT CHEATS" atY:y];
    y += 26;
    
    [self addToggle:@"Air Jump" atY:y action:@selector(airJumpTapped) enabled:cheat_air_jump 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Bunny Hop" atY:y action:@selector(bunnyHopTapped) enabled:cheat_bunny_hop 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addBhopSliderAtY:y];
    y += 60;
    
    [self addSectionHeader:@"OTHER CHEATS" atY:y];
    y += 26;
    
    [self addToggle:@"Add Score" atY:y action:@selector(addskoreTapped) enabled:cheat_add_score 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Invisible" atY:y action:@selector(invisibleTapped) enabled:cheat_invisible 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    self.innerContent.frame = CGRectMake(0, 0, self.innerContent.frame.size.width, y + 20);
    self.scrollView.contentSize = self.innerContent.frame.size;
}

- (void)buildAimbotTab {
    double y = 10;
    
    [self addSectionHeader:@"AIMBOT" atY:y];
    y += 26;
    
    [self addToggle:@"Enable Aimbot" atY:y action:@selector(aimbotTapped) enabled:aimbot_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Team Check" atY:y action:@selector(aimbotTeamTapped) enabled:aimbot_team_check 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Visible Check" atY:y action:@selector(visibleCheckTapped) enabled:aimbot_visible_check 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Shooting Check" atY:y action:@selector(shootingCheckTapped) enabled:aimbot_shooting_check 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"FOV Circle" atY:y action:@selector(aimbotFovTapped) enabled:aimbot_fov_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addBoneSelectorAtY:y];
    y += 36;
    
    [self addFovSliderAtY:y];
    y += 60;
    
    [self addSmoothSliderAtY:y];
    y += 60;
    
    [self addSectionHeader:@"TRIGGERBOT" atY:y];
    y += 26;
    
    [self addToggle:@"Enable Triggerbot" atY:y action:@selector(triggerbotTapped) enabled:triggerbot_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Team Check" atY:y action:@selector(teamTapped) enabled:triggerbot_team_check 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addTriggerDelaySliderAtY:y];
    y += 60;
    
    [self addSectionHeader:@"RECOIL CONTROL" atY:y];
    y += 26;
    
    [self addToggle:@"Enable RCS" atY:y action:@selector(rcsTapped) enabled:rcs_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addRCSHSliderAtY:y];
    y += 60;
    
    [self addRCSVSliderAtY:y];
    y += 60;
    
    self.innerContent.frame = CGRectMake(0, 0, self.innerContent.frame.size.width, y + 20);
    self.scrollView.contentSize = self.innerContent.frame.size;
}

- (void)buildMiscTab {
    double y = 10;
    
    [self addSectionHeader:@"VIEWMODEL" atY:y];
    y += 26;
    
    [self addToggle:@"Custom Viewmodel" atY:y action:@selector(viewmodelTapped) enabled:viewmodel_enabled 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addViewmodelXSliderAtY:y];
    y += 60;
    
    [self addViewmodelYSliderAtY:y];
    y += 60;
    
    [self addViewmodelZSliderAtY:y];
    y += 60;
    
    [self addSectionHeader:@"MISC" atY:y];
    y += 26;
    
    [self addToggle:@"Screenshot Safe" atY:y action:@selector(screenshotSafeTapped) enabled:screenshot_safe 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addToggle:@"Hit Sound" atY:y action:@selector(hitSoundTapped) enabled:hit_sound 
             colorR:NULL g:NULL b:NULL show:NO];
    y += 36;
    
    [self addMenuScaleSliderAtY:y];
    y += 60;
    
    self.innerContent.frame = CGRectMake(0, 0, self.innerContent.frame.size.width, y + 20);
    self.scrollView.contentSize = self.innerContent.frame.size;
}

#pragma mark - UI Helper Methods

- (void)addSectionHeader:(NSString *)title atY:(double)y {
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(12, y, self.innerContent.bounds.size.width - 24, 22)];
    header.text = title;
    header.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:0.55];
    header.font = [UIFont boldSystemFontOfSize:11];
    header.userInteractionEnabled = NO;
    [self.innerContent addSubview:header];
    [self.sectionHeaders addObject:header];
}

- (CAShapeLayer *)addToggle:(NSString *)label 
                        atY:(double)y 
                     action:(SEL)action 
                    enabled:(BOOL)enabled 
                     colorR:(float *)rPtr 
                          g:(float *)gPtr 
                          b:(float *)bPtr 
                       show:(BOOL)showSwatch {
    
    CGRect bounds = self.innerContent.bounds;
    
    // Create row view
    UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, y, bounds.size.width, 30)];
    rowView.userInteractionEnabled = YES;
    rowView.backgroundColor = [UIColor colorWithRed:g_menuR green:g_menuG blue:g_menuB alpha:0.0];
    [self.innerContent addSubview:rowView];
    [self.rowViews addObject:rowView];
    
    // Create label
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, bounds.size.width - 80, 30)];
    textLabel.text = label;
    textLabel.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:1.0];
    textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    textLabel.userInteractionEnabled = NO;
    [rowView addSubview:textLabel];
    [self.toggleLabels addObject:textLabel];
    
    // Create color swatch if needed
    if (rPtr && gPtr && bPtr) {
        UIView *swatch = [[UIView alloc] initWithFrame:CGRectMake(bounds.size.width - 65, 5, 20, 20)];
        swatch.backgroundColor = [UIColor colorWithRed:*rPtr green:*gPtr blue:*bPtr alpha:1.0];
        swatch.layer.cornerRadius = 4.0;
        swatch.layer.borderWidth = 1.5;
        swatch.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        swatch.hidden = !showSwatch;
        swatch.userInteractionEnabled = YES;
        swatch.tag = 9901;
        [rowView addSubview:swatch];
        
        // Store pointers
        NSValue *rValue = [NSValue valueWithPointer:rPtr];
        NSValue *gValue = [NSValue valueWithPointer:gPtr];
        NSValue *bValue = [NSValue valueWithPointer:bPtr];
        objc_setAssociatedObject(swatch, "rPtr", rValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(swatch, "gPtr", gValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(swatch, "bPtr", bValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        UITapGestureRecognizer *swatchTap = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                                     action:@selector(swatchTapped:)];
        [swatch addGestureRecognizer:swatchTap];
    }
    
    // Create checkbox
    UIView *checkbox = [[UIView alloc] initWithFrame:CGRectMake(bounds.size.width - 37, 4, 22, 22)];
    checkbox.layer.borderWidth = 2.0;
    checkbox.layer.borderColor = [UIColor whiteColor].CGColor;
    checkbox.layer.cornerRadius = 4.0;
    checkbox.userInteractionEnabled = NO;
    [rowView addSubview:checkbox];
    
    // Create checkmark layer
    CAShapeLayer *checkmark = [self createCheckmarkLayer:checkbox.bounds];
    checkmark.opacity = enabled ? 1.0 : 0.0;
    [checkbox.layer addSublayer:checkmark];
    
    // Add tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    tap.cancelsTouchesInView = NO;
    [rowView addGestureRecognizer:tap];
    
    return checkmark;
}

- (CAShapeLayer *)createCheckmarkLayer:(CGRect)bounds {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = bounds;
    layer.fillColor = nil;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.lineWidth = 2.5;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(bounds.size.width * 0.2, bounds.size.height * 0.5)];
    [path addLineToPoint:CGPointMake(bounds.size.width * 0.4, bounds.size.height * 0.7)];
    [path addLineToPoint:CGPointMake(bounds.size.width * 0.8, bounds.size.height * 0.3)];
    
    layer.path = path.CGPath;
    return layer;
}

- (void)animateCheckmark:(CAShapeLayer *)checkmark show:(BOOL)show {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.fromValue = @(checkmark.opacity);
    anim.toValue = show ? @1.0 : @0.0;
    anim.duration = 0.2;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    checkmark.opacity = show ? 1.0 : 0.0;
    [checkmark addAnimation:anim forKey:@"opacity"];
}

#pragma mark - Sliders

- (void)addFovSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.fovValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.fovValueLabel.textColor = [UIColor whiteColor];
    self.fovValueLabel.font = [UIFont systemFontOfSize:11];
    self.fovValueLabel.textAlignment = NSTextAlignmentRight;
    self.fovValueLabel.text = [NSString stringWithFormat:@"%.0f", aimbot_fov];
    [self.innerContent addSubview:self.fovValueLabel];
    
    self.fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.fovSlider.minimumValue = 10.0;
    self.fovSlider.maximumValue = 180.0;
    self.fovSlider.value = aimbot_fov;
    [self.fovSlider addTarget:self action:@selector(fovSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.fovSlider];
}

- (void)fovSliderChanged:(UISlider *)slider {
    aimbot_fov = slider.value;
    self.fovValueLabel.text = [NSString stringWithFormat:@"%.0f", aimbot_fov];
}

- (void)addSmoothSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.smoothValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.smoothValueLabel.textColor = [UIColor whiteColor];
    self.smoothValueLabel.font = [UIFont systemFontOfSize:11];
    self.smoothValueLabel.textAlignment = NSTextAlignmentRight;
    self.smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
    [self.innerContent addSubview:self.smoothValueLabel];
    
    self.smoothSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.smoothSlider.minimumValue = 1.0;
    self.smoothSlider.maximumValue = 20.0;
    self.smoothSlider.value = aimbot_smooth;
    [self.smoothSlider addTarget:self action:@selector(smoothSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.smoothSlider];
}

- (void)smoothSliderChanged:(UISlider *)slider {
    aimbot_smooth = slider.value;
    self.smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
}

- (void)addTriggerDelaySliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.triggerDelayValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.triggerDelayValueLabel.textColor = [UIColor whiteColor];
    self.triggerDelayValueLabel.font = [UIFont systemFontOfSize:11];
    self.triggerDelayValueLabel.textAlignment = NSTextAlignmentRight;
    self.triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.0fms", triggerbot_delay];
    [self.innerContent addSubview:self.triggerDelayValueLabel];
    
    self.triggerDelaySlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.triggerDelaySlider.minimumValue = 0.0;
    self.triggerDelaySlider.maximumValue = 500.0;
    self.triggerDelaySlider.value = triggerbot_delay;
    [self.triggerDelaySlider addTarget:self action:@selector(triggerDelaySliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.triggerDelaySlider];
}

- (void)triggerDelaySliderChanged:(UISlider *)slider {
    triggerbot_delay = slider.value;
    self.triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.0fms", triggerbot_delay];
}

- (void)addRCSHSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.rcsHValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.rcsHValueLabel.textColor = [UIColor whiteColor];
    self.rcsHValueLabel.font = [UIFont systemFontOfSize:11];
    self.rcsHValueLabel.textAlignment = NSTextAlignmentRight;
    self.rcsHValueLabel.text = [NSString stringWithFormat:@"%.1f", rcs_horizontal];
    [self.innerContent addSubview:self.rcsHValueLabel];
    
    self.rcsHSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.rcsHSlider.minimumValue = 0.0;
    self.rcsHSlider.maximumValue = 2.0;
    self.rcsHSlider.value = rcs_horizontal;
    [self.rcsHSlider addTarget:self action:@selector(rcsHSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.rcsHSlider];
}

- (void)rcsHSliderChanged:(UISlider *)slider {
    rcs_horizontal = slider.value;
    self.rcsHValueLabel.text = [NSString stringWithFormat:@"%.1f", rcs_horizontal];
}

- (void)addRCSVSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.rcsVValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.rcsVValueLabel.textColor = [UIColor whiteColor];
    self.rcsVValueLabel.font = [UIFont systemFontOfSize:11];
    self.rcsVValueLabel.textAlignment = NSTextAlignmentRight;
    self.rcsVValueLabel.text = [NSString stringWithFormat:@"%.1f", rcs_vertical];
    [self.innerContent addSubview:self.rcsVValueLabel];
    
    self.rcsVSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.rcsVSlider.minimumValue = 0.0;
    self.rcsVSlider.maximumValue = 2.0;
    self.rcsVSlider.value = rcs_vertical;
    [self.rcsVSlider addTarget:self action:@selector(rcsVSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.rcsVSlider];
}

- (void)rcsVSliderChanged:(UISlider *)slider {
    rcs_vertical = slider.value;
    self.rcsVValueLabel.text = [NSString stringWithFormat:@"%.1f", rcs_vertical];
}

- (void)addBhopSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.bhopValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.bhopValueLabel.textColor = [UIColor whiteColor];
    self.bhopValueLabel.font = [UIFont systemFontOfSize:11];
    self.bhopValueLabel.textAlignment = NSTextAlignmentRight;
    self.bhopValueLabel.text = [NSString stringWithFormat:@"%.1f", bhop_speed];
    [self.innerContent addSubview:self.bhopValueLabel];
    
    self.bhopSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.bhopSlider.minimumValue = 1.0;
    self.bhopSlider.maximumValue = 5.0;
    self.bhopSlider.value = bhop_speed;
    [self.bhopSlider addTarget:self action:@selector(bhopSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.bhopSlider];
}

- (void)bhopSliderChanged:(UISlider *)slider {
    bhop_speed = slider.value;
    self.bhopValueLabel.text = [NSString stringWithFormat:@"%.1f", bhop_speed];
}

- (void)addViewmodelXSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.viewmodelXValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.viewmodelXValueLabel.textColor = [UIColor whiteColor];
    self.viewmodelXValueLabel.font = [UIFont systemFontOfSize:11];
    self.viewmodelXValueLabel.textAlignment = NSTextAlignmentRight;
    self.viewmodelXValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_x];
    [self.innerContent addSubview:self.viewmodelXValueLabel];
    
    self.viewmodelXSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.viewmodelXSlider.minimumValue = -10.0;
    self.viewmodelXSlider.maximumValue = 10.0;
    self.viewmodelXSlider.value = viewmodel_x;
    [self.viewmodelXSlider addTarget:self action:@selector(viewmodelXSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.viewmodelXSlider];
}

- (void)viewmodelXSliderChanged:(UISlider *)slider {
    viewmodel_x = slider.value;
    self.viewmodelXValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_x];
}

- (void)addViewmodelYSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.viewmodelYValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.viewmodelYValueLabel.textColor = [UIColor whiteColor];
    self.viewmodelYValueLabel.font = [UIFont systemFontOfSize:11];
    self.viewmodelYValueLabel.textAlignment = NSTextAlignmentRight;
    self.viewmodelYValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_y];
    [self.innerContent addSubview:self.viewmodelYValueLabel];
    
    self.viewmodelYSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.viewmodelYSlider.minimumValue = -10.0;
    self.viewmodelYSlider.maximumValue = 10.0;
    self.viewmodelYSlider.value = viewmodel_y;
    [self.viewmodelYSlider addTarget:self action:@selector(viewmodelYSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.viewmodelYSlider];
}

- (void)viewmodelYSliderChanged:(UISlider *)slider {
    viewmodel_y = slider.value;
    self.viewmodelYValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_y];
}

- (void)addViewmodelZSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.viewmodelZValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.viewmodelZValueLabel.textColor = [UIColor whiteColor];
    self.viewmodelZValueLabel.font = [UIFont systemFontOfSize:11];
    self.viewmodelZValueLabel.textAlignment = NSTextAlignmentRight;
    self.viewmodelZValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_z];
    [self.innerContent addSubview:self.viewmodelZValueLabel];
    
    self.viewmodelZSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.viewmodelZSlider.minimumValue = -10.0;
    self.viewmodelZSlider.maximumValue = 10.0;
    self.viewmodelZSlider.value = viewmodel_z;
    [self.viewmodelZSlider addTarget:self action:@selector(viewmodelZSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.viewmodelZSlider];
}

- (void)viewmodelZSliderChanged:(UISlider *)slider {
    viewmodel_z = slider.value;
    self.viewmodelZValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_z];
}

- (void)addArrowsMarginSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.arrowsMarginValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.arrowsMarginValueLabel.textColor = [UIColor whiteColor];
    self.arrowsMarginValueLabel.font = [UIFont systemFontOfSize:11];
    self.arrowsMarginValueLabel.textAlignment = NSTextAlignmentRight;
    self.arrowsMarginValueLabel.text = [NSString stringWithFormat:@"%.0f", esp_arrows_margin];
    [self.innerContent addSubview:self.arrowsMarginValueLabel];
    
    self.arrowsMarginSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.arrowsMarginSlider.minimumValue = 50.0;
    self.arrowsMarginSlider.maximumValue = 300.0;
    self.arrowsMarginSlider.value = esp_arrows_margin;
    [self.arrowsMarginSlider addTarget:self action:@selector(arrowsMarginSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.arrowsMarginSlider];
}

- (void)arrowsMarginSliderChanged:(UISlider *)slider {
    esp_arrows_margin = slider.value;
    self.arrowsMarginValueLabel.text = [NSString stringWithFormat:@"%.0f", esp_arrows_margin];
}

- (void)addMenuScaleSliderAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    
    self.menuScaleValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 60, y - 24, 50, 20)];
    self.menuScaleValueLabel.textColor = [UIColor whiteColor];
    self.menuScaleValueLabel.font = [UIFont systemFontOfSize:11];
    self.menuScaleValueLabel.textAlignment = NSTextAlignmentRight;
    self.menuScaleValueLabel.text = [NSString stringWithFormat:@"%.1f", menu_scale];
    [self.innerContent addSubview:self.menuScaleValueLabel];
    
    self.menuScaleSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    self.menuScaleSlider.minimumValue = 0.5;
    self.menuScaleSlider.maximumValue = 1.5;
    self.menuScaleSlider.value = menu_scale;
    [self.menuScaleSlider addTarget:self action:@selector(menuScaleSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.innerContent addSubview:self.menuScaleSlider];
}

- (void)menuScaleSliderChanged:(UISlider *)slider {
    menu_scale = slider.value;
    self.menuScaleValueLabel.text = [NSString stringWithFormat:@"%.1f", menu_scale];
    self.transform = CGAffineTransformMakeScale(menu_scale, menu_scale);
}

- (void)addBoneSelectorAtY:(double)y {
    CGFloat width = self.innerContent.bounds.size.width;
    NSArray *bones = @[@"Head", @"Chest", @"Pelvis"];
    CGFloat btnWidth = (width - 40) / 3.0;
    
    for (int i = 0; i < bones.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(15 + i * (btnWidth + 5), y, btnWidth, 30);
        [btn setTitle:bones[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        btn.backgroundColor = (aimbot_bone == i) ? [UIColor colorWithWhite:0.3 alpha:1.0] : [UIColor colorWithWhite:0.15 alpha:1.0];
        btn.layer.cornerRadius = 4.0;
        btn.tag = i;
        [btn addTarget:self action:@selector(boneTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.innerContent addSubview:btn];
    }
}

- (void)boneTapped:(UIButton *)sender {
    aimbot_bone = (int)sender.tag;
    
    for (UIView *subview in self.innerContent.subviews) {
        if ([subview isKindOfClass:[UIButton class]] && subview.tag < 3) {
            UIButton *btn = (UIButton *)subview;
            btn.backgroundColor = (btn.tag == aimbot_bone) ? [UIColor colorWithWhite:0.3 alpha:1.0] : [UIColor colorWithWhite:0.15 alpha:1.0];
        }
    }
}

#pragma mark - Toggle Handlers

// ESP Toggles
- (void)boxTapped {
    esp_box_enabled = !esp_box_enabled;
    [self updateCheckmarkForSelector:@selector(boxTapped) enabled:esp_box_enabled];
}

- (void)boxOutlineTapped {
    esp_box_outline = !esp_box_outline;
    [self updateCheckmarkForSelector:@selector(boxOutlineTapped) enabled:esp_box_outline];
}

- (void)boxFillTapped {
    esp_box_fill = !esp_box_fill;
    [self updateCheckmarkForSelector:@selector(boxFillTapped) enabled:esp_box_fill];
}

- (void)boxCornerTapped {
    esp_box_corner = !esp_box_corner;
    [self updateCheckmarkForSelector:@selector(boxCornerTapped) enabled:esp_box_corner];
}

- (void)box3DTapped {
    esp_box_3d = !esp_box_3d;
    [self updateCheckmarkForSelector:@selector(box3DTapped) enabled:esp_box_3d];
}

- (void)lineTapped {
    esp_line_enabled = !esp_line_enabled;
    [self updateCheckmarkForSelector:@selector(lineTapped) enabled:esp_line_enabled];
}

- (void)lineOutlineTapped {
    esp_line_outline = !esp_line_outline;
    [self updateCheckmarkForSelector:@selector(lineOutlineTapped) enabled:esp_line_outline];
}

- (void)nameTapped {
    esp_name_enabled = !esp_name_enabled;
    [self updateCheckmarkForSelector:@selector(nameTapped) enabled:esp_name_enabled];
}

- (void)nameOutlineTapped {
    esp_name_outline = !esp_name_outline;
    [self updateCheckmarkForSelector:@selector(nameOutlineTapped) enabled:esp_name_outline];
}

- (void)healthTapped {
    esp_health_enabled = !esp_health_enabled;
    [self updateCheckmarkForSelector:@selector(healthTapped) enabled:esp_health_enabled];
}

- (void)healthBarTapped {
    esp_healthbar_enabled = !esp_healthbar_enabled;
    [self updateCheckmarkForSelector:@selector(healthBarTapped) enabled:esp_healthbar_enabled];
}

- (void)healthBarOutlineTapped {
    esp_healthbar_outline = !esp_healthbar_outline;
    [self updateCheckmarkForSelector:@selector(healthBarOutlineTapped) enabled:esp_healthbar_outline];
}

- (void)weaponTapped {
    esp_weapon_enabled = !esp_weapon_enabled;
    [self updateCheckmarkForSelector:@selector(weaponTapped) enabled:esp_weapon_enabled];
}

- (void)weaponIconTapped {
    esp_weapon_icon = !esp_weapon_icon;
    [self updateCheckmarkForSelector:@selector(weaponIconTapped) enabled:esp_weapon_icon];
}

- (void)platformTapped {
    esp_platform_enabled = !esp_platform_enabled;
    [self updateCheckmarkForSelector:@selector(platformTapped) enabled:esp_platform_enabled];
}

- (void)avatarTapped {
    esp_avatar_enabled = !esp_avatar_enabled;
    [self updateCheckmarkForSelector:@selector(avatarTapped) enabled:esp_avatar_enabled];
}

- (void)arrowsTapped {
    esp_arrows_enabled = !esp_arrows_enabled;
    [self updateCheckmarkForSelector:@selector(arrowsTapped) enabled:esp_arrows_enabled];
}

- (void)arrowsOutlineTapped {
    esp_arrows_outline = !esp_arrows_outline;
    [self updateCheckmarkForSelector:@selector(arrowsOutlineTapped) enabled:esp_arrows_outline];
}

// Cheat Toggles
- (void)infAmmoTapped {
    cheat_inf_ammo = !cheat_inf_ammo;
    [self updateCheckmarkForSelector:@selector(infAmmoTapped) enabled:cheat_inf_ammo];
}

- (void)noSpreadTapped {
    cheat_no_spread = !cheat_no_spread;
    [self updateCheckmarkForSelector:@selector(noSpreadTapped) enabled:cheat_no_spread];
}

- (void)airJumpTapped {
    cheat_air_jump = !cheat_air_jump;
    [self updateCheckmarkForSelector:@selector(airJumpTapped) enabled:cheat_air_jump];
}

- (void)fastKnifeTapped {
    cheat_fast_knife = !cheat_fast_knife;
    [self updateCheckmarkForSelector:@selector(fastKnifeTapped) enabled:cheat_fast_knife];
}

- (void)bunnyHopTapped {
    cheat_bunny_hop = !cheat_bunny_hop;
    [self updateCheckmarkForSelector:@selector(bunnyHopTapped) enabled:cheat_bunny_hop];
}

- (void)wallshotTapped {
    cheat_wallshot = !cheat_wallshot;
    [self updateCheckmarkForSelector:@selector(wallshotTapped) enabled:cheat_wallshot];
}

- (void)fireRateTapped {
    cheat_fire_rate = !cheat_fire_rate;
    [self updateCheckmarkForSelector:@selector(fireRateTapped) enabled:cheat_fire_rate];
}

- (void)addskoreTapped {
    cheat_add_score = !cheat_add_score;
    [self updateCheckmarkForSelector:@selector(addskoreTapped) enabled:cheat_add_score];
}

- (void)invisibleTapped {
    cheat_invisible = !cheat_invisible;
    [self updateCheckmarkForSelector:@selector(invisibleTapped) enabled:cheat_invisible];
}

// Aimbot Toggles
- (void)aimbotTapped {
    aimbot_enabled = !aimbot_enabled;
    [self updateCheckmarkForSelector:@selector(aimbotTapped) enabled:aimbot_enabled];
}

- (void)aimbotTeamTapped {
    aimbot_team_check = !aimbot_team_check;
    [self updateCheckmarkForSelector:@selector(aimbotTeamTapped) enabled:aimbot_team_check];
}

- (void)visibleCheckTapped {
    aimbot_visible_check = !aimbot_visible_check;
    [self updateCheckmarkForSelector:@selector(visibleCheckTapped) enabled:aimbot_visible_check];
}

- (void)shootingCheckTapped {
    aimbot_shooting_check = !aimbot_shooting_check;
    [self updateCheckmarkForSelector:@selector(shootingCheckTapped) enabled:aimbot_shooting_check];
}

- (void)aimbotFovTapped {
    aimbot_fov_enabled = !aimbot_fov_enabled;
    [self updateCheckmarkForSelector:@selector(aimbotFovTapped) enabled:aimbot_fov_enabled];
}

- (void)triggerbotTapped {
    triggerbot_enabled = !triggerbot_enabled;
    [self updateCheckmarkForSelector:@selector(triggerbotTapped) enabled:triggerbot_enabled];
}

- (void)teamTapped {
    triggerbot_team_check = !triggerbot_team_check;
    [self updateCheckmarkForSelector:@selector(teamTapped) enabled:triggerbot_team_check];
}

- (void)rcsTapped {
    rcs_enabled = !rcs_enabled;
    [self updateCheckmarkForSelector:@selector(rcsTapped) enabled:rcs_enabled];
}

// Misc Toggles
- (void)viewmodelTapped {
    viewmodel_enabled = !viewmodel_enabled;
    [self updateCheckmarkForSelector:@selector(viewmodelTapped) enabled:viewmodel_enabled];
}

- (void)screenshotSafeTapped {
    screenshot_safe = !screenshot_safe;
    [self updateCheckmarkForSelector:@selector(screenshotSafeTapped) enabled:screenshot_safe];
}

- (void)hitSoundTapped {
    hit_sound = !hit_sound;
    [self updateCheckmarkForSelector:@selector(hitSoundTapped) enabled:hit_sound];
}

- (void)updateCheckmarkForSelector:(SEL)selector enabled:(BOOL)enabled {
    for (UIView *rowView in self.rowViews) {
        for (UIGestureRecognizer *gesture in rowView.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gesture;
                if (tap.view == rowView) {
                    for (UIView *subview in rowView.subviews) {
                        if (subview.layer.sublayers.count > 0) {
                            for (CALayer *layer in subview.layer.sublayers) {
                                if ([layer isKindOfClass:[CAShapeLayer class]]) {
                                    [self animateCheckmark:(CAShapeLayer *)layer show:enabled];
                                    return;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#pragma mark - Color Row

- (void)addColorRow:(NSString *)label 
               atY:(double)y 
            inView:(UIView *)container 
              rPtr:(float *)rPtr 
              gPtr:(float *)gPtr 
              bPtr:(float *)bPtr 
          onChange:(void (^)(void))onChange {
    
    CGRect bounds = container.bounds;
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, y + 8, bounds.size.width - 60, 20)];
    textLabel.text = label;
    textLabel.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:1.0];
    textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [container addSubview:textLabel];
    
    UIView *swatch = [[UIView alloc] initWithFrame:CGRectMake(bounds.size.width - 46, y + 5, 26, 26)];
    swatch.backgroundColor = [UIColor colorWithRed:*rPtr green:*gPtr blue:*bPtr alpha:1.0];
    swatch.layer.cornerRadius = 6.0;
    swatch.layer.borderWidth = 1.5;
    swatch.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    swatch.userInteractionEnabled = YES;
    [container addSubview:swatch];
    
    NSValue *rValue = [NSValue valueWithPointer:rPtr];
    NSValue *gValue = [NSValue valueWithPointer:gPtr];
    NSValue *bValue = [NSValue valueWithPointer:bPtr];
    
    objc_setAssociatedObject(swatch, "rPtr", rValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(swatch, "gPtr", gValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(swatch, "bPtr", bValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(swatch, "onChange", onChange, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                           action:@selector(colorRowSwatchTapped:)];
    [swatch addGestureRecognizer:tap];
}

- (void)colorRowSwatchTapped:(UITapGestureRecognizer *)gesture {
    UIView *swatch = gesture.view;
    
    NSValue *rValue = objc_getAssociatedObject(swatch, "rPtr");
    NSValue *gValue = objc_getAssociatedObject(swatch, "gPtr");
    NSValue *bValue = objc_getAssociatedObject(swatch, "bPtr");
    void (^onChange)(void) = objc_getAssociatedObject(swatch, "onChange");
    
    if (!rValue || !gValue || !bValue) return;
    
    float *rPtr = (float *)[rValue pointerValue];
    float *gPtr = (float *)[gValue pointerValue];
    float *bPtr = (float *)[bValue pointerValue];
    
    [self showColorPickerForSwatch:swatch rPtr:rPtr gPtr:gPtr bPtr:bPtr onChange:onChange];
}

- (void)swatchTapped:(UITapGestureRecognizer *)gesture {
    UIView *swatch = gesture.view;
    
    NSValue *rValue = objc_getAssociatedObject(swatch, "rPtr");
    NSValue *gValue = objc_getAssociatedObject(swatch, "gPtr");
    NSValue *bValue = objc_getAssociatedObject(swatch, "bPtr");
    
    if (!rValue || !gValue || !bValue) return;
    
    float *rPtr = (float *)[rValue pointerValue];
    float *gPtr = (float *)[gValue pointerValue];
    float *bPtr = (float *)[bValue pointerValue];
    
    [self showColorPickerForSwatch:swatch rPtr:rPtr gPtr:gPtr bPtr:bPtr onChange:nil];
}

- (void)showColorPickerForSwatch:(UIView *)swatch 
                            rPtr:(float *)rPtr 
                            gPtr:(float *)gPtr 
                            bPtr:(float *)bPtr 
                        onChange:(void (^)(void))onChange {
    
    if (qword_100093BB0) {
        [qword_100093BB0 removeFromSuperview];
        qword_100093BB0 = nil;
    }
    
    UIWindow *window = swatch.window;
    if (!window) return;
    
    UIView *popupBg = [[UIView alloc] initWithFrame:window.bounds];
    popupBg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.01];
    popupBg.userInteractionEnabled = YES;
    qword_100093BB0 = popupBg;
    [window addSubview:popupBg];
    
    CGFloat pickerWidth = fmin(window.bounds.size.width * 0.85, 300.0);
    CGFloat pickerHeight = pickerWidth * 0.55 + 18.0 + 18.0 + 10.0 + 36.0 + 24.0 + 16.0;
    
    UIView *pickerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerWidth, pickerHeight)];
    pickerContainer.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.97];
    pickerContainer.layer.cornerRadius = 12.0;
    pickerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    pickerContainer.layer.shadowRadius = 12.0;
    pickerContainer.layer.shadowOpacity = 0.5;
    pickerContainer.layer.shadowOffset = CGSizeZero;
    pickerContainer.userInteractionEnabled = YES;
    
    ColorPickerView *picker = [[ColorPickerView alloc] initWithFrame:CGRectMake(8, 8, pickerWidth - 16, pickerHeight - 16)
                                                            initialR:*rPtr 
                                                                   g:*gPtr 
                                                                   b:*bPtr];
    
    picker.onChange = ^{
        UIColor *color = [UIColor colorWithHue:picker.hue 
                                    saturation:picker.saturation 
                                    brightness:picker.brightness 
                                         alpha:picker.alpha];
        CGFloat r, g, b, a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        
        *rPtr = r;
        *gPtr = g;
        *bPtr = b;
        
        swatch.backgroundColor = [UIColor colorWithRed:*rPtr green:*gPtr blue:*bPtr alpha:1.0];
        
        if (onChange) {
            onChange();
        }
    };
    
    [pickerContainer addSubview:picker];
    
    pickerContainer.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    CGRect swatchFrame = [swatch convertRect:swatch.bounds toView:window];
    CGFloat pickerX = swatchFrame.origin.x - pickerHeight - 8.0;
    if (pickerX < 8.0) {
        pickerX = swatchFrame.origin.x + swatchFrame.size.width + 8.0;
    }
    CGFloat pickerY = window.bounds.size.height - pickerWidth - 8.0;
    if (swatchFrame.origin.y - pickerWidth * 0.5 < pickerY) {
        pickerY = swatchFrame.origin.y - pickerWidth * 0.5;
    }
    pickerY = fmax(pickerY, 8.0);
    
    pickerContainer.center = CGPointMake(pickerHeight * 0.5 + pickerX, pickerWidth * 0.5 + pickerY);
    [popupBg addSubview:pickerContainer];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:pickerContainer 
                                                                                 action:@selector(handlePopupDrag:)];
    panGesture.cancelsTouchesInView = NO;
    [pickerContainer addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:popupBg 
                                                                                  action:@selector(handleDismissTap:)];
    [popupBg addGestureRecognizer:dismissTap];
    
    void (^dismissBlock)(void) = ^{
        [popupBg removeFromSuperview];
        qword_100093BB0 = nil;
    };
    objc_setAssociatedObject(popupBg, "dismissBlock", dismissBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Tab Management

- (void)tabTapped:(UIButton *)sender {
    [self showTab:(int)sender.tag];
}

- (void)showTab:(int)tabIndex {
    self.currentTab = tabIndex;
    
    for (UIView *subview in self.innerContent.subviews) {
        [subview removeFromSuperview];
    }
    [self.rowViews removeAllObjects];
    [self.toggleLabels removeAllObjects];
    [self.sectionHeaders removeAllObjects];
    
    switch (tabIndex) {
        case 0: [self buildESPTab]; break;
        case 1: [self buildCheatsTab]; break;
        case 2: [self buildAimbotTab]; break;
        case 3: [self buildMiscTab]; break;
        case 4: /* Config tab */ break;
        case 5: /* Skin tab */ break;
    }
    
    for (UIView *subview in self.tabBar.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)subview;
            btn.backgroundColor = (btn.tag == tabIndex) ? [UIColor colorWithWhite:0.2 alpha:1.0] : [UIColor clearColor];
        }
    }
    
    [self.scrollView setContentOffset:CGPointZero animated:NO];
}

#pragma mark - Gestures

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastPanPoint = self.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.center = CGPointMake(self.lastPanPoint.x + translation.x, 
                                 self.lastPanPoint.y + translation.y);
    }
}

- (void)toggleCollapse {
    self.isCollapsed = !self.isCollapsed;
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isCollapsed) {
            self.scrollView.alpha = 0.0;
            self.tabBar.alpha = 0.0;
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 
                                   self.frame.size.width, 44);
        } else {
            self.scrollView.alpha = 1.0;
            self.tabBar.alpha = 1.0;
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 
                                   self.frame.size.width, 500);
        }
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
       shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint point = [touch locationInView:self];
        return point.y < 44;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

#pragma mark - Lifecycle

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        [self centerMenu];
    }
}

- (void)centerMenu {
    if (self.superview) {
        CGRect superBounds = self.superview.bounds;
        self.center = CGPointMake(superBounds.size.width / 2, superBounds.size.height / 2);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

#pragma mark - UIView Category for Popup Gestures

@implementation UIView (PopupGestures)

- (void)handlePopupDrag:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.center = CGPointMake(self.center.x + translation.x, 
                                 self.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:self.superview];
    }
}

- (void)handleDismissTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    
    BOOL hitPicker = NO;
    for (UIView *subview in self.subviews) {
        if (CGRectContainsPoint(subview.frame, point)) {
            hitPicker = YES;
            break;
        }
    }
    
    if (!hitPicker) {
        void (^dismissBlock)(void) = objc_getAssociatedObject(self, "dismissBlock");
        if (dismissBlock) {
            dismissBlock();
        }
    }
}

@end

//
//  ESP_View.h
//  WXR
//
//  ESP rendering view for Standoff 2
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

@class MenuView;

@interface ESP_View : UIView

// Rendering layers
@property (nonatomic, strong) CAShapeLayer *espBoxLayer;
@property (nonatomic, strong) CAShapeLayer *espBoxFillLayer;
@property (nonatomic, strong) CAShapeLayer *espBoxOutlineLayer;
@property (nonatomic, strong) CAShapeLayer *espLineLayer;
@property (nonatomic, strong) CAShapeLayer *espLineOutlineLayer;
@property (nonatomic, strong) CAShapeLayer *espHealthBarLayer;
@property (nonatomic, strong) CAShapeLayer *espHealthBarLayerOrange;
@property (nonatomic, strong) CAShapeLayer *espHealthBarLayerRed;
@property (nonatomic, strong) CAShapeLayer *espHealthBarOutlineLayer;
@property (nonatomic, strong) CAShapeLayer *fovCircleLayer;
@property (nonatomic, strong) CAShapeLayer *fovCircleOutlineLayer;
@property (nonatomic, strong) CAShapeLayer *arrowsLayer;
@property (nonatomic, strong) CAShapeLayer *arrowsOutlineLayer;

// Label pools
@property (nonatomic, strong) NSMutableArray *nameLabelPool;
@property (nonatomic, strong) NSMutableArray *healthLabelPool;
@property (nonatomic, strong) NSMutableArray *weaponLabelPool;
@property (nonatomic, strong) NSMutableArray *weaponIconPool;
@property (nonatomic, strong) NSMutableArray *platformLabelPool;
@property (nonatomic, strong) NSMutableArray *avatarPool;

// UI elements
@property (nonatomic, strong) UILabel *watermarkLabel;
@property (nonatomic, strong) UILabel *playerCountLabel;
@property (nonatomic, strong) UILabel *noPlayersLabel;
@property (nonatomic, strong) MenuView *menuView;

// Display link
@property (nonatomic, strong) CADisplayLink *displayLinkData;

// Aimbot state
@property (nonatomic, assign) uint64_t aimbotCurrentTarget;
@property (nonatomic, assign) double aimbotLastWriteTime;

// Triggerbot state
@property (nonatomic, assign) BOOL triggerbotShooting;
@property (nonatomic, assign) double triggerbotLastShotTime;

// Hit sound
@property (nonatomic, strong) AVAudioEngine *hitAudioEngine;
@property (nonatomic, strong) AVAudioPlayerNode *hitPlayerNode;
@property (nonatomic, strong) AVAudioPCMBuffer *hitSoundBuffer;
@property (nonatomic, strong) NSMutableDictionary *prevHpMap;
@property (nonatomic, assign) BOOL hitSoundReady;

// Flags
@property (nonatomic, assign) BOOL hasAttemptedLaunch;
@property (nonatomic, assign) BOOL isESPCountEnabled;

// Methods
- (void)update_data;
- (void)clearAllBoxes;
- (void)launchGame;
- (void)startBackgroundKeeper;
- (void)runAimbot:(uint64_t)localPlayer 
          players:(uint64_t)playersPtr 
            count:(int)playerCount 
        localTeam:(int)localTeam 
             task:(unsigned int)task 
            width:(double)width 
           height:(double)height 
       viewMatrix:(float[16])matrix;
- (void)applyViewmodelSettings:(uint64_t)localPlayer task:(unsigned int)task;

@end

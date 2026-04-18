//
//  ESP_View.m
//  WXR
//
//  ESP rendering implementation
//

#import "ESP_View.h"
#import "MenuView.h"
#import "MemoryUtils.h"
#import "MathUtils.h"

// Global ESP settings
BOOL esp_box_enabled = NO;
BOOL esp_box_3d = NO;
BOOL esp_box_corner = NO;
BOOL esp_box_fill = NO;
BOOL esp_box_outline = NO;
float esp_box_r = 1.0f, esp_box_g = 1.0f, esp_box_b = 1.0f;
float esp_box_outline_r = 0.0f, esp_box_outline_g = 0.0f, esp_box_outline_b = 0.0f;

BOOL esp_line_enabled = NO;
BOOL esp_line_outline = NO;
int esp_line_origin = 1; // 0=top, 1=center, 2=bottom
float esp_line_r = 1.0f, esp_line_g = 1.0f, esp_line_b = 1.0f;
float esp_line_outline_r = 0.0f, esp_line_outline_g = 0.0f, esp_line_outline_b = 0.0f;

BOOL esp_name_enabled = NO;
BOOL esp_name_outline = NO;

BOOL esp_health_enabled = NO;
BOOL esp_health_bar_enabled = NO;
BOOL esp_health_bar_outline = NO;

BOOL esp_weapon_enabled = NO;
BOOL esp_weapon_icon_enabled = NO;

BOOL esp_platform_enabled = NO;
BOOL esp_avatar_enabled = NO;

BOOL esp_arrows_enabled = NO;
BOOL esp_arrows_outline = NO;
float esp_arrows_margin = 50.0f;
float esp_arrows_r = 1.0f, esp_arrows_g = 1.0f, esp_arrows_b = 1.0f;
float esp_arrows_outline_r = 0.0f, esp_arrows_outline_g = 0.0f, esp_arrows_outline_b = 0.0f;

BOOL esp_team_check = YES;

// Cheat settings
BOOL esp_inf_ammo = NO;
BOOL esp_no_spread = NO;
BOOL esp_air_jump = NO;
BOOL esp_fast_knife = NO;
BOOL esp_bunny_hop = NO;
int esp_bhop_setting = 10;
BOOL esp_wallshot = NO;
BOOL esp_fire_rate = NO;
BOOL esp_addscore = NO;
BOOL esp_invisible = NO;

BOOL esp_rcs_enabled = NO;
int esp_rcs_h = 0;
int esp_rcs_v = 0;

// Aimbot settings
BOOL aimbot_enabled = NO;
BOOL aimbot_fov_enabled = NO;
float aimbot_fov = 100.0f;
float aimbot_smooth = 1.0f;
BOOL aimbot_visible_check = NO;
BOOL aimbot_shooting_check = NO;
BOOL aimbot_team_check = YES;
int aimbot_bone = 0; // 0=head, 1=chest, etc

// Triggerbot settings
BOOL triggerbot_enabled = NO;
float triggerbot_delay = 0.0f;

// Hit sound
BOOL esp_hit_sound_enabled = NO;

// Process info
static int cached_pid = 0;
static unsigned int cached_task = 0;
static uint64_t cached_base = 0;

@implementation ESP_View

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    self.hasAttemptedLaunch = NO;
    self.isESPCountEnabled = NO;
    self.userInteractionEnabled = YES;
    
    // Setup box fill layer
    self.espBoxFillLayer = [CAShapeLayer layer];
    self.espBoxFillLayer.fillColor = [[UIColor colorWithWhite:1.0 alpha:0.3] CGColor];
    self.espBoxFillLayer.strokeColor = [[UIColor clearColor] CGColor];
    [self.layer addSublayer:self.espBoxFillLayer];
    
    // Setup box outline layer
    self.espBoxOutlineLayer = [CAShapeLayer layer];
    self.espBoxOutlineLayer.strokeColor = [[UIColor blackColor] CGColor];
    self.espBoxOutlineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.espBoxOutlineLayer.lineWidth = 3.0;
    [self.layer addSublayer:self.espBoxOutlineLayer];
    
    // Setup box layer
    self.espBoxLayer = [CAShapeLayer layer];
    self.espBoxLayer.strokeColor = [[UIColor whiteColor] CGColor];
    self.espBoxLayer.fillColor = [[UIColor clearColor] CGColor];
    self.espBoxLayer.lineWidth = 1.5;
    [self.layer addSublayer:self.espBoxLayer];
    
    // Setup health bar layers
    [self setupHealthBarLayers];
    
    // Setup line layers
    [self setupLineLayers];
    
    // Setup FOV circle layers
    [self setupFOVLayers];
    
    // Setup arrows layers
    [self setupArrowsLayers];
    
    // Setup label pools
    self.nameLabelPool = [NSMutableArray new];
    self.healthLabelPool = [NSMutableArray new];
    self.weaponLabelPool = [NSMutableArray new];
    self.weaponIconPool = [NSMutableArray new];
    self.platformLabelPool = [NSMutableArray new];
    self.avatarPool = [NSMutableArray new];
    
    // Setup watermark
    [self setupWatermark];
    
    // Setup aimbot state
    self.aimbotCurrentTarget = 0;
    self.aimbotLastWriteTime = 0.0;
    self.triggerbotShooting = NO;
    self.triggerbotLastShotTime = 0.0;
    
    // Setup hit sound
    self.prevHpMap = [NSMutableDictionary new];
    self.hitSoundReady = NO;
    
    // Setup menu
    self.menuView = [[MenuView alloc] initWithFrame:CGRectMake(0, 0, 270, 280)];
    self.menuView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
    [self addSubview:self.menuView];
    
    // Setup display link
    self.displayLinkData = [CADisplayLink displayLinkWithTarget:self selector:@selector(update_data)];
    self.displayLinkData.preferredFramesPerSecond = 120;
    [self.displayLinkData addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // Start background keeper
    [self startBackgroundKeeper];
    
    // Register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(clearAllBoxes) 
                                                 name:@"ESPClearBoxes" 
                                               object:nil];
}

- (void)setupHealthBarLayers {
    // Health bar outline
    self.espHealthBarOutlineLayer = [CAShapeLayer layer];
    self.espHealthBarOutlineLayer.strokeColor = [[UIColor blackColor] CGColor];
    self.espHealthBarOutlineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.espHealthBarOutlineLayer.lineWidth = 3.0;
    [self.layer addSublayer:self.espHealthBarOutlineLayer];
    
    // Green health bar (>70 HP)
    self.espHealthBarLayer = [CAShapeLayer layer];
    self.espHealthBarLayer.strokeColor = [[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.9] CGColor];
    self.espHealthBarLayer.fillColor = [[UIColor clearColor] CGColor];
    self.espHealthBarLayer.lineWidth = 3.0;
    self.espHealthBarLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:self.espHealthBarLayer];
    
    // Orange health bar (40-70 HP)
    self.espHealthBarLayerOrange = [CAShapeLayer layer];
    self.espHealthBarLayerOrange.strokeColor = [[UIColor colorWithRed:1.0 green:0.55 blue:0.0 alpha:0.9] CGColor];
    self.espHealthBarLayerOrange.fillColor = [[UIColor clearColor] CGColor];
    self.espHealthBarLayerOrange.lineWidth = 3.0;
    self.espHealthBarLayerOrange.lineCap = kCALineCapRound;
    [self.layer addSublayer:self.espHealthBarLayerOrange];
    
    // Red health bar (<40 HP)
    self.espHealthBarLayerRed = [CAShapeLayer layer];
    self.espHealthBarLayerRed.strokeColor = [[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.9] CGColor];
    self.espHealthBarLayerRed.fillColor = [[UIColor clearColor] CGColor];
    self.espHealthBarLayerRed.lineWidth = 3.0;
    self.espHealthBarLayerRed.lineCap = kCALineCapRound;
    [self.layer addSublayer:self.espHealthBarLayerRed];
}

- (void)setupLineLayers {
    // Line outline
    self.espLineOutlineLayer = [CAShapeLayer layer];
    self.espLineOutlineLayer.strokeColor = [[UIColor blackColor] CGColor];
    self.espLineOutlineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.espLineOutlineLayer.lineWidth = 3.0;
    [self.layer addSublayer:self.espLineOutlineLayer];
    
    // Line
    self.espLineLayer = [CAShapeLayer layer];
    self.espLineLayer.strokeColor = [[UIColor whiteColor] CGColor];
    self.espLineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.espLineLayer.lineWidth = 1.0;
    [self.layer addSublayer:self.espLineLayer];
}

- (void)setupFOVLayers {
    // FOV circle outline
    self.fovCircleOutlineLayer = [CAShapeLayer layer];
    self.fovCircleOutlineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.fovCircleOutlineLayer.strokeColor = [[UIColor colorWithWhite:0.0 alpha:0.6] CGColor];
    self.fovCircleOutlineLayer.lineWidth = 3.0;
    self.fovCircleOutlineLayer.hidden = YES;
    [self.layer addSublayer:self.fovCircleOutlineLayer];
    
    // FOV circle
    self.fovCircleLayer = [CAShapeLayer layer];
    self.fovCircleLayer.fillColor = [[UIColor clearColor] CGColor];
    self.fovCircleLayer.strokeColor = [[UIColor whiteColor] CGColor];
    self.fovCircleLayer.lineWidth = 1.5;
    self.fovCircleLayer.hidden = YES;
    [self.layer addSublayer:self.fovCircleLayer];
}

- (void)setupArrowsLayers {
    // Arrows outline
    self.arrowsOutlineLayer = [CAShapeLayer layer];
    self.arrowsOutlineLayer.fillColor = [[UIColor blackColor] CGColor];
    self.arrowsOutlineLayer.strokeColor = [[UIColor clearColor] CGColor];
    self.arrowsOutlineLayer.lineWidth = 0.0;
    [self.layer addSublayer:self.arrowsOutlineLayer];
    
    // Arrows
    self.arrowsLayer = [CAShapeLayer layer];
    self.arrowsLayer.fillColor = [[UIColor whiteColor] CGColor];
    self.arrowsLayer.strokeColor = [[UIColor clearColor] CGColor];
    self.arrowsLayer.lineWidth = 0.0;
    [self.layer addSublayer:self.arrowsLayer];
}

- (void)setupWatermark {
    UILabel *label = [[UILabel alloc] init];
    label.text = @"WXR | IOS";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:16.0];
    label.userInteractionEnabled = NO;
    [self addSubview:label];
    self.watermarkLabel = label;
    
    self.playerCountLabel = [UILabel new];
    self.playerCountLabel.hidden = YES;
    
    self.noPlayersLabel = [UILabel new];
    self.noPlayersLabel.hidden = YES;
}

- (void)update_data {
    // Check if any ESP feature is enabled
    if (!esp_box_enabled && !esp_box_3d && !esp_box_corner && 
        !esp_line_enabled && !esp_name_enabled && !esp_health_enabled &&
        !esp_health_bar_enabled && !esp_weapon_enabled && !esp_arrows_enabled) {
        [self clearAllBoxes];
        self.watermarkLabel.text = @"WXR | IOS";
        [self.watermarkLabel sizeToFit];
        return;
    }
    
    // Get game process
    int pid = get_pid_by_name("Standoff2");
    if (pid <= 0) {
        [self handleNoProcess];
        return;
    }
    
    // Get task and base address
    if (pid != cached_pid || cached_task == 0 || cached_base == 0) {
        cached_task = get_task_by_pid(pid);
        if (!cached_task) {
            cached_pid = pid;
            [self handleNoProcess];
            return;
        }
        cached_base = get_image_base_address(cached_task, "UnityFramework");
        cached_pid = pid;
        if (!cached_task || !cached_base) {
            [self handleNoProcess];
            return;
        }
    }
    
    unsigned int task = cached_task;
    uint64_t base = cached_base;
    
    // Read game data and render ESP
    [self readAndRenderESP:task base:base];
}

- (void)readAndRenderESP:(unsigned int)task base:(uint64_t)base {
    // Read GameManager
    uint64_t gameManager = read_memory_uint64(base + 0x83D0BD0, task);
    if (!gameManager) return;
    
    // Read LocalPlayer
    uint64_t localPlayerManager = read_memory_uint64(gameManager + 0x58, task);
    if (!localPlayerManager) return;
    
    uint64_t localPlayer = read_memory_uint64(localPlayerManager + 0xB8, task);
    if (!localPlayer) {
        localPlayer = read_memory_uint64(localPlayerManager + 0xB0, task);
    }
    if (!localPlayer) return;
    
    // Apply cheats
    [self applyCheats:localPlayer task:task];
    
    // Read players array
    uint64_t playersPtr = read_memory_uint64(localPlayerManager + 0x28, task);
    if (!playersPtr) return;
    
    int playerCount = read_memory_int32(playersPtr + 0x18, task);
    if (playerCount < 1 || playerCount > 100) return;
    
    // Read view matrix
    float viewMatrix[16];
    [self readViewMatrix:viewMatrix localPlayer:localPlayer task:task];
    
    // Get local team
    int localTeam = [self getPlayerTeam:localPlayer task:task];
    
    // Run aimbot
    [self runAimbot:localPlayer 
            players:playersPtr 
              count:playerCount 
          localTeam:localTeam 
               task:task 
              width:self.bounds.size.width 
             height:self.bounds.size.height 
         viewMatrix:viewMatrix];
    
    // Render ESP for all players
    [self renderPlayers:playersPtr 
                  count:playerCount 
            localPlayer:localPlayer 
              localTeam:localTeam 
                   task:task 
             viewMatrix:viewMatrix];
}

- (void)applyCheats:(uint64_t)localPlayer task:(unsigned int)task {
    // Infinite Ammo
    if (esp_inf_ammo) {
        uint64_t weapon = read_memory_uint64(localPlayer + 136, task);
        if (weapon) {
            uint64_t weaponData = read_memory_uint64(weapon + 160, task);
            if (weaponData) {
                write_memory_int32(weaponData + 280, 0, task);
                write_memory_int32(weaponData + 284, 999, task);
                write_memory_int32(weaponData + 288, 0, task);
                write_memory_int32(weaponData + 292, 999, task);
            }
        }
    }
    
    // No Spread
    if (esp_no_spread) {
        uint64_t weapon = read_memory_uint64(localPlayer + 136, task);
        if (weapon) {
            uint64_t weaponData = read_memory_uint64(weapon + 160, task);
            if (weaponData) {
                int spread = read_memory_int32(weaponData + 484, task);
                write_memory_int32(weaponData + 488, spread, task);
            }
        }
    }
    
    // Air Jump
    if (esp_air_jump) {
        uint64_t movement = read_memory_uint64(localPlayer + 272, task);
        if (movement) {
            uint64_t jumpData = read_memory_uint64(movement + 16, task);
            if (jumpData) {
                write_memory_uint8(jumpData + 204, 4, task);
            }
        }
    }
    
    // Fast Knife
    if (esp_fast_knife) {
        uint64_t weapon = read_memory_uint64(localPlayer + 136, task);
        if (weapon) {
            uint64_t weaponData = read_memory_uint64(weapon + 160, task);
            if (weaponData) {
                uint64_t weaponInfo = read_memory_uint64(weaponData + 168, task);
                if (weaponInfo) {
                    int weaponType = read_memory_int32(weaponInfo + 24, task);
                    if (weaponType >= 70 && weaponType <= 89) { // Knife range
                        write_memory_float(weaponData + 280, 0.01f, task);
                    }
                }
            }
        }
    }
    
    // Bunny Hop
    if (esp_bunny_hop) {
        uint64_t movement = read_memory_uint64(localPlayer + 152, task);
        if (movement) {
            uint64_t jumpData = read_memory_uint64(movement + 168, task);
            if (jumpData) {
                uint64_t velocity = read_memory_uint64(jumpData + 80, task);
                if (velocity) {
                    write_memory_float(velocity + 16, (float)esp_bhop_setting, task);
                    write_memory_float(velocity + 96, (float)esp_bhop_setting, task);
                }
            }
            
            uint64_t gravityData = read_memory_uint64(movement + 176, task);
            if (gravityData) {
                write_memory_float(gravityData + 104, 0.0f, task);
                write_memory_float(gravityData + 108, 0.0f, task);
                write_memory_float(gravityData + 112, 0.0f, task);
            }
        }
    }
    
    // Wallshot
    if (esp_wallshot) {
        uint64_t weapon = read_memory_uint64(localPlayer + 136, task);
        if (weapon) {
            uint64_t weaponData = read_memory_uint64(weapon + 160, task);
            if (weaponData) {
                uint64_t weaponInfo = read_memory_uint64(weaponData + 168, task);
                if (weaponInfo) {
                    write_memory_float(weaponInfo + 328, 9999.0f, task);
                    write_memory_float(weaponInfo + 416, 1.0f, task);
                    write_memory_int32(weaponInfo + 420, 9999, task);
                    write_memory_int32(weaponInfo + 600, 1, task);
                    write_memory_float(weaponInfo + 616, 1.0f, task);
                    write_memory_int32(weaponInfo + 612, 1, task);
                    write_memory_int32(weaponInfo + 628, 9999, task);
                    write_memory_int32(weaponInfo + 732, 1, task);
                    write_memory_float(weaponInfo + 748, 9999.0f, task);
                }
            }
        }
    }
    
    // Fire Rate
    if (esp_fire_rate) {
        uint64_t weapon = read_memory_uint64(localPlayer + 136, task);
        if (weapon) {
            uint64_t weaponData = read_memory_uint64(weapon + 160, task);
            if (weaponData) {
                write_memory_int32(weaponData + 256, 0, task);
                write_memory_int32(weaponData + 260, 0, task);
            }
        }
    }
    
    // RCS (Recoil Control System)
    if (esp_rcs_enabled) {
        uint64_t weapon = read_memory_uint64(localPlayer + 136, task);
        if (weapon) {
            uint64_t weaponData = read_memory_uint64(weapon + 160, task);
            if (weaponData) {
                uint64_t recoilData = read_memory_uint64(weaponData + 352, task);
                if (recoilData) {
                    uint64_t recoilPattern = read_memory_uint64(recoilData + 344, task);
                    if (recoilPattern) {
                        write_memory_int32(recoilPattern + 16, esp_rcs_h, task);
                        write_memory_int32(recoilPattern + 20, esp_rcs_v, task);
                        
                        if (read_memory_uint8(recoilPattern + 112, task)) {
                            int val = read_memory_int32(recoilPattern + 116, task) ^ esp_rcs_h;
                            write_memory_int32(recoilPattern + 120, val, task);
                        }
                        
                        if (read_memory_uint8(recoilPattern + 100, task)) {
                            int val = read_memory_int32(recoilPattern + 104, task) ^ esp_rcs_v;
                            write_memory_int32(recoilPattern + 108, val, task);
                        }
                    }
                }
            }
        }
    }
    
    // Invisible
    if (esp_invisible) {
        uint64_t visibility = read_memory_uint64(localPlayer + 136, task);
        if (visibility) {
            write_memory_int32(visibility + 136, 10, task);
        }
    }
    
    // Add Score
    if (esp_addscore) {
        uint64_t stats = read_memory_uint64(localPlayer + 344, task);
        if (stats) {
            uint64_t scoreData = read_memory_uint64(stats + 56, task);
            if (scoreData) {
                uint64_t scoreArray = read_memory_uint64(scoreData + 24, task);
                int count = read_memory_int32(scoreData + 32, task);
                
                if (count > 0 && count < 64 && scoreArray) {
                    for (int i = 0; i < count; i++) {
                        uint64_t key = read_memory_uint64(scoreArray + 40 + (i * 24), task);
                        uint64_t value = read_memory_uint64(scoreArray + 48 + (i * 24), task);
                        
                        if (key && value) {
                            int keyLen = read_memory_int32(key + 16, task);
                            if (keyLen == 5) {
                                uint64_t keyStr = read_memory_uint64(key + 20, task);
                                if (keyStr == 0x72006F00630073LL) { // "score"
                                    int lastByte = read_memory_uint8(key + 28, task);
                                    if (lastByte == 101) { // 'e'
                                        write_memory_int32(value + 16, 333, task);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)renderPlayers:(uint64_t)playersPtr 
                count:(int)count 
          localPlayer:(uint64_t)localPlayer 
            localTeam:(int)localTeam 
                 task:(unsigned int)task 
           viewMatrix:(float[16])matrix {
    // Implement player rendering
}

- (void)clearAllBoxes {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    self.espBoxLayer.path = nil;
    self.espBoxFillLayer.path = nil;
    self.espLineLayer.path = nil;
    self.espBoxOutlineLayer.path = nil;
    self.espLineOutlineLayer.path = nil;
    self.espHealthBarLayer.path = nil;
    self.espHealthBarLayerOrange.path = nil;
    self.espHealthBarLayerRed.path = nil;
    self.espHealthBarOutlineLayer.path = nil;
    self.fovCircleLayer.hidden = YES;
    self.fovCircleOutlineLayer.hidden = YES;
    self.arrowsLayer.path = nil;
    self.arrowsOutlineLayer.path = nil;
    
    // Hide all labels
    for (UILabel *label in self.nameLabelPool) {
        label.hidden = YES;
    }
    for (UILabel *label in self.healthLabelPool) {
        label.hidden = YES;
    }
    for (UILabel *label in self.weaponLabelPool) {
        label.hidden = YES;
    }
    for (UIImageView *icon in self.weaponIconPool) {
        icon.hidden = YES;
    }
    for (UILabel *label in self.platformLabelPool) {
        label.hidden = YES;
    }
    for (UIImageView *avatar in self.avatarPool) {
        avatar.hidden = YES;
    }
    
    [CATransaction commit];
}

- (void)handleNoProcess {
    [self clearAllBoxes];
    self.watermarkLabel.text = @"WXR | IOS";
    [self.watermarkLabel sizeToFit];
    
    if (!self.hasAttemptedLaunch) {
        [self launchGame];
        self.hasAttemptedLaunch = YES;
    }
}

- (void)launchGame {
    // Launch Standoff2 if not running
    NSURL *url = [NSURL URLWithString:@"standoff2://"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)startBackgroundKeeper {
    // Keep app in background
}

- (void)runAimbot:(uint64_t)localPlayer 
          players:(uint64_t)playersPtr 
            count:(int)playerCount 
        localTeam:(int)localTeam 
             task:(unsigned int)task 
            width:(double)width 
           height:(double)height 
       viewMatrix:(float[16])matrix {
    // Implement aimbot logic
}

- (void)readViewMatrix:(float[16])matrix localPlayer:(uint64_t)localPlayer task:(unsigned int)task {
    // Read view matrix from camera
    uint64_t camera = read_memory_uint64(localPlayer + 224, task);
    if (camera) {
        uint64_t cameraData = read_memory_uint64(camera + 32, task);
        if (cameraData) {
            uint64_t matrixPtr = read_memory_uint64(cameraData + 16, task);
            if (matrixPtr) {
                // Read 4x4 matrix (16 floats)
                for (int i = 0; i < 16; i++) {
                    matrix[i] = read_memory_float(matrixPtr + 256 + (i * 4), task);
                }
            }
        }
    }
}

- (int)getPlayerTeam:(uint64_t)player task:(unsigned int)task {
    // Get player team from stats
    uint64_t stats = read_memory_uint64(player + 344, task);
    if (!stats) return 0;
    
    uint64_t teamData = read_memory_uint64(stats + 56, task);
    if (!teamData) return 0;
    
    uint64_t teamArray = read_memory_uint64(teamData + 24, task);
    if (!teamArray) return 0;
    
    int count = read_memory_int32(teamData + 32, task);
    if (count < 1 || count > 64) return 0;
    
    // Search for "team" key
    for (int i = 0; i < count; i++) {
        uint64_t key = read_memory_uint64(teamArray + 40 + (i * 24), task);
        uint64_t value = read_memory_uint64(teamArray + 48 + (i * 24), task);
        
        if (key && value) {
            int keyLen = read_memory_int32(key + 16, task);
            if (keyLen == 4) {
                uint64_t keyStr = read_memory_uint64(key + 20, task);
                if (keyStr == 0x6D006100650074LL) { // "team"
                    return read_memory_int32(value + 16, task);
                }
            }
        }
    }
    
    return 0;
}

- (void)applyViewmodelSettings:(uint64_t)localPlayer task:(unsigned int)task {
    // Apply viewmodel offset settings
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.displayLinkData invalidate];
}

@end

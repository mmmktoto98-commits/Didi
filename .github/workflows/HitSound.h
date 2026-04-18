//
//  HitSound.h
//  WXR
//
//  Hit sound system for Standoff 2
//

#import <Foundation/Foundation.h>

@class ESP_View;

@interface ESP_View (HitSound)

// Initialize hit sound system
- (void)initHitSoundSystem;

// Play hit sound
- (void)playHitSound;

// Check for hits and play sound
- (void)checkHitSound:(uint64_t)playersPtr 
                count:(int)playerCount 
            localTeam:(int)localTeam 
                 task:(unsigned int)task;

// Cleanup hit sound system
- (void)cleanupHitSoundSystem;

@end

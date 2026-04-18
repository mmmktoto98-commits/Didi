//
//  HitSound.m
//  WXR
//
//  Hit sound system for Standoff 2
//

#import "ESP_View.h"
#import <AVFoundation/AVFoundation.h>
#import <mach/mach.h>

// External globals
extern BOOL hit_sound;

// Helper functions
extern unsigned int read_memory_uint32(unsigned long address, unsigned int task);
extern unsigned long read_memory_uint64(unsigned long address, unsigned int task);

@implementation ESP_View (HitSound)

- (void)initHitSoundSystem {
    NSLog(@"[HitSound] Initializing hit sound system...");
    
    // Initialize AVAudioEngine
    self.hitAudioEngine = [[AVAudioEngine alloc] init];
    self.hitPlayerNode = [[AVAudioPlayerNode alloc] init];
    
    [self.hitAudioEngine attachNode:self.hitPlayerNode];
    [self.hitAudioEngine connect:self.hitPlayerNode 
                              to:self.hitAudioEngine.mainMixerNode 
                          format:nil];
    
    // Load hit sound from bundle
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"hitsound" ofType:@"wav"];
    if (!soundPath) {
        soundPath = [[NSBundle mainBundle] pathForResource:@"hit" ofType:@"wav"];
    }
    
    if (soundPath) {
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        NSError *error = nil;
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:soundURL error:&error];
        
        if (!error && audioFile) {
            AVAudioFormat *format = audioFile.processingFormat;
            AVAudioFrameCount frameCount = (AVAudioFrameCount)audioFile.length;
            
            self.hitSoundBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format 
                                                                 frameCapacity:frameCount];
            
            [audioFile readIntoBuffer:self.hitSoundBuffer error:&error];
            
            if (!error) {
                NSLog(@"[HitSound] ✓ Loaded hit sound: %@ (%u frames)", soundPath, frameCount);
                self.hitSoundReady = YES;
            } else {
                NSLog(@"[HitSound] ✗ Failed to read audio file: %@", error);
                self.hitSoundBuffer = nil;
                self.hitSoundReady = NO;
            }
        } else {
            NSLog(@"[HitSound] ✗ Failed to load audio file: %@", error);
            self.hitSoundReady = NO;
        }
    } else {
        NSLog(@"[HitSound] ✗ Hit sound file not found in bundle");
        self.hitSoundReady = NO;
    }
    
    // Start audio engine
    NSError *error = nil;
    [self.hitAudioEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"[HitSound] ✗ Failed to start audio engine: %@", error);
        self.hitSoundReady = NO;
    } else {
        NSLog(@"[HitSound] ✓ Audio engine started successfully");
    }
    
    // Initialize HP tracking map
    self.prevHpMap = [[NSMutableDictionary alloc] init];
    
    NSLog(@"[HitSound] Initialization complete. Ready: %@", self.hitSoundReady ? @"YES" : @"NO");
}

- (void)playHitSound {
    if (!hit_sound) return;
    if (!self.hitSoundReady) return;
    if (!self.hitSoundBuffer) return;
    if (!self.hitPlayerNode) return;
    if (!self.hitAudioEngine.isRunning) return;
    
    // Schedule buffer for playback
    [self.hitPlayerNode scheduleBuffer:self.hitSoundBuffer 
                     completionHandler:nil];
    
    // Start playing if not already playing
    if (!self.hitPlayerNode.isPlaying) {
        [self.hitPlayerNode play];
    }
}

- (void)checkHitSound:(uint64_t)playersPtr 
                count:(int)playerCount 
            localTeam:(int)localTeam 
                 task:(unsigned int)task {
    
    if (!hit_sound) {
        // Clear HP map when disabled
        if (self.prevHpMap.count > 0) {
            [self.prevHpMap removeAllObjects];
        }
        return;
    }
    
    if (!self.hitSoundReady) return;
    
    // Get players array
    uint64_t playersArray = read_memory_uint64(playersPtr + 24, task);
    if (!playersArray || playersArray < 0x1000001) return;
    
    int maxPlayers = playerCount - 1;
    if (maxPlayers > 31) maxPlayers = 31;
    
    NSMutableSet *currentPlayerIds = [NSMutableSet set];
    
    for (int i = 0; i < maxPlayers; i++) {
        uint64_t player = read_memory_uint64(playersArray + 48 + i * 24, task);
        if (!player || player < 0x1000001) continue;
        
        // Get player team
        int playerTeam = read_memory_uint32(player + 0xA0, task);
        
        // Skip teammates
        if (playerTeam == localTeam) continue;
        
        // Get current HP
        int currentHp = read_memory_uint32(player + 0x98, task);
        
        // Skip dead players
        if (currentHp <= 0) continue;
        
        // Create unique player ID
        NSString *playerId = [NSString stringWithFormat:@"%llu", player];
        [currentPlayerIds addObject:playerId];
        
        // Get previous HP
        NSNumber *prevHpNum = self.prevHpMap[playerId];
        
        if (prevHpNum) {
            int prevHp = [prevHpNum intValue];
            
            // Check if HP decreased (hit detected)
            if (currentHp < prevHp) {
                int damage = prevHp - currentHp;
                NSLog(@"[HitSound] 🎯 Hit detected! Player: %@ | Damage: %d | HP: %d -> %d", 
                      playerId, damage, prevHp, currentHp);
                
                // Play hit sound
                [self playHitSound];
            }
        }
        
        // Update HP in map
        self.prevHpMap[playerId] = @(currentHp);
    }
    
    // Clean up old player entries (players that left or died)
    NSMutableArray *keysToRemove = [NSMutableArray array];
    for (NSString *key in self.prevHpMap.allKeys) {
        if (![currentPlayerIds containsObject:key]) {
            [keysToRemove addObject:key];
        }
    }
    
    for (NSString *key in keysToRemove) {
        [self.prevHpMap removeObjectForKey:key];
    }
}

- (void)cleanupHitSoundSystem {
    NSLog(@"[HitSound] Cleaning up hit sound system...");
    
    if (self.hitPlayerNode) {
        [self.hitPlayerNode stop];
        [self.hitAudioEngine detachNode:self.hitPlayerNode];
        self.hitPlayerNode = nil;
    }
    
    if (self.hitAudioEngine) {
        [self.hitAudioEngine stop];
        self.hitAudioEngine = nil;
    }
    
    self.hitSoundBuffer = nil;
    self.hitSoundReady = NO;
    
    if (self.prevHpMap) {
        [self.prevHpMap removeAllObjects];
        self.prevHpMap = nil;
    }
    
    NSLog(@"[HitSound] ✓ Cleanup complete");
}

@end

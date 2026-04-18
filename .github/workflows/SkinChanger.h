#import <Foundation/Foundation.h>
#import <vector>
#import <map>
#import <string>

// Skin data structures
struct SkinInfo {
    int skinId;
    unsigned long address;
};

@interface MenuView (SkinChanger)

// Skin changer properties
@property (nonatomic, strong) UIView *skinContainer;
@property (nonatomic, strong) UIView *skinContent;
@property (nonatomic, assign) double skinListStartY;
@property (nonatomic, strong) NSTimer *skinTimer;

@property (nonatomic, assign) int selectedOwnedIdx;
@property (nonatomic, assign) int selectedReplaceIdx;

// C++ containers for skin data
@property (nonatomic, assign) std::map<int, std::string> allSkinsMap;
@property (nonatomic, assign) std::vector<std::pair<int, std::string>> allSkinsList;
@property (nonatomic, assign) std::vector<SkinInfo> ownedSkinsInfo;
@property (nonatomic, strong) NSMutableDictionary *cachedSkins;

// Skin changer methods
- (void)refreshSkinList;
- (void)ownedSkinTapped:(UITapGestureRecognizer *)gesture;
- (void)replaceSkinTapped:(UITapGestureRecognizer *)gesture;
- (void)tryApplySkinPair;

@end

// Helper functions
int get_pid_by_name(const char *processName);
unsigned int get_task_by_pid(int pid);
unsigned long get_image_base_address(unsigned int task, const char *imageName);

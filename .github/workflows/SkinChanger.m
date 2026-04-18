#import "MenuView.h"
#import "SkinChanger.h"
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <libproc.h>

// Global variables for caching
static int cached_pid = 0;
static unsigned int cached_task = 0;
static unsigned long cached_base = 0;

#pragma mark - Helper Functions

int get_pid_by_name(const char *processName) {
    int count = proc_listallpids(NULL, 0);
    if (count <= 0) return -1;
    
    pid_t *pids = (pid_t *)malloc(count * sizeof(pid_t));
    if (!pids) return -1;
    
    proc_listallpids(pids, count * sizeof(pid_t));
    
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    for (int i = 0; i < count; i++) {
        memset(pathBuffer, 0, sizeof(pathBuffer));
        proc_name(pids[i], pathBuffer, sizeof(pathBuffer));
        
        if (strcasestr(pathBuffer, processName)) {
            int result = pids[i];
            free(pids);
            return result;
        }
    }
    
    free(pids);
    return -1;
}

unsigned int get_task_by_pid(int pid) {
    mach_port_t host = mach_host_self();
    processor_set_name_t default_set;
    processor_set_t priv_set;
    task_array_t task_list;
    mach_msg_type_number_t task_count;
    
    if (processor_set_default(host, &default_set) != KERN_SUCCESS) {
        return 0;
    }
    
    if (host_processor_set_priv(host, default_set, &priv_set) != KERN_SUCCESS) {
        return 0;
    }
    
    if (processor_set_tasks(priv_set, &task_list, &task_count) != KERN_SUCCESS) {
        return 0;
    }
    
    for (mach_msg_type_number_t i = 0; i < task_count; i++) {
        int task_pid;
        if (pid_for_task(task_list[i], &task_pid) == KERN_SUCCESS && task_pid == pid) {
            return task_list[i];
        }
    }
    
    return 0;
}

unsigned long get_image_base_address(unsigned int task, const char *imageName) {
    task_dyld_info_data_t dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    
    if (task_info(task, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) != KERN_SUCCESS) {
        return 0;
    }
    
    vm_offset_t data;
    mach_msg_type_number_t dataCnt;
    
    // Read dyld_all_image_infos structure
    if (vm_read(task, dyld_info.all_image_info_addr, 160, &data, &dataCnt) != KERN_SUCCESS || dataCnt < 160) {
        return 0;
    }
    
    uint32_t image_count = *(uint32_t *)(data + 4);
    uint64_t image_array_addr = *(uint64_t *)(data + 8);
    
    vm_deallocate(mach_task_self(), data, dataCnt);
    
    // Allocate buffer for image infos
    size_t info_size = 24 * image_count;
    char *infos = (char *)malloc(info_size);
    if (!infos) return 0;
    
    // Read image info array
    if (vm_read(task, image_array_addr, info_size, &data, &dataCnt) != KERN_SUCCESS || dataCnt < info_size) {
        free(infos);
        return 0;
    }
    
    memcpy(infos, (void *)data, info_size);
    vm_deallocate(mach_task_self(), data, dataCnt);
    
    // Search for image by name
    for (uint32_t i = 0; i < image_count; i++) {
        uint64_t image_load_addr = *(uint64_t *)(infos + i * 24);
        uint64_t image_file_path_addr = *(uint64_t *)(infos + i * 24 + 8);
        
        char path_buffer[1024];
        memset(path_buffer, 0, sizeof(path_buffer));
        
        if (vm_read(task, image_file_path_addr, 1024, &data, &dataCnt) == KERN_SUCCESS) {
            size_t copy_size = dataCnt < 1024 ? dataCnt : 1024;
            memcpy(path_buffer, (void *)data, copy_size);
            vm_deallocate(mach_task_self(), data, dataCnt);
            
            if (strstr(path_buffer, imageName)) {
                free(infos);
                return image_load_addr;
            }
        }
    }
    
    free(infos);
    return 0;
}

#pragma mark - Memory Read Helper

unsigned long read_memory_ptr(unsigned int task, unsigned long address) {
    vm_offset_t data;
    mach_msg_type_number_t dataCnt;
    
    if (vm_read(task, address, 8, &data, &dataCnt) != KERN_SUCCESS || dataCnt < 8) {
        return 0;
    }
    
    unsigned long result = *(unsigned long *)data;
    vm_deallocate(mach_task_self(), data, dataCnt);
    return result;
}

unsigned int read_memory_int(unsigned int task, unsigned long address) {
    vm_offset_t data;
    mach_msg_type_number_t dataCnt;
    
    if (vm_read(task, address, 4, &data, &dataCnt) != KERN_SUCCESS || dataCnt < 4) {
        return 0;
    }
    
    unsigned int result = *(unsigned int *)data;
    vm_deallocate(mach_task_self(), data, dataCnt);
    return result;
}

unsigned short read_memory_ushort(unsigned int task, unsigned long address) {
    vm_offset_t data;
    mach_msg_type_number_t dataCnt;
    
    if (vm_read(task, address, 2, &data, &dataCnt) != KERN_SUCCESS || dataCnt < 2) {
        return 0;
    }
    
    unsigned short result = *(unsigned short *)data;
    vm_deallocate(mach_task_self(), data, dataCnt);
    return result;
}

#pragma mark - MenuView SkinChanger Category

@implementation MenuView (SkinChanger)

- (void)ownedSkinTapped:(UITapGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    self.selectedOwnedIdx = (int)view.tag - 1000;
    [self refreshSkinList];
    [self tryApplySkinPair];
}

- (void)replaceSkinTapped:(UITapGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    self.selectedReplaceIdx = (int)view.tag - 2000;
    [self refreshSkinList];
    [self tryApplySkinPair];
}

- (void)tryApplySkinPair {
    if (self.selectedOwnedIdx < 0 || self.selectedReplaceIdx < 0) {
        return;
    }
    
    if (self.selectedOwnedIdx >= self.ownedSkinsInfo.size()) {
        return;
    }
    
    if (self.selectedReplaceIdx >= self.allSkinsList.size()) {
        return;
    }
    
    // Get owned skin address
    SkinInfo ownedSkin = self.ownedSkinsInfo[self.selectedOwnedIdx];
    unsigned long skinAddress = ownedSkin.address;
    
    // Get replacement skin ID
    int replacementSkinId = self.allSkinsList[self.selectedReplaceIdx].first;
    
    // Get process info
    int pid = get_pid_by_name("Standoff2");
    if (pid <= 0) return;
    
    unsigned int task = get_task_by_pid(pid);
    if (!task) return;
    
    // Validate address range (basic sanity check)
    if (skinAddress < 0x100000000 || skinAddress > 0x200000000) {
        return;
    }
    
    // Write new skin ID to memory
    int newSkinId = replacementSkinId;
    mach_vm_write(task, skinAddress + 16, (vm_offset_t)&newSkinId, 4);
}

- (void)refreshSkinList {
    // Get process ID
    int pid = get_pid_by_name("Standoff2");
    if (pid <= 0) {
        cached_pid = 0;
        cached_task = 0;
        cached_base = 0;
        return;
    }
    
    // Check if we need to refresh task and base address
    if (pid != cached_pid || cached_task == 0 || cached_base == 0) {
        cached_task = get_task_by_pid(pid);
        if (cached_task) {
            cached_base = get_image_base_address(cached_task, "UnityFramework");
        } else {
            cached_task = 0;
            cached_base = 0;
        }
        cached_pid = pid;
    }
    
    if (!cached_task || !cached_base) {
        return;
    }
    
    // Navigate to skin manager (offset 0x83E0E70 = 138123120)
    unsigned long skinManagerPtr = read_memory_ptr(cached_task, cached_base + 138123120);
    if (!skinManagerPtr) return;
    
    unsigned long skinDataPtr = read_memory_ptr(cached_task, skinManagerPtr + 88);
    if (!skinDataPtr) return;
    
    // Get skin list pointer
    unsigned long skinListPtr1 = read_memory_ptr(cached_task, skinDataPtr + 184);
    if (!skinListPtr1) {
        skinListPtr1 = read_memory_ptr(cached_task, skinDataPtr + 176);
    }
    if (!skinListPtr1) return;
    
    unsigned long skinListPtr = read_memory_ptr(cached_task, skinListPtr1);
    if (!skinListPtr) return;
    
    // Check if skin container is visible
    if ([self.skinContainer isHidden]) {
        return;
    }
    
    // Get all skins list
    unsigned long allSkinsListPtr = read_memory_ptr(cached_task, skinListPtr + 232);
    unsigned int allSkinsCount = read_memory_int(cached_task, allSkinsListPtr + 32);
    
    if (allSkinsCount < 1 || allSkinsCount > 10000) {
        return;
    }
    
    // Clear and rebuild all skins map
    self.allSkinsMap.clear();
    self.allSkinsList.clear();
    
    unsigned long skinsArrayPtr = read_memory_ptr(cached_task, allSkinsListPtr + 24);
    
    for (unsigned int i = 0; i < allSkinsCount; i++) {
        unsigned long skinEntryPtr = read_memory_ptr(cached_task, skinsArrayPtr + 48 + i * 24);
        if (!skinEntryPtr) continue;
        
        int skinId = read_memory_int(cached_task, skinEntryPtr + 16);
        
        // Read skin name
        unsigned long skinNamePtr = read_memory_ptr(cached_task, skinEntryPtr + 24);
        if (!skinNamePtr) continue;
        
        unsigned int nameLength = read_memory_int(cached_task, skinNamePtr + 16);
        if (nameLength < 1 || nameLength > 256) continue;
        
        // Read Unicode string (2 bytes per character)
        std::string skinName;
        skinName.reserve(nameLength);
        
        for (unsigned int j = 0; j < nameLength; j++) {
            unsigned short ch = read_memory_ushort(cached_task, skinNamePtr + 20 + j * 2);
            if (ch >= 0x80) {
                skinName.push_back('?');
            } else {
                skinName.push_back((char)ch);
            }
        }
        
        if (skinName.empty()) continue;
        
        // Add to map
        self.allSkinsMap[skinId] = skinName;
        
        // Filter for knives and gloves
        NSString *lowerName = [[NSString stringWithUTF8String:skinName.c_str()] lowercaseString];
        
        BOOL isKnifeOrGlove = ([lowerName containsString:@"knife"] ||
                               [lowerName containsString:@"m9"] ||
                               [lowerName containsString:@"bayonet"] ||
                               [lowerName containsString:@"karambit"] ||
                               [lowerName containsString:@"butterfly"] ||
                               [lowerName containsString:@"kunai"] ||
                               [lowerName containsString:@"jkommando"] ||
                               [lowerName containsString:@"dual"] ||
                               [lowerName containsString:@"gloves"]);
        
        BOOL isNotCase = ![lowerName containsString:@"case"] && ![lowerName containsString:@"graffiti"];
        
        if (isKnifeOrGlove && isNotCase) {
            self.allSkinsList.push_back(std::make_pair(skinId, skinName));
        }
    }
    
    // Get owned skins
    unsigned long ownedSkinsListPtr = read_memory_ptr(cached_task, skinListPtr + 248);
    unsigned int ownedSkinsCount = read_memory_int(cached_task, ownedSkinsListPtr + 32);
    
    self.ownedSkinsInfo.clear();
    NSMutableArray *ownedSkinNames = [NSMutableArray array];
    
    if (ownedSkinsCount > 0 && ownedSkinsCount <= 2000) {
        unsigned long ownedArrayPtr = read_memory_ptr(cached_task, ownedSkinsListPtr + 24);
        
        for (unsigned int i = 0; i < ownedSkinsCount; i++) {
            unsigned long ownedSkinPtr = read_memory_ptr(cached_task, ownedArrayPtr + 48 + i * 24);
            if (!ownedSkinPtr) continue;
            
            int ownedSkinId = read_memory_int(cached_task, ownedSkinPtr + 16);
            
            // Store skin info
            SkinInfo info;
            info.skinId = ownedSkinId;
            info.address = ownedSkinPtr;
            self.ownedSkinsInfo.push_back(info);
            
            // Get skin name from map
            auto it = self.allSkinsMap.find(ownedSkinId);
            if (it != self.allSkinsMap.end()) {
                NSString *name = [NSString stringWithUTF8String:it->second.c_str()];
                [ownedSkinNames addObject:name];
            } else {
                [ownedSkinNames addObject:[NSString stringWithFormat:@"Skin #%d", ownedSkinId]];
            }
        }
    }
    
    // Clear existing UI
    for (UIView *subview in self.skinContent.subviews) {
        [subview removeFromSuperview];
    }
    
    // Build owned skins section
    [self addSectionHeader:@"YOUR INVENTORY" atY:4.0];
    
    double y = 30.0;
    
    if (self.ownedSkinsInfo.empty()) {
        UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, y, self.skinContent.bounds.size.width - 20, 30)];
        emptyLabel.text = @"Inventory empty";
        emptyLabel.textColor = [UIColor grayColor];
        emptyLabel.font = [UIFont italicSystemFontOfSize:12];
        [self.skinContent addSubview:emptyLabel];
        y += 40.0;
    } else {
        for (size_t i = 0; i < self.ownedSkinsInfo.size(); i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, y, self.skinContent.bounds.size.width - 20, 30)];
            label.text = [NSString stringWithFormat:@"  %@", ownedSkinNames[i]];
            label.font = [UIFont systemFontOfSize:13];
            label.textColor = [UIColor whiteColor];
            
            if (i == self.selectedOwnedIdx) {
                label.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
            } else {
                label.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
            }
            
            label.layer.cornerRadius = 4.0;
            label.layer.masksToBounds = YES;
            label.userInteractionEnabled = YES;
            label.tag = 1000 + i;
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ownedSkinTapped:)];
            [label addGestureRecognizer:tap];
            
            [self.skinContent addSubview:label];
            y += 35.0;
        }
    }
    
    // Build replacement skins section
    y += 10.0;
    [self addSectionHeader:@"SELECT REPLACEMENT" atY:y];
    y += 26.0;
    
    if (self.allSkinsList.empty()) {
        UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, y, self.skinContent.bounds.size.width - 20, 30)];
        emptyLabel.text = @"No replacement skins found";
        emptyLabel.textColor = [UIColor grayColor];
        [self.skinContent addSubview:emptyLabel];
    } else {
        for (size_t i = 0; i < self.allSkinsList.size(); i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, y, self.skinContent.bounds.size.width - 20, 30)];
            
            NSString *skinName = [NSString stringWithUTF8String:self.allSkinsList[i].second.c_str()];
            label.text = [NSString stringWithFormat:@"  %@", skinName];
            label.font = [UIFont systemFontOfSize:13];
            label.textColor = [UIColor whiteColor];
            
            if (i == self.selectedReplaceIdx) {
                label.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
            } else {
                label.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
            }
            
            label.layer.cornerRadius = 4.0;
            label.layer.masksToBounds = YES;
            label.userInteractionEnabled = YES;
            label.tag = 2000 + i;
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replaceSkinTapped:)];
            [label addGestureRecognizer:tap];
            
            [self.skinContent addSubview:label];
            y += 35.0;
        }
    }
    
    // Update content size
    CGRect frame = self.skinContent.frame;
    frame.size.height = y + 20;
    self.skinContent.frame = frame;
}

@end

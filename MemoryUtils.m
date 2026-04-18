//
//  MemoryUtils.m
//  WXR
//
//  Memory reading/writing implementation
//

#import "MemoryUtils.h"
#import <sys/sysctl.h>

int get_pid_by_name(const char *name) {
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size;
    
    if (sysctl(mib, 4, NULL, &size, NULL, 0) < 0) {
        return -1;
    }
    
    struct kinfo_proc *procs = malloc(size);
    if (!procs) return -1;
    
    if (sysctl(mib, 4, procs, &size, NULL, 0) < 0) {
        free(procs);
        return -1;
    }
    
    int count = size / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        if (strcmp(procs[i].kp_proc.p_comm, name) == 0) {
            int pid = procs[i].kp_proc.p_pid;
            free(procs);
            return pid;
        }
    }
    
    free(procs);
    return -1;
}

unsigned int get_task_by_pid(int pid) {
    mach_port_t task;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    return task;
}

uint64_t get_image_base_address(unsigned int task, const char *image_name) {
    // Read task info to find image base
    // This is simplified - actual implementation would parse dyld info
    return 0x100000000; // Placeholder
}

uint64_t read_memory_uint64(uint64_t address, unsigned int task) {
    uint64_t value = 0;
    mach_vm_size_t size = sizeof(value);
    kern_return_t kr = mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)&value, &size);
    return (kr == KERN_SUCCESS) ? value : 0;
}

uint32_t read_memory_uint32(uint64_t address, unsigned int task) {
    uint32_t value = 0;
    mach_vm_size_t size = sizeof(value);
    kern_return_t kr = mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)&value, &size);
    return (kr == KERN_SUCCESS) ? value : 0;
}

int32_t read_memory_int32(uint64_t address, unsigned int task) {
    return (int32_t)read_memory_uint32(address, task);
}

uint16_t read_memory_uint16(uint64_t address, unsigned int task) {
    uint16_t value = 0;
    mach_vm_size_t size = sizeof(value);
    kern_return_t kr = mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)&value, &size);
    return (kr == KERN_SUCCESS) ? value : 0;
}

uint8_t read_memory_uint8(uint64_t address, unsigned int task) {
    uint8_t value = 0;
    mach_vm_size_t size = sizeof(value);
    kern_return_t kr = mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)&value, &size);
    return (kr == KERN_SUCCESS) ? value : 0;
}

float read_memory_float(uint64_t address, unsigned int task) {
    float value = 0.0f;
    mach_vm_size_t size = sizeof(value);
    kern_return_t kr = mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)&value, &size);
    return (kr == KERN_SUCCESS) ? value : 0.0f;
}

void read_memory_buffer(uint64_t address, void *buffer, size_t size, unsigned int task) {
    mach_vm_size_t read_size = size;
    mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)buffer, &read_size);
}

BOOL write_memory_uint64(uint64_t address, uint64_t value, unsigned int task) {
    kern_return_t kr = mach_vm_write(task, address, (vm_offset_t)&value, sizeof(value));
    return kr == KERN_SUCCESS;
}

BOOL write_memory_uint32(uint64_t address, uint32_t value, unsigned int task) {
    kern_return_t kr = mach_vm_write(task, address, (vm_offset_t)&value, sizeof(value));
    return kr == KERN_SUCCESS;
}

BOOL write_memory_int32(uint64_t address, int32_t value, unsigned int task) {
    return write_memory_uint32(address, (uint32_t)value, task);
}

BOOL write_memory_float(uint64_t address, float value, unsigned int task) {
    kern_return_t kr = mach_vm_write(task, address, (vm_offset_t)&value, sizeof(value));
    return kr == KERN_SUCCESS;
}

BOOL write_memory_buffer(uint64_t address, const void *buffer, size_t size, unsigned int task) {
    kern_return_t kr = mach_vm_write(task, address, (vm_offset_t)buffer, size);
    return kr == KERN_SUCCESS;
}

NSString* read_memory_string(uint64_t address, unsigned int task) {
    char buffer[256];
    read_memory_buffer(address, buffer, sizeof(buffer), task);
    buffer[255] = '\0';
    return [NSString stringWithUTF8String:buffer];
}

NSString* read_memory_unicode_string(uint64_t address, int length, unsigned int task) {
    if (length <= 0 || length > 256) return @"";
    
    unichar *buffer = malloc(length * sizeof(unichar));
    if (!buffer) return @"";
    
    read_memory_buffer(address, buffer, length * sizeof(unichar), task);
    NSString *result = [NSString stringWithCharacters:buffer length:length];
    free(buffer);
    
    return result;
}

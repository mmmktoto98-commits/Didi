//
//  MemoryUtils.h
//  WXR
//
//  Memory reading/writing utilities
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>

// Process utilities
int get_pid_by_name(const char *name);
unsigned int get_task_by_pid(int pid);
uint64_t get_image_base_address(unsigned int task, const char *image_name);

// Memory reading
uint64_t read_memory_uint64(uint64_t address, unsigned int task);
uint32_t read_memory_uint32(uint64_t address, unsigned int task);
int32_t read_memory_int32(uint64_t address, unsigned int task);
uint16_t read_memory_uint16(uint64_t address, unsigned int task);
uint8_t read_memory_uint8(uint64_t address, unsigned int task);
float read_memory_float(uint64_t address, unsigned int task);
void read_memory_buffer(uint64_t address, void *buffer, size_t size, unsigned int task);

// Memory writing
BOOL write_memory_uint64(uint64_t address, uint64_t value, unsigned int task);
BOOL write_memory_uint32(uint64_t address, uint32_t value, unsigned int task);
BOOL write_memory_int32(uint64_t address, int32_t value, unsigned int task);
BOOL write_memory_float(uint64_t address, float value, unsigned int task);
BOOL write_memory_buffer(uint64_t address, const void *buffer, size_t size, unsigned int task);

// String reading
NSString* read_memory_string(uint64_t address, unsigned int task);
NSString* read_memory_unicode_string(uint64_t address, int length, unsigned int task);

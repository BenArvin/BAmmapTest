//
//  ViewController.m
//  BAmmapTest
//
//  Created by BenArvin on 2021/4/8.
//

#import "ViewController.h"
#import <sys/mman.h>
#import <sys/stat.h>

@interface ViewController ()

@end

int mapFile(const char *inPathName, void **outDataPtr, size_t *outDataLength, size_t appendSize) {
    int outError;
    int fileDescriptor;
    struct stat statInfo;
    
    outError = 0;
    *outDataPtr = NULL;
    *outDataLength = 0;
    
    fileDescriptor = open(inPathName, O_RDWR, 0);
    if(fileDescriptor < 0) {
        outError = errno;
    } else {
        if(fstat(fileDescriptor, &statInfo) != 0) {
            outError = errno;
        } else {
            ftruncate(fileDescriptor, statInfo.st_size + appendSize);
            fsync(fileDescriptor);
            *outDataPtr = mmap(NULL,
                               statInfo.st_size + appendSize,
                               PROT_READ|PROT_WRITE,
                               MAP_FILE|MAP_SHARED,
                               fileDescriptor,
                               0);
            if(*outDataPtr == MAP_FAILED) {
                outError = errno;
            } else {
                *outDataLength = statInfo.st_size;
            }
        }
        close(fileDescriptor);
    }
    return outError;
}

int unmapFile(void *outDataPtr, size_t outDataLength) {
    return munmap(outDataPtr, outDataLength);
}


void ProcessFile(const char *inPathName) {
    size_t dataLength;
    void *dataPtr;
    char *appendStr = " append_key";
    int appendSize = (int)strlen(appendStr);
    if (mapFile(inPathName, &dataPtr, &dataLength, appendSize) == 0) {
        dataPtr = dataPtr + dataLength;
        memcpy(dataPtr, appendStr, appendSize);
        // Unmap files
        unmapFile(dataPtr, appendSize + dataLength);
    }
}

@implementation ViewController

// TODO: 1、自动调整为页大小证书倍
// TODO: 2、自动扩展大小
// TODO: 3、错误回滚
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"test.txt"];
    NSLog(@"path: %@", path);
    NSString *str = @"test str";
    [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    ProcessFile(path.UTF8String);
    NSString *result = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"result:%@", result);
}


@end

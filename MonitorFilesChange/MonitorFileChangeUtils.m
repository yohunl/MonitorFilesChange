//
//  MonitorFileChangeUtils.m
//  MonitorFilesChange
//
//  Created by lingyohunl on 2016/11/17.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import "MonitorFileChangeUtils.h"
#import <fcntl.h>
#import <sys/event.h>
@interface MonitorFileChangeUtils () {

	CFFileDescriptorRef kqref;
  CFRunLoopSourceRef  rls;
}
@property (strong) NSString *path;
@property (nonatomic,copy) void (^fileChangeBlock)(NSInteger type);
@end
@implementation MonitorFileChangeUtils
- (void)kqueueFired
{
  int             kq;
  struct kevent   event;
  struct timespec timeout = { 0, 0 };
  int             eventCount;
  
  kq = CFFileDescriptorGetNativeDescriptor(self->kqref);
  assert(kq >= 0);
  
  eventCount = kevent(kq, NULL, 0, &event, 1, &timeout);
  assert( (eventCount >= 0) && (eventCount < 2) );
  
  if (self.fileChangeBlock) {
    self.fileChangeBlock(eventCount);
  }
  
  CFFileDescriptorEnableCallBacks(self->kqref, kCFFileDescriptorReadCallBack);
}

static void KQCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, void *info)
{
  MonitorFileChangeUtils *helper = (MonitorFileChangeUtils *)(__bridge id)(CFTypeRef) info;
  [helper kqueueFired];
}

- (void) beginGeneratingDocumentNotificationsInPath: (NSString *) docPath
{
  int                     dirFD;
  int                     kq;
  int                     retVal;
  struct kevent           eventToAdd;
  CFFileDescriptorContext context = { 0, (void *)(__bridge CFTypeRef) self, NULL, NULL, NULL };
  
  dirFD = open([docPath fileSystemRepresentation], O_EVTONLY);
  assert(dirFD >= 0);
  
  kq = kqueue();
  assert(kq >= 0);
  
  eventToAdd.ident  = dirFD;
  eventToAdd.filter = EVFILT_VNODE;
  eventToAdd.flags  = EV_ADD | EV_CLEAR;
  eventToAdd.fflags = NOTE_WRITE;
  eventToAdd.data   = 0;
  eventToAdd.udata  = NULL;
  
  retVal = kevent(kq, &eventToAdd, 1, NULL, 0, NULL);
  assert(retVal == 0);
  
  self->kqref = CFFileDescriptorCreate(NULL, kq, true, KQCallback, &context);
  rls = CFFileDescriptorCreateRunLoopSource(NULL, self->kqref, 0);
  assert(rls != NULL);
  
  CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
  CFRelease(rls);
  CFFileDescriptorEnableCallBacks(self->kqref, kCFFileDescriptorReadCallBack);
}

- (void) dealloc
{
  self.path = nil;
  CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
  CFFileDescriptorDisableCallBacks(self->kqref, kCFFileDescriptorReadCallBack);
}

- (void)watcherForPath:(NSString *)aPath block:(void (^)(NSInteger type))block {
  self.path = aPath;
  self.fileChangeBlock = block;
  [self beginGeneratingDocumentNotificationsInPath:aPath];
}


@end

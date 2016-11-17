# MonitorFilesChange
检测/监测文件,文件夹的变化



> 我们有些时候,需要监测一个文件/文件夹的变化,例如在某个文件被修改的时候,可以获取到通知,或者我们有个播放列表是扫描某个文件夹下的所有文件,那么当这个目录新添或者删除一些文件后,我们的播放列表要同步更新,这种情况下,我们都需要监听文件/文件夹的变化

本文的demo已经上传到github上了,地址是 
由于在UNIX系统中,文件夹和文件其实对系统来说,只是属性不同而已,地位是一样的,在下文中,我可能会用文件,也可能会用文件夹,其实都是适用的.

碰到这样的一个需求,首先你的反应肯定是,这还不简单,我直接开一个定时器,每隔5s就重新扫描一下指定的文件夹/文件,这不就结了.....
其实这样也没有错,只是多开了一个定时器,效率低一些而已.但还是解决了问题的,对这种方式,假如文件夹中文件很多,效率就更低了,每次重新拿到列表后,还得做字符串的匹配等等...,这种方式,我就不多说了,任何一个开发者分分钟都可以写出这个低效的代码.

这是一个常见的需求,官方其实提供了两种思路来解决这个问题

### 方法一
官方给出的示例demo [Classes_DirectoryWatcher](https://developer.apple.com/library/content/samplecode/DocInteraction/Listings/Classes_DirectoryWatcher_m.html)
大体上的思路是:  
  1. 根据文件/文件夹的路径，调用open函数打开文件夹，得到文件句柄。
  2. 通过kqueue()函数创建一个kqueue队列来处理系统事件（文件创建或者删除），得到queueId
  3. 创建一个kevent结构体，设置相关属性，连同kqueue的ID一起传给kevent()函数，完成系统对kevent的关联。
  4. 调用CFFileDescriptorCreateRunloopSouce创建一个接收系统事件的runloop source，同时设置文件描述符的回调函数（回调函数采用C语言标准的回调函数格式）， 并加到默认的runloopMode中。
  5. 启用回调函数。
  6. 关闭kqueue，关闭文件夹

这样操作后,当文件/文件夹有变化,系统会触发相应的回调,你收到回调了,就可以进行各种处理了

其核心代码如下:
``` objc
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

```


### 方法二:GCD方式
大体思路是:
首先是使用O_EVTONLY模式打开文件/文件夹,然后创建一个GCD的source,当然了,其unsigned long mask参数要选VNODE系列的,例如要检测文件的些人,可以用DISPATCH_VNODE_WRITE

核心代码:
``` objc
- (void)__beginMonitoringFile
{
  
  _fileDescriptor = open([[_fileURL path] fileSystemRepresentation],
                         O_EVTONLY);
  dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                   _fileDescriptor,
                                   DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE | DISPATCH_VNODE_WRITE,
                                   defaultQueue);        
  dispatch_source_set_event_handler(_source, ^ {
    unsigned long eventTypes = dispatch_source_get_data(_source);
    [self __alertDelegateOfEvents:eventTypes];
  });
  
  dispatch_source_set_cancel_handler(_source, ^{
    close(_fileDescriptor);
    _fileDescriptor = 0;
    _source = nil;

    // If this dispatch source was canceled because of a rename or delete notification, recreate it
    if (_keepMonitoringFile) {
        _keepMonitoringFile = NO;
        [self __beginMonitoringFile];
    }
  });
  dispatch_resume(_source);
}

```



### 参考文档

[handling-filesystem-events-with-gcd](http://www.davidhamrick.com/2011/10/10/handling-filesystem-events-with-gcd.html)
[Monitoring-Files-With-GCD-Being-Edited-With-A-Text-Editor](http://www.davidhamrick.com/2011/10/13/Monitoring-Files-With-GCD-Being-Edited-With-A-Text-Editor.html)
[gcd-zhi-jian-ting-wen-jian](http://ksnowlv.github.io/blog/2014/09/06/gcd-zhi-jian-ting-wen-jian/)
[GCDWorkQueues](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html)
[iMonitorMyFiles](https://github.com/tblank555/iMonitorMyFiles)





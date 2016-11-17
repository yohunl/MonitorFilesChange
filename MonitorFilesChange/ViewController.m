//
//  ViewController.m
//  MonitorFilesChange
//
//  Created by lingyohunl on 2016/11/17.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import "ViewController.h"
#import "MonitorFileChangeHelp.h"
@interface ViewController ()<UITextFieldDelegate>
{
    NSURL *_testFileURL;
    __weak IBOutlet UITextField *_textToWriteField;
    __weak IBOutlet UITextView *_eventTextView;
}

@end



@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  // Create the test file URL
    NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                        inDomains:NSUserDomainMask] firstObject];
    _testFileURL = [documentsDirectory URLByAppendingPathComponent:@"testFile"];
    
    // Write some text to that test file
    [self __writeText:@"Whadderp?"
                toURL:_testFileURL];
    
    MonitorFileChangeHelp *fileMonitor = [MonitorFileChangeHelp new];
    [fileMonitor watcherForPath:_testFileURL.absoluteString block:^(NSInteger type) {
    if (type == DISPATCH_VNODE_ATTRIB) {
     [self __logTextToScreen:@"Test file's DISPATCH_VNODE_ATTRIB changed."];
    }
    else if (type == DISPATCH_VNODE_DELETE) {
     [self __logTextToScreen:@"Test file's DISPATCH_VNODE_DELETE changed."];
    }
    else if (type ==  DISPATCH_VNODE_EXTEND) {
       [self __logTextToScreen:@"Test file's DISPATCH_VNODE_EXTEND changed."];
    }
    else if (type ==  DISPATCH_VNODE_LINK) {
       [self __logTextToScreen:@"Test file's DISPATCH_VNODE_LINK changed."];
    }
    else if (type ==  DISPATCH_VNODE_RENAME){
      [self __logTextToScreen:@"Test file's DISPATCH_VNODE_RENAME changed."];
    }
    else if (type ==  DISPATCH_VNODE_REVOKE) {
      [self __logTextToScreen:@"Test file's DISPATCH_VNODE_REVOKE changed."];
    }
    else if (type == DISPATCH_VNODE_WRITE) {
      [self __logTextToScreen:@"Test file's DISPATCH_VNODE_WRITE changed."];
    }

    }];
   
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{

    [self.view endEditing:YES];
}

#pragma mark - Actions

- (IBAction)write:(UIButton *)sender
{
    [self __writeText:_textToWriteField.text
                toURL:_testFileURL];
    [self dismissKeyboard:sender];
}

- (void)dismissKeyboard:(UIButton *)sender
{
    [_textToWriteField resignFirstResponder];
}

#pragma mark - UI Helper Methods

- (void)__writeText:(NSString *)text toURL:(NSURL *)URL
{
    [self __logTextToScreen:[NSString stringWithFormat:@"Writing text: %@", text]];
    
    NSData *dataFromText = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    [dataFromText writeToURL:URL
                     options:kNilOptions
                       error:nil];
}

- (void)__logTextToScreen:(NSString *)text
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        NSString *logTime = [dateFormatter stringFromDate:[NSDate date]];
        
        NSString *previousText = _eventTextView.text;
        _eventTextView.text = [NSString stringWithFormat:@"%@: %@\n%@", logTime, text, previousText];
    });
}

#pragma mark - UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self write:nil];
    return YES;
}



@end

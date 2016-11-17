//
//  MyTableViewController.m
//  MonitorFilesChange
//
//  Created by lingyohunl on 2016/11/17.
//  Copyright © 2016年 yohunl. All rights reserved.
//

#import "MyTableViewController.h"
#import "MonitorFileChangeUtils.h"
@interface MyTableViewController ()
{
  NSArray *items;
  MonitorFileChangeUtils *utils;
}

@end

@implementation MyTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
  [self scanDocuments];
  
  NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
  utils = [MonitorFileChangeUtils new];
  [utils watcherForPath:path block:^(NSInteger type) {
    [self scanDocuments];
  }];
}


// Number of sections
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
  return 1;
}

// Rows per section
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
  return items.count;
}

// Return a cell for the index path
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  cell.textLabel.text = [items objectAtIndex:indexPath.row];
  return cell;
}

- (void) scanDocuments
{
  NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
  items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
  [self.tableView reloadData];
}

- (IBAction)addFile:(id)sender {
  NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
  NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
  NSString *filename = guid;
  NSString *filestring =  [path stringByAppendingPathComponent:filename]; 
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL fileAlreadyExists = [fileManager fileExistsAtPath:filestring];
  
  if (!fileAlreadyExists) {
    NSData *data = [NSData data];
    [fileManager createFileAtPath:filestring contents:data attributes:nil];
  }
 
  
    
   
}


@end

//
//  AW_StatusViewController.m
//  Statuses
//
//  Created by Alan Wang on 1/6/15.
//  Copyright (c) 2015 Alan Wang. All rights reserved.
//

#import "AW_StatusViewController.h"

@interface AW_StatusViewController ()

@property (nonatomic, strong) NSMutableArray *connectedDevices; // This is an array because the list of devices to
                                                                // choose from will be a set so there will be no duplicates

@end

@implementation AW_StatusViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Navigation bar stuff
    self.navigationItem.title = @"Statuses";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didPressAddButton)];
    
    // Temporary setup to test tableview
    self.connectedDevices = @[@[@"name1", @"status1"], @[@"name2", @"status2"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation Bar
- (void)didPressAddButton
{
    // Instantiate modal view controller
    // Present modal view controller
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.connectedDevices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"UITableViewCell"];
    
    // Temporary setup to test tableview
    NSArray *cellContents = self.connectedDevices[indexPath.row];
    
    cell.textLabel.text = cellContents[0];
    cell.detailTextLabel.text = cellContents[1];
    
    return cell;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Dismiss keyboard
    [textField resignFirstResponder];
    
    // Update characteristics
    
    
    
    return YES;
}

@end

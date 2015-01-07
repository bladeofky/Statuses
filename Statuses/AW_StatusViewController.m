//
//  AW_StatusViewController.m
//  Statuses
//
//  Created by Alan Wang on 1/6/15.
//  Copyright (c) 2015 Alan Wang. All rights reserved.
//

#import "AW_StatusViewController.h"
#import "AW_ConnectViewController.h"

@interface AW_StatusViewController ()



@end

@implementation AW_StatusViewController
#pragma mark - Accessors
-(NSArray *)connectedDevices
{
    if (!_connectedDevices) {
        _connectedDevices = @[];
    }
    
    return _connectedDevices;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Navigation bar stuff
    self.navigationItem.title = @"Statuses";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didPressAddButton)];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
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
    AW_ConnectViewController *connectViewController = [[AW_ConnectViewController alloc]init];
    connectViewController.connectedPeripherals = [self.connectedDevices mutableCopy];
    connectViewController.statusVC = self;
    UINavigationController *dummyNavigationController = [[UINavigationController alloc]initWithRootViewController:connectViewController];
    
    [self presentViewController:dummyNavigationController animated:YES completion:nil];
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
    
    CBPeripheral *peripheral = self.connectedDevices[indexPath.row];
    
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = [peripheral.identifier UUIDString];
    
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

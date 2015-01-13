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
    // Get values for all connected peripherals
    for (CBPeripheral *peripheral in self.connectedDevices) {
        for (CBService *service in peripheral.services) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
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
    
    [self presentViewController:dummyNavigationController animated:NO completion:nil];
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
    
    if (peripheral) {
        CBService *service = peripheral.services[0];
        
        CBCharacteristic *userNameCharacteristic = service.characteristics[0];
        CBCharacteristic *statusCharacteristic = service.characteristics[1];
        
        NSData *userNameData = userNameCharacteristic.value;
        NSData *statusData = statusCharacteristic.value;
        
        NSString *userName = [[NSString alloc]initWithData:userNameData encoding:NSUTF8StringEncoding];
        NSString *status = [[NSString alloc]initWithData:statusData encoding:NSUTF8StringEncoding];
        
        cell.textLabel.text = userName;
        cell.detailTextLabel.text = status;

    }

    return cell;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Dismiss keyboard
    [textField resignFirstResponder];
    
    // Update characteristics
    NSData *data = [textField.text dataUsingEncoding:NSUTF8StringEncoding];
    BOOL isUpdateSuccessful;
    
    if (textField == self.nameTextField) {
        isUpdateSuccessful = [self.peripheralManager updateValue:data forCharacteristic:self.nameCharacteristic onSubscribedCentrals:nil];
    }
    else if (textField == self.statusTextField) {
        isUpdateSuccessful = [self.peripheralManager updateValue:data forCharacteristic:self.statusCharacteristic onSubscribedCentrals:nil];
    }
    else {
        // Intentionally left blank
    }
    
    if (!isUpdateSuccessful) {
        NSLog(@"Update was not successful");
    }
    
    return YES;
}

#pragma mark - CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Discovered service(s): %@", peripheral.services);
        // Discover the characteristics for each service
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Discovered characteristics %@ for service %@", service.characteristics, service);
        for (CBCharacteristic *characteristic in service.characteristics) {
            // Subscribe to characteristics
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error subscribing to characteristics: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Subscribes to characteristic: %@", characteristic);
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Value of %@ updated to: %@", characteristic, characteristic.value);
    [self.tableView reloadData];
}

@end

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

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBCentralManager *centralManager;



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

-(CBUUID *)statusServiceUUID
{
    if (!_statusServiceUUID) {
        NSString *serviceUUIDString = @"FDBC7F6F-1A7F-4259-92CE-CD63BE9920F1"; // Randomly generated using uuidgen in terminal
        _statusServiceUUID = [CBUUID UUIDWithString:serviceUUIDString];
    }
    
    return _statusServiceUUID;
}

-(CBMutableCharacteristic *)nameCharacteristic
{
    if (!_nameCharacteristic) {
        NSString *nameCharacteristicUUIDString = @"5ED26EFA-1392-43D1-A57C-4FA763C9DA12";
        CBUUID *nameCharacteristicUUID = [CBUUID UUIDWithString:nameCharacteristicUUIDString];
        _nameCharacteristic = [[CBMutableCharacteristic alloc]initWithType:nameCharacteristicUUID
                                                                properties:CBCharacteristicPropertyNotify
                                                                     value:nil
                                                               permissions:CBAttributePermissionsReadable];
    }
                                   
    return _nameCharacteristic;
}

-(CBMutableCharacteristic *)statusCharacteristic
{
    if (!_statusCharacteristic) {
        NSString *statusCharacteristicUUIDString = @"14884F8C-10ED-45CA-BD5C-35BDC08ACEB0";
        CBUUID *statusCharacteristicUUID = [CBUUID UUIDWithString:statusCharacteristicUUIDString];
        
        _statusCharacteristic = [[CBMutableCharacteristic alloc]initWithType:statusCharacteristicUUID
                                                                  properties:CBCharacteristicPropertyNotify
                                                                       value:nil
                                                                 permissions:CBAttributePermissionsReadable];
    }
    
    return _statusCharacteristic;

}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Navigation bar stuff
    self.navigationItem.title = @"Statuses";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didPressAddButton)];
    
    // Set up Core Bluetooth managers
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil options:nil];

}

-(void)viewWillAppear:(BOOL)animated
{
    // Update characteristics
    NSData *nameData = [self.nameTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    NSData *statusData = [self.statusTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.peripheralManager updateValue:nameData forCharacteristic:self.nameCharacteristic onSubscribedCentrals:nil];
    [self.peripheralManager updateValue:statusData forCharacteristic:self.statusCharacteristic onSubscribedCentrals:nil];
    
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
    // Instantiate modal view controller and pass required references
    AW_ConnectViewController *connectViewController = [[AW_ConnectViewController alloc]init];
    connectViewController.connectedPeripherals = [self.connectedDevices mutableCopy];
    connectViewController.statusVC = self;
    
    self.centralManager.delegate = connectViewController;
    connectViewController.centralManager = self.centralManager;
    
    self.peripheralManager.delegate = connectViewController;
    connectViewController.peripheralManager = self.peripheralManager;

    
    // Present modal view controller
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
    NSData *nameData = [self.nameTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheralManager updateValue:nameData forCharacteristic:self.nameCharacteristic onSubscribedCentrals:nil];
    
    NSData *statusData = [self.statusTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheralManager updateValue:statusData forCharacteristic:self.statusCharacteristic onSubscribedCentrals:nil];
    
    return YES;
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Log state
    NSLog(@"Central Manager state update to: %@", [self stringForCentralManagerState:central.state]);
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        self.isReadyToScan = YES;
    }
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSMutableArray *temp = [self.connectedDevices mutableCopy];
    [temp removeObject:peripheral];
    self.connectedDevices = [temp copy];
    
    [self.tableView reloadData];
}


#pragma mark - CBPeripheralManagerDelegate
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Log state
    NSLog(@"Peripheral Manager state update to: %@", [self stringForPeripheralManagerState:peripheral.state]);
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        
        // Create/add service
        CBMutableService *statusService = [[CBMutableService alloc]initWithType:self.statusServiceUUID primary:YES];
        statusService.characteristics = @[self.nameCharacteristic, self.statusCharacteristic];
        [self.peripheralManager addService:statusService];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Successfully published service: %@", service);
        self.isReadyToAdvertise = YES;
    }
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Retry sending status data in case underlying queue is full when we first attempt to send it.
    NSData *statusData = [self.statusTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheralManager updateValue:statusData forCharacteristic:self.statusCharacteristic onSubscribedCentrals:nil];
}

//-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
//{
//    CBCharacteristic *characteristic;
//    
//    if ([request.characteristic.UUID isEqual:self.nameCharacteristic.UUID]) {
//        characteristic = self.nameCharacteristic;
//    }
//    else if ([request.characteristic.UUID isEqual:self.statusCharacteristic.UUID]) {
//        characteristic = self.statusCharacteristic;
//    }
//    else {
//        // Left blank
//    }
//    
//    request.value = characteristic.value;
//    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
//}

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


#pragma mark - Helper methods
- (NSString *)stringForCentralManagerState: (CBCentralManagerState)state
{
    NSString *output;
    
    switch (state) {
        case CBCentralManagerStateUnknown:
            output = @"State unknown, update imminent.";
            break;
        case CBCentralManagerStatePoweredOn:
            output = @"Bluetooth is currently powered on and available to use.";
            break;
        case CBCentralManagerStatePoweredOff:
            output = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStateResetting:
            output = @"The connection with the system service was momentarily lost, update imminent.";
            break;
        case CBCentralManagerStateUnauthorized:
            output = @"The application is not authorized to use the Bluetooth Low Energy Central/Client role.";
            break;
        case CBCentralManagerStateUnsupported:
            output = @"The platform does not support the Bluetooth Low Energy Central/Client role.";
            break;
        default:
            output = @"CBManagerState not recognized.";
            break;
    }
    
    return output;
}

- (NSString *)stringForPeripheralManagerState: (CBPeripheralManagerState)state
{
    NSString *output;
    
    switch (state) {
        case CBPeripheralManagerStateUnknown:
            output = @"The current state of the peripheral manager is unknown; an update is imminent.";
            break;
        case CBPeripheralManagerStateResetting:
            output = @"The connection with the system service was momentarily lost; an update is imminent.";
            break;
        case CBPeripheralManagerStateUnsupported:
            output = @"The platform doesn't support the Bluetooth low energy peripheral/server role.";
            break;
        case CBPeripheralManagerStateUnauthorized:
            output = @"The app is not authorized to use the Bluetooth low energy peripheral/server role.";
            break;
        case CBPeripheralManagerStatePoweredOff:
            output = @"Bluetooth is currently powered off.";
            break;
        case CBPeripheralManagerStatePoweredOn:
            output = @"Bluetooth is currently powered on and is available to use.";
            break;
        default:
            output = @"Unknown Peripheral Manager State.";
            break;
    }
    
    return output;
}

@end

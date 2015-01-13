//
//  AW_ConnectViewController.m
//  Statuses
//
//  Created by Alan Wang on 1/6/15.
//  Copyright (c) 2015 Alan Wang. All rights reserved.
//

#import "AW_ConnectViewController.h"
#import "AW_StatusViewController.h"

@interface AW_ConnectViewController ()

@property (nonatomic, strong) NSMutableOrderedSet *discoveredPeripherals;

@end

@implementation AW_ConnectViewController

#pragma mark - Accessors
-(NSMutableOrderedSet *)discoveredPeripherals
{
    if (!_discoveredPeripherals) {
        _discoveredPeripherals = [[NSMutableOrderedSet alloc]init];
    }
    
    return _discoveredPeripherals;
}

-(NSMutableArray *)connectedPeripherals
{
    if (!_connectedPeripherals) {
        _connectedPeripherals = [[NSMutableArray alloc]init];
    }
    
    return _connectedPeripherals;
}

#pragma mark - View Lifecycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Navigation Bar Items
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didPressCancelButton)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDoneButton)];
    self.navigationItem.title = @"Connect To Devices";
    
    // Set up table view
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    // Begin scanning and advertising
    #warning TODO: It would be better to use KVO for isReadyToScan and isReadyToAdvertise
    if (self.statusVC.isReadyToScan) {
        [self.centralManager scanForPeripheralsWithServices:@[self.statusVC.statusServiceUUID] options:@{CBCentralManagerOptionShowPowerAlertKey : @YES}];
        NSLog(@"Central Manager started scanning");
    }
    
    if (self.statusVC.isReadyToAdvertise) {
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[self.statusVC.statusServiceUUID]}];
    }
    
}

#pragma mark - Navigation
- (void)didPressCancelButton
{
    [self.centralManager stopScan];
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Central manager stopped scanning");
    NSLog(@"Peripheral manager stopped advertising");
    
    // Change delegates
    self.centralManager.delegate = self.statusVC;
    self.peripheralManager.delegate = self.statusVC;
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didPressDoneButton
{
    // Stop scanning and advertising
    [self.centralManager stopScan];
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Central manager stopped scanning");
    NSLog(@"Peripheral manager stopped advertising");
    
    // Change delegates
    self.centralManager.delegate = self.statusVC;
    self.peripheralManager.delegate = self.statusVC;
    
    // Copy connected peripherals back to Status view controller
    self.statusVC.connectedDevices = [self.connectedPeripherals copy];
    
    // Dismiss this view controller
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.discoveredPeripherals count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    CBPeripheral *peripheral = [self.discoveredPeripherals objectAtIndex:indexPath.row];
    
    if ([self.connectedPeripherals containsObject:peripheral]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = peripheral.name;
    
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral *peripheral = [self.discoveredPeripherals objectAtIndex:indexPath.row];
    [self.centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered peripheral: %@", peripheral.name);
    
    // Add peripheral to table data
    [self.discoveredPeripherals addObject:peripheral];
    
    // Update tableview
    [self.tableView reloadData];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to peripheral: %@", peripheral.name);
    peripheral.delegate = self.statusVC;
    [self.connectedPeripherals addObject:peripheral];
    
    #warning TODO: Why does this get called repeatedly?
    // Discover peripheral's services and characteristics
    [peripheral discoverServices:@[self.statusVC.statusServiceUUID]];

    // Update table view (for checkmark accessory)
    [self.tableView reloadData];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnected from peripheral: %@", peripheral.name);
    [self.tableView reloadData];
}

#pragma mark - CBPeripheralManagerDelegate

-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error) {
        NSLog(@"Error advertising services: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Began advertising services");
    }
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

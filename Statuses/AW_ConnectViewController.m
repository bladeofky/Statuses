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

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *statusServiceUUID;

@property (nonatomic, strong) NSMutableOrderedSet *discoveredPeripherals;

@end

@implementation AW_ConnectViewController

#pragma mark - Accessors
-(CBUUID *)statusServiceUUID
{
    if (!_statusServiceUUID) {
        NSString *serviceUUIDString = @"FDBC7F6F-1A7F-4259-92CE-CD63BE9920F1"; // Randomly generated using uuidgen in terminal
        _statusServiceUUID = [CBUUID UUIDWithString:serviceUUIDString];
    }
    
    return _statusServiceUUID;
}

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
    
    // Instantiate Central Manager and start scanning for peripherals
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil]; //Scanning will automatically begin when the correct state is reached
    
    // Instantiate Peripheral Manager
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil options:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation
- (void)didPressCancelButton
{
    [self.centralManager stopScan];
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Central manager stopped scanning");
    NSLog(@"Peripheral manager stopped advertising");
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didPressDoneButton
{
    // Stop scanning and advertising
    [self.centralManager stopScan];
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Central manager stopped scanning");
    NSLog(@"Peripheral manager stopped advertising");
    
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
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Log state
    NSLog(@"Central Manager state update to: %@", [self stringForCentralManagerState:central.state]);
    
    // If ready, begin scanning for peripherals
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:@[self.statusServiceUUID] options:@{CBCentralManagerOptionShowPowerAlertKey : @YES}];
        NSLog(@"Central Manager started scanning");
    }
}

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
    [self.connectedPeripherals addObject:peripheral];
    
    // Update table view (for checkmark accessory)
    [self.tableView reloadData];
}

#pragma mark - CBPeripheralManagerDelegate
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Log state
    NSLog(@"Peripheral Manager state update to: %@", [self stringForPeripheralManagerState:peripheral.state]);
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        // Create characteristics and add service for sending and receiving name/status
        NSString *nameCharacteristicUUIDString = @"5ED26EFA-1392-43D1-A57C-4FA763C9DA12";
        NSString *statusCharacteristicUUIDString = @"14884F8C-10ED-45CA-BD5C-35BDC08ACEB0";
        
        CBUUID *nameCharacteristicUUID = [CBUUID UUIDWithString:nameCharacteristicUUIDString];
        CBUUID *statusCharacteristicUUID = [CBUUID UUIDWithString:statusCharacteristicUUIDString];
        
        CBMutableCharacteristic *nameCharacteristic = [[CBMutableCharacteristic alloc]initWithType:nameCharacteristicUUID
                                                                                        properties:CBCharacteristicPropertyRead
                                                                                             value:nil
                                                                                       permissions:CBAttributePermissionsReadable];
        CBMutableCharacteristic *statusCharacteristic = [[CBMutableCharacteristic alloc]initWithType:statusCharacteristicUUID
                                                                                          properties:CBCharacteristicPropertyRead
                                                                                               value:nil
                                                                                         permissions:CBAttributePermissionsReadable];
        
        CBMutableService *statusService = [[CBMutableService alloc]initWithType:self.statusServiceUUID primary:YES];
        statusService.characteristics = @[nameCharacteristic, statusCharacteristic];
        [self.peripheralManager addService:statusService];
        
        // Start advertising
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[self.statusServiceUUID]}];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Successfully published service with UUID: %@", service.UUID.UUIDString);
    }
}

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
